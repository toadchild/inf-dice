#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <assert.h>
#include <pthread.h>

#define B_MAX  5
#define SAVES_MAX  3
#define SUCCESS_MAX (B_MAX * SAVES_MAX)
#define STAT_MAX 40
#define ROLL_MAX 20
#define DAM_MAX 20

// Other assumptions require that NUM_THREADS equals ROLL_MAX
#define NUM_THREADS ROLL_MAX
#define MULTI_THREADED 1

#define MAX(a,b) (a > b ? a : b)
#define MIN(a,b) (a < b ? a : b)

enum ammo_t{
    AMMO_NORMAL,
    AMMO_DA,
    AMMO_EXP,
    AMMO_FIRE,
    AMMO_NONE,
};

static const char *ammo_labels[] = {
    "NORMAL",
    "DA",
    "EXP",
    "FIRE",
    "NONE",
};

/*
 * This is an implementation of Infinity dice math that enumerates every
 * possible combination given the BS and B of both models and tabulates
 * the outcomes.
 *
 * Created by Jonathan Polley.
 */

/*
 * Structure for a single die result.
 */
struct result{
    int value;          // Number that was rolled
    int is_hit;         // If the die is a hit (true on a crit)
    int is_crit;        // If the die is a crit
};

/*
 * Data structure for each player.
 *
 * Includes both player attributes and their hit/success tables.
 */
struct player{
    int player_num;             // ID of player
    int stat;                   // target number for rolls
    int crit_val;               // minimum value for a crit
    int arm_bonus;              // armor bonus if beaten in CC
    int burst;                  // number of dice
    int dam;                    // damage value
    int modified_dam;           // damage value after conditional modifiers
    int template;               // Is this a template weapon
    enum ammo_t ammo;           // ammo type

    struct result d[B_MAX];     // current set of dice being evaluated

    // count of hit types
    // first index is number of regular hits
    // second index is number of crits
    // third index is the damage of the hit
    // value is number of times this happened
    int64_t hit[B_MAX + 1][B_MAX + 1][DAM_MAX + 1];;

    // Number of times N successes was inflicted
    double success[SUCCESS_MAX + 1];
};

/*
 * Master data structure.
 */
struct dice{
    int thread_num;
    struct player p1, p2;

    int64_t num_rolls, rolls_made;
};




/*
 * print_player_hits()
 *
 * Helper for print_tables().  Prints likelyhood that player scored a
 * certain number of hits/crits.
 */
static int64_t print_player_hits(struct player *p, int p_num, int64_t num_rolls){
    int hits, crits, dam;
    int64_t n_rolls = 0;

    for(hits = 0; hits <= B_MAX; hits++){
        for(crits = 0; crits <= B_MAX; crits++){
            for(dam = 0; dam <= DAM_MAX; dam++){
                if((hits > 0 || crits > 0) && p->hit[hits][crits][dam] > 0){
                    printf("P%d Hits: %2d Crits: %2d at Dam: %2d - %6.2f%% (%lld)\n", p_num, hits, crits, dam, 100.0 * p->hit[hits][crits][dam] / num_rolls, p->hit[hits][crits][dam]);
                    n_rolls += p->hit[hits][crits][dam];
                }
            }
        }
    }
    printf("\n");

    return n_rolls;
}

/*
 * print_player_successes()
 *
 * Helper for print_tables().  Prints likelyhood that player scored a
 * certain number of successes.
 */
double print_player_successes(struct player *p, int p_num, int64_t num_rolls){
    double cumul_prob;
    int success;
    double n_success = 0;

    cumul_prob = 0.0;
    for(success = SUCCESS_MAX; success > 0; success--){
        if(p->success[success] > 0){
            double prob = 100.0 * p->success[success] / num_rolls;
            cumul_prob += prob;
            if(prob >= 0.005){
                printf("P%d Scores %2d Success(es): %6.2f%%     %2d+ Successes: %6.2f%%\n", p_num, success, prob, success, cumul_prob);
            }

            n_success += p->success[success];
        }
    }
    printf("\n");

    return n_success;
}

/*
 * print_tables()
 *
 * Prints generated data in an orderly format.
 *
 * Prints both raw hit data and success statistics.
 */
static void print_tables(struct dice *d){
    int64_t n_rolls = 0, n = 0;
    int dam;
    double n_success = 0;
    double n2;

    printf("Total Hits: %lld\n", d->num_rolls);
    printf("Actual Rolls Made: %lld\n", d->rolls_made);
    printf("\n");

    n_rolls += print_player_hits(&d->p1, 1, d->num_rolls);

    // sum up all misses from both players
    for(dam = 0; dam <= DAM_MAX; dam++){
        n += d->p1.hit[0][0][dam] + d->p2.hit[0][0][dam];
    }

    n_rolls += n;
    printf("No Hits: %6.2f%% %lld\n", 100.0 * n / d->num_rolls, n);
    printf("\n");

    n_rolls += print_player_hits(&d->p2, 2, d->num_rolls);
    assert(n_rolls == d->num_rolls);

    printf("\n");
    printf("======================================================\n");
    printf("\n");

    n_success += print_player_successes(&d->p1, 1, d->num_rolls);

    n2 = d->p1.success[0] + d->p2.success[0];
    n_success += n2;
    printf("No Successes: %6.2f%%\n", 100.0 * n2 / d->num_rolls);
    printf("\n");

    n_success += print_player_successes(&d->p2, 2, d->num_rolls);
    assert(round(n_success) == d->num_rolls);
}

/*
 * factorial()
 *
 * Standard numerical function. Precalculated for efficiency.
 */
static int64_t factorial(int n){
    switch(n){
        case 0:
        case 1:
            return 1;
            break;
        case 2:
            return 2;
            break;
        case 3:
            return 6;
            break;
        case 4:
            return 24;
            break;
        case 5:
            return 120;
            break;
        default:
            return n * factorial(n - 1);
            break;
    }
}

/*
 * choose()
 *
 * Standard probability/statistics function.
 */
static int64_t choose(int n, int k){
    return factorial(n) / (factorial(k) * factorial(n - k));
}

/*
 * hit_prob()
 *
 * Uses binomial theorem to calculate the likelyhood that a certain number
 * of hits were successful.
 */
static double hit_prob(int successes, int trials, double probability){
    return choose(trials, successes) * pow(probability, successes) * pow(1 - probability, trials - successes);
}

/*
 * fire_damage()
 *
 * Helper for calc_player_successes(). Recursively calculates how many successes
 * Fire ammo could have inflicted.
 */

static void fire_damage(struct player *p, int hits, int total_hits, int dam, double prob, int depth){
    int success;

    // record damage at bottom of stack or when we hit the cap
    if(total_hits >= SUCCESS_MAX || depth == 0){
        p->success[MIN(total_hits, SUCCESS_MAX)] += prob;
        return;
    }

    for(success = 0; success <= hits; success++){
        double new_prob = hit_prob(success, hits, ((double)dam) / ROLL_MAX);
        int new_depth = depth - 1;

        if(success == 0){
            // record data if no additional hits were scored.
            new_depth = 0;
        }

        fire_damage(p, success, total_hits + success, dam, prob * new_prob, new_depth);
    }
}

/*
 * calc_player_successes()
 *
 * For a given player, traverses their hit/crit table and determines how
 * likely they are to have inflicted successes on their opponent.
 */
static void calc_player_successes(struct player *p){
    int hits, crits, dam, success;

    for(hits = 0; hits <= B_MAX; hits++){
        for(crits = 0; crits <= B_MAX; crits++){
            for(dam = 0; dam <= DAM_MAX; dam++){
                if(p->hit[hits][crits][dam] > 0){
                    // We scored this many hits and crits
                    // now we need to determine how likely it was we caused however many successes
                    // Gotta binomialize!

                    // crits always hit, so they are an offset into the success array
                    // then we count up to the max number of hits.
                    int saves;
                    if(p->ammo == AMMO_FIRE){
                        // Fire ammo
                        // If you fail the save, you must roll again, ad infinitum.
                        fire_damage(p, hits + crits, crits, dam, p->hit[hits][crits][dam], SUCCESS_MAX);
                    }else if(p->ammo == AMMO_NONE){
                        // Non-lethal skill (Dodge, Smoke)
                        // There is no saving throw. Number of successes still
                        // matters for smoke.
                        p->success[crits + hits] += p->hit[hits][crits][dam];
                    }else{
                        switch(p->ammo){
                            case AMMO_DA:
                                // DA - two saves per hit, plus the second die for crits
                                saves = 2 * hits + crits;
                                break;
                            case AMMO_EXP:
                                // EXP - three saves per hit, plus the extra two for crits
                                saves = 3 * hits + 2 * crits;
                                break;
                            case AMMO_NORMAL:
                                // Normal - one save per regular hit
                                saves = hits;
                                break;
                            default:
                                printf("ERROR: P%d Unknown ammo type: %d\n", p->player_num, p->ammo);
                                exit(1);
                                break;
                        }

                        for(success = 0; success <= saves; success++){
                            assert(crits + success <= SUCCESS_MAX);
                            p->success[crits + success] += hit_prob(success, saves, ((double)dam) / ROLL_MAX) * p->hit[hits][crits][dam];
                        }
                    }
                }
            }
        }
    }
}

/*
 * calc_successes()
 *
 * Causes the success tables to be calculated for each player.
 */
static void calc_successes(struct dice *d){
    calc_player_successes(&d->p1);
    calc_player_successes(&d->p2);
}

/*
 * count_player_results()
 *
 * Compares each die for a given player to the best roll for the other
 * player. Then counts how many uncanceled hits/crits this player scored.
 */
static void count_player_results(struct player *us, struct player *them, int *hits, int *crits, int *dam){
    int i;
    int best;   // offset into them's d array for their best roll

    *hits = 0;
    *crits = 0;

    // Find highest successful roll of other player
    // Use the fact that the array is sorted
    // If they scored a hit, grant them an ARM bonus
    *dam = us->dam;
    best = 0;
    for(i = them->burst - 1; i >= 0; i--){
        if(them->d[i].is_hit){
            best = i;
            *dam = MAX(us->dam - them->arm_bonus, 0);
            break;
        }
    }

    assert(best >= 0 && best < them->burst);

    for(i = us->burst - 1; i >= 0; i--){
        if(us->d[i].is_hit){
            if(us->d[i].is_crit){
                // crit, see if it was canceled
                if(!(them->stat >= us->stat && them->d[best].is_crit)){
                    (*crits)++;
                }else{
                    // All lower dice will also be canceled
                    break;
                }
            }else{
                // it was a regular hit, see if it was canceled
                if(!(us->template && them->d[best].is_hit) &&
                        (them->template || !them->d[best].is_hit ||
                        (!them->d[best].is_crit &&
                        (them->d[best].value < us->d[i].value ||
                        (them->d[best].value == us->d[i].value && them->stat < us->stat))))){
                    (*hits)++;
                }else{
                    // All lower dice will also be canceled
                    break;
                }
            }
        }
    }
}

/*
 * repeat_factor()
 *
 * Helper for count_roll_results()
 *
 * Counts the lengths of sequences in the die rolls in order to find the
 * factorial denominator for the data multiplier. This is easy to do since
 * the roller outputs the numbers in sorted order.
 */
static int repeat_factor(struct player *p){
    int seq_len = 1, seq_num;
    int i;
    int fact = 1;

    seq_num = p->d[0].value;
    for(i = 1; i < p->burst; i++){
        if(p->d[i].value != seq_num){
            if(seq_len > 1){
                fact *= factorial(seq_len);
            }
            seq_num = p->d[i].value;
            seq_len = 1;
        }else{
            seq_len++;
        }
    }
    if(seq_len > 1){
        fact *= factorial(seq_len);
    }

    return fact;
}

/*
 * miss_factor()
 *
 * Helper for count_roll_results()
 *
 * Counts how many die rolls we didn't bother rolling because we know
 * they were going to miss.
 */
static int miss_factor(struct player *p){
    int i;
    int fact = 1;

    for(i = 0; i < p->burst; i++){
        if(p->d[i].is_hit){
            continue;
        }
        fact *= ROLL_MAX - p->d[i].value + 1;
    }

    return fact;
}

/*
 * template_factor()
 *
 * Helper for count_roll_results()
 *
 * Counts how many die rolls we didn't bother rolling because template
 * weapons auto-hit.
 */
static int template_factor(struct player *p){
    if(p->template){
        return pow(ROLL_MAX, p->burst);
    }

    return 1;
}

/*
 * print_roll
 *
 * Test function that prints roll values and their multiplier.
 */
void print_roll(struct dice *d, int64_t multiplier, int dam1, int dam2){
    int i;
    for(i = 0; i < d->p1.burst; i++){
        printf("%02d ", d->p1.d[i].value);
    }
    printf("| ");
    for(i = 0; i < d->p2.burst; i++){
        printf("%02d ", d->p2.d[i].value);
    }
    printf("x %lld", multiplier);

    printf("| dam1: %d dam2: %d\n", dam1, dam2);
}

/*
 * count_roll_results()
 *
 * For a given configuration of dice, calculates who won the FtF roll,
 * and how many hits/crits they scored.  Adds these to a running tally.
 *
 * Uses factorials to calculate a multiplicative factor to un-stack the
 * duplicate die rolls that the matrix symmetry optimization cut out.
 */
static void count_roll_results(struct dice *d){
    int hits1, crits1;
    int hits2, crits2;
    int fact1, fact2;
    int dam1, dam2;
    int64_t multiplier;

    // Hits are counted as 'multiplier' since we are using matrix symmetries
    fact1 = repeat_factor(&d->p1);
    fact2 = repeat_factor(&d->p2);
    multiplier = factorial(d->p1.burst) / fact1 * factorial(d->p2.burst) / fact2;

    // more multipliers for rolling up all misses
    multiplier *= miss_factor(&d->p1);
    multiplier *= miss_factor(&d->p2);

    // more multipliers for template weapons
    multiplier *= template_factor(&d->p1);
    multiplier *= template_factor(&d->p2);

    count_player_results(&d->p1, &d->p2, &hits1, &crits1, &dam1);
    count_player_results(&d->p2, &d->p1, &hits2, &crits2, &dam2);

    //print_roll(d, multiplier, dam1, dam2);

    if(crits1 + hits1){
        d->p1.hit[hits1][crits1][dam1] += multiplier;
    }

    if(hits2 + crits2){
        d->p2.hit[hits2][crits2][dam2] += multiplier;
    }

    // Need to ensure we only count totally whiffed rolls once
    if(hits1 + crits1 + hits2 + crits2 == 0){
        d->p2.hit[0][0][0] += multiplier;
    }

    d->num_rolls += multiplier;
    d->rolls_made++;
}

/*
 * annotate_roll()
 *
 * This is a helper for roll_dice() that marks whether a given die is a
 * hit or a crit.
 *
 */
static void annotate_roll(struct player *p, int n){
    if(p->d[n].value <= p->stat){
        p->d[n].is_hit = 1;

        if(p->d[n].value >= p->crit_val){
            p->d[n].is_crit = 1;
        }else{
            p->d[n].is_crit = 0;
        }
    }else{
        p->d[n].is_hit = 0;
        p->d[n].is_crit = 0;
    }
}

/*
 * roll_dice()
 *
 * Recursive die roller.  Generates all possible permutations of dice,
 * calls into count_roll_results() as each row is completed.
 *
 * Uses matrix symmetries to cut down on the number of identical
 * evaluations.
 */
static void roll_dice(int b1, int b2, int start1, int start2, struct dice *d, int thread_num){
    int i, b;
    int step;

    // step is used for outermost loop to divide up data between threads
    // Each thread does a single digit of first die roll
    if(thread_num >= 0){
        step = ROLL_MAX;
        start1 = thread_num + 1;
    }else{
        step = 1;
    }

    if(b1 > 0){
        // roll next die for P1
        for(i = start1; i <= ROLL_MAX; i += step){
            b = d->p1.burst - b1;

            d->p1.d[b].value = i;

            annotate_roll(&d->p1, b);

            // If this die is a miss, we know all higher rolls are misses, too.
            // Send in a multiplier and exit this loop early.
            // Don't do it on the first index, since that is our thread slicer
            // Don't do it on the start value, as that has a different multiplier on the back-end
            roll_dice(b1 - 1, b2, i, 1, d, -1);

            // Only roll a miss once; all subsequent misses are multiplied out
            if(!d->p1.d[b].is_hit){
                break;
            }

            // Only do a template once; they auto-hit
            if(d->p1.template){
                break;
            }
        }
    }else if(b2 > 0){
        // roll next die for P2
        for(i = start2; i <= ROLL_MAX; i++){
            b = d->p2.burst - b2;

            d->p2.d[b].value = i;

            annotate_roll(&d->p2, b);

            roll_dice(0, b2 - 1, 21, i, d, -1);

            // Only roll a miss once; all subsequent misses are multiplied out
            if(!d->p2.d[b].is_hit){
                break;
            }

            // Only do a template once; they auto-hit
            if(d->p2.template){
                break;
            }
        }
    }else{
        // all dice are rolled; count results
        count_roll_results(d);
    }
}


/*
 * rolling_thread()
 */
void *rolling_thread(void *data){
    struct dice *d = data;

    // Misses and auto-hits are corrected for with multipliers.
    // In those cases, only roll one time and short-circuit the rest.
    if(d->thread_num <= d->p1.stat && (!d->p1.template || d->thread_num == 0)){
        roll_dice(d->p1.burst, d->p2.burst, 1, 1, d, d->thread_num);
    }

    return NULL;
}


/*
 * tabulate()
 *
 * This function generates and then prints two tables.
 *
 * First is the total number of hits/crits possible for each player.
 * This is calculated using roll_dice().
 *
 * Second is the number of successes that each of these hit outcomes could
 * cause. These are calculated by calc_successes().
 *
 * Finally, both datasets are printed using print_tables().
 */
static void tabulate(struct player *p1, struct player *p2){
    struct dice d[NUM_THREADS];
    pthread_t threads[NUM_THREADS];
    int t, h, c, dam;
    int rval;

    for(t = 0; t < NUM_THREADS; t++){
        memset(&d[t], 0, sizeof(d[t]));

        d[t].thread_num = t;
        memcpy(&d[t].p1, p1, sizeof(*p1));
        memcpy(&d[t].p2, p2, sizeof(*p2));

#if MULTI_THREADED
        rval = (pthread_create(&threads[t], NULL, rolling_thread, &d[t]));
#else
        rolling_thread(&d[t]);
#endif
        if(rval){
            printf("ERROR: failed to create thread %d of %d\n", t, NUM_THREADS);
            exit(1);
        }
    }

    // Wait for all threads and sum the results
#if MULTI_THREADED
    pthread_join(threads[0], NULL);
#endif
    //printf("thread %d num_rolls %lld\n", 0, d[0].num_rolls);
    for(t = 1; t < NUM_THREADS; t++){
#if MULTI_THREADED
        pthread_join(threads[t], NULL);
#endif
        //printf("thread %d num_rolls %lld\n", t, d[t].num_rolls);
        d[0].num_rolls += d[t].num_rolls;
        d[0].rolls_made += d[t].rolls_made;

        // copy hit and crit data
        for(h = 0; h <= B_MAX; h++){
            for(c = 0; c <= B_MAX; c++){
                for(dam = 0; dam <= DAM_MAX; dam++){
                    d[0].p1.hit[h][c][dam] += d[t].p1.hit[h][c][dam];
                    d[0].p2.hit[h][c][dam] += d[t].p2.hit[h][c][dam];
                }
            }
        }
    }
    //printf("total rolls %lld should be %.0f\n", d[0].num_rolls, pow(ROLL_MAX, d[0].p1.burst + d[0].p2.burst));
    assert(d[0].num_rolls == pow(ROLL_MAX, d[0].p1.burst + d[0].p2.burst));

    calc_successes(d);

    print_tables(d);
}

static void print_player(const struct player *p, int p_num){
    printf("P%d STAT %2d CRIT %2d B %d TEMPLATE %d DAM %2d ARM_BONUS %d AMMO %s\n", p_num, p->stat, p->crit_val, p->burst, p->template, p->dam, p->arm_bonus, ammo_labels[p->ammo]);
}

static void usage(const char *program){
    printf("Usage: %s <MODE> <STAT 1> <B 1> <DAM 1> <AMMO 1> <STAT 2> <B 2> <DAM 2> <AMMO 2>\n", program);
    printf("Modes:\n");
    printf("    BS - Used for most cases\n");
    printf("    CC - If both models are in CC. ARM bonus is granted.\n");
    exit(0);
}

static void parse_ammo(const char *ammo, struct player *p){
    switch(ammo[0]){
        case 'N':
            p->ammo = AMMO_NORMAL;
            break;
        case 'D':
            p->ammo = AMMO_DA;
            break;
        case 'E':
            p->ammo = AMMO_EXP;
            break;
        case 'F':
            p->ammo = AMMO_FIRE;
            break;
        case '-':
            p->ammo = AMMO_NONE;
            break;
        default:
            printf("ERROR: P%d AMMO type '%s' unknown.  Must be one of N, D, E, F, -\n", p->player_num, ammo);
            exit(1);
            break;
    }
}

static void parse_stat(const char *str, struct player *p){
    char *end;

    if(strcmp(str, "T") == 0){
        // Template weapon
        // Automatically hits, cannot crit

        p->stat = ROLL_MAX;
        p->crit_val = ROLL_MAX + 1;
        p->template = 1;
    }else{
        // Normal weapon that needs a roll
        // Crits if it hits the target number

        p->stat = strtol(str, &end, 10);
        if(*str && *end){
            printf("ERROR: P%d Stat %s cannot be read\n", p->player_num, str);
            exit(1);
        }

        if(p->stat < 0 || p->stat > STAT_MAX){
            printf("ERROR: P%d Stat %d must be in the range of 0 to %d\n", p->player_num, p->stat, STAT_MAX);
            exit(1);
        }

        if(p->stat > ROLL_MAX){
            p->crit_val = ROLL_MAX - (p->stat - ROLL_MAX);
        }else{
            p->crit_val = p->stat;
        }
    }
}

static void parse_b(const char *str, struct player *p){
    p->burst = strtol(str, NULL, 10);

    if(p->burst < 1 || p->burst > B_MAX){
        printf("ERROR: P%d B %d must be in the range of 1 to %d\n", p->player_num, p->burst, B_MAX);
        exit(1);
    }
}

static void parse_dam(const char *str, struct player *p){
    p->dam = strtol(str, NULL, 10);

    if(p->dam < 0 || p->dam > DAM_MAX){
        printf("ERROR: P%d DAM %d must be in the range of 0 to %d\n", p->player_num, p->dam, DAM_MAX);
        exit(1);
    }
}

static void parse_args(int argc, const char *argv[], struct player *p1, struct player *p2){
    int i;

    if(argc != 10){
        usage(argv[0]);
    }

    i = 2;
    parse_stat(argv[i++], p1);
    parse_b(argv[i++], p1);
    parse_dam(argv[i++], p1);
    parse_ammo(argv[i++], p1);
    parse_stat(argv[i++], p2);
    parse_b(argv[i++], p2);
    parse_dam(argv[i++], p2);
    parse_ammo(argv[i++], p2);

    // Quick and dirty CPU limiter
    if(p1->burst + p2->burst > 9){
        printf("ERROR: Combined B value may not exceed 9\n");
        exit(1);
    }

    // Template Sanity
    if(p1->template && p2->template){
        printf("ERROR: FtF roll cannot have two templates\n");
        exit(1);
    }
}

int main(int argc, const char *argv[]){
    struct player p1, p2;

    memset(&p1, 0, sizeof(p1));
    memset(&p2, 0, sizeof(p2));
    p1.player_num = 1;
    p2.player_num = 2;

    if(argc < 2){
        usage(argv[0]);
    }

    if(strcmp(argv[1], "BS") == 0){
        parse_args(argc, argv, &p1, &p2);
    }else if(strcmp(argv[1], "CC") == 0){
        parse_args(argc, argv, &p1, &p2);

        p1.arm_bonus = 3;
        p2.arm_bonus = 3;
    }else{
        usage(argv[0]);
    }

    print_player(&p1, 1);
    print_player(&p2, 2);
    printf("\n");

    tabulate(&p1, &p2);

    return 0;
}
