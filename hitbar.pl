#!/usr/bin/perl

use strict;
use warnings;

my $players = ['p1', 'p2'];
my $colors = {
    p1 => {
        base => 0x003000,
        step => 0x000d00,
    },
    p2 => {
        base => 0x003030,
        step => 0x000d0d,
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
    my $color;
    my $step = $colors->{$p}{step};

    # solid backgrounds
    $color = $colors->{$p}{base};
    for my $i (1 .. $steps){
        print ".$p-hit-$i {\n";
        print "    color: $colors->{text};\n";
        printf "    background-color: #%06x;\n", $color;
        print "}\n\n";

        $colors->{$p}{max} = $color;

        $color += $step;
    }

    # gradients for cumulative probabilities
    $color = $colors->{$p}{base};
    for my $i (1 .. $steps){
        print ".$p-cumul-hit-$i {\n";
        print "    color: $colors->{text};\n";
        printf "    background-color: #%06x;\n", $color;
        printf "    background: -webkit-linear-gradient(left, #%06x, #%06x); /* For Safari */\n", $color, $colors->{$p}{max};
        printf "    background: -o-linear-gradient(left, #%06x, #%06x); /* For Opera 11.1 to 12.0 */\n", $color, $colors->{$p}{max};
        printf "    background: -moz-linear-gradient(left, #%06x, #%06x); /* For Firefox 3.6 to 15 */\n", $color, $colors->{$p}{max};
        printf "    background: linear-gradient(left, #%06x, #%06x); /* Standard syntax */\n", $color, $colors->{$p}{max};

        print "}\n\n";

        $color += $step;
    }
}
