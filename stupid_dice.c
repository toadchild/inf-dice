#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <assert.h>

const int B_MAX = 5;
const int SAVES_MAX = 3;
const int W_MAX = B_MAX * SAVES_MAX;
const int STAT_MAX = 20;

/*
 * This is a really dumb implementation of Infinity dice math that enumerates
 * every possible combination given the BS and B of both models and tabulates
 * the outcomes
 */

struct result{
    int value;
    int is_hit;
    int is_crit;
};

struct player{
    int stat;
    int n;
    int dam;
    int ammo;
    struct result d[B_MAX];
    int best;   // offset into d

    // count of hit types
    // first index is number of regular hits
    // second index is number of crits
    // value is number of times this happened
    uint64_t hit[B_MAX + 1][B_MAX + 1];

    // Number of times N wounds was inflicted
    double w[W_MAX + 1];
};

struct dice{
    struct player p1, p2;

    uint64_t num_rolls;
};

int print_player_hits(struct player *p, int p_num, int num_rolls){
    int hits, crits;
    int n_rolls = 0;

    for(hits = 0; hits <= B_MAX; hits++){
        for(crits = 0; crits <= B_MAX; crits++){
            if((hits > 0 || crits > 0) && p->hit[hits][crits] > 0){
                printf("P%d Hits: %d Crits %d - %lld (%0.02f)%%\n", p_num, hits, crits, p->hit[hits][crits], 100.0 * p->hit[hits][crits] / num_rolls);
                n_rolls += p->hit[hits][crits];
            }
        }
    }
    printf("\n");

    return n_rolls;
}

void print_tables(struct dice *d){
    int w;
    uint64_t n_rolls = 0, n;
    double n2;
    double cumul_prob;;

    n_rolls += print_player_hits(&d->p1, 1, d->num_rolls);

    n = d->p1.hit[0][0] + d->p2.hit[0][0];
    n_rolls += n;
    printf("No Hits - %lld (%0.02f)%%\n", n, 100.0 * n / d->num_rolls);
    printf("\n");

    n_rolls += print_player_hits(&d->p2, 2, d->num_rolls);

    printf("Tables contain %lld rolls.  Total should be %lld\n\n", n_rolls, d->num_rolls);

    cumul_prob = 0.0;
    for(w = W_MAX; w > 0; w--){
        if(d->p2.w[w] > 0){
            double prob = 100.0 * d->p2.w[w] / d->num_rolls;
            cumul_prob += prob;
            if(prob >= 0.01){
                printf("P2 Scores %d Wound(s): %0.02f%%     %d+ Wounds: %0.02f%%\n", w, prob, w, cumul_prob);
            }
        }
    }
    printf("\n");

    n2 = d->p1.w[0] + d->p2.w[0];
    printf("No Wounds: %0.02f%%\n", 100.0 * n2 / d->num_rolls);
    printf("\n");

    for(w = 1; w <= W_MAX; w++){
        if(d->p1.w[w] > 0){
            double prob = 100.0 * d->p1.w[w] / d->num_rolls;
            if(prob >= 0.01){
                printf("P1 Scores %d Wound(s): %0.2f%%\n", w, prob);
            }
        }
    }
    printf("\n");
}

uint64_t factorial(int n){
    if(n == 0){
        return 1;
    }
    return n * factorial(n - 1);
}

uint64_t choose(int n, int k){
    return factorial(n) / (factorial(k) * factorial(n - k));
}

double hit_prob(int successes, int trials, double probability){
    return choose(trials, successes) * pow(probability, successes) * pow(1 - probability, trials - successes);
}

void fire_damage(struct player *p, int hits, int total_hits, double prob, int depth){
    int w;

    if(depth == 0){
        // record damage at bottom of stack
        printf("W %d\n", total_hits);

        assert(total_hits <= W_MAX);
        p->w[total_hits] += prob;
        return;
    }

    for(w = 0; w <= hits; w++){
        double new_prob = hit_prob(w, hits, ((double)p->dam) / 20);
        int new_depth = depth - 1;

        if(w == 0){
            // record data if no additional hits were scored.
            new_depth = 0;
        }

        fire_damage(p, w, total_hits + w, prob * new_prob, new_depth);
    }
}

void calc_player_wounds(struct player *p){
    int hits, crits, w;

    for(hits = 0; hits <= B_MAX; hits++){
        for(crits = 0; crits <= B_MAX; crits++){
            if(p->hit[hits][crits] > 0){
                // We scored this many hits and crits
                // now we need to determine how likely it was we caused however many wounds
                // Gotta binomialize!

                // crits always hit, so they are an offset into the w array
                // then we count up to the max number of hits.
                int saves;
                switch(p->ammo){
                    case 'D':
                        // DA - two saves per hit, plus the second die for crits
                        saves = 2 * hits + crits;
                        break;
                    case 'E':
                        // EXP - three saves per hit, plus the extra two for crits
                        saves = 3 * hits + 2 * crits;
                        break;
                    default:
                        // Normal - one save per regular hit
                        saves = hits;
                }

                if(p->ammo != 'F'){
                    for(w = 0; w <= saves; w++){
                        assert(crits + w <= W_MAX);
                        p->w[crits + w] += hit_prob(w, saves, ((double)p->dam) / 20) * p->hit[hits][crits];
                    }
                }else{
                    // Fire ammo
                    // If you fail the save, you must roll again, ad infinitum.
                    fire_damage(p, hits + crits, crits, p->hit[hits][crits], SAVES_MAX - 1);
                }
            }
        }
    }
}

void calc_wounds(struct dice *d){
    int hits, crits, i, w;

    calc_player_wounds(&d->p1);
    calc_player_wounds(&d->p2);
}

void count_player_results(struct player *us, struct player *them, int *hits, int *crits){
    // This is also a stupid algortithm
    int i;

    // Find highest roll of other player
    them->best = 0;
    for(i = 1; i < them->n; i++){
        if(them->d[i].is_hit && 
                (!them->d[them->best].is_hit || 
                (them->d[i].value > them->d[them->best].value))){
            them->best = i;
        }
    }

    for(i = 0; i < us->n; i++){
        if(us->d[i].is_hit){
            if(us->d[i].is_crit){
                // crit, see if it was canceled

                if(!(them->stat >= us->stat && them->d[them->best].is_crit)){
                    (*crits)++;
                }
            }else{
                // it was a regular hit, see if it was canceled

                if(!them->d[them->best].is_hit || (!them->d[them->best].is_crit &&
                        (them->d[them->best].value < us->d[i].value ||
                        (them->d[them->best].value == us->d[i].value && them->stat < us->stat)))){
                    (*hits)++;
                }
            }
        }
    }
}

void _count_results(struct dice *d){
    int hits1 = 0, crits1 = 0;
    int hits2 = 0, crits2 = 0;

    count_player_results(&d->p1, &d->p2, &hits1, &crits1);
    count_player_results(&d->p2, &d->p1, &hits2, &crits2);

    if((crits1 + hits1 > 0) && (crits2 + hits2 > 0)){
        int i;
        printf("ERROR, both sides scored hits!!!!\n");
        /*
        printf("stat1: %d\nn1: %d\n", d->stat1, d->n1);
        for(i = 0; i < d->n1; i++){
            printf("d1[%d]: %d\n", i, d->d1[i]);
        }
        printf("\n");

        printf("stat2: %d\nn2: %d\n", d->stat2, d->n2);
        for(i = 0; i < d->n2; i++){
            printf("d2[%d]: %d\n", i, d->d2[i]);
        }
        printf("\n");

        printf("hits1: %d\ncrits1: %d\n", hits1, crits1);
        printf("hits2: %d\ncrits2: %d\n", hits2, crits2);
        */
        exit(1);
    }

    // Need to ensure we only count totally whiffed rolls once
    if(crits1 + hits1){
        d->p1.hit[hits1][crits1]++;
    }else{
        d->p2.hit[hits2][crits2]++;
    }

    d->num_rolls++;
}

void annotate_roll(struct player *p, int n){
    if(p->d[n].value == p->stat){
        p->d[n].is_crit = 1;
    }else{
        p->d[n].is_crit = 0;
    }

    if(p->d[n].value <= p->stat){
        p->d[n].is_hit = 1;
    }else{
        p->d[n].is_hit = 0;
    }
}

void _gen_table(int b1, int b2, struct dice *d){
    int i;

    if(b1 > 0){
        // roll next die for P1
        for(i = 1; i <= STAT_MAX; i++){
            d->p1.d[d->p1.n - b1].value = i;

            annotate_roll(&d->p1, d->p1.n - b1);
            _gen_table(b1 - 1, b2, d);
        }
    }else if(b2 > 0){
        // roll next die for P2
        for(i = 1; i <= STAT_MAX; i++){
            d->p2.d[d->p2.n - b2].value = i;

            annotate_roll(&d->p2, d->p2.n - b2);
            _gen_table(b1, b2 - 1, d);
        }
    }else{
        // all dice are rolled; count results
        _count_results(d);
    }
}

void tabulate(struct player *p1, struct player *p2){
    struct dice d;
    memset(&d, 0, sizeof(d));

    d.p1.n = p1->n;
    d.p2.n = p2->n;
    d.p1.stat = p1->stat;
    d.p2.stat = p2->stat;
    d.p1.dam = p1->dam;
    d.p2.dam = p2->dam;
    d.p1.ammo = p1->ammo;
    d.p2.ammo = p2->ammo;

    // recursive roller
    _gen_table(d.p1.n, d.p2.n, &d);
    
    calc_wounds(&d);

    print_tables(&d);
}   

int main(int argc, char *argv[]){
    struct player p1, p2;
    int i;

    if(argc != 9){
        printf("Usage: %s <BS 1> <B 1> <DAM 1> <AMMO 1> <BS 2> <B 2> <DAM 2> <AMMO 2>\n", argv[0]);
        return 1;
    }

    i = 1;
    p1.stat = strtol(argv[i++], NULL, 10);
    p1.n = strtol(argv[i++], NULL, 10);
    p1.dam = strtol(argv[i++], NULL, 10);
    p1.ammo = argv[i++][0];
    p2.stat = strtol(argv[i++], NULL, 10);
    p2.n = strtol(argv[i++], NULL, 10);
    p2.dam = strtol(argv[i++], NULL, 10);
    p2.ammo = argv[i++][0];

    if(p1.n < 1 || p1.n > B_MAX){
        printf("B 1 must be in the range of 1 to %d\n", B_MAX);
        return 1;
    }

    if(p2.n < 1 || p2.n > B_MAX){
        printf("B 2 must be in the range of 1 to %d\n", B_MAX);
        return 1;
    }

    if(p1.stat < 1 || p1.stat > STAT_MAX){
        printf("BS 1 must be in the range of 1 to %d\n", STAT_MAX);
        return 1;
    }

    if(p2.stat < 1 || p2.stat > STAT_MAX){
        printf("BS 2 must be in the range of 1 to %d\n", STAT_MAX);
        return 1;
    }

    if(p1.dam < 1 || p1.dam > STAT_MAX){
        printf("DAM 1 must be in the range of 1 to %d\n", STAT_MAX);
        return 1;
    }

    if(p2.dam < 1 || p2.dam > STAT_MAX){
        printf("DAM 2 must be in the range of 1 to %d\n", STAT_MAX);
        return 1;
    }

    if(p1.ammo != 'N' && p1.ammo != 'D' && p1.ammo != 'E' && p1.ammo != 'F'){
        printf("AMMO 1 must be one of N, D, E, F\n");
        return 1;
    }

    if(p2.ammo != 'N' && p2.ammo != 'D' && p2.ammo != 'E' && p2.ammo != 'F'){
        printf("AMMO 2 must be one of N, D, E, F\n");
        return 1;
    }

    tabulate(&p1, &p2);

    return 0;
}
