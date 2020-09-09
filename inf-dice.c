/*
 * This is an implementation of Infinity dice math that enumerates every
 * possible combination given the BS and B of both models and tabulates
 * the outcomes.
 *
 * Created by Jonathan Polley.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <assert.h>
#include <pthread.h>

#define B_MAX  5
#define SAVES_MAX  4
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
    AMMO_FIRE,
    AMMO_NONE,
};

static const char *ammo_labels[] = {
    "NORMAL",
    "FIRE",
    "NONE",
};

enum tag_t {
    TAG_SHOCK,
    TAG_EM,
    TAG_C,
    TAG_D,
    TAG_E,
    NUM_TAGS,
};

#define TAG_MASK(x) (1 << x)

enum tag_mask_t {
    TAG_MASK_NONE = 0,
    TAG_MASK_A = TAG_MASK(TAG_SHOCK),
    TAG_MASK_B = TAG_MASK(TAG_EM),
    TAG_MASK_C = TAG_MASK(TAG_C),
    TAG_MASK_D = TAG_MASK(TAG_D),
    TAG_MASK_E = TAG_MASK(TAG_E),
    TAG_MASK_MAX = TAG_MASK(NUM_TAGS),
};

static const char *tag_labels[] = {
    "SHOCK",
    "EM",
    "C",
    "D",
    "E",
};

#define TAG_LABEL_NONE "NONE"

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
    int crit_boost;             // bonus to die roll for stat > 20
    int crit_on_one;            // if it also crits on ones
    int burst;                  // number of dice
    int template;               // Is this a template weapon
    int num_saves;              // number of saves for this ammo
    int dam[SAVES_MAX];         // damage value
    int tag_mask[SAVES_MAX];    // tag bitmask for each save
    const char *tag_label[SAVES_MAX];    // string tag name for each save
    enum ammo_t ammo;           // ammo type

    struct result d[B_MAX];     // current set of dice being evaluated

    // count of hit types
    // first index is number of regular hits
    // second index is number of crits
    // value is number of times this happened
    int64_t hit[B_MAX + 1][B_MAX + 1];

    // Number of times N successes was inflicted
    // second index is the bitmasked combination of tags present
    double success[SUCCESS_MAX + 1][TAG_MASK_MAX];
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
    int hits, crits;
    int64_t n_rolls = 0;

    for(hits = 0; hits <= B_MAX; hits++){
        for(crits = 0; crits <= B_MAX; crits++){
            if((hits > 0 || crits > 0) && p->hit[hits][crits] > 0){
                printf("P%d Hits: %2d Crits: %2d - %6.3f%% (%lld)\n", p_num, hits, crits, 100.0 * p->hit[hits][crits] / num_rolls, p->hit[hits][crits]);
                n_rolls += p->hit[hits][crits];
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
    int success;
    double n_success = 0;
    double tagged_prob[SUCCESS_MAX + 1][NUM_TAGS] = {};
    double tagless_prob[SUCCESS_MAX + 1] = {};
    double untagged_prob[SUCCESS_MAX + 1] = {};

    for(success = SUCCESS_MAX; success > 0; success--){
        int tagged_output = 0;
        int mask;
        for(mask = 0; mask < TAG_MASK_MAX; mask++){
            if(p->success[success][mask] > 0){
                double prob = 100.0 * p->success[success][mask] / num_rolls;
                untagged_prob[success] += prob;
                int tag;
                for(tag = 0; tag < NUM_TAGS; tag++){
                    if(TAG_MASK(tag) & mask){
                        tagged_prob[success][tag] += prob;
                    }
                }
                if(mask == 0){
                    tagless_prob[success] += prob;
                }

                n_success += p->success[success][mask];
            }
        }

        int tag;
        for(tag = 0; tag < NUM_TAGS; tag++){
            double prob = tagged_prob[success][tag];
            if(prob){
                printf("P%d Scores %2d Success(es): %6.3f%% %s\n", p_num, success, prob, tag_labels[tag]);
            }
        }
        if(tagless_prob[success]){
            printf("P%d Scores %2d Success(es): %6.3f%% %s\n", p_num, success, tagless_prob[success], TAG_LABEL_NONE);
        }
        if(untagged_prob[success]){
            printf("P%d Scores %2d Success(es): %6.3f%%\n", p_num, success, untagged_prob[success]);
        }
    }

    double cumul_prob = 0;
    for(success = SUCCESS_MAX; success > 0; success--){
        if(tagless_prob[success]){
            cumul_prob += tagless_prob[success];
            printf("P%d Scores %2d+ Successes:  %6.3f%% %s\n", p_num, success, cumul_prob, TAG_LABEL_NONE);
        }
    }
    int tag;
    for(tag = 0; tag < NUM_TAGS; tag++){
        cumul_prob = 0;
        for(success = SUCCESS_MAX; success > 0; success--){
            if(tagged_prob[success][tag]){
                cumul_prob += tagged_prob[success][tag];
                printf("P%d Scores %2d+ Successes:  %6.3f%% %s\n", p_num, success, cumul_prob, tag_labels[tag]);
            }
        }
    }
    cumul_prob = 0;
    for(success = SUCCESS_MAX; success > 0; success--){
        cumul_prob += untagged_prob[success];
        if(cumul_prob){
            printf("P%d Scores %2d+ Successes:  %6.3f%%\n", p_num, success, cumul_prob);
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
    double n_failures;

    printf("Total Rolls: %lld\n", d->num_rolls);
    printf("Actual Rolls Made: %lld\n", d->rolls_made);
    printf("Savings: %.02f%%\n", 100 - (100.0 * d->rolls_made / d->num_rolls));
    printf("\n");

    n_rolls += print_player_hits(&d->p1, 1, d->num_rolls);

    // sum up all misses from both players
    n += d->p1.hit[0][0] + d->p2.hit[0][0];

    n_rolls += n;
    printf("No Hits: %6.3f%% %lld\n", 100.0 * n / d->num_rolls, n);
    printf("\n");

    n_rolls += print_player_hits(&d->p2, 2, d->num_rolls);
    assert(n_rolls == d->num_rolls);

    printf("\n");
    printf("======================================================\n");
    printf("\n");

    n_success += print_player_successes(&d->p1, 1, d->num_rolls);

    n_failures = d->p1.success[0][TAG_MASK_NONE] + d->p2.success[0][TAG_MASK_NONE];
    printf("No Successes: %6.3f%%\n", 100.0 * n_failures / d->num_rolls);
    printf("\n");

    n_success += print_player_successes(&d->p2, 2, d->num_rolls);
    assert(round(n_success + n_failures) == d->num_rolls);
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
 * success_prob()
 *
 * Uses binomial theorem to calculate the likelyhood that a certain number
 * of hits were successful.
 */
static double success_prob(int successes, int trials, double probability){
    return choose(trials, successes) * pow(probability, successes) * pow(1 - probability, trials - successes);
}

static void hit_prob_multi_helper(struct player *p, int *saves, double hit_prob, int n, int successes, double prob, enum tag_mask_t mask){
    if(n == p->num_saves + 1){
        assert(successes <= SUCCESS_MAX);
        p->success[successes][mask] += prob * hit_prob;
    }else{
        int i;
        double dam_prob = ((double)p->dam[n]) / ROLL_MAX;
        for(i = 0; i <= saves[n]; i++){
            double new_prob = success_prob(i, saves[n], dam_prob);
            // If we scored a hit, add that save's tag to the mask.
            enum tag_mask_t new_mask = mask;
            if(i){
                new_mask |= p->tag_mask[n];
            }
            hit_prob_multi_helper(p, saves, hit_prob, n + 1, successes + i, prob * new_prob, new_mask);
        }
    }
}

/*
 * hit_prob_multi()
 *
 * Recurses to find the probability that any combination of saves passed or
 * failed.
 */
static void hit_prob_multi(struct player *p, int *saves, double hit_prob){
    hit_prob_multi_helper(p, saves, hit_prob, 0, 0, 1.0, TAG_MASK_NONE);
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
    if(hits == 0 || total_hits >= SUCCESS_MAX || depth == 0){
        // TODO: Don't ignore tags when dealing with fire damage.
        p->success[MIN(total_hits, SUCCESS_MAX)][TAG_MASK_NONE] += prob;
        return;
    }

    for(success = 0; success <= hits; success++){
        double new_prob = success_prob(success, hits, ((double)dam) / ROLL_MAX);
        int new_depth = depth - 1;

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
            if(p->hit[hits][crits] > 0){
                // We scored this many hits and crits
                // now we need to determine how likely it was we caused however many successes
                // Gotta binomialize!
                int saves[SAVES_MAX] = {};
                if(p->ammo == AMMO_FIRE){
                    // Fire ammo
                    // If you fail the save, you must roll again, ad infinitum.
                    int i;
                    for(i = 0; i < p->num_saves; i++){
                        fire_damage(p, hits + crits, crits, p->dam[i], p->hit[hits][crits], SUCCESS_MAX);
                    }
                }else if(p->ammo == AMMO_NONE){
                    // Non-lethal skill (Dodge, Smoke)
                    // There is no saving throw. Number of successes still
                    // matters for smoke.
                    p->success[crits + hits][TAG_MASK_NONE] += p->hit[hits][crits];
                }else{
                    // Most normal ammo types; roll p->num_saves saving throws per hit.
                    int i;
                    for(i = 0; i < p->num_saves; i++){
                        saves[i] += hits + crits;
                    }
                    // Criticals inflict an extra save.
                    // Copy stats from the first save.
                    if (crits) {
                        saves[p->num_saves] += crits;
                    }

                    hit_prob_multi(p, saves, p->hit[hits][crits]);
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
static void count_player_results(struct player *us, struct player *them, int *hits, int *crits){
    int i;
    int best;      // offset into them's d array for their best roll
    int best_crit; // offset into them's d array for their best critical roll

    *hits = 0;
    *crits = 0;

    // Find highest successful roll of other player
    // Use the fact that the array is sorted
    best = 0;
    best_crit = -1;
    for(i = 0; i < them->burst; i++){
        if(them->d[i].is_hit){
            if(them->d[i].is_crit){
                best_crit = i;
            }else{
                best = i;
            }
        }
    }
    if(best_crit >= 0){
        best = best_crit;
    }

    assert(best >= 0 && best < them->burst);

    for(i = 0; i < us->burst; i++){
        if(us->d[i].is_hit){
            if(us->d[i].is_crit){
                // crit, see if it was canceled
                if(!(them->d[best].is_crit)){
                    (*crits)++;
                }
            }else{
                // it was a regular hit, see if it was canceled
                if(!(us->template && them->d[best].is_hit) &&
                        (them->template || !them->d[best].is_hit ||
                            (!them->d[best].is_crit &&
                                (them->d[best].value < us->d[i].value)))){
                    (*hits)++;
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
        printf("%2d ", d->p1.d[i].value);
    }
    printf("| ");
    for(i = 0; i < d->p2.burst; i++){
        printf("%2d ", d->p2.d[i].value);
    }
    printf("x %4lld", multiplier);

    printf(" | dam1: %d dam2: %d\n", dam1, dam2);
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

    count_player_results(&d->p1, &d->p2, &hits1, &crits1);
    count_player_results(&d->p2, &d->p1, &hits2, &crits2);

    //print_roll(d, multiplier, dam1, dam2);

    if(crits1 + hits1){
        d->p1.hit[hits1][crits1] += multiplier;
    }

    if(hits2 + crits2){
        d->p2.hit[hits2][crits2] += multiplier;
    }

    // Need to ensure we only count totally whiffed rolls once
    if(hits1 + crits1 + hits2 + crits2 == 0){
        d->p2.hit[0][0] += multiplier;
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

        if((p->d[n].value >= p->crit_val) || (p->crit_on_one && p->d[n].value == 1)){
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

            d->p1.d[b].value = i + d->p1.crit_boost;

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

            d->p2.d[b].value = i + d->p2.crit_boost;

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
                d[0].p1.hit[h][c] += d[t].p1.hit[h][c];
                d[0].p2.hit[h][c] += d[t].p2.hit[h][c];
            }
        }
    }
    //printf("total rolls %lld should be %.0f\n", d[0].num_rolls, pow(ROLL_MAX, d[0].p1.burst + d[0].p2.burst));
    assert(d[0].num_rolls == pow(ROLL_MAX, d[0].p1.burst + d[0].p2.burst));

    calc_successes(d);

    print_tables(d);
}

static void print_player(const struct player *p, int p_num){
    int i;

    printf("P%d STAT %2d CRIT %2d CRIT_1 %s BOOST %2d B %d TEMPLATE %d AMMO %s", p_num, p->stat, p->crit_val, p->crit_on_one ? "Y" : "N", p->crit_boost, p->burst, p->template, ammo_labels[p->ammo]);

    for(i = 0; i < p->num_saves; i++){
        printf(" DAM[%d] %2d TAG[%d] %s", i, p->dam[i], i, p->tag_label[i]);
    }
    printf("\n");
}

static void usage(const char *program){
    printf("Usage: %s <STAT 1> <B 1> <SAVES 1> <DAM 1> <TAG 1> <...> <STAT 2> <B 2> <SAVES 2> <DAM 2> <TAG 2> <...>\n", program);
    exit(0);
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
        int no_crit = 0;
        // Normal weapon that needs a roll
        // Crits if it hits the target number

        p->stat = strtol(str, &end, 10);

        // If the stat ends in *, no crits are permitted
        if(*end == '*'){
            no_crit = 1;
            end++;
        }

        // If the stat ends in !, also crits on a 1
        if(*end == '!'){
            p->crit_on_one = 1;
            // If we're critting on 1, make sure stat is at least 1
            if (p->stat < 1) {
                p->stat = 1;
            }
            end++;
        }

        if(*str && *end){
            printf("ERROR: P%d Stat %s cannot be read\n", p->player_num, str);
            exit(1);
        }

        if(p->stat < 0 || p->stat > STAT_MAX){
            printf("ERROR: P%d Stat %d must be in the range of 0 to %d\n", p->player_num, p->stat, STAT_MAX);
            exit(1);
        }

        if(no_crit){
            p->crit_val = ROLL_MAX + 1;
        }else if(p->stat > ROLL_MAX){
            p->crit_val = ROLL_MAX;
            p->crit_boost = p->stat - ROLL_MAX;
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

static void parse_dam(const char **argv, int argc, int *i, struct player *p){
    // Format: N D1 T1 [D2 T2 [D3 T3]]
    // N is number of damage values coming
    // Dn is damage value
    // Tn is tag
    int save;

    char ammo = argv[(*i)++][0];
    switch(ammo){
        case '1':
            p->ammo = AMMO_NORMAL;
            p->num_saves = 1;
            break;
        case '2':
            p->ammo = AMMO_NORMAL;
            p->num_saves = 2;
            break;
        case '3':
            p->ammo = AMMO_NORMAL;
            p->num_saves = 3;
            break;
        case 'F':
            p->ammo = AMMO_FIRE;
            p->num_saves = 1;
            break;
        case '-':
            p->ammo = AMMO_NONE;
            p->num_saves = 1;
            break;
        default:
            printf("ERROR: P%d AMMO type '%c' unknown.  Must be one of 1, 2, 3, F, -\n", p->player_num, ammo);
            exit(1);
            break;
    }

    if(*i + p->num_saves * 2 > argc){
        printf("ERROR: Too few damage values for number of saves\n");
        exit(1);
    }

    for(save = 0; save < p->num_saves; save++){
        p->dam[save] = strtol(argv[(*i)++], NULL, 10);

        if(p->dam[save] < 0 || p->dam[save] > DAM_MAX){
            printf("ERROR: P%d DAM[%d] %d must be in the range of 0 to %d\n", p->player_num, save, p->dam[save], DAM_MAX);
            exit(1);
        }

        const char *tag_label = argv[(*i)++];
        p->tag_label[save] = tag_label;
        if(strcmp(tag_label, TAG_LABEL_NONE) == 0){
            p->tag_mask[save] = TAG_MASK_NONE;
        }else{
            int tag;
            for(tag = 0; tag < NUM_TAGS; tag++){
                if(strcmp(tag_label, tag_labels[tag]) == 0){
                    p->tag_mask[save] = TAG_MASK(tag);
                    break;
                }
            }
            if(tag == NUM_TAGS){
                printf("ERROR: P%d TAG[%d] '%s' is unknown.\n", p->player_num, save, tag_label);
                exit(1);
            }
        }
    }

    // Load an extra copy of the first values at the end of the list.
    // This is used for crits.
    p->dam[p->num_saves] = p->dam[0];
    p->tag_mask[p->num_saves] = p->tag_mask[0];
    p->tag_label[p->num_saves] = p->tag_label[0];
}

static void parse_args(int argc, const char *argv[], struct player *p1, struct player *p2){
    int i;

    if(argc < 9){
        printf("ERROR: Too few arguments\n");
        usage(argv[0]);
    }

    i = 1;
    parse_stat(argv[i++], p1);
    parse_b(argv[i++], p1);
    parse_dam(argv, argc, &i, p1);

    parse_stat(argv[i++], p2);
    parse_b(argv[i++], p2);
    parse_dam(argv, argc, &i, p2);

    if(argc > i){
        printf("ERROR: Too many arguments\n");
        usage(argv[0]);
    }

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

    parse_args(argc, argv, &p1, &p2);

    print_player(&p1, 1);
    print_player(&p2, 2);
    printf("\n");

    tabulate(&p1, &p2);

    return 0;
}
