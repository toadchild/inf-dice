#!/usr/bin/perl

use strict;
use warnings;

use JSON::PP;
use Data::Dumper;

my $json = JSON::PP->new;
$json->pretty(1);

my %default_wtype = (
    LI => 'W',
    MI => 'W',
    HI => 'W',
    WB => 'W',
    SK => 'W',
    REM => 'STR',
    TAG => 'STR',
);

sub has_nwi{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/No Wound Incapacitation/){
            return 1;
        }
    }
    return 0;
}

sub has_shasvastii{
    my ($unit) = @_;

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Shasvastii/){
            return 1;
        }
    }
    return 0;
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
            return -3;
        }elsif($spec =~ m/CH: Camo/){
            return -3;
        }elsif($spec =~ m/CH: TO Camo/){
            return -6;
        }elsif($spec =~ m/ODD:/){
            return -6;
        }elsif($spec =~ m/ODF:/){
            return -6;
        }
    }

    return 0;
}

sub dodge_unit{
    my ($unit) = @_;

    if($unit->{type} eq 'REM' || $unit->{type} eq 'TAG'){
        return -6;
    }

    for my $spec (@{$unit->{spec}}){
        if($spec =~ m/Motorcycle/){
            return -6;
        }
    }

    return 0;
}

sub get_weapons{
    my ($unit) = @_;
    my $weapons = {};

    for my $w (@{$unit->{bsw}}){
        $weapons->{$w} = 1;
    }

    for my $w (@{$unit->{ccw}}){
        $weapons->{$w} = 1;
    }

    for my $child (@{$unit->{childs}}){
        for my $w (@{$child->{bsw}}){
            $weapons->{$w} = 1;
        }

        for my $w (@{$child->{ccw}}){
            $weapons->{$w} = 1;
        }
    }

    return [keys %$weapons];
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

my $unit_data = {};
my $file;
for my $fname (glob "ia-data/ia-data_*_units_data.json"){
    local $/;
    my $json_text;
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

        my $new_unit = {};
        $new_unit->{name} = $unit->{name};
        $new_unit->{bs} = $unit->{bs};
        $new_unit->{ph} = $unit->{ph};
        $new_unit->{cc} = $unit->{cc};
        $new_unit->{wip} = $unit->{wip};
        $new_unit->{arm} = $unit->{arm};
        $new_unit->{bts} = $unit->{bts};
        $new_unit->{w_type} = uc($unit->{wtype} // $default_wtype{$unit->{type}});
        $new_unit->{dodge_unit} = dodge_unit($unit);
        $new_unit->{w} = $unit->{w};
        $new_unit->{nwi} = has_nwi($unit);
        $new_unit->{shasvastii} = has_shasvastii($unit);
        $new_unit->{weapons} = get_weapons($unit);
        $new_unit->{ikohl} = has_ikohl($unit);
        $new_unit->{immunity} = has_immunity($unit);
        $new_unit->{hyperdynamics} = has_hyperdynamics($unit);
        $new_unit->{ch} = has_camo($unit);
        $new_unit->{type} = $unit->{type};

        if(defined($faction) && $faction ne $unit->{army}){
            die "Mismatched faction in $unit->name: $faction != $unit->army";
        }
        $faction = $unit->{army};

        push @unit_list, $new_unit;
    }
    $unit_data->{$faction} = [sort unit_sort @unit_list];
}

open $file, '>', 'unit_data.js' or die "Unable to open file";
print $file "units = ";
print $file $json->encode($unit_data);
