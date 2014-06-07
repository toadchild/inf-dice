#!/usr/bin/perl

use strict;
use warnings;

use JSON::PP;
use Clone qw(clone);

my $json = JSON::PP->new;
$json->pretty(1);
$json->canonical(1);

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

sub has_cc2w{
    return has_spec(@_, 'CC with 2 Weapons');
}

sub has_poison{
    return has_spec(@_, 'Poison');
}

sub has_symbiont{
    my ($unit, $inactive) = @_;
    if(has_spec($unit, 'Symbiont Armour')){
        if($inactive){
            return 1;
        }
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
        if($spec =~ m/i-Kohl.*(\d+)/){
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
    return has_spec(@_, 'X Visor');
}

sub has_fo{
    return has_spec(@_, 'Forward Observer');
}

sub has_hacker{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Hacking Device Plus/){
            return 3;
        }
        if($spec =~ m/Defensive Hacking Device/){
            return 1;
        }
        if($spec =~ m/Hacking Device/){
            return 2;
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

my $dual_weapons = {};
my $dual_ccw = {};
my $poison_ccw = {};
sub get_weapons{
    my ($unit, $new_unit, $inherit_weapon, $ability_func) = @_;
    my $weapons = {};

    for my $w (@{$unit->{bsw}}){
        $weapons->{$w} = 1;
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
        if(has_fo($child) || has_hacker($child) >= 3){
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

    # If they have CC with two weapons, add a combined CCW
    if(has_cc2w($new_unit)){
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

    # If they have Poison, their CCW gets Shock in addition to its other types
    if(has_poison($new_unit)){
        my @ccws;
        for my $w (keys %$weapons){
            if($w =~ m/CCW/){
                push @ccws, $w;
            }
        }
        for my $w (@ccws){
            delete $weapons->{$w};
            $poison_ccw->{"Poison $w"} = 1;
            $weapons->{"Poison $w"} = 1;
        }
    }

    if(keys %$weapons){
        if(!has_aibeacon($new_unit) && $inherit_weapon){
            # add a Fist if they have no Knife, Pistol, or CCW
            my $has_ccw = 0;
            for my $w (keys %$weapons){
                if($w eq 'Knife' || $w =~ m/CCW/ || $w =~ m/Pistol/){
                    $has_ccw = 1;
                }
            }
            if(!$has_ccw){
                $weapons->{Fist} = 1;
            }
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
);

sub unit_sort{
    # first sort by unit type
    if($a->{type} ne $b->{type}){
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
    $new_unit->{spec} = $unit->{spec} if defined $unit->{spec} && @{$unit->{spec}};

    # Modifiers
    $new_unit->{motorcycle} = 1 if !$rider && has_motorcycle($new_unit);
    $new_unit->{nwi} = 1 if has_nwi($new_unit);
    $new_unit->{symbiont} = 1 if has_symbiont($new_unit, $symbiont_inactive);
    $new_unit->{shasvastii} = 1 if has_shasvastii($new_unit) || $inherit_shasvastii;
    $new_unit->{xvisor} = 1 if has_xvisor($new_unit);
    $new_unit->{nbw} = 1 if has_nbw($new_unit);
    $new_unit->{berserk} = 1 if has_berserk($new_unit);

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

    # get_weapons goes into the childs list
    get_weapons($unit, $new_unit, $inherit_weapon, $ability_func);
}

my $unit_data = {};
my $file;
my $json_text;

# load fixed name data from the locale file
open $file, '<', 'ia-data/ia-lang_40_en.js' or die "Unable to open file";
my $found_names = 0;
while(<$file>){
    if($found_names){
        $json_text .= $_;

        if($_ =~ m/;/){
            last;
        }
    }

    if($_ =~ m/names/){
        $found_names = 1;
        $json_text = "{\n";
    }
}
$json_text =~ s/'/"/g;
$json_text =~ s/;//;
my $localized_data = $json->decode($json_text);

for my $fname (glob "ia-data/ia-data_*_units_data.json"){
    local $/;
    open $file, '<', $fname or die "Unable to open file";
    $json_text = "[\n";
    $json_text .= <$file>;
    $json_text .= "]";
    my $source_data = $json->decode($json_text);

    my @unit_list;
    my $faction;
    for my $unit (@$source_data){
        # Skip Spec-Ops
        if($unit->{bs} eq 'X'){
            next;
        }

        # Apply updates from localized data
        if(exists $localized_data->{isc}{$unit->{isc}}){
            $unit->{isc} = $localized_data->{isc}{$unit->{isc}};
        }

        if(exists $localized_data->{name}{$unit->{name}}){
            $unit->{name} = $localized_data->{name}{$unit->{name}};
        }

        # Use the longer ISC names
        $unit->{short_name} = $unit->{name};
        $unit->{name} = $unit->{isc};

        # Patch some unit names

        # Only keep one kind of Caliban
        if($unit->{short_name} eq 'Caliban E'){
            $unit->{name} = 'Caliban';
        }elsif($unit->{name} =~ m/Caliban/){
            next;
        }elsif($unit->{name} eq '"The Shrouded"'){
            $unit->{name} = 'Shrouded';
        }elsif($unit->{name} eq 'Assault Pack'){
            $unit->{name} = 'Assault Pack Controller';
        }elsif($unit->{name} eq 'Armoured Cavalry'){
            $unit->{name} = 'Squalo';
        }elsif($unit->{name} =~ m/^Tikbalangs/){
            $unit->{name} = 'Tikbalangs';
        }
        $unit->{name} =~ s/^Shasvastii //;
        $unit->{name} =~ s/^Hassassin //;
        $unit->{name} =~ s/^The //;

        if($unit->{name} =~ m/Chaksa/){
            $unit->{spec} = [grep($_ ne 'Poison', @{$unit->{spec}})];
        }

        my $new_unit = {};
        parse_unit($new_unit, $unit);

        if(defined($faction) && $faction ne $unit->{army}){
            die "Mismatched faction in $unit->name: $faction != $unit->army";
        }
        $faction = $unit->{army};

        if(!$skip_list->{$new_unit->{name}}){
            push @unit_list, $new_unit;
        }

        # Check for child units with special skills we care about
        for my $specialist (@specialist_profiles){
            my $ability = $new_unit->{$specialist->{key}};

            for my $child (@{$unit->{childs}}){
                next if $child->{_processed};
                if(!$ability && ($ability = $specialist->{ability_func}($child))){
                    my $child_unit = clone($new_unit);

                    # stats replace if present, otherwise inherit
                    $child->{spec} = [@{$unit->{spec}}, @{$child->{spec}}];
                    $child->{bsw} = [@{$unit->{bsw}}, @{$child->{bsw}}];
                    $child->{ccw} = [@{$unit->{ccw}}, @{$child->{ccw}}];
                    $child->{childs} = $unit->{childs};
                    parse_unit($child_unit, $child, $specialist->{ability_func});

                    $child_unit->{name} = $new_unit->{name} . $specialist->{name_func}($ability);

                    push @unit_list, $child_unit;
                }
            }
        }

        # Check for alternate profiles
        for my $alt (@{$unit->{altp}}){
            next if $alt->{isc} eq 'CrazyKoala';

            my $alt_unit = clone($new_unit);

            # stats replace if present, otherwise inherit
            parse_unit($alt_unit, $alt);

            my $alt_tag = $alt->{isc};
            if($alt_tag !~ m/\(/){
                $alt_tag = "($alt_tag)";
            }
            $alt_unit->{name} = "$new_unit->{name} $alt_tag";

            # Tell the base unit how many wounds the Operator has
            if($alt->{isc} eq 'Operator'){
                $new_unit->{operator} = $alt_unit->{w};
            }

            push @unit_list, $alt_unit;
        }
    }
    $unit_data->{$faction} = [sort unit_sort @unit_list];
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
