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

my %default_wtype = (
    LI => 'W',
    MI => 'W',
    HI => 'W',
    WB => 'W',
    SK => 'W',
    REM => 'STR',
    TAG => 'STR',
);

my $skip_list = {
    "Uxìa McNeill" => 1,
    "Tohaa Diplomatic Delegates" => 1,
    "Rasyat Diplomatic Division" => 1,
    "Teucer" => 1,
};

my $alternate_names = {
    "Kazak Spetsnazs (Mimetism)" => "Kazak Spetsnazs (Parachutist)",
};

my @specialist_profiles = (
    {
        key => 'msv',
        ability_func => \&has_msv,
        name_func => \&name_msv,
    },
    {
        key => 'ch',
        ability_func => \&has_camo,
        name_func => \&name_camo,
    },
    {
        key => 'xvisor',
        ability_func => \&has_xvisor,
        name_func => \&name_xvisor,
    },
    {
        key => 'specialist',
        ability_func => \&has_specialist,
        name_func => \&name_specialist,
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

sub name_xvisor{
    return " (X Visor)";
}

sub name_specialist{
    return " (Specialist)";
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
    if(has_spec($unit, 'Symbiont Armour')){
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
        if($spec =~ m/i-K[oh][oh]l.*(\d+)/){
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
        }elsif($spec =~ m/CH: TO Camo/){
            return 3;
        }
    }

    return 0;
}

sub has_odd{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/ODD:/){
            return 1;
        }elsif($spec =~ m/ODF:/){
            return 2;
        }
    }

    return 0;
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
    if(has_spec(@_, 'X Visor')){
        return 1;
    }
    if(has_spec(@_, 'X-2 Visor')){
        return 2;
    }
    return 0;
}

sub has_fo{
    return has_spec(@_, 'Forward Observer');
}

sub has_hacker{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec eq 'Defensive Hacking Device'){
            return 1;
        }
        if($spec eq 'Hacking Device'){
            return 2;
        }
        if($spec eq 'Hacking Device Plus'){
            return 3;
        }
        if($spec eq 'Assault Hacking Device'){
            return 4;
        }
        if($spec eq 'EI Assault Hacking Device'){
            return 5;
        }
        if($spec eq 'EI Hacking Device'){
            return 6;
        }
        if($spec eq 'Hacking Device: UPGRADE: Stop!'){
            return 7;
        }
    }

    return 0;
}

sub has_motorcycle{
    return has_spec(@_, "Motorcycle");
}

sub has_specialist{
    return has_spec(@_, "Specialist");
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

my $dual_weapons = {};
my $dual_ccw = {};
my $poison_ccw = {};
sub get_weapons{
    my ($unit, $new_unit, $inherit_weapon, $rider, $ability_func) = @_;
    my $weapons = {};

    for my $w (@{$unit->{bsw}}){
        $weapons->{$w} = 1;
    }

    # Kum don't keep their Smoke LGLs when dismounted
    if($rider){
        for my $w (@{$new_unit->{weapons}}){
            $weapons->{$w} = 1 unless $w eq 'Smoke Light Grenade Launcher';
        }
    }

    for my $w (@{$unit->{ccw}}){
        $weapons->{$w} = 1;
    }

    if(!$inherit_weapon){
        $new_unit->{hacker} = 0;
    }
    
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

        # All forward observers and HD+ have Flash Pulse inclusive
        if(has_fo($child)){
            $weapons->{'Flash Pulse'} = 1;
        }

        for my $w (@{$child->{bsw}}){
            $weapons->{$w} = 1;
        }

        for my $w (@{$child->{ccw}}){
            $weapons->{$w} = 1;
        }

        if(has_hacker($child)){
            $new_unit->{hacker} = has_hacker($child);
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

    if(keys %$weapons){
        if(!has_aibeacon($new_unit) && $inherit_weapon){
            $weapons->{'Bare-Handed'} = 1;
        }

        $new_unit->{weapons} = [sort keys %$weapons];
    }elsif(!$inherit_weapon){
        $new_unit->{weapons} = [];
    }
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

    if($ability_func){
        $inherit_weapon = 0;
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
    if($v = has_odd($new_unit)){
        $new_unit->{odd} = $v;
    }
    if($v = has_msv($new_unit)){
        $new_unit->{msv} = $v;
    }
    if($v = has_hacker($new_unit) || $new_unit->{hacker}){
        $new_unit->{hacker} = $v;
    }
    if($v = has_ma($new_unit)){
        $new_unit->{ma} = $v;
    }
    if($v = has_marksmanship($new_unit)){
        $new_unit->{marksmanship} = $v;
    }
    if($v = has_symbiont($new_unit, $symbiont_inactive)){
        $new_unit->{symbiont} = $v;
    }
    if($v = has_xvisor($new_unit)){
        $new_unit->{xvisor} = $v;
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

    return $flat_unit;
}

my $unit_data = {};
my $file;
my $json_text;

for my $fname (glob("mayanet_data/Toolbox/*_units.json"), glob("mayanet_data/Toolbox/add_*.json")){
    next if $fname eq "mayanet_data/Toolbox/other_units.json";

    warn "Parsing $fname\n";
    local $/;
    open $file, '<', $fname or die "Unable to open file";
    $json_text = <$file>;
    my $source_data = $json->decode($json_text);

    for my $unit (@$source_data){
        warn "    Processing $unit->{isc}\n";

        # handle multi-profile units
        my $flat_unit = flatten_unit($unit);

        # Skip Spec-Ops
        if($flat_unit->{bs} eq 'X'){
            next;
        }

        # Use the longer ISC names
        $flat_unit->{short_name} = $flat_unit->{name};
        $flat_unit->{name} = $flat_unit->{isc};

        # Patch some flat_unit names

        # Only keep one kind of Caliban
        if($flat_unit->{name} eq 'Shasvastii Caliban (Seed-Embryo)'){
            $flat_unit->{name} = 'Caliban';
        }elsif($flat_unit->{name} =~ m/Caliban/){
            next;
        }elsif($flat_unit->{name} eq '"The Shrouded"'){
            $flat_unit->{name} = 'Shrouded';
        }elsif($flat_unit->{name} =~ m/^Tikbalangs/){
            $flat_unit->{name} = 'Tikbalangs';
        }elsif($flat_unit->{name} eq 'Kasym Beg (Lieutenant)'){
            next;
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

        if(!$skip_list->{$new_unit->{name}}){
            push @{$unit_data->{$unit->{army}}}, $new_unit;
        }

        # Check for child units with special skills we care about
        for my $specialist (@specialist_profiles){
            my $ability = $new_unit->{$specialist->{key}};

            for my $child (@{$unit->{childs}}){
                next if $child->{_processed};
                if(!$ability && ($ability = $specialist->{ability_func}($child))){
                    my $child_unit = clone($new_unit);

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
            delete $alt->{childs};

            next if $alt->{name} eq 'CrazyKoala';

            if($alt->{name} eq 'Antipode (3)'){
                $alt->{name} = 'Antipode';
            }

            warn "        Processing $alt->{name}\n";

            my $alt_unit;
            if(!$alt->{independent}){
                $alt_unit = clone($new_unit);
            }else{
                # Independent models don't inherit from their controller
                $alt_unit = {};
            }

            # stats replace if present, otherwise inherit
            parse_unit($alt_unit, $alt);

            if(!$alt->{independent}){
                my $alt_tag = $alt->{name};
                if($alt_tag !~ m/\(/){
                    $alt_tag = "($alt_tag)";
                }
                $alt_unit->{name} = "$new_unit->{name} $alt_tag";
            }

            # Tell the base unit how many wounds the Operator has
            if($alt->{name} eq 'Operator'){
                $new_unit->{operator} = $alt_unit->{w};
            }

            # Add transmutation wounds to base profile
            if(has_transmutation($new_unit)){
                $new_unit->{w} += $alt->{w} // 0;
            }

            push @{$unit_data->{$unit->{army}}}, $alt_unit;
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
print $file $json->encode([keys $dual_ccw]);

open $file, '>', 'poison_ccw.dat' or die "Unable to open file";
print $file $json->encode([keys $poison_ccw]);
