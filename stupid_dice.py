#!/usr/bin/env python

import sys

B_MAX = 5
SAVES_MAX = 3
W_MAX = (B_MAX * SAVES_MAX)
STAT_MAX = 20
ROLL_MAX=  20
DAM_MAX = 20

# Other assumptions require that NUM_THREADS equals ROLL_MAX
NUM_THREADS = ROLL_MAX

# ammo types
AMMO_NORMAL = 1
AMMO_DA = 2
AMMO_EXP = 3
AMMO_FIRE = 4

#
# This is an implementation of Infinity dice math that enumerates every
# possible combination given the BS and B of both models and tabulates
# the outcomes.
#
# Created by Jonathan Polley.
#

#
# Structure for a single die result.
#
#struct result{
#    int value;          # Number that was rolled
#    int is_hit;         # If the die is a hit (true on a crit)
#    int is_crit;        # If the die is a crit
#};

#
# Data structure for each player.
#
# Includes both player attributes and their hit/wound tables.
#
#struct player{
#    int stat;                   # target number for rolls
#    int n;                      # number of dice
#    int dam;                    # damage value
#    enum ammo_t ammo;           # ammo type
#
#    struct result d[B_MAX];     # current set of dice being evaluated
#    int best;                   # offset into d - their best die

    # count of hit types
    # first index is number of regular hits
    # second index is number of crits
    # value is number of times this happened
#    uint64_t hit[B_MAX + 1][B_MAX + 1];

    # Number of times N wounds was inflicted
#    double w[W_MAX + 1];
#};

#
# Master data structure.
#
#struct dice{
#    int thread_num;
#    struct player p1, p2;
#
#    uint64_t num_rolls;
#};




#
# print_player_hits()
#
# Helper for print_tables().  Prints likelyhood that player scored a
# certain number of hits/crits.
#
def print_player_hits(p, p_num, num_rolls):
    n_rolls = 0;

    for hits in range(B_MAX+1):
        for crits in range(B_MAX+1):
            if (hits > 0 or crits > 0) and p['hit'][hits][crits] > 0:
                print "P%d Hits: %d Crits %d: %6.2f%% (%d)" % (p_num, hits, crits, 100.0 * p['hit'][hits][crits] / num_rolls, p['hit'][hits][crits])
                n_rolls += p['hit'][hits][crits]
    print

    return n_rolls

#
# print_player_wounds()
#
# Helper for print_tables().  Prints likelyhood that player scored a
# certain number of wounds.
#
def print_player_wounds(p, p_num, num_rolls):
    cumul_prob = 0.0;
    for w in range(W_MAX, 0, -1):
        if p['w'][w] > 0:
            prob = 100.0 * p['w'][w] / num_rolls
            cumul_prob += prob;
            if prob >= 0.005:
                print "P%d Scores %2d Wound(s): %6.2f%%     %2d+ Wounds: %6.2f%%" % (p_num, w, prob, w, cumul_prob)
    print

#
# print_tables()
#
# Prints generated data in an orderly format.
#
# Prints both raw hit data and wound statistics.
#
def print_tables(d):
    n_rolls = 0

    print "Total Hits: %d" % (d['num_rolls'])
    print

    n_rolls += print_player_hits(d['p1'], 1, d['num_rolls'])

    n = d['p1']['hit'][0][0] + d['p2']['hit'][0][0];
    n_rolls += n;
    print "No Hits: %6.2f%% %d" % (100.0 * n / d['num_rolls'], n)
    print

    n_rolls += print_player_hits(d['p2'], 2, d['num_rolls'])
    assert(n_rolls == d['num_rolls'])

    print
    print "======================================================"
    print

    print_player_wounds(d['p1'], 1, d['num_rolls'])

    n2 = d['p1']['w'][0] + d['p2']['w'][0];
    print "No Wounds: %6.2f%%" % (100.0 * n2 / d['num_rolls'])
    print

    print_player_wounds(d['p2'], 2, d['num_rolls']);

#
# factorial()
#
# Standard numerical function. Precalculated for efficiency.
#
def factorial(n):
    if n == 0 or n == 1:
        return 1
    if n == 2:
        return 2
    if n == 3:
        return 6
    if n == 4:
        return 24
    if n == 5:
        return 120

    return n * factorial(n - 1)

#
# choose()
#
# Standard probability/statistics function.
#
def choose(n, k):
    return factorial(n) / (factorial(k) * factorial(n - k))

#
# hit_prob()
#
# Uses binomial theorem to calculate the likelyhood that a certain number
# of hits were successful.
#
def hit_prob(successes, trials, probability):
    return choose(trials, successes) * pow(probability, successes) * pow(1 - probability, trials - successes)

#
# fire_damage()
#
# Helper for calc_player_wounds(). Recursively calculates how many wounds
# Fire ammo could have inflicted.
#
def fire_damage(p, hits, total_hits, prob, depth):
    if depth == 0:
        # record damage at bottom of stack
        assert(total_hits <= W_MAX)
        p['w'][total_hits] += prob
        return

    for w in range(hits + 1):
        new_prob = hit_prob(w, hits, (float(p['dam']) / ROLL_MAX))
        new_depth = depth - 1

        if w == 0:
            # record data if no additional hits were scored.
            new_depth = 0;

        fire_damage(p, w, total_hits + w, prob * new_prob, new_depth)

#
# calc_player_wounds()
#
# For a given player, traverses their hit/crit table and determines how
# likely they are to have inflicted wounds on their opponent.
#
def calc_player_wounds(p):
    for hits in range(B_MAX + 1):
        for crits in range(B_MAX + 1):
            if p['hit'][hits][crits] > 0:
                # We scored this many hits and crits
                # now we need to determine how likely it was we caused however many wounds
                # Gotta binomialize!

                # crits always hit, so they are an offset into the w array
                # then we count up to the max number of hits.
                if p['ammo'] == AMMO_FIRE:
                    # Fire ammo
                    # If you fail the save, you must roll again, ad infinitum.
                    fire_damage(p, hits + crits, crits, p['hit'][hits][crits], SAVES_MAX - 1)
                else:
                    if p['ammo'] == AMMO_DA:
                        # DA - two saves per hit, plus the second die for crits
                        saves = 2 * hits + crits;
                    if p['ammo'] == AMMO_EXP:
                        # EXP - three saves per hit, plus the extra two for crits
                        saves = 3 * hits + 2 * crits;
                    if p['ammo'] == AMMO_NORMAL:
                        # Normal - one save per regular hit
                        saves = hits;

                    for w in range(saves+1):
                        assert(crits + w <= W_MAX);
                        p['w'][crits + w] += hit_prob(w, saves, (float(p['dam'])) / ROLL_MAX) * p['hit'][hits][crits]

#
# calc_wounds()
#
# Causes the wound tables to be calculated for each player.
#
def calc_wounds(d):
    calc_player_wounds(d['p1'])
    calc_player_wounds(d['p2'])

#
# count_player_results()
#
# Compares each die for a given player to the best roll for the other
# player. Then counts how many uncanceled hits/crits this player scored.
#
def count_player_results(us, them):
    hits = 0;
    crits = 0;

    # Find highest successful roll of other player
    # Use the fact that the array is sorted
    them['best'] = 0
    for i in range(them['n'] - 1, -1, -1):
        if them['d'][i]['is_hit']:
            them['best'] = i
            break;

    for i in range(us['n'] - 1, -1, -1):
        if us['d'][i]['is_hit']:
            if us['d'][i]['is_crit']:
                # crit, see if it was canceled
                if not (them['stat'] >= us['stat'] and them['d'][them['best']]['is_crit']):
                    crits += 1
                else:
                    # All lower dice will also be canceled
                    break;
            else:
                # it was a regular hit, see if it was canceled
                if not them['d'][them['best']]['is_hit'] or (not them['d'][them['best']]['is_crit'] and
                        (them['d'][them['best']]['value'] < us['d'][i]['value'] or
                        (them['d'][them['best']]['value'] == us['d'][i]['value'] and them['stat'] < us['stat']))):
                    hits += 1
                else:
                    # All lower dice will also be canceled
                    break;
    return (hits, crits)

#
# repeat_factor()
#
# Helper for count_roll_results()
#
# Counts the lengths of sequences in the die rolls in order to find the
# factorial denominator for the data multiplier. This is easy to do since
# the roller outputs the numbers in sorted order.
#
def repeat_factor(p):
    seq_len = 1
    fact = 1

    seq_num = p['d'][0]['value']
    for i in range(1, p['n']):
        # misses are counted differently, not using sequences
        if p['d'][i]['value'] != seq_num:
            if seq_len > 1:
                fact *= factorial(seq_len)
            seq_num = p['d'][i]['value']
            seq_len = 1
        else:
            seq_len += 1

    if seq_len > 1:
        fact *= factorial(seq_len)

    return fact;

#
# miss_factor()
#
# Helper for count_roll_results()
#
# Counts how many die rolls we didn't bother rolling because we know
# they were going to miss.
#
def miss_factor(p, start):
    fact = 1

    for i in range(start, p['n']):
        if(p['d'][i]['is_hit']):
            continue

        fact *= ROLL_MAX - p['d'][i]['value'] + 1

    return fact

#
# print_roll
#
# Test function that prints roll values and their multiplier.
#
def print_roll(d, multiplier):
    for i in range(d['p1']['n']):
        print "%02d " % (d['p1']['d'][i]['value']),

    print "| ",
    for i in range(d['p2']['n']):
        print "%02d " % (d['p2']['d'][i]['value']),

    print "x %d" % (multiplier)

#
# count_roll_results()
#
# For a given configuration of dice, calculates who won the FtF roll,
# and how many hits/crits they scored.  Adds these to a running tally.
#
# Uses factorials to calculate a multiplicative factor to un-stack the
# duplicate die rolls that the matrix symmetry optimization cut out.
#
def count_roll_results(d):
    # Hits are counted as 'multiplier' since we are using matrix symmetries
    fact1 = repeat_factor(d['p1'])
    fact2 = repeat_factor(d['p2'])
    multiplier = factorial(d['p1']['n']) / fact1 * factorial(d['p2']['n']) / fact2

    # more multipliers for rolling up all misses
    multiplier *= miss_factor(d['p1'], 0)
    multiplier *= miss_factor(d['p2'], 0)

    #print_roll(d, multiplier)

    (hits1, crits1) = count_player_results(d['p1'], d['p2'])
    (hits2, crits2) = count_player_results(d['p2'], d['p1'])

    assert((crits1 + hits1 == 0) or (crits2 + hits2 == 0))

    # Need to ensure we only count totally whiffed rolls once
    if crits1 + hits1:
        d['p1']['hit'][hits1][crits1] += multiplier
    else:
        d['p2']['hit'][hits2][crits2] += multiplier

    d['num_rolls'] += multiplier

#
# annotate_roll()
#
# This is a helper for roll_dice() that marks whether a given die is a
# hit or a crit.
#
# XXX This should be extended to support stats over 20 with extended
# crititcal ranges.
#
def annotate_roll(p, n):
    if p['d'][n]['value'] == p['stat']:
        p['d'][n]['is_crit'] = 1
    else:
        p['d'][n]['is_crit'] = 0

    if p['d'][n]['value'] <= p['stat']:
        p['d'][n]['is_hit'] = 1
    else:
        p['d'][n]['is_hit'] = 0

#
# roll_dice()
#
# Recursive die roller.  Generates all possible permutations of dice,
# calls into count_roll_results() as each row is completed.
#
# Uses matrix symmetries to cut down on the number of identical
# evaluations.
#
def roll_dice(b1, b2, start1, start2, d, thread_num):
    # step is used for outermost loop to divide up data between threads
    # Each thread does a single digit of first die roll
    if thread_num >= 0:
        step = ROLL_MAX
        start1 = thread_num + 1
    else:
        step = 1

    if b1 > 0:
        # roll next die for P1
        for i in range(start1, ROLL_MAX + 1, step):
            n = d['p1']['n'] - b1

            d['p1']['d'][n]['value'] = i

            annotate_roll(d['p1'], n)

            # If this die is a miss, we know all higher rolls are misses, too.
            # Send in a multiplier and exit this loop early.
            # Don't do it on the first index, since that is our thread slicer
            # Don't do it on the start value, as that has a different multiplier on the back-end
            roll_dice(b1 - 1, b2, i, 1, d, -1)

            if(not d['p1']['d'][n]['is_hit']):
                break

    elif b2 > 0:
        # roll next die for P2
        for i in range(start2, ROLL_MAX + 1):
            n = d['p2']['n'] - b2

            d['p2']['d'][n]['value'] = i

            annotate_roll(d['p2'], n)

            roll_dice(0, b2 - 1, 21, i, d, -1)

            if not d['p2']['d'][n]['is_hit']:
                break

    else:
        # all dice are rolled; count results
        count_roll_results(d)


#
# rolling_thread()
#
def rolling_thread(data):
    d = data;

    if(d['thread_num'] <= d['p1']['stat']):
        roll_dice(d['p1']['n'], d['p2']['n'], 1, 1, d, d['thread_num'])

#
# tabulate()
#
# This function generates and then prints two tables.
#
# First is the total number of hits/crits possible for each player.
# This is calculated using roll_dice().
#
# Second is the number of wounds that each of these hit outcomes could
# cause. These are calculated by calc_wounds().
#
# Finally, both datasets are printed using print_tables().
#
def tabulate(p1, p2):
    d = []
    threads = []

    for t in range(NUM_THREADS):
        d.append({})
        d[t]['p1'] = {}
        d[t]['p2'] = {}
        d[t]['thread_num'] = t
        d[t]['p1']['n'] = p1['n']
        d[t]['p2']['n'] = p2['n']
        d[t]['p1']['stat'] = p1['stat']
        d[t]['p2']['stat'] = p2['stat']
        d[t]['p1']['dam'] = p1['dam']
        d[t]['p2']['dam'] = p2['dam']
        d[t]['p1']['ammo'] = p1['ammo']
        d[t]['p2']['ammo'] = p2['ammo']
        d[t]['num_rolls'] = 0

        d[t]['p1']['d'] = []
        d[t]['p2']['d'] = []
        for i in range(B_MAX + 1):
            d[t]['p1']['d'].append({})
            d[t]['p2']['d'].append({})

        d[t]['p1']['w'] = []
        d[t]['p2']['w'] = []
        for i in range(W_MAX + 1):
            d[t]['p1']['w'].append(0.0)
            d[t]['p2']['w'].append(0.0)

        d[t]['p1']['hit'] = []
        d[t]['p2']['hit'] = []
        for i in range(B_MAX + 1):
            d[t]['p1']['hit'].append([])
            d[t]['p2']['hit'].append([])
            for j in range(B_MAX + 1):
                d[t]['p1']['hit'][i].append(0)
                d[t]['p2']['hit'][i].append(0)

        #rval = (pthread_create(&threads[t], NULL, rolling_thread, &d[t]));
        rolling_thread(d[t])

    # Wait for all threads and sum the results
    #pthread_join(threads[0], NULL);
    print "thread %d num_rolls %d" % (0, d[0]['num_rolls'])
    for t in range(1, NUM_THREADS):
        #pthread_join(threads[t], NULL);
        print "thread %d num_rolls %d" % (t, d[t]['num_rolls'])
        d[0]['num_rolls'] += d[t]['num_rolls']

        # copy hit and crit data
        for h in range(B_MAX + 1):
            for c in range(B_MAX + 1):
                d[0]['p1']['hit'][h][c] += d[t]['p1']['hit'][h][c]
                d[0]['p2']['hit'][h][c] += d[t]['p2']['hit'][h][c]

    print "total rolls %d should be %.0f" % (d[0]['num_rolls'], pow(ROLL_MAX, d[0]['p1']['n'] + d[0]['p2']['n']))
    assert(d[0]['num_rolls'] == pow(ROLL_MAX, d[0]['p1']['n'] + d[0]['p2']['n']))
    
    calc_wounds(d[0])

    print_tables(d[0])


# MAIN

if len(sys.argv) != 9:
    printf("Usage: %s <BS 1> <B 1> <DAM 1> <AMMO 1> <BS 2> <B 2> <DAM 2> <AMMO 2>\n", sys.argv[0])
    exit(1)

p1 = {}
p2 = {}

i = 1
p1['stat'] = int(sys.argv[i])
i += 1
p1['n'] = int(sys.argv[i])
i += 1
p1['dam'] = int(sys.argv[i])
i += 1
ammo1 = sys.argv[i][0]
i += 1
p2['stat'] = int(sys.argv[i])
i += 1
p2['n'] = int(sys.argv[i])
i += 1
p2['dam'] = int(sys.argv[i])
i += 1
ammo2 = sys.argv[i][0]
i += 1

if p1['n'] < 1 or p1['n'] > B_MAX:
    print "B 1 must be in the range of 1 to %d" % (B_MAX)
    exit(1)

if p2['n'] < 1 or p2['n'] > B_MAX:
    print "B 2 must be in the range of 1 to %d" % (B_MAX)
    exit(1)

if p1['stat'] < 1 or p1['stat'] > STAT_MAX:
    print "BS 1 must be in the range of 1 to %d" % i(STAT_MAX)
    exit(1)

if p2['stat'] < 1 or p2['stat'] > STAT_MAX:
    print "BS 2 must be in the range of 1 to %d" % (STAT_MAX)
    exit(1)

if p1['dam'] < 1 or p1['dam'] > DAM_MAX:
    print "DAM 1 must be in the range of 1 to %d" % (DAM_MAX)
    exit(1)

if p2['dam'] < 1 or p2['dam'] > DAM_MAX:
    print "DAM 2 must be in the range of 1 to %d" % (DAM_MAX)
    exit(1)

if ammo1 == 'N':
    p1['ammo'] = AMMO_NORMAL
elif ammo1 == 'D':
    p1['ammo'] = AMMO_DA
elif ammo1 == 'E':
    p1['ammo'] = AMMO_EXP
elif ammo1 == 'F':
    p1['ammo'] = AMMO_FIRE
else:
    print "ERROR: AMMO 1 type %c unknown.  Must be one of N, D, E, F" % (ammo1)
    exit(1);

if ammo2 == 'N':
    p2['ammo'] = AMMO_NORMAL
elif ammo2 == 'D':
    p2['ammo'] = AMMO_DA
elif ammo2 == 'E':
    p2['ammo'] = AMMO_EXP
elif ammo2 == 'F':
    p2['ammo'] = AMMO_FIRE
else:
    print "ERROR: AMMO 1 type %c unknown.  Must be one of N, D, E, F" % (ammo2)
    exit(1);

tabulate(p1, p2)
