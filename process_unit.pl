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

my $dual_weapons = {};
my $dual_ccw = {};
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
    $new_unit->{bs} = $unit->{bs} if defined $unit->{bs};
    $new_unit->{ph} = $unit->{ph} if defined $unit->{ph};
    $new_unit->{cc} = $unit->{cc} if defined $unit->{cc};
    $new_unit->{wip} = $unit->{wip} if defined $unit->{wip};
    $new_unit->{arm} = $unit->{arm} if defined $unit->{arm};
    $new_unit->{bts} = $unit->{bts} if defined $unit->{bts};
    $new_unit->{w} = $unit->{w} if defined $unit->{w};
    $new_unit->{type} = $unit->{type} if defined $unit->{type} && $unit->{type} ne ' ';
    $new_unit->{w_type} = uc($unit->{wtype} // $default_wtype{$new_unit->{type}});
    $new_unit->{spec} = $unit->{spec} if defined $unit->{spec} && @{$unit->{spec}};

    # Modifiers
    $new_unit->{motorcycle} = !$rider && has_motorcycle($new_unit);
    $new_unit->{nwi} = has_nwi($new_unit);
    $new_unit->{symbiont} = has_symbiont($new_unit, $symbiont_inactive);
    $new_unit->{shasvastii} = has_shasvastii($new_unit) || $inherit_shasvastii;
    $new_unit->{ikohl} = has_ikohl($new_unit);
    $new_unit->{immunity} = has_immunity($new_unit);
    $new_unit->{hyperdynamics} = has_hyperdynamics($new_unit);
    $new_unit->{ch} = has_camo($new_unit);
    $new_unit->{odd} = has_odd($new_unit);
    $new_unit->{msv} = has_msv($new_unit);
    $new_unit->{xvisor} = has_xvisor($new_unit);
    $new_unit->{hacker} = has_hacker($new_unit) || $new_unit->{hacker} || 0;

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
