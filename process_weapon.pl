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

open IN, '<', 'dual_weapons.dat' or die "Unable to open file";
$json_text = <IN>;
my $dual_weapons = $json->decode($json_text);

open IN, '<', 'dual_ccw.dat' or die "Unable to open file";
$json_text = <IN>;
my $dual_ccw = $json->decode($json_text);

open IN, '<', 'poison_ccw.dat' or die "Unable to open file";
$json_text = <IN>;
my $poison_ccw = $json->decode($json_text);

my $all_ammo = {};
my $weapon_data = {};
my $file;
for my $fname (glob "mayanet_data/Toolbox/weapons.json"){
    my $json_text;
    open $file, '<', $fname or die "Unable to open file";
    $json_text = <$file>;
    my $source_data = $json->decode($json_text);

    WEAPON: for my $weapon (@$source_data){
        # Skip unimplemented weapons or other equipment
        if($weapon->{name} =~ m/Koala|Charges|Discover|Electric Pulse|Hedgehog|Observer|Jammer|Sepsitor/){
            next;
        }

        # deploy weapons have a dodge penalty
        if($weapon->{name} =~ m/Mine|Mauler/){
            $weapon->{deploy} = 1;
        }else{
            $weapon->{deploy} = 0;
        }

        # Multiple ammo types and burst reduction
        my $multi = 0;
        if($weapon->{name} =~ m/MULTI/){
            $multi = 1;
        }

        my $template = 0;
        if($weapon->{template} ne "No"){
            $template = 1;
        }

        my @ammo;
        if($multi){
            @ammo = split /\//, $weapon->{ammo};
        }else{
            @ammo = $weapon->{ammo};
        }

        # Remap ammo names
        my $ammo_maps = {
            N => 'Normal',
            PLASMA => 'Plasma',
            FIRE => 'Fire',
        };
        @ammo = map {exists($ammo_maps->{$_}) ? $ammo_maps->{$_} : $_} @ammo;

        my $new_weapon = {};

        $new_weapon->{name} = $weapon->{name};
        if($weapon->{mode}){
            $new_weapon->{display_name} = $weapon->{name} . " " . $weapon->{mode};
        }else{
            $new_weapon->{display_name} = $weapon->{name};
        }

        # alternate profiles for alternate-fire weapons
        $new_weapon->{alt_profile} = $weapon->{alt_profile};

        my (@b, @t);
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

            push @b, $b;

            push @t, $template;
        }

        $new_weapon->{ammo} = \@ammo;
        $new_weapon->{b} = \@b;
        $new_weapon->{template} = \@t;

        $new_weapon->{dam} = $weapon->{damage};

        $new_weapon->{att_guided} = ($weapon->{note} =~ m/Guided/) ? 1 : 0;
        $new_weapon->{att_cc} = $weapon->{cc} eq 'Yes' ? 1 : 0;
        $new_weapon->{att_dtw} = $weapon->{cc} eq 'No' && !$weapon->{deploy} && !$weapon->{att_guided} && $weapon->{short_dist} eq '--' ? 1 : 0;
        $new_weapon->{att_deploy} = $weapon->{deploy};
        $new_weapon->{att_supp} = ($weapon->{suppressive} // "") eq 'Yes' ? 1 : 0;;

        if($weapon->{name} eq 'Marker' || $weapon->{name} =~ m/Grenade|GL/){
            $new_weapon->{att_spec} = 1;
        }

        if($weapon->{short_dist} ne '--'){
            $new_weapon->{att_bs} = 1;
            $new_weapon->{stat} = uc($weapon->{attr} // 'BS');

            my @brackets = ('short', 'medium', 'long', 'max');
            my @ranges;

            my $low = 0;
            for my $bracket (@brackets){
                my $high = $weapon->{$bracket . '_dist'};
                my $mod = $weapon->{$bracket . '_mod'};

                if($high eq '--'){
                    last;
                }

                if($mod > 0){
                    $mod = '+' . $mod;
                }

                push @ranges, "$low-$high/$mod";
                $low = $high;
            }

            $new_weapon->{ranges} = [@ranges];
        }

        $weapon_data->{$new_weapon->{name}} = $new_weapon;
    }
}

# Increase burst for dual weapons
for my $name (keys %$dual_weapons){
    next if $name eq 'CrazyKoala';

    my $base_name = $name;
    my $dual_name = $name . " (2)";

    while($name){
        warn "Dualizing $name\n";

        my $new_weapon = clone($weapon_data->{$name});

        for(my $i = 0; $i < @{$new_weapon->{b}}; $i++){
            $new_weapon->{b}[$i]++;
        }
        $new_weapon->{name} =~ s/$base_name/$dual_name/;
        $new_weapon->{display_name} =~ s/$base_name/$dual_name/;

        $weapon_data->{$new_weapon->{name}} = $new_weapon;

        if($new_weapon->{alt_profile}){
            $name = $new_weapon->{alt_profile};
            $new_weapon->{alt_profile} =~ s/$base_name/$dual_name/;
        }else{
            $name = undef;
        }
    }
}

for my $weapon (@$dual_ccw){
    $weapon =~ m/([\w\/]+) CCW \+ ([\w\/]+) CCW/;
    my @ammo = ($1, $2);
    my $ammo = join('+', @ammo);

    $all_ammo->{$ammo} = 1;

    my $new_weapon = {
        ammo => [$ammo],
        att_cc => 1,
        b => [1],
        dam => 'PH',
        name => $weapon,
        display_name => $weapon,
        template => [0],
    };

    $weapon_data->{$new_weapon->{name}} = $new_weapon;
}

for my $weapon (@$poison_ccw){
    $weapon =~ m/Poison ([\w\/]+)? ?CCW/;
    my $ammo = $1;
    if($ammo){
        $ammo .= "+Shock";
    }else{
        $ammo = "Shock";
    }

    $all_ammo->{$ammo} = 1;

    my $new_weapon = {
        ammo => [$ammo],
        att_cc => 1,
        b => [1],
        dam => 'PH',
        name => $weapon,
        template => [0],
    };

    $weapon_data->{$new_weapon->{name}} = $new_weapon;
}

# new ammo types
$all_ammo->{Breaker} = 1;
$all_ammo->{DT} = 1;

open $file, '>', 'weapon_data.js' or die "Unable to open file";
print $file 'var weapon_data = ';
print $file $json->encode($weapon_data);
print $file 'var ammos = ';
print $file $json->encode([sort keys %$all_ammo]);
