#!/usr/bin/perl

use strict;
use warnings;

my $players = ['p1', 'p2'];
my $colors = {
    p1 => {
        pure => {
            r => 255,
            g => 177,
            b => 41,
        },
        text => 'black',
    },
    p2 => {
        pure => {
            r => 6,
            g => 164,
            b => 235,
        },
        text => 'black',
    },
    miss => {
        color => '#000000',
        text => 'white',
    },
};

my $steps = 5;

sub initial_color{
    my ($p) = @_;
    return (
        $colors->{$p}{pure}{r} * 0.75,
        $colors->{$p}{pure}{g} * 0.75,
        $colors->{$p}{pure}{b} * 0.75,
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
    text-align: center;
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
    for my $i (1 .. $steps + 1){
        print ".$p-hit-$i {\n";
        print "    color: $colors->{$p}{text};\n";
        printf "    background-color: #%02x%02x%02x;\n", $r, $g, $b;
        print "}\n\n";

        if($i < $steps){
            $r += $step_r;
            $g += $step_g;
            $b += $step_b;
        }
    }

    # Do another few steps at the same level in case they made a crazy
    # custom unit
    for my $i ($steps + 1 .. 2 * $steps){
        print ".$p-hit-$i {\n";
        print "    color: $colors->{$p}{text};\n";
        printf "    background-color: #%02x%02x%02x;\n", $r, $g, $b;
        print "}\n\n";
    }
}
