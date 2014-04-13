#!/usr/bin/perl

use strict;
use warnings;

use JSON::PP;
use Clone qw(clone);

my $json = JSON::PP->new;
$json->pretty(1);
$json->canonical(1);
local $/;
my $json_text;

open IN, '<', 'dual_weapons.dat' or die "Unable to open file";
$json_text = <IN>;
my $dual_weapons = $json->decode($json_text);

open IN, '<', 'dual_ccw.dat' or die "Unable to open file";
$json_text = <IN>;
my $dual_ccw = $json->decode($json_text);

my $all_ammo = {};
my $weapon_data = {};
my $file;
for my $fname (glob "ia-data/ia-data_*_weapons_data.json"){
    my $json_text;
    open $file, '<', $fname or die "Unable to open file";
    $json_text = <$file>;
    my $source_data = $json->decode($json_text);

    WEAPON: for my $weapon (@$source_data){
        # Skip unimplemented weapons or other equipment
        if($weapon->{name} =~ m/Mines|Koala|Charges|Discover|Mauler|Electric Pulse|Hedgehog|Observer|Jammer|Marker|Sepsitor/){
            next;
        }

        # Fix name of Fist attack
        if($weapon->{name} eq 'TAG Fist'){
            $weapon->{name} = 'Fist';
        }

        # Multiple ammo types and burst reduction
        my $multi = 0;
        if($weapon->{name} =~ m/MULTI/){
            $multi = 1;
        }

        my $shotgun = 0;
        if($weapon->{name} =~ m/Shotgun/ && $weapon->{name} !~ m/Light/){
            $shotgun = 1;
        }

        my @ammo;
        if($multi || $shotgun){
            @ammo = split /\//, $weapon->{ammo};
        }else{
            @ammo = $weapon->{ammo};
        }

        # Remap ammo names
        my $ammo_maps = {
            N => 'Normal',
            PLASMA => 'Plasma',
        };
        @ammo = map {exists($ammo_maps->{$_}) ? $ammo_maps->{$_} : $_} @ammo;

        # integrated ammo
        if($multi){
            push @ammo, "AP+$ammo[$#ammo]";
        }

        my $new_weapon = {};

        $new_weapon->{name} = $weapon->{name};

        my @b;
        for my $ammo (@ammo){
            # sanity check ammo types
            $all_ammo->{$ammo} = 1;

            my $b;

            if($weapon->{burst} eq '--'){
                $b = 1;
            }else{
                $weapon->{burst} =~ m/^(\d)/;
                $b = int($1);
            }

            if($multi){
                if($ammo =~ m/\+/){
                    $b = 1;
                }elsif($ammo ne 'Normal'){
                    $b = 2;
                }
            }

            push @b, $b;
        }

        $new_weapon->{ammo} = \@ammo;
        $new_weapon->{b} = \@b;

        $new_weapon->{dam} = $weapon->{damage};

        $new_weapon->{att_cc} = $weapon->{cc} eq 'Yes' ? 1 : 0;
        $new_weapon->{att_dtw} = $weapon->{cc} eq 'No' && $weapon->{short_dist} eq '--' ? 1 : 0;

        if($weapon->{short_dist} ne '--'){
            $new_weapon->{att_bs} = 1;
            $new_weapon->{stat} = uc($weapon->{attr} // 'BS');
        }

        $weapon_data->{$new_weapon->{name}} = $new_weapon;

        # Increase burst for dual weapons
        if($dual_weapons->{$new_weapon->{name}}){
            $new_weapon = clone($new_weapon);

            for(my $i = 0; $i < @{$new_weapon->{b}}; $i++){
                $new_weapon->{b}[$i]++;
            }
            $new_weapon->{name} .= " (2)";

            $weapon_data->{$new_weapon->{name}} = $new_weapon;
        }
    }
}

for my $weapon (@$dual_ccw){
    $weapon =~ m/([\w\/]+) CCW \+ ([\w\/]+) CCW/;
    my @ammo = ($1, $2);
    my $ammo = join('+', @ammo);

    # E/M Ammo has a special name
    $ammo =~ s/E\/M/E\/M(12)/;

    $all_ammo->{$ammo} = 1;

    my $new_weapon = {
        ammo => [$ammo],
        att_cc => 1,
        b => [1],
        dam => 'PH',
        name => $weapon,
    };

    $weapon_data->{$new_weapon->{name}} = $new_weapon;
}

open $file, '>', 'weapon_data.js' or die "Unable to open file";
print $file 'var weapon_data = ';
print $file $json->encode($weapon_data);
print $file 'var ammos = ';
print $file $json->encode([sort keys %$all_ammo]);
