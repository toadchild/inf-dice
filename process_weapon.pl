#!/usr/bin/perl

use strict;
use warnings;

use JSON::PP;
use Data::Dumper;

my $json = JSON::PP->new;
$json->pretty(1);
$json->canonical(1);

my $all_ammo = {};
my $weapon_data = {};
my $file;
for my $fname (glob "ia-data/ia-data_*_weapons_data.json"){
    local $/;
    my $json_text;
    open $file, '<', $fname or die "Unable to open file";
    $json_text = <$file>;
    my $source_data = $json->decode($json_text);

    WEAPON: for my $weapon (@$source_data){
        # Skip unimplemented weapons or other equipment
        if($weapon->{name} =~ m/Mines|Koala|Charges|Discover|Mauler|Pulse|Hedgehog|Observer|Jammer|Marker|Sepsitor/){
            next;
        }

        # Fix weapon
        if($weapon->{name} eq 'Templar CCW'){
            $weapon->{ammo} = 'AP+Shock';
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
        @ammo = map {$_ eq 'N' ? 'Normal' : $_} @ammo;
        @ammo = map {$_ eq 'FIRE' ? 'Fire' : $_} @ammo;

        # integrated ammo
        if($multi){
            push @ammo, "AP+$ammo[$#ammo]";
        }

        my $new_weapon = {};

        $new_weapon->{name} = $weapon->{name};

        my @b;
        for my $ammo (@ammo){
            # skip unimplemented ammo
            if($ammo =~ m/PLASMA|Adhesive|N\+E\/M|Stun/){
                next WEAPON;
            }

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
        if($weapon->{name} =~ m/Grenade/){
            $new_weapon->{att_throw} = 1;
        }else{
            $new_weapon->{att_throw} = 0;
        }
        $new_weapon->{att_bs} = $weapon->{short_dist} ne '--' && !$new_weapon->{att_throw} ? 1 : 0;

        $weapon_data->{$new_weapon->{name}} = $new_weapon;
    }
}

open $file, '>', 'weapon_data.js' or die "Unable to open file";
print $file 'var weapon_data = ';
print $file $json->encode($weapon_data);
print $file 'var ammos = ';
print $file $json->encode([sort keys %$all_ammo]);
