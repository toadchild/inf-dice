#!/usr/bin/perl

use strict;
use warnings;

use JSON::PP;
use Clone qw(clone);
use Data::Dumper;

my $json = JSON::PP->new;
# pretty print output
$json->pretty(1);
# output fields in sorted order (minimizes diffs between runs)
$json->canonical(1);
# relaxed corectness checking of input
$json->relaxed(1);

my %default_wtype = (
    LI => 'W',
    MI => 'W',
    HI => 'W',
    WB => 'W',
    SK => 'W',
    REM => 'STR',
    TAG => 'STR',
);

# Profiles to skip; used where all we want are the sub-profiles
my $skip_base_profile_list = {
    "Uxìa McNeill" => 1,
    "Teucer" => 1,
    "Kazak Spetsnazs" => 1,
    "Patroclus" => 1,
};

# Units that need to be totally skipped in their entirety
my $skip_unit_list = {
    4023 => 1,  # Kasym Beg Lieutenant
    9018 => 1,  # ABH
    9003 => 1,  # Druze (generic merc)
    9034 => 1,  # Bashi (non-specialist)
    9037 => 1,  # Saito (non-specialist)
};

my $alternate_names = {
};

my @specialist_profiles = (
    {
        key => 'msv',
        ability_func => \&has_msv,
        name_func => \&name_msv,
    },
    {
        key => 'ad',
        ability_func => \&has_ad,
        name_func => \&name_ad,
    },
    {
        key => 'ch',
        ability_func => \&has_camo,
        name_func => \&name_camo,
    },
    {
        key => 'odd',
        ability_func => \&has_odd,
        name_func => \&name_odd,
    },
    {
        key => 'xvisor',
        ability_func => \&has_xvisor,
        name_func => \&name_xvisor,
    },
    {
        key => 'ma',
        ability_func => \&has_ma,
        name_func => \&name_ma,
    },
    {
        key => 'nbw',
        ability_func => \&has_nbw,
        name_func => \&name_nbw,
    },
    {
        key => 'sapper',
        ability_func => \&has_sapper,
        name_func => \&name_sapper,
    },
    {
        key => 'marksmanship',
        ability_func => \&has_marksmanship,
        name_func => \&name_marksmanship,
    },
);

sub name_msv{
    my ($msv) = @_;
    return " (MSV $msv)";
}

my $camo_names = {
    1 => 'Mimetism',
    2 => 'Camo',
    3 => 'TO Camo',
};

sub name_camo{
    my ($ch) = @_;
    return " ($camo_names->{$ch})";
}

sub name_odd{
    my ($ch) = @_;
    return " (ODD)";
}

sub name_xvisor{
    return " (X Visor)";
}

sub name_ma{
    my ($ma) = @_;
    return " (MA $ma)";
}

sub name_nbw{
    return " (Natural Born Warrior)";
}

sub name_sapper{
    return " (Sapper)";
}

sub name_marksmanship{
    my ($marks) = @_;
    return " (Marksmanship $marks)";
}

my $ad_names = {
    1 => 'Parachutist',
    2 => 'Airborne Infiltration',
    3 => 'Inferior Combat Jump',
    4 => 'Combat Jump',
    5 => 'Superior Combat Jump',
};

sub name_ad{
    my ($ad) = @_;
    return " ($ad_names->{$ad})";
}

sub has_spec{
    my ($unit, $name) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/$name/){
            return 1;
        }
    }
    return 0;
}

sub has_aibeacon{
    return has_spec(@_, 'AI Beacon');
}

sub has_seedembryo{
    return has_spec(@_, 'Seed-Embryo');
}

sub has_dualwield{
    return has_spec(@_, 'Dual Wield');
}

sub has_poison{
    return has_spec(@_, 'Poison');
}

sub has_symbiont{
    my ($unit, $inactive) = @_;
    if($inactive){
        return 1;
    }
    if(has_spec($unit, 'Symbiont Armor')){
        return 2;
    }
    return 0;
}

sub has_nwi{
    return has_spec(@_, 'No Wound Incapacitation');
}

sub has_shasvastii{
    return has_spec(@_, 'Shasvastii');
}

sub has_ikohl{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        # i-Kohl L3
        if($spec =~ m/I-Kohl.*(\d+)/){
            return -3 * $1;
        }
    }
    return 0;
}

sub has_hyperdynamics{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        # Hyper-Dynamics L1
        if($spec =~ m/Hyper-Dynamics.*(\d+)/){
            return 3 * $1;
        }
    }
    return 0;
}

sub has_immunity{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Total Immunity/){
            return 'total';
        }elsif($spec =~ m/Bioimmunity/){
            return 'bio';
        }elsif($spec =~ m/Shock Immunity/){
            return 'shock';
        }elsif($spec =~ m/Regeneration/){
            return 'shock';
        }
    }

    return '';
}

sub has_camo{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/CH: Mimetism/){
            return 1;
        }elsif($spec =~ m/CH: Camo/){
            return 2;
        }elsif($spec =~ m/CH: Ambush Camo/){
            return 2;
        }elsif($spec =~ m/CH: TO Camo/){
            return 3;
        }
    }

    return 0;
}

sub has_odd{
    return has_spec(@_, 'ODD:');
}

sub has_msv{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Multispectral.*(\d)/){
            return $1;
        }
    }

    return 0;
}

sub has_xvisor{
    return has_spec(@_, 'X Visor');
}

sub has_fo{
    return has_spec(@_, 'Forward Observer');
}

sub has_hacker{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Hacking Device/){
            return $spec;
        }
    }

    return 0;
}

sub has_motorcycle{
    return has_spec(@_, "Motorcycle");
}

sub has_pilot{
    return has_spec(@_, "Pilot");
}

sub has_operator{
    return has_spec(@_, "Operator");
}

sub has_ma{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Martial.*(\d)/){
            return $1;
        }
    }

    return 0;
}

sub has_guard{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Guard.*(\d)/){
            return $1;
        }
    }

    return 0;
}

sub has_protheion{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Protheion.*(\d)/){
            return $1;
        }
    }

    return 0;
}

sub has_nbw{
    return has_spec(@_, 'Natural Born Warrior');
}

sub has_berserk{
    return has_spec(@_, 'Berserk');
}

sub has_marksmanship{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Marksmanship.*(\d)/){
            return $1;
        }
    }

    return 0;
}

sub has_sapper{
    return has_spec(@_, 'Sapper');
}

sub has_transmutation{
    return has_spec(@_, '^Transmutation');
}

sub has_g_sync{
    return has_spec(@_, '^G: Sync');
}

sub has_g_servant{
    return has_spec(@_, '^G: Servant');
}

sub has_ad{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Parachutist/){
            return 1;
        }elsif($spec =~ m/Airborne Infiltration/){
            return 2;
        }elsif($spec =~ m/Inferior Combat Jump/){
            return 3;
        }elsif($spec =~ m/Superior Combat Jump/){
            return 5;
        }elsif($spec =~ m/Combat Jump/){
            return 4;
        }
    }

    return 0;
}

sub has_fatality{
    my ($unit) = @_;

    if ($unit->{type} eq 'TAG') {
        return 1;
    }

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Fatality.*(\d)/){
            return $1;
        }
    }

    return 0;
}

sub has_full_auto{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Full Auto.*(\d)/){
            return $1;
        }
    }

    return 0;
}

sub has_remote_presence{
    return has_spec(@_, 'G: Remote Presence') || has_spec(@_, 'G: Autotool') || has_spec(@_, 'G: Jumper L1');
}

my $dual_weapons = {};
my $dual_ccw = {};
my $poison_ccw = {};
sub get_weapons{
    my ($unit, $new_unit, $inherit_weapon, $rider, $ability_func) = @_;
    my $weapons = {};
    my $hackers = {};

    for my $w (@{$unit->{bsw}}){
        $weapons->{$w} = 1;
    }

    for my $w (@{$unit->{ccw}}){
        $weapons->{$w} = 1;
    }

    # All forward observers have Flash Pulse inclusive
    if(has_fo($unit)){
        $weapons->{'Flash Pulse'} = 1;
        $weapons->{'Forward Observer'} = 1;
    }

    if(has_protheion($unit)){
        $weapons->{'Protheion'} = 1;
    }

    if(has_hacker($unit)){
        $hackers->{has_hacker($unit)} = 1;
    }

    if($inherit_weapon){
        CHILD: for my $child (@{$unit->{childs}}){
            # Keep specialists out of normal circulation
            if(!$ability_func){
                for my $specialist (@specialist_profiles){
                    if($specialist->{ability_func}($child)){
                        next CHILD;
                    }
                }
            }

            # select only the special children otherwise
            if($ability_func && !&$ability_func($child)){
                next;
            }

            # only read in each child once
            if($child->{_processed}){
                next;
            }
            $child->{_processed} = 1;

            # All forward observers have Flash Pulse inclusive
            if(has_fo($child)){
                $weapons->{'Flash Pulse'} = 1;
                $weapons->{'Forward Observer'} = 1;
            }

            for my $w (@{$child->{bsw}}){
                $weapons->{$w} = 1;
            }

            for my $w (@{$child->{ccw}}){
                $weapons->{$w} = 1;
            }

            if(has_hacker($child)){
                $hackers->{has_hacker($child)} = 1;
            }
        }
    }

    # Make a list of dual weapons used
    for my $w (keys %$weapons){
        if($w =~ m/(.*) \(2\)/){
            $dual_weapons->{$1} = 1;
        }
    }

    # If they have Dual Wield, add a combined CCW
    if(has_dualwield($new_unit)){
        my @ccws;
        for my $w (keys %$weapons){
            if($w =~ m/ CCW/){
                push @ccws, $w;
            }
        }
        my $new_ccw = join(' + ', sort(@ccws));
        $dual_ccw->{$new_ccw} = 1;
        $weapons->{$new_ccw} = 1;
    }

    if(!has_aibeacon($new_unit) && !has_seedembryo($new_unit)){
        $weapons->{'Bare-Handed'} = 1;
    }

    $new_unit->{weapons} = [sort keys %$weapons];
    $new_unit->{hacker} = [sort keys %$hackers];
}

my %unit_type_order = (
    LI => 1,
    MI => 2,
    HI => 3,
    SK => 4,
    WB => 5,
    TAG => 6,
    REM => 7,
    "N/A" => 8,         # AI Beacons
);

sub unit_sort{
    # first sort by unit type
    if($a->{type} ne $b->{type}){
        if(!defined $unit_type_order{$a->{type}}){
            die "Unknown type '$a->{type}' in unit $a->{name}";
        }
        if(!defined $unit_type_order{$b->{type}}){
            die "Unknown type '$b->{type}' in unit $b->{name}";
        }
        return $unit_type_order{$a->{type}} <=> $unit_type_order{$b->{type}};
    }
    # then by name
    return $a->{name} cmp $b->{name};
}

sub parse_unit{
    my ($new_unit, $unit, $ability_func) = @_;

    # Seed Embryos do not inherit their parent profile's weapons
    my ($inherit_weapon, $inherit_shasvastii) = (1, 0);
    if($new_unit->{shasvastii}){
        $inherit_weapon = 0;
        $inherit_shasvastii = 1;
    }

    my $rider = 0;
    if(has_motorcycle($new_unit)){
        $rider = 1;
    }

    # If the parent has symbiont, this unit has inactive symbiont
    my $symbiont_inactive = 0;
    if(has_symbiont($new_unit)){
        $symbiont_inactive = 1;
    }

    # Stats
    $new_unit->{name} = $unit->{name};
    $new_unit->{bs} = int($unit->{bs}) if defined $unit->{bs};
    $new_unit->{ph} = int($unit->{ph}) if defined $unit->{ph};
    $new_unit->{cc} = int($unit->{cc}) if defined $unit->{cc};
    $new_unit->{wip} = int($unit->{wip}) if defined $unit->{wip};
    $new_unit->{arm} = int($unit->{arm}) if defined $unit->{arm};
    $new_unit->{bts} = int($unit->{bts}) if defined $unit->{bts};
    $new_unit->{w} = int($unit->{w}) if defined $unit->{w};
    $new_unit->{type} = $unit->{type} if defined $unit->{type} && $unit->{type} ne ' ';
    $new_unit->{w_type} = uc($unit->{wtype} // $default_wtype{$new_unit->{type}});
    $new_unit->{spec} = $unit->{spec} if defined $unit->{spec};

    # Modifiers
    if(!$rider){
        $new_unit->{motorcycle} = 1 if has_motorcycle($new_unit);
    }else{
        delete $new_unit->{motorcycle};
    }

    $new_unit->{nwi} = 1 if has_nwi($new_unit);
    $new_unit->{shasvastii} = 1 if has_shasvastii($new_unit) || $inherit_shasvastii;
    $new_unit->{nbw} = 1 if has_nbw($new_unit);
    $new_unit->{berserk} = 1 if has_berserk($new_unit);
    $new_unit->{sapper} = 1 if has_sapper($new_unit);
    $new_unit->{xvisor} = 1 if has_xvisor($new_unit);
    $new_unit->{odd} = 1 if has_odd($new_unit);

    $new_unit->{dependent} = 1 if has_g_sync($new_unit) || has_g_servant($new_unit);

    # leveled skills
    my $v;
    if($v = has_ikohl($new_unit)){
        $new_unit->{ikohl} = $v;
    }
    if($v = has_immunity($new_unit)){
        $new_unit->{immunity} = $v;
    }
    if($v = has_hyperdynamics($new_unit)){
        $new_unit->{hyperdynamics} = $v;
    }
    if($v = has_camo($new_unit)){
        $new_unit->{ch} = $v;
    }
    if($v = has_msv($new_unit)){
        $new_unit->{msv} = $v;
    }
    if($v = has_ma($new_unit)){
        $new_unit->{ma} = $v;
    }
    if($v = has_guard($new_unit)){
        $new_unit->{guard} = $v;
    }
    if($v = has_protheion($new_unit)){
        $new_unit->{protheion} = $v;
    }
    if($v = has_fatality($new_unit)){
        $new_unit->{fatality} = $v;
    }
    if($v = has_full_auto($new_unit)){
        $new_unit->{full_auto} = $v;
    }
    if($v = has_marksmanship($new_unit)){
        $new_unit->{marksmanship} = $v;
    }
    if($v = has_symbiont($new_unit, $symbiont_inactive)){
        $new_unit->{symbiont} = $v;
    }
    if($v = has_ad($new_unit)){
        $new_unit->{ad} = $v;
    }
    if($v = has_remote_presence($new_unit)){
        $new_unit->{remote_presence} = $v;
    }

    # get_weapons goes into the childs list
    get_weapons($unit, $new_unit, $inherit_weapon, $rider, $ability_func);
}

sub flatten_unit{
    my ($unit, $i) = @_;

    if(!exists $unit->{profiles}){
        $unit->{profiles} = [];
        return $unit;
    }

    my $flat_unit = clone($unit);
    my $profile = $flat_unit->{profiles}->[$i // 0];

    while(my ($key, $value) = each %$profile){
        if(ref($value) eq 'ARRAY'){
            push @{$flat_unit->{$key}}, @$value;
        }else{
            $flat_unit->{$key} = $value;
        }
    }

    # Mark that this profile does not inherit from base.
    if ($flat_unit->{independent} || has_pilot($flat_unit) || has_g_sync($flat_unit) || has_g_servant($flat_unit) || has_operator($flat_unit)) {
        $flat_unit->{no_inherit} = 1;
    }

    return $flat_unit;
}

my $unit_data = {};
my $file;
my $json_text;

for my $fname (glob("unit_data/*_units.json")){
    next if $fname eq "unit_data/other_units.json";

    local $/;
    open $file, '<', $fname or die "Unable to open file";
    $json_text = <$file>;
    my $source_data = $json->decode($json_text);

    for my $unit (@$source_data){
        # Skip anything marked as oboslete
        if ($unit->{obsolete}) {
            next;
        }

        # Skip these units
        if ($skip_unit_list->{$unit->{id}}) {
            next;
        }

        # handle multi-profile units
        my $flat_unit = flatten_unit($unit);

        # Skip Spec-Ops
        if($flat_unit->{bs} eq 'X'){
            next;
        }

        # Use the longer ISC names
        $flat_unit->{name} = $flat_unit->{isc};

        # Only keep one kind of Caliban
        if($flat_unit->{name} eq 'Shasvastii Caliban (Seed-Embryo)'){
            $flat_unit->{name} = 'Caliban';
        }elsif($flat_unit->{name} =~ m/Caliban/){
            next;
        }elsif($flat_unit->{name} =~ m/^Tikbalangs/){
            $flat_unit->{name} = 'Tikbalangs';
        }elsif($flat_unit->{name} eq 'Bit & Kiss!') {
            $flat_unit->{name} = 'Bit';
        }
        $flat_unit->{name} =~ s/^Shasvastii //;
        $flat_unit->{name} =~ s/^Hassassin //;
        $flat_unit->{name} =~ s/^The //;

        my $new_unit = {};
        parse_unit($new_unit, $flat_unit);

        if($unit->{army} eq "Military Orders"){
            next;
        }

        if(!exists $unit_data->{$unit->{army}}){
            $unit_data->{$unit->{army}} = [];
        }

        if(!$skip_base_profile_list->{$new_unit->{name}}){
            push @{$unit_data->{$unit->{army}}}, $new_unit;
        }


        # Check for child units with special skills we care about
        for my $specialist (@specialist_profiles){
            my $ability = $new_unit->{$specialist->{key}};

            for my $child (@{$unit->{childs}}){
                next if $child->{_processed};
                if(!$ability && ($ability = $specialist->{ability_func}($child))){
                    my $child_unit = clone($new_unit);

                    # It will get hacker again if it picks up a child profile with a hacking device
                    delete $child_unit->{hacker};

                    # stats replace if present, otherwise inherit
                    $child->{spec} = [@{$flat_unit->{spec}}, @{$child->{spec}}];
                    $child->{bsw} = [@{$flat_unit->{bsw}}, @{$child->{bsw}}];
                    $child->{ccw} = [@{$flat_unit->{ccw}}, @{$child->{ccw}}];
                    $child->{childs} = $flat_unit->{childs};
                    parse_unit($child_unit, $child, $specialist->{ability_func});

                    $child_unit->{name} = $new_unit->{name} . $specialist->{name_func}($ability);
                    if($alternate_names->{$child_unit->{name}}){
                        $child_unit->{name} = $alternate_names->{$child_unit->{name}};
                    }

                    push @{$unit_data->{$unit->{army}}}, $child_unit;
                }
            }
        }

        # Check for alternate profiles
        for(my $i = 1; $i < scalar @{$flat_unit->{profiles}}; $i++){
            my $alt = flatten_unit($unit, $i);

            next if $alt->{name} eq 'CrazyKoala';
            next if $alt->{name} eq 'MadTrap';
            next if $alt->{name} eq 'SymbioBug';

            my $alt_unit;
            if(!$alt->{no_inherit}){
                $alt_unit = clone($new_unit);
                # It will get hacker again if it picks up a child profile with a hacking device
                # Really need to clean this up...
                delete $alt_unit->{hacker};
                delete $alt_unit->{fatality};
            }else{
                # Independent models don't inherit from their controller
                $alt_unit = {};
                # Independent models don't inherit their controller's options
                delete $alt->{childs};
            }

            # stats replace if present, otherwise inherit
            parse_unit($alt_unit, $alt);

            if(!$alt->{independent}){
                $alt_unit->{name} = "$new_unit->{name} ($alt_unit->{name})";
            }elsif($alt_unit->{dependent}){
                $alt_unit->{name} = "$alt_unit->{name} ($new_unit->{name})";
            }

            # Tell the base unit how many wounds the Operator has
            if($alt->{name} eq 'Operator'){
                $new_unit->{operator} = $alt_unit->{w};
            }

            # Add transmutation wounds to base profile
            if(has_transmutation($new_unit)){
                $new_unit->{w} += $alt->{w} // 0;
            }

            # Don't put on duplicate units
            if($unit_data->{$unit->{army}}[-1]{name} ne $alt_unit->{name}){
                push @{$unit_data->{$unit->{army}}}, $alt_unit;
            }
        }
    }
}

for my $faction (keys %$unit_data){
    $unit_data->{$faction} = [sort unit_sort @{$unit_data->{$faction}}];
}

open $file, '>', 'unit_data.js' or die "Unable to open file";
print $file "var unit_data = ";
print $file $json->encode($unit_data);

open $file, '>', 'dual_weapons.dat' or die "Unable to open file";
print $file $json->encode($dual_weapons);

open $file, '>', 'dual_ccw.dat' or die "Unable to open file";
print $file $json->encode([keys %$dual_ccw]);

open $file, '>', 'poison_ccw.dat' or die "Unable to open file";
print $file $json->encode([keys %$poison_ccw]);
