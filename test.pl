#!/usr/bin/perl

use strict;
use warnings;

my ($output, $expected);

###########################################################################
# Test FtF where both sides are using normal ammo
###########################################################################

$expected = <<EOF;
P1 STAT  9 CRIT  9 CRIT_1 N BOOST  0 B 3 TEMPLATE 0 AMMO NORMAL DAM[0]  4 TAG[0] NONE
P2 STAT 12 CRIT 12 CRIT_1 N BOOST  0 B 1 TEMPLATE 0 AMMO NORMAL DAM[0] 12 TAG[0] NONE

Total Rolls: 160000
Actual Rolls Made: 2860
Savings: 98.21%

P1 Hits:  0 Crits:  1 -   7.53% (12045)
P1 Hits:  0 Crits:  2 -   0.50% (807)
P1 Hits:  0 Crits:  3 -   0.01% (19)
P1 Hits:  1 Crits:  0 -  24.97% (39948)
P1 Hits:  1 Crits:  1 -   4.11% (6576)
P1 Hits:  1 Crits:  2 -   0.17% (276)
P1 Hits:  2 Crits:  0 -  14.08% (22524)
P1 Hits:  2 Crits:  1 -   1.22% (1956)
P1 Hits:  3 Crits:  0 -   3.05% (4880)

No Hits:  10.82% 17317

P2 Hits:  0 Crits:  1 -   4.29% (6859)
P2 Hits:  1 Crits:  0 -  29.25% (46793)


======================================================

P1 Scores  3 Success(es):   0.11% NONE
P1 Scores  3 Success(es):   0.11%
P1 Scores  2 Success(es):   1.86% NONE
P1 Scores  2 Success(es):   1.86%
P1 Scores  1 Success(es):  15.44% NONE
P1 Scores  1 Success(es):  15.44%
P1 Scores  6+ Successes:    0.00% NONE
P1 Scores  5+ Successes:    0.00% NONE
P1 Scores  4+ Successes:    0.00% NONE
P1 Scores  3+ Successes:    0.12% NONE
P1 Scores  2+ Successes:    1.97% NONE
P1 Scores  1+ Successes:   17.41% NONE
P1 Scores  6+ Successes:    0.00%
P1 Scores  5+ Successes:    0.00%
P1 Scores  4+ Successes:    0.00%
P1 Scores  3+ Successes:    0.12%
P1 Scores  2+ Successes:    1.97%
P1 Scores  1+ Successes:   17.41%

No Successes:  61.44%

P2 Scores  2 Success(es):   1.54% NONE
P2 Scores  2 Success(es):   1.54%
P2 Scores  1 Success(es):  19.61% NONE
P2 Scores  1 Success(es):  19.61%
P2 Scores  2+ Successes:    1.54% NONE
P2 Scores  1+ Successes:   21.15% NONE
P2 Scores  2+ Successes:    1.54%
P2 Scores  1+ Successes:   21.15%

EOF

$output = `./inf-dice-n4 9 3 1 4 NONE 12 1 1 12 NONE`;

die if $output ne $expected;

###########################################################################
# Done!
###########################################################################

print "All tests pass!\n";
