#!/usr/bin/perl

use strict;
use warnings;

my $players = ['p1', 'p2'];
my $colors = {
    p1 => {
        pure => {
            r => 0xac,
            g => 0x87,
            b => 0xc1,
        }
    },
    p2 => {
        pure => {
            r => 0xff,
            g => 0xd3,
            b => 0x24,
        }
    },
    miss => {
        color => '#000000',
    },
    text => 'white',
};

my $steps = 15;

print <<EOF;
.hitbar {
    width: 100%;
    height: 2em;
    border-spacing: 0px;
    margin: auto;
}

EOF

print ".miss {\n";
print "    color: $colors->{text};\n";
print "    background-color: $colors->{miss}{color};\n";
print "}\n\n";


for my $p (@$players){
    my ($r, $g, $b);
    my ($step_r, $step_g, $step_b);

    $r = $colors->{$p}{pure}{r} * 0.25;
    $g = $colors->{$p}{pure}{g} * 0.25;
    $b = $colors->{$p}{pure}{b} * 0.25;

    $step_r = ($colors->{$p}{pure}{r} - $r) / $steps;
    $step_g = ($colors->{$p}{pure}{g} - $g) / $steps;
    $step_b = ($colors->{$p}{pure}{b} - $b) / $steps;

    # solid backgrounds
    for my $i (1 .. $steps){
        print ".$p-hit-$i {\n";
        print "    color: $colors->{text};\n";
        printf "    background-color: #%02x%02x%02x;\n", $r, $g, $b;
        print "}\n\n";

        $r += $step_r;
        $g += $step_g;
        $b += $step_b;
    }

    $r = $colors->{$p}{pure}{r} * 0.1;
    $g = $colors->{$p}{pure}{g} * 0.1;
    $b = $colors->{$p}{pure}{b} * 0.1;

    my $pure = sprintf "%02x%02x%02x", $colors->{$p}{pure}{r}, $colors->{$p}{pure}{g}, $colors->{$p}{pure}{b};

    # gradients for cumulative probabilities
    for my $i (1 .. $steps){
        print ".$p-cumul-hit-$i {\n";
        print "    color: $colors->{text};\n";
        printf "    background-color: #%02x%02x%02x;\n", $r, $g, $b;
        printf "    background: -webkit-linear-gradient(left, #%02x%02x%02x, #%s);\n", $r, $g, $b, $pure;
        printf "    background: -o-linear-gradient(left, #%02x%02x%02x, #%s);\n", $r, $g, $b, $pure;
        printf "    background: -moz-linear-gradient(left, #%02x%02x%02x, #%s);\n", $r, $g, $b, $pure;
        printf "    background: linear-gradient(left, #%02x%02x%02x, #%s);\n", $r, $g, $b, $pure;

        print "}\n\n";

        $r += $step_r;
        $g += $step_g;
        $b += $step_b;
    }
}
