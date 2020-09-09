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

P1 Hits:  0 Crits:  1 -  7.528% (12045)
P1 Hits:  0 Crits:  2 -  0.504% (807)
P1 Hits:  0 Crits:  3 -  0.012% (19)
P1 Hits:  1 Crits:  0 - 24.968% (39948)
P1 Hits:  1 Crits:  1 -  4.110% (6576)
P1 Hits:  1 Crits:  2 -  0.172% (276)
P1 Hits:  2 Crits:  0 - 14.078% (22524)
P1 Hits:  2 Crits:  1 -  1.222% (1956)
P1 Hits:  3 Crits:  0 -  3.050% (4880)

No Hits: 10.823% 17317

P2 Hits:  0 Crits:  1 -  4.287% (6859)
P2 Hits:  1 Crits:  0 - 29.246% (46793)


======================================================

P1 Scores  6 Success(es):  0.000% NONE
P1 Scores  6 Success(es):  0.000%
P1 Scores  5 Success(es):  0.000% NONE
P1 Scores  5 Success(es):  0.000%
P1 Scores  4 Success(es):  0.004% NONE
P1 Scores  4 Success(es):  0.004%
P1 Scores  3 Success(es):  0.111% NONE
P1 Scores  3 Success(es):  0.111%
P1 Scores  2 Success(es):  1.855% NONE
P1 Scores  2 Success(es):  1.855%
P1 Scores  1 Success(es): 15.439% NONE
P1 Scores  1 Success(es): 15.439%
P1 Scores  6+ Successes:   0.000% NONE
P1 Scores  5+ Successes:   0.000% NONE
P1 Scores  4+ Successes:   0.004% NONE
P1 Scores  3+ Successes:   0.115% NONE
P1 Scores  2+ Successes:   1.970% NONE
P1 Scores  1+ Successes:  17.410% NONE
P1 Scores  6+ Successes:   0.000%
P1 Scores  5+ Successes:   0.000%
P1 Scores  4+ Successes:   0.004%
P1 Scores  3+ Successes:   0.115%
P1 Scores  2+ Successes:   1.970%
P1 Scores  1+ Successes:  17.410%

No Successes: 61.442%

P2 Scores  2 Success(es):  1.543% NONE
P2 Scores  2 Success(es):  1.543%
P2 Scores  1 Success(es): 19.605% NONE
P2 Scores  1 Success(es): 19.605%
P2 Scores  2+ Successes:   1.543% NONE
P2 Scores  1+ Successes:  21.148% NONE
P2 Scores  2+ Successes:   1.543%
P2 Scores  1+ Successes:  21.148%

EOF

$output = `./inf-dice-n4 9 3 1 4 NONE 12 1 1 12 NONE`;

die if $output ne $expected;

###########################################################################
# Test FtF of DA vs EXP
###########################################################################

$expected = <<EOF;
P1 STAT 12 CRIT 12 CRIT_1 N BOOST  0 B 1 TEMPLATE 0 AMMO NORMAL DAM[0]  2 TAG[0] NONE DAM[1]  2 TAG[1] NONE
P2 STAT 12 CRIT 12 CRIT_1 N BOOST  0 B 1 TEMPLATE 0 AMMO NORMAL DAM[0] 10 TAG[0] NONE DAM[1] 10 TAG[1] NONE DAM[2] 10 TAG[2] NONE

Total Rolls: 400
Actual Rolls Made: 169
Savings: 57.75%

P1 Hits:  0 Crits:  1 -  4.750% (19)
P1 Hits:  1 Crits:  0 - 35.750% (143)

No Hits: 19.000% 76

P2 Hits:  0 Crits:  1 -  4.750% (19)
P2 Hits:  1 Crits:  0 - 35.750% (143)


======================================================

P1 Scores  3 Success(es):  0.005% NONE
P1 Scores  3 Success(es):  0.005%
P1 Scores  2 Success(es):  0.486% NONE
P1 Scores  2 Success(es):  0.486%
P1 Scores  1 Success(es):  7.589% NONE
P1 Scores  1 Success(es):  7.589%
P1 Scores  3+ Successes:   0.005% NONE
P1 Scores  2+ Successes:   0.491% NONE
P1 Scores  1+ Successes:   8.080% NONE
P1 Scores  3+ Successes:   0.005%
P1 Scores  2+ Successes:   0.491%
P1 Scores  1+ Successes:   8.080%

No Successes: 56.186%

P2 Scores  4 Success(es):  0.297% NONE
P2 Scores  4 Success(es):  0.297%
P2 Scores  3 Success(es):  5.656% NONE
P2 Scores  3 Success(es):  5.656%
P2 Scores  2 Success(es): 15.188% NONE
P2 Scores  2 Success(es): 15.188%
P2 Scores  1 Success(es): 14.594% NONE
P2 Scores  1 Success(es): 14.594%
P2 Scores  4+ Successes:   0.297% NONE
P2 Scores  3+ Successes:   5.953% NONE
P2 Scores  2+ Successes:  21.141% NONE
P2 Scores  1+ Successes:  35.734% NONE
P2 Scores  4+ Successes:   0.297%
P2 Scores  3+ Successes:   5.953%
P2 Scores  2+ Successes:  21.141%
P2 Scores  1+ Successes:  35.734%

EOF

$output = `./inf-dice-n4 12 1 2 2 NONE 2 NONE 12 1 3 10 NONE 10 NONE 10 NONE`;

die if $output ne $expected;

###########################################################################
# Done!
###########################################################################

print "All tests pass!\n";
