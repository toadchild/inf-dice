#!/usr/bin/perl

use strict;
use warnings;

use JSON::PP;
use Clone qw(clone);
use Data::Dumper;

my $json = JSON::PP->new;
$json->pretty(1);
$json->canonical(1);
$json->relaxed(1);
local $/;
my $json_text;

open IN, '<', 'hacking_implemented.dat' or die "Unable to open file";
$json_text = <IN>;
my $hacking_implemented = $json->decode($json_text);

my $all_ammo = {};
my $weapon_data = {};
my $file;
my $fname = "unit_data/hacking.json";
open $file, '<', $fname or die "Unable to open file";
$json_text = <$file>;
my $source_data = $json->decode($json_text);

my $devices = {};
for my $device (@{$source_data->{"Hacking Devices"}}){
    $devices->{$device->{name}} = {
        groups => $device->{groups},
        upgrades => $device->{upgrades},
    };
}

my $groups = {};
for my $group (@{$source_data->{"Hacking Program Groups"}}){
    $groups->{$group->{name}} = $group->{programs};
}

my $burst = {};
for my $program (@{$source_data->{"Hacking Programs"}}){
    $burst->{$program->{name}} = $program->{burst};
}

open $file, '>', 'hacking_data.js' or die "Unable to open file";
print $file 'var hacking_devices = ';
print $file $json->encode($devices);
print $file 'var hacking_groups = ';
print $file $json->encode($groups);
print $file 'var hacking_burst = ';
print $file $json->encode($burst);
print $file 'var hacking_implemented = ';
print $file $json->encode($hacking_implemented);
