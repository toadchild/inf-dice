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
# Test shoot vs. dodge
###########################################################################

$expected = <<EOF;
P1 STAT 12 CRIT 12 CRIT_1 N BOOST  0 B 3 TEMPLATE 0 AMMO NORMAL DAM[0] 10 TAG[0] NONE
P2 STAT 12 CRIT 12 CRIT_1 N BOOST  0 B 1 TEMPLATE 0 AMMO NONE DAM[0]  0 TAG[0] NONE

Total Rolls: 160000
Actual Rolls Made: 5915
Savings: 96.30%

P1 Hits:  0 Crits:  1 -  5.209% (8334)
P1 Hits:  0 Crits:  2 -  0.409% (654)
P1 Hits:  0 Crits:  3 -  0.012% (19)
P1 Hits:  1 Crits:  0 - 26.029% (41646)
P1 Hits:  1 Crits:  1 -  5.115% (8184)
P1 Hits:  1 Crits:  2 -  0.268% (429)
P1 Hits:  2 Crits:  0 - 22.564% (36102)
P1 Hits:  2 Crits:  1 -  2.537% (4059)
P1 Hits:  3 Crits:  0 -  8.546% (13673)

No Hits:  7.240% 11584

P2 Hits:  0 Crits:  1 -  4.287% (6859)
P2 Hits:  1 Crits:  0 - 17.786% (28457)


======================================================

P1 Scores  6 Success(es):  0.000% NONE
P1 Scores  6 Success(es):  0.000%
P1 Scores  5 Success(es):  0.009% NONE
P1 Scores  5 Success(es):  0.009%
P1 Scores  4 Success(es):  0.229% NONE
P1 Scores  4 Success(es):  0.229%
P1 Scores  3 Success(es):  2.531% NONE
P1 Scores  3 Success(es):  2.531%
P1 Scores  2 Success(es): 13.257% NONE
P1 Scores  2 Success(es): 13.257%
P1 Scores  1 Success(es): 32.803% NONE
P1 Scores  1 Success(es): 32.803%
P1 Scores  6+ Successes:   0.000% NONE
P1 Scores  5+ Successes:   0.010% NONE
P1 Scores  4+ Successes:   0.238% NONE
P1 Scores  3+ Successes:   2.770% NONE
P1 Scores  2+ Successes:  16.027% NONE
P1 Scores  1+ Successes:  48.830% NONE
P1 Scores  6+ Successes:   0.000%
P1 Scores  5+ Successes:   0.010%
P1 Scores  4+ Successes:   0.238%
P1 Scores  3+ Successes:   2.770%
P1 Scores  2+ Successes:  16.027%
P1 Scores  1+ Successes:  48.830%

No Successes: 29.098%

P2 Scores  1 Success(es): 22.073% NONE
P2 Scores  1 Success(es): 22.073%
P2 Scores  1+ Successes:  22.073% NONE
P2 Scores  1+ Successes:  22.073%

EOF

$output = `./inf-dice-n4 12 3 1 10 NONE 12 1 - 0 NONE`;

die if $output ne $expected;

###########################################################################
# Test flame template
###########################################################################

$expected = <<EOF;
P1 STAT 20 CRIT 21 CRIT_1 N BOOST  0 B 1 TEMPLATE 1 AMMO CONTINUOUS DAM[0] 12 TAG[0] NONE
P2 STAT  0 CRIT  0 CRIT_1 N BOOST  0 B 1 TEMPLATE 0 AMMO NONE DAM[0]  0 TAG[0] NONE

Total Rolls: 400
Actual Rolls Made: 1
Savings: 99.75%

P1 Hits:  1 Crits:  0 - 100.000% (400)

No Hits:  0.000% 0



======================================================

P1 Scores 24 Success(es):  0.000% NONE
P1 Scores 24 Success(es):  0.000%
P1 Scores 23 Success(es):  0.000% NONE
P1 Scores 23 Success(es):  0.000%
P1 Scores 22 Success(es):  0.001% NONE
P1 Scores 22 Success(es):  0.001%
P1 Scores 21 Success(es):  0.001% NONE
P1 Scores 21 Success(es):  0.001%
P1 Scores 20 Success(es):  0.001% NONE
P1 Scores 20 Success(es):  0.001%
P1 Scores 19 Success(es):  0.002% NONE
P1 Scores 19 Success(es):  0.002%
P1 Scores 18 Success(es):  0.004% NONE
P1 Scores 18 Success(es):  0.004%
P1 Scores 17 Success(es):  0.007% NONE
P1 Scores 17 Success(es):  0.007%
P1 Scores 16 Success(es):  0.011% NONE
P1 Scores 16 Success(es):  0.011%
P1 Scores 15 Success(es):  0.019% NONE
P1 Scores 15 Success(es):  0.019%
P1 Scores 14 Success(es):  0.031% NONE
P1 Scores 14 Success(es):  0.031%
P1 Scores 13 Success(es):  0.052% NONE
P1 Scores 13 Success(es):  0.052%
P1 Scores 12 Success(es):  0.087% NONE
P1 Scores 12 Success(es):  0.087%
P1 Scores 11 Success(es):  0.145% NONE
P1 Scores 11 Success(es):  0.145%
P1 Scores 10 Success(es):  0.242% NONE
P1 Scores 10 Success(es):  0.242%
P1 Scores  9 Success(es):  0.403% NONE
P1 Scores  9 Success(es):  0.403%
P1 Scores  8 Success(es):  0.672% NONE
P1 Scores  8 Success(es):  0.672%
P1 Scores  7 Success(es):  1.120% NONE
P1 Scores  7 Success(es):  1.120%
P1 Scores  6 Success(es):  1.866% NONE
P1 Scores  6 Success(es):  1.866%
P1 Scores  5 Success(es):  3.110% NONE
P1 Scores  5 Success(es):  3.110%
P1 Scores  4 Success(es):  5.184% NONE
P1 Scores  4 Success(es):  5.184%
P1 Scores  3 Success(es):  8.640% NONE
P1 Scores  3 Success(es):  8.640%
P1 Scores  2 Success(es): 14.400% NONE
P1 Scores  2 Success(es): 14.400%
P1 Scores  1 Success(es): 24.000% NONE
P1 Scores  1 Success(es): 24.000%
P1 Scores 24+ Successes:   0.000% NONE
P1 Scores 23+ Successes:   0.001% NONE
P1 Scores 22+ Successes:   0.001% NONE
P1 Scores 21+ Successes:   0.002% NONE
P1 Scores 20+ Successes:   0.004% NONE
P1 Scores 19+ Successes:   0.006% NONE
P1 Scores 18+ Successes:   0.010% NONE
P1 Scores 17+ Successes:   0.017% NONE
P1 Scores 16+ Successes:   0.028% NONE
P1 Scores 15+ Successes:   0.047% NONE
P1 Scores 14+ Successes:   0.078% NONE
P1 Scores 13+ Successes:   0.131% NONE
P1 Scores 12+ Successes:   0.218% NONE
P1 Scores 11+ Successes:   0.363% NONE
P1 Scores 10+ Successes:   0.605% NONE
P1 Scores  9+ Successes:   1.008% NONE
P1 Scores  8+ Successes:   1.680% NONE
P1 Scores  7+ Successes:   2.799% NONE
P1 Scores  6+ Successes:   4.666% NONE
P1 Scores  5+ Successes:   7.776% NONE
P1 Scores  4+ Successes:  12.960% NONE
P1 Scores  3+ Successes:  21.600% NONE
P1 Scores  2+ Successes:  36.000% NONE
P1 Scores  1+ Successes:  60.000% NONE
P1 Scores 24+ Successes:   0.000%
P1 Scores 23+ Successes:   0.001%
P1 Scores 22+ Successes:   0.001%
P1 Scores 21+ Successes:   0.002%
P1 Scores 20+ Successes:   0.004%
P1 Scores 19+ Successes:   0.006%
P1 Scores 18+ Successes:   0.010%
P1 Scores 17+ Successes:   0.017%
P1 Scores 16+ Successes:   0.028%
P1 Scores 15+ Successes:   0.047%
P1 Scores 14+ Successes:   0.078%
P1 Scores 13+ Successes:   0.131%
P1 Scores 12+ Successes:   0.218%
P1 Scores 11+ Successes:   0.363%
P1 Scores 10+ Successes:   0.605%
P1 Scores  9+ Successes:   1.008%
P1 Scores  8+ Successes:   1.680%
P1 Scores  7+ Successes:   2.799%
P1 Scores  6+ Successes:   4.666%
P1 Scores  5+ Successes:   7.776%
P1 Scores  4+ Successes:  12.960%
P1 Scores  3+ Successes:  21.600%
P1 Scores  2+ Successes:  36.000%
P1 Scores  1+ Successes:  60.000%

No Successes: 40.000%


EOF

$output = `./inf-dice-n4 T 1 1C 12 NONE 0 1 - 0 NONE`;

die if $output ne $expected;

###########################################################################
# Test fire in FtF against normal
###########################################################################

$expected = <<EOF;
P1 STAT 12 CRIT 12 CRIT_1 N BOOST  0 B 2 TEMPLATE 0 AMMO CONTINUOUS DAM[0] 13 TAG[0] NONE
P2 STAT  5 CRIT  5 CRIT_1 N BOOST  0 B 1 TEMPLATE 0 AMMO NORMAL DAM[0]  8 TAG[0] NONE

Total Rolls: 8000
Actual Rolls Made: 546
Savings: 93.17%

P1 Hits:  0 Crits:  1 -  4.050% (324)
P1 Hits:  0 Crits:  2 -  0.237% (19)
P1 Hits:  1 Crits:  0 - 41.800% (3344)
P1 Hits:  1 Crits:  1 -  4.975% (398)
P1 Hits:  2 Crits:  0 - 26.363% (2109)

No Hits: 13.488% 1079

P2 Hits:  0 Crits:  1 -  4.513% (361)
P2 Hits:  1 Crits:  0 -  4.575% (366)


======================================================

P1 Scores 24 Success(es):  0.012% NONE
P1 Scores 24 Success(es):  0.012%
P1 Scores 23 Success(es):  0.006% NONE
P1 Scores 23 Success(es):  0.006%
P1 Scores 22 Success(es):  0.008% NONE
P1 Scores 22 Success(es):  0.008%
P1 Scores 21 Success(es):  0.013% NONE
P1 Scores 21 Success(es):  0.013%
P1 Scores 20 Success(es):  0.018% NONE
P1 Scores 20 Success(es):  0.018%
P1 Scores 19 Success(es):  0.027% NONE
P1 Scores 19 Success(es):  0.027%
P1 Scores 18 Success(es):  0.040% NONE
P1 Scores 18 Success(es):  0.040%
P1 Scores 17 Success(es):  0.059% NONE
P1 Scores 17 Success(es):  0.059%
P1 Scores 16 Success(es):  0.087% NONE
P1 Scores 16 Success(es):  0.087%
P1 Scores 15 Success(es):  0.127% NONE
P1 Scores 15 Success(es):  0.127%
P1 Scores 14 Success(es):  0.186% NONE
P1 Scores 14 Success(es):  0.186%
P1 Scores 13 Success(es):  0.271% NONE
P1 Scores 13 Success(es):  0.271%
P1 Scores 12 Success(es):  0.394% NONE
P1 Scores 12 Success(es):  0.394%
P1 Scores 11 Success(es):  0.570% NONE
P1 Scores 11 Success(es):  0.570%
P1 Scores 10 Success(es):  0.821% NONE
P1 Scores 10 Success(es):  0.821%
P1 Scores  9 Success(es):  1.179% NONE
P1 Scores  9 Success(es):  1.179%
P1 Scores  8 Success(es):  1.683% NONE
P1 Scores  8 Success(es):  1.683%
P1 Scores  7 Success(es):  2.387% NONE
P1 Scores  7 Success(es):  2.387%
P1 Scores  6 Success(es):  3.363% NONE
P1 Scores  6 Success(es):  3.363%
P1 Scores  5 Success(es):  4.698% NONE
P1 Scores  5 Success(es):  4.698%
P1 Scores  4 Success(es):  6.494% NONE
P1 Scores  4 Success(es):  6.494%
P1 Scores  3 Success(es):  8.864% NONE
P1 Scores  3 Success(es):  8.864%
P1 Scores  2 Success(es): 11.902% NONE
P1 Scores  2 Success(es): 11.902%
P1 Scores  1 Success(es): 15.643% NONE
P1 Scores  1 Success(es): 15.643%
P1 Scores 24+ Successes:   0.012% NONE
P1 Scores 23+ Successes:   0.017% NONE
P1 Scores 22+ Successes:   0.026% NONE
P1 Scores 21+ Successes:   0.038% NONE
P1 Scores 20+ Successes:   0.057% NONE
P1 Scores 19+ Successes:   0.084% NONE
P1 Scores 18+ Successes:   0.124% NONE
P1 Scores 17+ Successes:   0.184% NONE
P1 Scores 16+ Successes:   0.271% NONE
P1 Scores 15+ Successes:   0.398% NONE
P1 Scores 14+ Successes:   0.584% NONE
P1 Scores 13+ Successes:   0.855% NONE
P1 Scores 12+ Successes:   1.249% NONE
P1 Scores 11+ Successes:   1.819% NONE
P1 Scores 10+ Successes:   2.640% NONE
P1 Scores  9+ Successes:   3.819% NONE
P1 Scores  8+ Successes:   5.501% NONE
P1 Scores  7+ Successes:   7.889% NONE
P1 Scores  6+ Successes:  11.252% NONE
P1 Scores  5+ Successes:  15.949% NONE
P1 Scores  4+ Successes:  22.444% NONE
P1 Scores  3+ Successes:  31.307% NONE
P1 Scores  2+ Successes:  43.210% NONE
P1 Scores  1+ Successes:  58.853% NONE
P1 Scores 24+ Successes:   0.012%
P1 Scores 23+ Successes:   0.017%
P1 Scores 22+ Successes:   0.026%
P1 Scores 21+ Successes:   0.038%
P1 Scores 20+ Successes:   0.057%
P1 Scores 19+ Successes:   0.084%
P1 Scores 18+ Successes:   0.124%
P1 Scores 17+ Successes:   0.184%
P1 Scores 16+ Successes:   0.271%
P1 Scores 15+ Successes:   0.398%
P1 Scores 14+ Successes:   0.584%
P1 Scores 13+ Successes:   0.855%
P1 Scores 12+ Successes:   1.249%
P1 Scores 11+ Successes:   1.819%
P1 Scores 10+ Successes:   2.640%
P1 Scores  9+ Successes:   3.819%
P1 Scores  8+ Successes:   5.501%
P1 Scores  7+ Successes:   7.889%
P1 Scores  6+ Successes:  11.252%
P1 Scores  5+ Successes:  15.949%
P1 Scores  4+ Successes:  22.444%
P1 Scores  3+ Successes:  31.307%
P1 Scores  2+ Successes:  43.210%
P1 Scores  1+ Successes:  58.853%

No Successes: 36.429%

P2 Scores  2 Success(es):  0.722% NONE
P2 Scores  2 Success(es):  0.722%
P2 Scores  1 Success(es):  3.996% NONE
P2 Scores  1 Success(es):  3.996%
P2 Scores  2+ Successes:   0.722% NONE
P2 Scores  1+ Successes:   4.718% NONE
P2 Scores  2+ Successes:   0.722%
P2 Scores  1+ Successes:   4.718%

EOF

$output = `./inf-dice-n4 12 2 1C 13 NONE 5 1 1 8 NONE`;

die if $output ne $expected;

###########################################################################
# Test DA + Continuous
###########################################################################

$expected = <<EOF;
P1 STAT 10 CRIT 10 CRIT_1 N BOOST  0 B 2 TEMPLATE 0 AMMO CONTINUOUS DAM[0] 12 TAG[0] NONE DAM[1] 12 TAG[1] NONE
P2 STAT  0 CRIT  0 CRIT_1 N BOOST  0 B 1 TEMPLATE 0 AMMO NONE DAM[0]  0 TAG[0] NONE

Total Rolls: 8000
Actual Rolls Made: 66
Savings: 99.17%

P1 Hits:  0 Crits:  1 -  5.000% (400)
P1 Hits:  0 Crits:  2 -  0.250% (20)
P1 Hits:  1 Crits:  0 - 45.000% (3600)
P1 Hits:  1 Crits:  1 -  4.500% (360)
P1 Hits:  2 Crits:  0 - 20.250% (1620)

No Hits: 25.000% 2000



======================================================

P1 Scores 24 Success(es):  0.028% NONE
P1 Scores 24 Success(es):  0.028%
P1 Scores 23 Success(es):  0.018% NONE
P1 Scores 23 Success(es):  0.018%
P1 Scores 22 Success(es):  0.023% NONE
P1 Scores 22 Success(es):  0.023%
P1 Scores 21 Success(es):  0.034% NONE
P1 Scores 21 Success(es):  0.034%
P1 Scores 20 Success(es):  0.050% NONE
P1 Scores 20 Success(es):  0.050%
P1 Scores 19 Success(es):  0.073% NONE
P1 Scores 19 Success(es):  0.073%
P1 Scores 18 Success(es):  0.107% NONE
P1 Scores 18 Success(es):  0.107%
P1 Scores 17 Success(es):  0.155% NONE
P1 Scores 17 Success(es):  0.155%
P1 Scores 16 Success(es):  0.223% NONE
P1 Scores 16 Success(es):  0.223%
P1 Scores 15 Success(es):  0.319% NONE
P1 Scores 15 Success(es):  0.319%
P1 Scores 14 Success(es):  0.454% NONE
P1 Scores 14 Success(es):  0.454%
P1 Scores 13 Success(es):  0.639% NONE
P1 Scores 13 Success(es):  0.639%
P1 Scores 12 Success(es):  0.893% NONE
P1 Scores 12 Success(es):  0.893%
P1 Scores 11 Success(es):  1.236% NONE
P1 Scores 11 Success(es):  1.236%
P1 Scores 10 Success(es):  1.693% NONE
P1 Scores 10 Success(es):  1.693%
P1 Scores  9 Success(es):  2.292% NONE
P1 Scores  9 Success(es):  2.292%
P1 Scores  8 Success(es):  3.063% NONE
P1 Scores  8 Success(es):  3.063%
P1 Scores  7 Success(es):  4.033% NONE
P1 Scores  7 Success(es):  4.033%
P1 Scores  6 Success(es):  5.221% NONE
P1 Scores  6 Success(es):  5.221%
P1 Scores  5 Success(es):  6.620% NONE
P1 Scores  5 Success(es):  6.620%
P1 Scores  4 Success(es):  8.173% NONE
P1 Scores  4 Success(es):  8.173%
P1 Scores  3 Success(es):  9.724% NONE
P1 Scores  3 Success(es):  9.724%
P1 Scores  2 Success(es): 10.909% NONE
P1 Scores  2 Success(es): 10.909%
P1 Scores  1 Success(es): 10.933% NONE
P1 Scores  1 Success(es): 10.933%
P1 Scores 24+ Successes:   0.028% NONE
P1 Scores 23+ Successes:   0.046% NONE
P1 Scores 22+ Successes:   0.069% NONE
P1 Scores 21+ Successes:   0.103% NONE
P1 Scores 20+ Successes:   0.153% NONE
P1 Scores 19+ Successes:   0.227% NONE
P1 Scores 18+ Successes:   0.334% NONE
P1 Scores 17+ Successes:   0.489% NONE
P1 Scores 16+ Successes:   0.712% NONE
P1 Scores 15+ Successes:   1.031% NONE
P1 Scores 14+ Successes:   1.485% NONE
P1 Scores 13+ Successes:   2.124% NONE
P1 Scores 12+ Successes:   3.017% NONE
P1 Scores 11+ Successes:   4.253% NONE
P1 Scores 10+ Successes:   5.946% NONE
P1 Scores  9+ Successes:   8.238% NONE
P1 Scores  8+ Successes:  11.301% NONE
P1 Scores  7+ Successes:  15.335% NONE
P1 Scores  6+ Successes:  20.556% NONE
P1 Scores  5+ Successes:  27.175% NONE
P1 Scores  4+ Successes:  35.348% NONE
P1 Scores  3+ Successes:  45.072% NONE
P1 Scores  2+ Successes:  55.981% NONE
P1 Scores  1+ Successes:  66.914% NONE
P1 Scores 24+ Successes:   0.028%
P1 Scores 23+ Successes:   0.046%
P1 Scores 22+ Successes:   0.069%
P1 Scores 21+ Successes:   0.103%
P1 Scores 20+ Successes:   0.153%
P1 Scores 19+ Successes:   0.227%
P1 Scores 18+ Successes:   0.334%
P1 Scores 17+ Successes:   0.489%
P1 Scores 16+ Successes:   0.712%
P1 Scores 15+ Successes:   1.031%
P1 Scores 14+ Successes:   1.485%
P1 Scores 13+ Successes:   2.124%
P1 Scores 12+ Successes:   3.017%
P1 Scores 11+ Successes:   4.253%
P1 Scores 10+ Successes:   5.946%
P1 Scores  9+ Successes:   8.238%
P1 Scores  8+ Successes:  11.301%
P1 Scores  7+ Successes:  15.335%
P1 Scores  6+ Successes:  20.556%
P1 Scores  5+ Successes:  27.175%
P1 Scores  4+ Successes:  35.348%
P1 Scores  3+ Successes:  45.072%
P1 Scores  2+ Successes:  55.981%
P1 Scores  1+ Successes:  66.914%

No Successes: 33.086%


EOF

$output = `./inf-dice-n4 10 2 2C 12 NONE 12 NONE 0 1 - 0 NONE`;

die if $output ne $expected;

###########################################################################
# Done!
###########################################################################

print "All tests pass!\n";
