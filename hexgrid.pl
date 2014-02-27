#!/usr/bin/perl

use strict;
use warnings;

use GD;

my @hexpoints = (
    [-1, 0],
    [-0.5, sqrt(3) / 2],
    [0.5, sqrt(3) / 2],
    [1, 0],
    [0.5, -sqrt(3) / 2],
    [-0.5, -sqrt(3) / 2],
);

my ($size, $fname) = @ARGV;

my $short = $size / 2 / 2;
my $long = $short * 2 / sqrt(3);

print "Short: $short\nLong: $long\n";
my $off = 2 * $short;
my $radius = $long * 0.9;
my $height = $short * 4;
my $width = int(3 * $long);
my $alpha = 120;

my $im = new GD::Image($width, $height, 1);
$im->alphaBlending(0);
$im->saveAlpha(1);

my $color_fg = $im->colorAllocateAlpha(255,255,255, 127);
my $color_bg = $im->colorAllocateAlpha(0,0,0, $alpha);
#$im->setAntiAliased($white);

$im->filledRectangle(0, 0, $width, $height, $color_bg);

sub drawhex{
    my ($im, $x, $y, $r, $color) = @_;

    my $poly = new GD::Polygon;

    for my $point (@hexpoints){
        $poly->addPt($x + $r * $point->[0], $y + $r * $point->[1]);
    }
    $im->filledPolygon($poly, $color);
}

drawhex($im, $width / 2, $height / 2, $radius, $color_fg);
drawhex($im, $width / 2, $height / 2 - $off, $radius, $color_fg);
drawhex($im, $width / 2, $height / 2 + $off, $radius, $color_fg);
drawhex($im, $width / 2 + $off * sqrt(3) / 2, $height / 2 + $off / 2, $radius, $color_fg);
drawhex($im, $width / 2 - $off * sqrt(3) / 2, $height / 2 + $off / 2, $radius, $color_fg);
drawhex($im, $width / 2 + $off * sqrt(3) / 2, $height / 2 - $off / 2, $radius, $color_fg);
drawhex($im, $width / 2 - $off * sqrt(3) / 2, $height / 2 - $off / 2, $radius, $color_fg);

print "Writing $width x $height hextile to $fname\n";
open OUT, '>', $fname;
binmode OUT;
print OUT $im->png;
