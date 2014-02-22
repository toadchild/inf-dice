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
        },
        text => 'black',
    },
    p2 => {
        pure => {
            r => 136,
            g => 172,
            b => 77,
        },
        text => 'black',
    },
    miss => {
        color => '#000000',
        text => 'white',
    },
};

my $steps = 15;

sub initial_color{
    my ($p) = @_;
    return (
        $colors->{$p}{pure}{r} * 0.5,
        $colors->{$p}{pure}{g} * 0.5,
        $colors->{$p}{pure}{b} * 0.5,
    );
}

sub final_color{
    my ($p) = @_;
    return (
        ($colors->{$p}{pure}{r} + 0xff) / 2,
        ($colors->{$p}{pure}{g} + 0xff) / 2,
        ($colors->{$p}{pure}{b} + 0xff) / 2,
    );
}

print <<EOF;
.hitbar {
    width: 100%;
    height: 2em;
    border-spacing: 0px;
    margin-top: 1em;
    margin-bottom: 1em;
}

EOF

print ".miss {\n";
print "    color: $colors->{miss}{text};\n";
print "    background-color: $colors->{miss}{color};\n";
print "}\n\n";


for my $p (@$players){
    my ($r, $g, $b);
    my ($final_r, $final_g, $final_b);
    my ($step_r, $step_g, $step_b);

    ($r, $g, $b) = initial_color($p);
    ($final_r, $final_g, $final_b) = final_color($p);

    $step_r = ($final_r - $r) / $steps;
    $step_g = ($final_g - $g) / $steps;
    $step_b = ($final_b - $b) / $steps;

    # solid backgrounds
    for my $i (1 .. $steps){
        print ".$p-hit-$i {\n";
        print "    color: $colors->{$p}{text};\n";
        printf "    background-color: #%02x%02x%02x;\n", $r, $g, $b;
        print "}\n\n";

        $r += $step_r;
        $g += $step_g;
        $b += $step_b;
    }

    ($r, $g, $b) = initial_color($p);

    my $final = sprintf "%02x%02x%02x", $final_r, $final_g, $final_b;

    # gradients for cumulative probabilities
    for my $i (1 .. $steps){
        print ".$p-cumul-hit-$i {\n";
        print "    color: $colors->{$p}{text};\n";
        printf "    background-color: #%02x%02x%02x;\n", $r, $g, $b;
        printf "    background: -webkit-linear-gradient(left, #%02x%02x%02x, #%s);\n", $r, $g, $b, $final;
        printf "    background: -o-linear-gradient(left, #%02x%02x%02x, #%s);\n", $r, $g, $b, $final;
        printf "    background: -moz-linear-gradient(left, #%02x%02x%02x, #%s);\n", $r, $g, $b, $final;
        printf "    background: linear-gradient(left, #%02x%02x%02x, #%s);\n", $r, $g, $b, $final;

        print "}\n\n";

        $r += $step_r;
        $g += $step_g;
        $b += $step_b;
    }
}
