#!/usr/bin/perl

use strict;
use warnings;
use Time::HiRes qw(time);
use CGI qw/:standard/;
use Data::Dumper;
use POSIX;

$CGI::POST_MAX=1024;  # max 1K posts
$CGI::DISABLE_UPLOADS = 1;  # no uploads


sub print_head{
    print <<EOF
Content-Type: text/html; charset=utf-8

<!DOCTYPE HTML>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Infinity Dice Calculator</title>
        <link href="inf-dice.css" rel="stylesheet" type="text/css">
        <link href="hitbar.css" rel="stylesheet" type="text/css">
        <script type="text/javascript" src="inf-dice.js"></script>
        <script type="text/javascript" src="unit_data.js"></script>
        <script type="text/javascript" src="weapon_data.js"></script>
    </head>
    <body onload="init_on_load()">
EOF
}

sub print_top{
    print <<EOF
    <div id="head" class="databox">
    <div class='content'>
    <h1>Infinity Dice Calculator</h1>
<p>
Use the Model and Action Selection tools below to describe the scenario you
want to learn about.  You can pick the faction, model, action, and weapons
you are interested in for both the active and reactive player.
</p>
<p>
If there are modifiers that are relevant to the
skills you have selected, they will be shown.  Sometimes an option will be
greyed out; that means it cannot be applied due to the particular combination
of other options you have chosen.
</p>
<p>
Once you are satisfied, press
the button to see the probabilties for this action.
</p>
    </div>
    </div>
EOF
}

my $ammo_codes = {
    Normal => {code => 'N'},
    Shock => {code => 'N', fatal => 1},
    Swarm => {code => 'N', fatal => 1, save => 'bts'},
    T2 => {code => 'N', dam => 2},
    AP => {code => 'N', ap => 0.5},
    'AP+DA' => {code => 'D', ap => 0.5},
    'AP+EXP' => {code => 'E', ap => 0.5},
    'AP+Shock' => {code => 'N', ap => 0.5, fatal => 1},
    DA => {code => 'D'},
    'DA+Shock' => {code => 'D', fatal => 1},
    EXP => {code => 'E'},
    Fire => {code => 'F', fatal_symbiont => 9},
    Monofilament => {code => 'N', fixed_dam => 12, no_arm_bonus => 1, fatal => 9},
    K1 => {code => 'N', fixed_dam => 12},
    Viral => {code => 'D', save => 'bts', fatal => 1, str_resist => 1, ignore_nwi => 1},
    Nanotech => {code => 'N', save => 'bts'},
    Flash => {code => 'N', save => 'bts', fatal => 9, label => 'Blinded', format => '%s hits %3$s%4$s'},
    'E/M' => {code => 'N', save => 'bts', fatal => 9, label => 'Disabled', format => '%s hits %3$s%4$s'},
    'E/M2' => {code => 'D', save => 'bts', fatal => 9, label => 'Disabled', format => '%s hits %3$s%4$s'},
    'Smoke' => {code => '-', cover => 0, no_lof => 1, dam => 0, format => '%s blocks %3$s with Smoke'},
    'Zero-V Smoke' => {code => '-', cover => 0, no_lof => 1, dam => 0, format => '%s blocks %3$s with Zero-V Smoke'},
    'Adhesive' => {code => 'N', alt_save => 'ph', alt_save_mod => -6, fatal => 9, label => 'Immobilized', format => '%s hits %3$s%4$s'},
    # Placeholders for unimplemented ammos
    'Plasma' => {code => 'N'},
    'N+E/M(12)' => {code => 'N'},
    'AP+E/M(12)' => {code => 'N', ap => 0.5},
    'Stun' => {code => 'N', save => 'bts'},
    'Dep. Repeater' => {code => '-', dam => 0, not_attack => 1, format => '%s places a Deployable Repeater'},
};

my $skill_codes = {
    'hack_imm' => {fatal => 9, label => 'Immobilized', title => 'Hack to Immobilize', no_lof => 1, format => '%s Hacks %3$s%4$s'},
    'hack_ahp' => {dam => 'w', title => 'Anti-Hacker Protocols', no_lof => 1, format => '%s Hacks %3$s%4$s'},
    'hack_def' => {title => 'Defensive Hacking', no_lof => 1, dam => 0, format => '%s Hacks Defensively against %3$s'},
    'hack_pos' => {fatal => 9, label => 'Possessed', threshold => 2, title => 'Hack to Possess', no_lof => 1, format => '%s Hacks %3$s%4$s'},
    'dodge' => {title => 'Dodge', no_lof => 1, dam => 0, format => '%s Dodges %3$s'},
};

my $immunity = ['', 'shock', 'bio', 'total'];
my $immunity_labels = {
    '' => 'None',
    'shock' => 'Shock',
    'bio' => 'Bio',
    'total' => 'Total',
};

my $immunities = {
    shock => {Shock => 'arm'},
    bio => {Shock => 'arm', Viral => 'bts'},
    total => {
        Shock => 'arm',
        AP => 'arm',
        'AP+DA' => 'arm',
        'AP+EXP' => 'arm',
        'AP+Shock' => 'arm',
        DA => 'arm',
        EXP => 'arm',
        Fire => 'arm',
        Nanotech => 'arm',
        Swarm => 'arm',
        'N+E/M(12)' => 'arm',
        # TODO verify what happens when a TI model is hit with E/M2
    },
};

my $symbiont_armor = [0, 2, 1];
my $symbiont_armor_labels = {
    0 => 'None',
    1 => 'Inactive',
    2 => 'Active',
};

my $operator = [0, 1, 2];
my $operator_labels = {
    0 => 'None',
    1 => '1 W',
    2 => '2 W',
};

my $ch = ['0', '-3', '-6'];
my $ch_labels = {
    0 => 'None',
    -3 => 'Mimetism/Camo (-3 Opponent BS)',
    -6 => 'TO Camo/ODD (-6 Opponent BS)',
};

my $ikohl = ['0', '-3', '-6', '-9'];
my $ikohl_labels = {
    0 => 'None',
    -3 => 'Level 1 (-3 Opponent CC)',
    -6 => 'Level 2 (-6 Opponent CC)',
    -9 => 'Level 3 (-9 Opponent CC)',
};

my $viz = ['0', '-3', '-6'];
my $viz_labels = {
    0 => 'None',
    -3 => 'Low Viz Zone (-3 BS)',
    -6 => 'Zero Viz Zone (-6 BS)',
};

my $link = [0, 3, 5, -5];
my $link_labels = {
    0 => 'None',
    3 => '3 (+1 B)',
    5 => '5 (+1 B, +3 BS)',
    -5 => '5, Long Skill (+3 BS)',
};

my $gang_up = [0, 3, 6, 9];
my $gang_up_labels = {
    0 => 'None',
    3 => '1 Ally (+3 CC/Dodge)',
    6 => '2 Allies (+6 CC/Dodge)',
    9 => '3 Allies (+9 CC/Dodge)',
};

my $hyperdynamics = [0, 3, 6, 9];
my $hyperdynamics_labels = {
    0 => 'None',
    3 => 'Level 1 (+3 PH to Dodge)',
    6 => 'Level 2 (+6 PH to Dodge)',
    9 => 'Level 3 (+9 PH to Dodge)',
};

my $msv = [0, 1, 2, 3];
my $msv_labels = {
    0 => 'None',
    1 => 'Level 1',
    2 => 'Level 2',
    3 => 'Level 3',
};

my $hacker = [0, 1, 2, 3];
my $hacker_labels = {
    0 => 'None',
    1 => 'Defensive Hacking Device',
    2 => 'Hacking Device',
    3 => 'Hacking Device Plus',
};

my $ma = [0, 1, 2, 3, 4, 5];
my $ma_labels = {
    0 => 'None',
    1 => 'Level 1',
    2 => 'Level 2',
    3 => 'Level 3',
    4 => 'Level 4',
    5 => 'Level 5',
};

my $evo = [0, 'ice', 'cap', 'sup_1', 'sup_2', 'sup_3'];
my $evo_labels = {
    0 => 'None',
    ice => 'Icebreaker (Halve Opponent BTS)',
    cap => 'Capture (1 WIP Roll to Capture a TAG)',
    sup_1 => 'Support Hacking - 1 Ally (+3 WIP)',
    sup_2 => 'Support Hacking - 2 Allies (+6 WIP)',
    sup_3 => 'Support Hacking - 3 Allies (+9 WIP)',
};

my $factions = [
    'Aleph',
    'Ariadna',
    'Combined Army',
    'Haqqislam',
    'Mercenary',
    'Nomads',
    'Panoceania',
    'Tohaa',
    'Yu Jing',
];

my $player_labels = {
    1 => 'Active Player',
    2 => 'Reactive Player',
};

sub span_popup_menu{
    my (%args) = @_;
    my $label = $args{-label} // '';
    delete $args{-label};

    return "<span id='$args{-name}'><label>$label " .  popup_menu(%args) .  "</label></span>\n";
}

sub span_checkbox{
    my (%args) = @_;

    return "<span id='$args{-name}'>" .  checkbox(%args) .  "</span>\n";
}

sub print_input_section{
    my ($player_num) = @_;
    my $player = "p" . $player_num;

    print "<div id='$player' class='inner-databox'>\n";
    print "<div class='content'>\n";
    printf "<h2>$player_labels->{$player_num}</h2>\n";

    print_input_attack_section($player);

    print "</div>\n";
    print "</div>\n";
}

sub print_input_attack_section{
    my ($player) = @_;

    print "<h3>Model</h3>",
          span_popup_menu(-name => "$player.faction",
              -values => $factions,
              -default => param("$player.faction") // '',
              -onchange => "set_faction('$player')",
              -label => 'Faction',
          ),
          "<br>",
          span_popup_menu(-name => "$player.unit",
              -default => param("$player.unit") // '',
              -onchange => "set_unit('$player')",
              -label => 'Unit',
          );

    print "<div id='$player.statline' class='statline'>",
          "<table>",
          "<tr><th>Type</th><th>CC</th><th>BS</th><th>PH</th><th>WIP</th><th>ARM</th><th>BTS</th>",
          "<th id='$player.statline_w_type'>",
          span_popup_menu(-name => "$player.w_type"),
          "</th>",
          "</tr>",
          "<tr>",
          "<br>",
          "<td id='$player.statline_type'>",
          span_popup_menu(-name => "$player.type"),
          "</td>",
          "<td id='$player.statline_cc'>",
          span_popup_menu(-name => "$player.cc"),
          "</td>",
          "<td id='$player.statline_bs'>",
          span_popup_menu(-name => "$player.bs"),
          "</td>",
          "<td id='$player.statline_ph'>",
          span_popup_menu(-name => "$player.ph"),
          "</td>",
          "<td id='$player.statline_wip'>",
          span_popup_menu(-name => "$player.wip"),
          "</td>",
          "<td id='$player.statline_arm'>",
          span_popup_menu(-name => "$player.arm"),
          "</td>",
          "<td id='$player.statline_bts'>",
          span_popup_menu(-name => "$player.bts"),
          "</td>",
          "<td id='$player.statline_w'>",
          span_popup_menu(-name => "$player.w"),
          "</td>",
          "</tr>",
          "</table>",
          "<div id='$player.skills'>Skills/Equipment:",
          "<div id='$player.statline_skills' class='skills'></div>",
          "</div>",
          "<br>",
          span_popup_menu(-name => "$player.w_taken",
              -label => "Wounds Previously Taken",
          ),
          "</div>\n";

    print "<div id='$player.attributes' style='display: none;'>\n",
          "<h4>Wounds</h4>",
          span_checkbox(-name => "$player.nwi",
              -checked => defined(param("$player.nwi")),
              -value => 1,
              -label => 'No Wound Incapacitation',
          ),
          "<br>",
          span_checkbox(-name => "$player.shasvastii",
              -checked => defined(param("$player.shasvastii")),
              -value => 1,
              -label => 'Shasvastii Spawn-Embryo',
          ),
          "<br>",
          span_popup_menu(-name => "$player.symbiont",
              -values => $symbiont_armor,
              -default => param("$player.symbiont") // '',
              -labels => $symbiont_armor_labels,
              -label => 'Symbiont Armor',
          ),
          "<br>",
          span_popup_menu(-name => "$player.operator",
              -values => $operator,
              -default => param("$player.operator") // '',
              -labels => $operator_labels,
              -label => 'Operator',
          ),
          "<br>",
          "<h4>Special Skills and Equipment</h4>",
          span_popup_menu(-name => "$player.immunity",
              -values => $immunity,
              -default => param("$player.immunity") // '',
              -labels => $immunity_labels,
              -label => "Immunity",
          ),
          "<br>",
          span_checkbox(-name => "$player.motorcycle",
              -checked => defined(param("$player.motorcycle")),
              -value => 1,
              -label => 'Motorcycle',
          ),
          "<br>",
          span_popup_menu(-name => "$player.hyperdynamics",
              -values => $hyperdynamics,
              -default => param("$player.hyperdynamics") // '',
              -labels => $hyperdynamics_labels,
              -label => "Hyperdynamics",
          ),
          "<br>",
          span_popup_menu(-name => "$player.ikohl",
              -values => $ikohl,
              -default => param("$player.ikohl") // '',
              -labels => $ikohl_labels,
              -label => "i-Kohl",
          ),
          "<br>",
          span_popup_menu(-name => "$player.ch",
              -values => $ch,
              -default => param("$player.ch") // '',
              -labels => $ch_labels,
              -label => "Camo",
          ),
          "<br>",
          span_popup_menu(-name => "$player.msv",
              -values => $msv,
              -default => param("$player.msv") // '',
              -labels => $msv_labels,
              -label => "Multispectral Visor",
          ),
          "<br>",
          span_popup_menu(-name => "$player.hacker",
              -values => $hacker,
              -default => param("$player.hacker") // '',
              -labels => $hacker_labels,
              -label => "Hacking Device",
          ),
          "<br>",
          span_popup_menu(-name => "$player.ma",
              -values => $ma,
              -default => param("$player.ma") // '',
              -labels => $ma_labels,
              -label => "Martial Arts",
              -onchange => "set_cc_first_strike()",
          ),
          "<br>",
          span_checkbox(-name => "$player.nbw",
              -checked => defined(param("$player.nbw")),
              -value => 1,
              -label => 'Natural Born Warrior',
              -onchange => "set_cc_first_strike(); set_berserk()",
          ),
          "<br>",
          span_checkbox(-name => "$player.has_berserk",
              -checked => defined(param("$player.has_berserk")),
              -value => 1,
              -label => 'Berserk',
              -onchange => "set_berserk()",
          ),
          "</div>\n";

    print "<div class='action'>
          <h3>Action</h3>",

          popup_menu(-name => "$player.action",
              -onchange => "set_action('$player')",
          ),
          "<br>",
          span_checkbox(-name => "$player.first_strike",
              -checked => defined(param("$player.first_strike")),
              -value => 1,
              -label => "First Strike",
          ),
          "</div>\n";

    print "<div id='$player.sec_weapon'>",
          "<h3>Weapon</h3>",
          span_popup_menu(-name => "$player.weapon",
              -onchange => "set_weapon('$player')",
              -label => 'Weapon',
          ),
          span_popup_menu(-name => "$player.stat",
              -label => "Stat",
          ),
          "<br>",
          span_popup_menu(-name => "$player.ammo",
              -onchange => "set_ammo('$player')",
              -label => "Ammo",
          ),
          span_popup_menu(-name => "$player.b",
              -label => "B",
          ),
          span_popup_menu(-name => "$player.dam",
              -label => 'DAM',
          ),
          "</div>";

    print "<div id='$player.sec_shoot'>
          <h3>Shooting Modifiers</h3>",
          span_popup_menu(-name => "$player.range",
              -label => "Range",
          ),
          "<br>",
          span_popup_menu(-name => "$player.link",
              -values => $link,
              -default => param("$player.link") // '',
              -labels => $link_labels,
              -label => "Link Team",
          ),
          "<br>",
          span_popup_menu(-name => "$player.viz",
              -values => $viz,
              -default => param("$player.viz") // '',
              -labels => $viz_labels,
              -label => "Visibility Penalty",
          ),
          "</div>";

    print "<div id='$player.sec_cc'>",
          "<h3>CC Modifiers</h3>",
          span_popup_menu(-name => "$player.gang_up",
              -values => $gang_up,
              -default => param("$player.gang_up") // '',
              -labels => $gang_up_labels,
              -label => "Gang Up",
          ),
          "<br>",
          span_checkbox(-name => "$player.berserk",
              -checked => defined(param("$player.berserk")),
              -value => 3,
              -label => 'Berserk (+9 CC, Normal Rolls)'),
          "</div>\n";

    print "<div id='$player.sec_hack'>",
          "<h3>Hacking Modifiers</h3>",
          span_popup_menu(-name => "$player.evo",
              -values => $evo,
              -default => param("$player.evo") // '',
              -labels => $evo_labels,
              -label => "EVO Support Program",
          ),
          "</div>\n";

    print "<div id='$player.sec_defense'>",
          "<h3>Defensive Modifiers</h3>",
          span_checkbox(-name => "$player.cover",
              -checked => defined(param("$player.cover")),
              -value => 3,
              -label => 'Cover (+3 ARM, -3 Opponent BS)'),
          "<br>",
          span_checkbox(-name => "$player.odf",
              -checked => defined(param("$player.odf")),
              -value => -6,
              -label => 'ODF (-6 Opponent BS)'),
          "</div>\n";
}


sub print_input_head{
    print <<EOF
    <div id="input" class="databox">
    <div class='content'>
    <h2>Model and Action Selection</h2>
    <form method="get">
EOF
}

sub print_input_tail{
    print <<EOF
    <div id="submit">
    <div class='content'>
        <input type="submit" value="Roll the Dice!">
    </div>
    </div>
    </form>
</div>
</div>
EOF
}

sub print_input{
    print_input_head();
    print_input_section(1);
    print_input_section(2);
    print_input_tail();
}


# Prints the output block showing the chance that the model took wounds
# Returns the maximum number of wounds inflicted for rollup purposes
sub print_player_output{
    my ($output, $player, $other) = @_;

    if(scalar keys %{$output->{hits}{$player}} == 0){
        # empty list, nothing to print
        return;
    }

    my $label = '';
    my $wounds = param("p$other.w") // 1;
    my $w_taken = param("p$other.w_taken") // 0;
    my $immunity = param("p$other.immunity") // '';
    my $ammo = param("p$player.ammo") // 'Normal';
    my $nwi = param("p$other.nwi");
    my $shasvastii = param("p$other.shasvastii");
    my $w_type = param("p$other.w_type") // 'W';
    my $name = param("p$player.unit") // 'Model A';
    my $other_name = param("p$other.unit") // 'Model B';
    my $symbiont = param("p$other.symbiont") // 0;
    my $operator_w = param("p$other.operator") // 0;
    my $action = param("p$player.action") // '';
    my $disabled_h;

    my $code = $skill_codes->{$action};
    if(!defined $code){
        $code = $ammo_codes->{$ammo};
    }
    my $fatal = $code->{fatal} // 0;
    my $dam = $code->{dam} // 1;
    my $threshold = $code->{threshold} // 1;

    # pretty printing
    my $format = $code->{format} // '%s inflicts %d or more wounds on %s%s';

    # thresholds or state changes
    my $unconscious = $wounds;
    my $dead = $wounds + 1;
    my $symb_disabled = -1;
    my $eject = -1;
    my $spawn = -1;

    if($symbiont && $code->{fatal_symbiont}){
        $fatal = $code->{fatal_symbiont};
    }

    if($symbiont == 2){
        $symb_disabled = $wounds;
        $unconscious++;
        $dead++;
        $wounds++;
    }

    if($operator_w){
        $unconscious += $operator_w;
        $dead += $operator_w;
        $eject = $wounds;
    }

    if($shasvastii){
        $spawn = $dead;
        $dead++;
    }

    if($fatal >= $wounds && !$immunities->{$immunity}{$ammo} && !($w_type eq 'STR' && $code->{str_resist})){
        # This ammo is instantly fatal, and we are not immune
        $dead = 1;
    }

    if($code->{ignore_nwi}){
        $nwi = 0;
    }

    # KOs in one shot, kills on followup
    if($dam eq 'w'){
        $dam = $unconscious - $w_taken;
        if($dam == 0){
            $dam = 1;
        }
    }

    if($nwi){
        $unconscious = -1;
    }

    print "<h3>$player_labels->{$player}</h3>";
    print "<p>\n";

    my $max_h = 0;
    for my $h (sort {$a <=> $b} keys %{$output->{hits}{$player}}){
        my $done;

        if($h < $threshold){
            next;
        }

        $max_h = $h;
        my $w = $h * $dam + $w_taken;

        if($w >= $dead){
            $label = sprintf " (%s)", $code->{label} // 'Dead';
            $done = 1;
            if(!$disabled_h){
                $disabled_h = $h;
            }
        }elsif($w == $symb_disabled){
            $label = ' (Symbiont Disabled)';
        }elsif($w == $eject){
            $label = ' (Operator Ejected)';
            if(!$disabled_h){
                $disabled_h = $h;
            }
        }elsif($w == $unconscious){
            $label = ' (Unconscious)';
            if(!$disabled_h){
                $disabled_h = $h;
            }
        }elsif($w == $spawn){
            $label = ' (Spawn Embryo)';
            if(!$disabled_h){
                $disabled_h = $h;
            }
        }elsif($operator_w && $w > $eject){
            $label = ' (Operator ' . ($wounds + $operator_w - $w) . ' W)';
        }else{
            $label = ' (' . ($wounds - $w) . " $w_type)";
        }

        printf "<span class='p$player-hit-$h hit_chance'>%.2f%%</span> ", $output->{cumul_hits}{$player}{$h};
        printf "$format<br>\n", $name, $h, $other_name, $label;

        # Stop once we print a line about them being dead
        if($done){
            last;
        }
    }

    print "</p>\n";

    return ($max_h, $disabled_h);
}

sub print_miss_output{
    my ($output, $text) = @_;

    print "<h3>Failures</h3>\n";
    if($output->{disabled}{1}){
        printf "<span class='splat hit_chance'>%.2f%%</span> ", $output->{disabled}{1};
        print "Disabled by first strike<br>\n";
    }
    if($output->{disabled}{2}){
        printf "<span class='splat hit_chance'>%.2f%%</span> ", $output->{disabled}{2};
        print "Disabled by first strike<br>\n";
    }
    printf "<span class='miss hit_chance'>%.2f%%</span> $text<br>\n", $output->{hits}{0};
}

sub print_hitbar_player{
    my ($output, $sort, $p, $cutoff) = @_;

    for my $h (sort {$a * $sort <=> $b * $sort} keys %{$output->{hits}{$p}}){
        my $width = $output->{hits}{$p}{$h};
        my $label = $h;
        if($h == $cutoff){
            $width = $output->{cumul_hits}{$p}{$h};
            if($width > $output->{hits}{$p}{$h}){
                $label .= '+';
            }
        }elsif($h > $cutoff){
            next;
        }

        print "<td style='width: $width%;' class='p$p-hit-$h'>";
        if($width >= 3.0){
            print $label;
        }
        print "</td>\n";
    }
}

sub print_hitbar_output{
    my ($output, $max_1, $max_2) = @_;

    print "<table class='hitbar'><tr>\n";

    print_hitbar_player($output, -1, 1, $max_1);

    if($output->{disabled}{2}){
        print "<td style='width: $output->{disabled}{2}%;' class='splat'>";
        if($output->{disabled}{2} >= 25.0){
            print "Disabled";
        }elsif($output->{disabled}{2} >= 3.0){
            print "D";
        }
        print "</td>\n";
    }

    if($output->{hits}{0}){
        print "<td style='width: $output->{hits}{0}%;' class='miss'>";
        if($output->{hits}{0} >= 3.0){
            print "0";
        }
        print "</td>\n";
    }

    if($output->{disabled}{1}){
        print "<td style='width: $output->{disabled}{1}%;' class='splat'>";
        if($output->{disabled}{1} >= 25.0){
            print "Disabled";
        }elsif($output->{disabled}{1} >= 3.0){
            print "D";
        }
        print "</td>\n";
    }

    print_hitbar_player($output, 1, 2, $max_2);

    print "</tr></table>\n"
}

sub print_roll_subtitle{
    my $name1 = param("p1.unit") // 'Model A';
    my $name2 = param("p2.unit") // 'Model B';

    my $act1 = param('p1.action');
    my $act2 = param('p2.action');

    my $weapon1 = param("p1.weapon");

    if(exists($skill_codes->{$act1})){
        $weapon1 = $skill_codes->{$act1}{title};
    }

    if($weapon1){
        $name1 .= " - " . $weapon1;
    }

    my $weapon2 = param("p2.weapon");

    if(exists($skill_codes->{$act2})){
        $weapon2 = $skill_codes->{$act2}{title};
    }

    if($weapon2){
        $name2 .= " - " . $weapon2;
    }

    print "<div class='subtitle'><span class='contestant'>$name1</span> vs. <span class='contestant'>$name2</span></div>\n";
}

sub print_ftf_output{
    my ($output) = @_;

    print "<h2>Face to Face Roll</h2>\n";
    print_roll_subtitle();

    if($output->{hits}){
        my ($max_1, $dis_1) = print_player_output($output, 1, 2);

        print_miss_output($output, 'Neither player succeeds');

        my ($max_2, $dis_2) = print_player_output($output, 2, 1);

        print_hitbar_output($output, $max_1, $max_2);
    }
}

sub print_normal_output{
    my ($output) = @_;

    print "<h2>Normal Roll</h2>\n";
    print_roll_subtitle();

    if($output->{hits}){
        my ($max_1, $dis_1) = print_player_output($output, 1, 2);
        my ($max_2, $dis_2) = print_player_output($output, 2, 1);

        print_miss_output($output, 'No success');

        print_hitbar_output($output, $max_1, $max_2);
    }
}

sub print_simultaneous_output{
    my ($output) = @_;

    print "<h2>Simultaneous Normal Rolls</h2>\n";
    print_roll_subtitle();

    my ($max_1, $max_2, $dis_1, $dis_2);

    if($output->{A}{hits}){
        ($max_1, $dis_1) = print_player_output($output->{A}, 1, 2);

        print_miss_output($output->{A}, 'No success');
    }

    if($output->{B}{hits}){
        ($max_2, $dis_2) = print_player_output($output->{B}, 2, 1);

        print_miss_output($output->{B}, 'No success');
    }

    if($output->{A}{hits}){
        print_hitbar_output($output->{A}, $max_1, 0);
    }

    if($output->{B}{hits}){
        print_hitbar_output($output->{B}, 0, $max_2);
    }
}

sub print_first_strike_output{
    my ($output) = @_;

    print "<h2>First Strike</h2>\n";
    print_roll_subtitle();

    my ($max_1, $max_2, $dis_1, $dis_2);

    # determine order of attacks
    my ($first, $second, @first_order, @second_order);
    if($output->{first_strike} == 1){
        $first = 'A';
        $second = 'B';
        @first_order = (1, 2);
        @second_order = (2, 1);
    }else{
        $first = 'B';
        $second = 'A';
        @first_order = (2, 1);
        @second_order = (1, 2);
    }

    if($output->{$first}{hits}){
        ($max_1, $dis_1) = print_player_output($output->{$first}, @first_order);

        # $dis_1 has the number of wounds needed to incapacitate the other player
        my $dis_chance = $output->{$first}{cumul_hits}{$first_order[0]}{$dis_1};

        # scale all their results down by this amount
        for my $w (keys %{$output->{$second}{cumul_hits}{$second_order[0]}}){
            $output->{$second}{cumul_hits}{$second_order[0]}{$w} *= 1 - ($dis_chance / 100.0);
        }
        for my $w (keys %{$output->{$second}{hits}{$second_order[0]}}){
            $output->{$second}{hits}{$second_order[0]}{$w} *= 1 - ($dis_chance / 100.0);
        }
        $output->{$second}{hits}{0} *= 1 - ($dis_chance / 100.0);

        # Put chance of being disabled in the hit results
        $output->{$second}{disabled}{$second_order[0]} = $dis_chance;

        print_miss_output($output->{$first}, 'No success');
    }

    if($output->{$second}{hits}){
        ($max_2, $dis_2) = print_player_output($output->{$second}, @second_order);

        print_miss_output($output->{$second}, 'No success');
    }

    if($output->{$first}{hits}){
        print_hitbar_output($output->{$first}, $max_1, $max_1);
    }

    if($output->{$second}{hits}){
        print_hitbar_output($output->{$second}, $max_2, $max_2);
    }
}

sub print_none_output{
    my ($output) = @_;

    print "<h2>No Roll</h2>\n";
    if($output->{hits}){
        print_miss_output($output->{B}, 'Nothing happens');

        print_hitbar_output($output, 0, 0);
    }
}

sub print_output{
    my ($output) = @_;

    if(!$output){
        return;
    }

    print "<div id='output' class='databox'>\n";
    print "<div class='content'>\n";

    if($output->{error}){
        print "<div class='output_error'>$output->{error}</div>\n";
    }elsif($output->{type} eq 'ftf'){
        print_ftf_output($output);
    }elsif($output->{type} eq 'normal'){
        print_normal_output($output);
    }elsif($output->{type} eq 'simultaneous'){
        print_simultaneous_output($output);
    }elsif($output->{type} eq 'first_strike'){
        print_first_strike_output($output);
    }elsif($output->{type} eq 'none'){
        print_none_output($output);
    }

    # Only show if we did calculations in the backend
    if($output->{raw}){
        print "<button onclick='mod_output()'>Show Modifiers</button>\n";
        print "<button onclick='raw_output()'>Show Raw Stats</button>\n";

        print "<div id='raw_output' style='display: none;'>
            <pre>
$output->{raw}
            </pre>
            </div>\n";

        print "<div id='mod_output' style='display: none;'>\n";

        if(@{$output->{mods}{1}}){
            print "<p>";
            print "<h3>Active Model</h3>\n";
            print "<ul>\n";
            for my $m (@{$output->{mods}{1}}){
                print "<li>$m\n";
            }
            print "</ul>\n";
            print "</p>";
        }

        if(@{$output->{mods}{2}}){
            print "<p>";
            print "<h3>Reactive Model</h3>\n";
            print "<ul>\n";
            for my $m (@{$output->{mods}{2}}){
                print "<li>$m\n";
            }
            print "</ul>\n";
            print "</p>\n";
        }

        print "</div>\n";
    }

    print "</div>\n";
    print "</div>\n";
}

sub print_tail{
    my ($time) = @_;

    print <<EOF
    <div id="contact">
This tool was created by <a href="http://ghostlords.com/">Jonathan Polley</a> to help enhance your enjoyment of Infinity the Game.
Please direct any feedback to <a href="mailto:inf-dice\@ghostlords.com">inf-dice\@ghostlords.com</a>.<br>
<a href="http://infinitythegame.com/">Infinity the Game</a> is &copy; Corvus Belli SLL.<br>
Unit and weapon data was graciously provided by Davide Imbriaco, creator of <a href="http://anyplace.it/ia/">Aleph Toolbox</a>.
    </div>
    <div id="time">Content took $time seconds to generate.</div>
    </body>
</html>
EOF
}

sub max{
    my ($a, $b) = @_;
    return $a > $b ? $a : $b;
}

sub gen_attack_args{
    my ($us, $them) = @_;
    my ($link_bs, $link_b) = (0, 0);
    my ($arm, $ap, $ammo, $cover, $ignore_cover, $save, $dam);
    my $b;
    my ($stat_name, $stat);
    my ($ammo_name, $code, $immunity);
    my $type;
    my @mod_strings;
    my $arm_bonus = 0;

    if((param("$us.link") // 0) >= 3){
        $link_b = 1;
    }

    if((abs(param("$us.link") // 0)) >= 5){
        $link_bs = 3;
    }

    $ammo_name = param("$us.ammo") // 'Normal';
    $code = $ammo_codes->{$ammo_name};
    $immunity = param("$them.immunity") // '';

    # Total Immunity ignores most ammo types
    if($immunities->{$immunity}{$ammo_name}){
        $ap = 1;
        $save = $immunities->{$immunity}{$ammo_name};
        $ammo = 'N';
    }else{
        $ap = $code->{ap} // 1;
        $save = $code->{save} // 'arm';
        $ammo = $code->{code};
    }

    $arm = ceil(abs(param("$them.$save") // 0) * $ap);
    $dam = param("$us.dam") // 0;
    $ignore_cover = $code->{cover} // 1;
    $cover = (param("$them.cover") // 0) * $ignore_cover;

    # Monofilament and K1 have fixed damage
    if($code->{fixed_dam}){
        $arm = 0;
        $dam = $code->{fixed_dam};
    }

    if($dam eq 'PH'){
        $dam = param("$us.ph") // 0;
    }elsif($dam eq 'PH-2'){
        $dam = (param("$us.ph") // 2) - 2;
    }

    my $action = param("$us.action");
    my $other_action = param("$them.action");

    # look up their skill/ammo code
    my $other_code = $skill_codes->{$other_action};
    if(!defined $other_code){
        $other_code = $ammo_codes->{param("$them.ammo") // 'Normal'};
    }

    if($action eq 'bs'){
        # BS mods
        $type = 'ftf';

        # look up stat to use
        $stat_name = lc(param("$us.stat") // 'bs');
        $stat = param("$us.$stat_name") // 0;
        $stat_name = uc($stat_name);

        push @mod_strings, "Base $stat_name of $stat";

        my $camo = param("$them.ch") // 0;
        my $odf = param("$them.odf") // 0;
        if($odf < $camo){
            $camo = $odf;
        }
        $camo *= $ignore_cover;

        if($cover){
            push @mod_strings, sprintf('Cover grants %+d %s', -$cover, $stat_name);
            $stat -= $cover;
        }

        if($link_bs){
            push @mod_strings, sprintf('Link Team grants %+d %s', $link_bs, $stat_name);
            $stat += $link_bs;
        }

        my $msv = param("$us.msv") // 0;
        if($msv >= 1 && $camo == -3){
            push @mod_strings, "MSV ignores CH modifier";
            $camo = 0;
        }elsif($msv >= 2 && $camo < 0){
            push @mod_strings, "MSV ignores CH/ODD/ODF modifier";
            $camo = 0;
        }elsif($camo < 0){
            push @mod_strings, sprintf('CH/ODD/ODF grants %+d %s', $camo, $stat_name);
            $stat += $camo;
        }

        my $viz = param("$us.viz") // 0;
        if($msv >= 1 && $viz == -3){
            push @mod_strings, "MSV ignores Visibility modifier";
            $viz = 0;
        }elsif($msv >= 2 && $viz < 0){
            push @mod_strings, "MSV ignores Visibility modifier";
            $viz = 0;
        }elsif($viz < 0){
            push @mod_strings, sprintf('Visibility grants %+d %s', $viz, $stat_name);
            $stat += $viz;
        }

        # Regular Smoke is useless against MSV2+
        if($msv >= 2){
            if((param("$them.ammo") // '') eq 'Smoke'){
                push @mod_strings, "MSV ignores Smoke";
                $type = 'normal';
            }
        }

        # Range comes in as 0-8/+3 OR +3
        # Select only the final number
        my $range = param("$us.range") // 0;
        $range =~ m/(-?\d+)$/;
        $range = $1;
        push @mod_strings, sprintf('Range grants %+d %s', $range,  $stat_name);
        $stat += $range;

        $stat = max($stat, 0);
        push @mod_strings, "Net $stat_name is $stat";

        $b = (param("$us.b") // 1);
        if($link_b){
            push @mod_strings, sprintf('Link Team grants %+d B', $link_b);
            $b += $link_b;
        }

        $arm += $cover;

        # Smoke provides no defense against non-lof skills
        if($ammo_name eq 'Smoke' || $ammo_name eq 'Zero-V Smoke'){
            if($other_code->{no_lof}){
                $type = 'normal';
            }
        }

        # First strike
        if(param("$us.first_strike")){
            $type = "first_strike";
        }

        # Some weapons aren't attacks
        if($code->{not_attack}){
            $type = 'normal';
        }
    }elsif($action eq 'dtw'){
        # DTW mods
        $type = 'normal';

        $stat = 'T';

        $b = (param("$us.b") // 1);
        if($link_b){
            push @mod_strings, sprintf('Link Team grants %+d B', $link_b);
            $b += $link_b;
        }

        $arm += $cover;

        # templates are FTF against Dodge
        if($other_action eq 'dodge'){
            $type = 'ftf';
        }

        # First strike
        if(param("$us.first_strike")){
            $type = "first_strike";
        }

    }elsif($action eq 'spec'){
        # Speculative Shot
        $type = 'ftf';

        # look up stat to use
        $stat_name = lc(param("$us.stat") // 'bs');
        $stat = param("$us.$stat_name") // 0;
        $stat_name = uc($stat_name);

        push @mod_strings, "Base $stat_name of $stat";

        push @mod_strings, sprintf('Speculative Shot grants -6 %s',  $stat_name);
        $stat -= 6;

        # Range comes in as 0-8/+3 OR +3
        # Select only the final number
        my $range = param("$us.range") // 0;
        $range =~ m/(-?\d+)$/;
        $range = $1;
        push @mod_strings, sprintf('Range grants %+d %s', $range,  $stat_name);
        $stat += $range;

        $stat = max($stat, 0);
        push @mod_strings, "Net $stat_name is $stat";

        $b = (param("$us.b") // 1);

        $arm += $cover;

        # Smoke provides no defense against non-lof skills
        if($ammo_name eq 'Smoke' || $ammo_name eq 'Zero-V Smoke'){
            if($other_code->{no_lof}){
                $type = 'normal';
            }
        }

        # Some weapons aren't attacks
        if($code->{not_attack}){
            $type = 'normal';
        }
    }elsif($action eq 'cc'){
        # CC mods
        $type = 'ftf';
        $arm_bonus = 3;

        $stat = param("$us.cc") // 0;
        push @mod_strings, "Base CC of $stat";

        my $us_ma = param("$us.ma") // 0;
        my $them_ma = param("$them.ma") // 0;

        # monofilament allows no CC ARM bonus
        if($code->{no_arm_bonus}){
            $arm_bonus = 0;
        }

        # CC ARM bonus only counts if both models are in CC
        if($other_action ne 'cc'){
            $arm_bonus = 0;
        }

        # No CC ARM bonus if they have Martial Arts unless we have NBW or MA4+
        if($them_ma && !(param("$us.nbw") || ($us_ma >= 4))){
            $arm_bonus = 0;
        }

        # berserk only works if they CC or Dodge in response
        # We must have berserk and they must not have NBW
        if(param("$us.has_berserk") && param("$us.berserk") && ($other_action eq 'cc' || $other_action eq 'dodge' || $other_action eq 'none')){
            if(!param("$them.nbw")){
                $stat += 9;
                $type = 'normal';
                push @mod_strings, 'Berserk grants +9 CC';
            }else{
                push @mod_strings, 'Berserk canceled by Natural Born Warrior';
            }
        }

        # iKohl does not work on models with STR
        my $ikohl = param("$them.ikohl") // 0;
        my $w_type = param("$us.w_type") // 'W';
        # i-Kohl also only works if the other party is executing CC
        if($ikohl){
            if($w_type eq 'STR'){
                $ikohl = 0;
                push @mod_strings, 'STR ignores i-Kohl';
            }elsif($other_action ne 'cc'){
                $ikohl = 0;
                push @mod_strings, 'i-Kohl negated by executing a non-CC skill';
            }else{
                push @mod_strings, sprintf('i-Kohl grants %+d CC', $ikohl);
                $stat += $ikohl;
            }
        }

        my $gang_up = param("$us.gang_up") // 0;
        if($gang_up){
            if($them_ma >= 5 && !param("$us.nbw")){
                push @mod_strings, "Gang-up canceled by MA 5";
            }else{
                push @mod_strings, sprintf('Gang-up grants %+d CC', $gang_up);
                $stat += $gang_up;
            }
        }

        $stat = max($stat, 0);
        push @mod_strings, "Net CC is $stat";

        $b = 1;

        # First strike requires MA 3+, but is canceled by the opponent having MA 4+ or NBW
        if($other_action eq 'cc' || $other_action eq 'dodge'){
            if(param("$us.first_strike") && $us_ma >= 3 && !(param("$them.nbw") || ($them_ma >= 4))){
                $type = "first_strike";
            }
        }
    }

    if(!$code->{alt_save}){
        $dam = max($dam - $arm, 0);
    }else{
        # Adhesive makes a PH saving throw instead of DAM - ARM check
        $dam = 20 - max(param("$them.$code->{alt_save}") + $code->{alt_save_mod}, 0);
    }

    return (
        $type,
        \@mod_strings,
        $stat,
        $b,
        $dam,
        $ammo,
        $arm_bonus,
    );
}

sub gen_hack_args{
    my ($us, $them) = @_;

    my $action = param("$us.action");
    my $other_action = param("$them.action");
    my $evo = param("$us.evo") // '';
    my $bts = param("$them.bts") // 0;

    my $type = 'ftf';
    my $can_hack = 0;
    my $b = 1;
    my @mod_strings;

    if($action eq 'hack_imm'){
        my $unit_type = param("$them.type") // '';
        my $faction = param("$them.faction") // '';

        if($unit_type eq 'REM' || $unit_type eq 'TAG'){
            $can_hack = 1;
        }elsif($unit_type eq 'HI' && $faction ne 'Ariadna'){
            # Ariadna HI are unhackable
            $can_hack = 1;
        }elsif($other_action eq 'hack_def'){
            $can_hack = 1;
        }

        # Immobilization does not protect against hacking attacks
        if($other_action eq 'hack_imm' || $other_action eq 'hack_ahp'){
            $type = 'normal';
        }

        # First strike
        if(param("$us.first_strike")){
            $type = "first_strike";
        }
    }elsif($action eq 'hack_pos'){
        my $unit_type = param("$them.type") // '';
        my $faction = param("$us.faction") // '';
        my $other_faction = param("$them.faction") // '';

        # CA TAGs cannot be possessed by humans
        if($unit_type eq 'TAG' && ($other_faction ne 'Combined Army' || $faction eq 'Combined Army')){
            $can_hack = 1;
        }elsif($other_action eq 'hack_def'){
            $can_hack = 1;
        }

        # Immobilization does not protect against hacking attacks
        if($other_action eq 'hack_imm' || $other_action eq 'hack_ahp'){
            $type = 'normal';
        }

        # EVO Capture program
        if($evo eq 'cap'){
            # rewrite global skill data to fix capture threshold
            $skill_codes->{hack_pos}{threshold} = 1;
        }else{
            $b = 2;
        }

        # First strike
        if(param("$us.first_strike")){
            $type = "first_strike";
        }
    }elsif($action eq 'hack_ahp'){
        my $hacker = param("$them.hacker") // 0;
        if($hacker > 0){
            $can_hack = 1;
        }

        # First strike
        if(param("$us.first_strike")){
            $type = "first_strike";
        }
    }elsif($action eq 'hack_def'){
        # Defensive Hacking is only useful against hacking attacks
        if($other_action eq 'hack_ahp' || $other_action eq 'hack_imm' || $other_action eq 'hack_pos'){
            $can_hack = 1;
        }
    }

    # If you can't hack it, do nothing
    if(!$can_hack){
        return gen_none_args();
    }

    # Dodge does not protect against hacking
    if($other_action eq 'dodge'){
        $type = 'normal';
    }

    my $stat = param("$us.wip") // 0;
    push @mod_strings, "Base WIP of $stat";

    # EVO support bonuses
    my $evo_mod = 0;
    if($evo eq 'sup_1'){
        $evo_mod = 3;
    }elsif($evo eq 'sup_2'){
        $evo_mod = 6;
    }elsif($evo eq 'sup_3'){
        $evo_mod = 9;
    }elsif($evo eq 'ice' && $bts){
        $bts = -ceil(abs($bts / 2));
        push @mod_strings, sprintf('EVO Icebreaker reduces BTS to %d', $bts);
    }

    if($evo_mod){
        push @mod_strings, sprintf('EVO Support grants %+d WIP', $evo_mod);
        $stat += $evo_mod;
    }

    if($bts){
        push @mod_strings, sprintf('BTS grants %+d WIP', $bts);
        $stat += $bts;
    }

    $stat = max($stat, 0);
    push @mod_strings, "Net WIP is $stat";

    return (
        $type,
        \@mod_strings,
        $stat,
        $b,
        0,
        '-',
        0,
    );
}

sub gen_dodge_args{
    my ($us, $them) = @_;
    my @mod_strings;

    my $dodge_unit = 0;
    my $unit_type = param("$us.type") // '';
    my $motorcycle = param("$us.motorcycle") // 0;
    if($unit_type eq 'REM' || $unit_type eq 'TAG' || $motorcycle){
        $dodge_unit = -6;
    }

    my $stat = param("$us.ph") // 0;
    push @mod_strings, "Base PH of $stat";

    if($dodge_unit){
        push @mod_strings, sprintf('Unit type grants %+d PH', $dodge_unit);
        $stat += $dodge_unit;
    }

    my $hyperdynamics = param("$us.hyperdynamics") // 0;
    if($hyperdynamics){
        push @mod_strings, sprintf('Hyperdynamics grants %+d PH', $hyperdynamics);
        $stat += $hyperdynamics;
    }

    my $type = 'ftf';

    # -6 to dodge templates
    if(param("$them.action") eq 'dtw'){
        push @mod_strings, 'Direct Template Weapon grants -6 PH';
        $stat -= 6;
    }elsif(param("$them.action") eq 'dodge'){
        # double-dodge is normal rolls
        $type = 'normal';
    }

    $stat = max($stat, 0);
    push @mod_strings, "Net PH is $stat";

    return (
        $type,
        \@mod_strings,
        $stat,
        1,
        0,
        '-',
        0,
    );
}

sub gen_none_args{
    return (
        'none',
        [],
        0,
        1,
        0,
        '-',
        0,
    );
}

sub gen_args{
    my ($us, $them) = @_;

    my $action = param("$us.action");
    if($action eq 'cc' || $action eq 'bs' || $action eq 'dtw' || $action eq 'spec'){
        return gen_attack_args($us, $them);
    }elsif($action eq 'hack_imm' || $action eq 'hack_ahp' || $action eq 'hack_def' || $action eq 'hack_pos'){
        return gen_hack_args($us, $them);
    }elsif($action eq 'dodge'){
        return gen_dodge_args($us, $them);
    }else{
        return gen_none_args();
    }

    return ();
}

sub execute_backend{
    my (@args) = @_;
    my $output;

    if(!open DICE, '-|', '/usr/local/bin/inf-dice', @args){
        $output->{error} = 'Unable to execute backend component.';
    }
    while(<DICE>){
        $_ =~ s/&/&amp;/g;
        $_ =~ s/</&lt;/g;

        $output->{raw} .= $_;
        if(m/^P(.) Scores +(\d+) S[^0-9]*([0-9.]+)%[^\d]*(\d+)\+ S[^0-9]*([0-9.]+)%/){
            $output->{hits}{$1}{$2} = $3;
            $output->{cumul_hits}{$1}{$4} = $5;
        }elsif(m/^No Successes: +([0-9.]+)/){
            $output->{hits}{0} = $1;
        }elsif(m/^ERROR/ || m/Assertion/){
            $output->{error} = $_;
        }
    }

    return $output;
}

# wrapper for execute_backend that does a pair of simultaneous normal rolls
sub execute_backend_simultaneous{
    my ($args1, $args2) = @_;
    my ($o1, $o2, $output);

    my ($none1, $none2, @args_none) = gen_none_args();

    $o1 = execute_backend(@$args1, @args_none);
    $o2 = execute_backend(@args_none, @$args2);

    $output->{raw} = $o1->{raw} . '<hr>' . $o2->{raw};
    $output->{type} = 'simultaneous';
    $output->{A} = $o1;
    $output->{B} = $o2;

    if($o1->{error}){
        $output->{error} = $o1->{error};
    }
    if($o2->{error}){
        if($output->{error}){
            $output->{error} .= '<br>' . $o2->{error};
        }else{
            $output->{error} = $o2->{error};
        }
    }

    return $output;
}

sub generate_output{
    my $output;

    if(!defined param('p1.action') || !defined param('p2.action')){
        return;
    }

    my ($act_1, $mod_strings_1, @args1) = gen_args('p1', 'p2');
    my ($act_2, $mod_strings_2, @args2) = gen_args('p2', 'p1');

    # determine if it's FtF or Normal
    my $type;
    if($act_1 eq 'none' && $act_2 eq 'none'){
        # There is no roll
        $output->{type} = 'none';
        $output->{hits}{0} = 100;
    }elsif($act_1 eq 'none' || $act_2 eq 'none'){
        # One player is making a Normal Roll
        $output = execute_backend(@args1, @args2);
        $output->{type} = 'normal';
    }elsif($act_1 eq 'first_strike' && ($act_2 ne 'first_strike')){
        # P1 gets first strike
        $output = execute_backend_simultaneous(\@args1, \@args2);
        $output->{type} = 'first_strike';
        $output->{first_strike} = 1;
    }elsif($act_2 eq 'first_strike' && ($act_1 ne 'first_strike')){
        # P2 gets first strike
        $output = execute_backend_simultaneous(\@args1, \@args2);
        $output->{type} = 'first_strike';
        $output->{first_strike} = 2;
    }elsif($act_1 eq 'normal' || $act_2 eq 'normal'){
        # Simultaneous Normal Rolls
        $output = execute_backend_simultaneous(\@args1, \@args2);
    }else{
        # Face to Face Roll
        $output = execute_backend(@args1, @args2);
        $output->{type} = 'ftf';
    }

    $output->{mods}{1} = $mod_strings_1;
    $output->{mods}{2} = $mod_strings_2;

    return $output;
}

sub print_page{
    my $start = time();

    my $output = generate_output();

    print_head();

    print_top();

    print_output($output);

    print_input();

    my $end = time();

    print_tail($end - $start);
}

if($ARGV[0]){
    my $IN;
    warn "reading parameters from $ARGV[0]";
    open $IN, $ARGV[0] or die;
    restore_parameters($IN);
    close $IN;
}

print_page();
