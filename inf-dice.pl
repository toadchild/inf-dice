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
        <title>Infinity Dice Calculator (N3)</title>
        <link href="inf-dice.css" rel="stylesheet" type="text/css">
        <link href="hitbar.css" rel="stylesheet" type="text/css">
        <script type="text/javascript" src="inf-dice.js"></script>
        <script type="text/javascript" src="unit_data.js"></script>
        <script type="text/javascript" src="weapon_data.js"></script>
        <script type="text/javascript" src="hacking_data.js"></script>
    </head>
    <body onload="init_on_load()">
EOF
}

sub print_top{
    print <<EOF
    <div id="head" class="databox">
    <div class='content'>
    <h1>Infinity Dice Calculator (N3)</h1>
<p>
The Infinity Dice Calculator is a statistical tool for the 3rd Edition of
Infinity (N3).  It is a work in progress and may still have errors.
Please report any issues to <a href="mailto:infinity\@ghostlords.com">
infinity\@ghostlords.com</a>. My other Infinity resources may be found
<a href="http://infinity.ghostlords.com/">here</a>.
</p>
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
the button to see the probabilties for this scenario.
</p>
    </div>
    </div>
EOF
}

my $tag_codes = {
    SHOCK => {fatal => 1, str_resist => 1},
    EM => {fatal => 9, label => 'Disabled', format => '%s hits %3$s%4$s'},
    NONE => {fatal => 0},
};

my $ammo_codes = {
    Normal => {saves => 1},
    Shock => {saves => 1, tag => 'SHOCK'},
    Swarm => {saves => 1, save => 'bts', tag => 'SHOCK'},
    T2 => {saves => 1, dam => 2},
    AP => {saves => 1, ap => 0.5},
    'AP+DA' => {saves => 2, ap => 0.5},
    'AP+EXP' => {saves => 3, ap => 0.5},
    'AP+Shock' => {saves => 1, ap => 0.5, tag => 'SHOCK'},
    DA => {saves => 2},
    'DA+Shock' => {saves => 2, tag => 'SHOCK'},
    EXP => {saves => 3},
    Fire => {saves => 'F', fatal_symbiont => 9},
    Monofilament => {saves => 1, fixed_dam => 12, fatal => 9},
    K1 => {saves => 1, fixed_dam => 12},
    Viral => {saves => 2, save => 'bts', tag => 'SHOCK'},
    Nanotech => {saves => 1, save => 'bts'},
    Flash => {saves => 1, save => 'bts', fatal => 9, label => 'Stunned', format => '%s hits %3$s%4$s', nonlethal => 1},
    Stun => {saves => 2, save => 'bts', fatal => 9, label => 'Stunned', format => '%s hits %3$s%4$s', nonlethal => 1},
    'E/M' => {saves => 1, ap => 0.5, save => 'bts', nonlethal => 1, tag => 'EM'},
    'E/M2' => {saves => 2, ap => 0.5, save => 'bts', nonlethal => 1, tag => 'EM'},
    'Smoke' => {saves => '-', cover => 0, no_lof => 1, dam => 0, format => '%s blocks %3$s with Smoke', nonlethal => 1},
    'Zero-V Smoke' => {saves => '-', cover => 0, no_lof => 1, dam => 0, format => '%s blocks %3$s with Zero-V Smoke', nonlethal => 1},
    'Adhesive' => {saves => 1, alt_save => 'ph', alt_save_mod => -6, fatal => 9, label => 'Immobilized', format => '%s hits %3$s%4$s', nonlethal => 1},
    'Dep. Repeater' => {saves => '-', dam => 0, not_attack => 1, format => '%s places a Deployable Repeater', nonlethal => 1},
    'Breaker' => {saves => 1, save => 'bts', ap => 0.5},
    'DT' => {saves => 2, save => 'bts'},
    'FO' => {saves => '-', format => '%s targets %3$s for 1 Turn', fatal => 9},
    'Plasma' => {saves => 2, save => ['arm', 'bts']},
    'AP+E/M' => {saves => 2, ap => 0.5, save => ['bts', 'arm'], tag => ['EM', 'NONE']},
    Striga => {saves => 1, save => 'bts', format => '%s inflicts %d or more wounds on %s%s - POWER UP (%2$d)'},
    'N+E/M' => {saves => 2, ap => [0.5, 1], save => ['bts', 'arm'], tag => ['EM', 'NONE']},
};

my $skill_codes = {
    'dodge' => {title => 'Dodge', no_lof => 1, dam => 0, format => '%s Dodges %3$s'},
    'change_face' => {title => 'Change Facing', no_lof => 1, dam => 0, format => '%s Dodges %3$s'},
    'reset' => {title => 'Reset', no_lof => 1, dam => 0, format => '%s Resets vs. %3$s'},
};

my $hack_codes = {
    # CLAW-1
    'Blackout' => {mod_att => 0, mod_def => 0, dam => 15, effect => {saves => 1, save => 'bts', format => '%s Disables %3$s'}},
    'Gotcha!' => {mod_att => 0, mod_def => 0, dam => 13, effect => {saves => 1, save => 'bts', format => '%s Immobilizes %3$s for 2 Turns', fatal => 9}},
    'Overlord' => {mod_att => 0, mod_def => 0, dam => 14, effect => {saves => 1, ap => 0.5, save => 'bts', format => '%s Possesses %3$s'}},
    'Spotlight' => {mod_att => -3, mod_def => 0, dam => 0, effect => {saves => '-', save => 'bts', format => '%s Targets %3$s for 1 Turn'}},
    # CLAW-2
    'Expel' => {mod_att => 0, mod_def => 0, dam => 13, effect => {saves => 1, save => 'bts', format => '%s Expels the Pilot of %3$s'}},
    'Oblivion' => {mod_att => 0, mod_def => 0, dam => 16, effect => {saves => 1, save => 'bts', format => '%s Isolates %3$s'}},
    # CLAW-3
    'Basilisk' => {mod_att => 0, mod_def => 0, dam => 13, effect => {saves => 1, save => 'bts', format => '%s Immobilizes %3$s for 2 Turns', fatal => 9}},
    'Carbonite' => {mod_att => 3, mod_def => 0, dam => 13, effect => {saves => 2, save => 'bts', format => '%s Immobilizes %3$s', fatal => 9}},
    'Total Control' => {mod_att => 0, mod_def => 0, dam => 16, effect => {saves => 2, save => 'bts', format => '%s Possesses %3$s', fatal => 9}},
    # SWORD-1
    'Brain Blast' => {mod_att => 0, mod_def => 0, dam => 14, effect => {saves => 1, save => 'bts'}},
    # SWORD-2
    'Redrum' => {mod_att => 0, mod_def => -3, dam => 16, effect => {saves => 2, save => 'bts'}},
    'Skullbuster' => {mod_att => 3, mod_def => 0, dam => 16, effect => {saves => 1, save => 'bts', ap=>0.5}},
    'Trinity' => {mod_att => 0, mod_def => 0, dam => 16, effect => {saves => 1, save => 'bts', tag => 'SHOCK'}},
    # SHIELD-1
    'Exorcism' => {mod_att => 0, mod_def => -3, dam => 18, reset_wip => 11, effect => {saves => 2, save => 'bts', format => '%s Cancels Possession on %3$s', fatal => 9}},
    # SHIELD-2
    'Breakwater' => {mod_att => 0, mod_def => -6, dam => 0, effect => {saves => '-', save => 'bts', format => '%s Defends vs. %3$s'}},
    # SHIELD-3
    'Zero Pain' => {mod_att => 0, mod_def => 0, dam => 0, effect => {saves => '-', save => 'bts', format => '%s Defends vs. %3$s', fatal => 9}},
    # UPGRADE
    'Sucker Punch' => {mod_att => 0, mod_def => -3, dam => 16, effect => {saves => 2, save => 'bts'}},
    'Stop!' => {mod_att => 0, mod_def => 0, dam => 16, effect => {saves => 1, ap => 0.5, save => 'bts', format => '%s Immobilizes %3$s for 2 Turns', fatal => 9}},
    'Exile' => {mod_att => 0, mod_def => 0, dam => 16, effect => {saves => 1, format => '%s Isolates %3$s (Fireteam canceled)', fatal => 9}},
    'Icebreaker' => {mod_att => 0, mod_def => 0, fixed_dam => 12, effect => {saves => 1, format => '%s Immobilizes %3$s', fatal => 9}},
    'Lightning' => {mod_att => 0, mod_def => -6, dam => 15, effect => {saves => 1, save => 'bts', ap => '0.5'}},
    'Maestro' => {mod_att => +3, mod_def => -3, dam => 14, effect => {saves => 1, format => '%s Renders %3$s Unconscious', fatal => 9}},
};

my $ma_codes = {
    1 => {attack => 0, enemy => -3, damage => 1, burst => 0},
    2 => {attack => 0, enemy =>  0, damage => 3, burst => 0},
    3 => {attack => 3, enemy => -3, damage => 0, burst => 0},
    4 => {attack => 0, enemy =>  0, damage => 0, burst => 1},
    5 => {attack => 0, enemy => -6, damage => 0, burst => 0},
};

my $guard_codes = {
    1 => {attack => 0, enemy => -3, damage => 1, burst => 0},
    2 => {attack => 3, enemy =>  0, damage => 1, burst => 0},
    3 => {attack => 0, enemy => -3, damage => 2, burst => 0},
    4 => {attack => 0, enemy =>  0, damage => 3, burst => 0},
};

my $protheion_codes = {
    1 => {attack => 3, enemy =>  0, damage => 1, burst => 0},
    2 => {attack => 0, enemy => -3, damage => 1, burst => 0},
    3 => {attack => 0, enemy =>  0, damage => 3, burst => 0},
    4 => {attack => 0, enemy =>  0, damage => 0, burst => 1},
    5 => {attack => 3, enemy => -3, damage => 0, burst => 0},
};

my $nbw_codes = {
    1 => {attack => 0, enemy => 0, damage => 0, burst => 0},
    2 => {attack => 3, enemy => 0, damage => 1, burst => 0},
};

my $immunity = ['', 'shock', 'bio', 'total'];
my $immunity_labels = {
    '' => 'None',
    'shock' => 'Shock',
    'bio' => 'Bio',
    'total' => 'Total',
};

my $immunities = {
    shock => {Shock => 'arm', SHOCK => 'arm'},
    bio => {Shock => 'arm', SHOCK => 'arm', Viral => 'bts'},
    total => {
        Shock => 'arm',
        SHOCK => 'arm',
        AP => 'arm',
        'AP+DA' => 'arm',
        'AP+EXP' => 'arm',
        'AP+Shock' => 'arm',
        DA => 'arm',
        EXP => 'arm',
        Fire => 'arm',
        Nanotech => 'arm',
        Swarm => 'arm',
        Plasma => 'arm',
        Swarm => 'arm',
        T2 => 'arm',
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

my $link = [0, 3, 5];
my $link_labels = {
    0 => 'None',
    3 => '3 (+1 B)',
    5 => '5 (+1 B, +3 BS)',
};

my $gang_up = [0, 1, 2, 3, 4, 5];
my $gang_up_labels = {
    0 => 'None',
    1 => '1 Ally (+1 B)',
    2 => '2 Allies (+2 B)',
    3 => '3 Allies (+3 B)',
    4 => '4 Allies (+4 B)',
    5 => '5 Allies (+5 B)',
};

my $coordinated = [0, 1, 2, 3];
my $coordinated_labels = {
    0 => 'None',
    1 => '1 Ally (+1 B / PH)',
    2 => '2 Allies (+2 B / PH)',
    3 => '3 Allies (+3 B / PH)',
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

my $evo = [0, 'ice', 'cap', 'sup_1', 'sup_2', 'sup_3'];
my $evo_labels = {
    0 => 'None',
    ice => 'Icebreaker (Halve Opponent BTS)',
    cap => 'Capture (1 WIP Roll to Capture a TAG)',
    sup_1 => 'Support Hacking - 1 Ally (+3 WIP)',
    sup_2 => 'Support Hacking - 2 Allies (+6 WIP)',
    sup_3 => 'Support Hacking - 3 Allies (+9 WIP)',
};

my $marksmanship = [0, 1, 2];
my $marksmanship_labels = {
    0 => 'None',
    1 => 'Level 1',
    2 => 'Level 2',
};

my $xvisor = [0, 1, 2];
my $xvisor_labels = {
    0 => 'None',
    1 => 'X Visor',
    2 => 'X-2 Visor',
};

my $fatality = [0, 1, 2];
my $fatality_labels = {
    0 => 'None',
    1 => 'Level 1',
    2 => 'Level 2',
};

my $full_auto = [0, 1, 2];
my $full_auto_labels = {
    0 => 'None',
    1 => 'Level 1',
    2 => 'Level 2',
};

my $misc_mod = ['+12', '+11', '+10', '+9', '+8', '+7', '+6', '+5', '+4', '+3', '+2', '+1', 0, -1, -2, -3, -4, -5, -6, -7, -8, -9, -10, -11, -12];

my $factions = [
    'Aleph',
    'Ariadna',
    'Combined Army',
    'Haqqislam',
    'Nomads',
    'Non-Aligned Armies',
    'PanOceania',
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
          span_popup_menu(-name => "$player.marksmanship",
              -values => $marksmanship,
              -default => param("$player.marksmanship") // '',
              -labels => $marksmanship_labels,
              -label => "Marksmanship",
          ),
          "<br>",
          span_popup_menu(-name => "$player.xvisor",
              -values => $xvisor,
              -default => param("$player.xvisor") // '',
              -labels => $xvisor_labels,
              -label => 'X Visor',
              -onchange => "set_xvisor('$player')",
          ),
          "<br>",
          span_checkbox(-name => "$player.has_berserk",
              -checked => defined(param("$player.has_berserk")),
              -value => 1,
              -label => 'Berserk',
          ),
          "<br>",
          span_checkbox(-name => "$player.sapper",
              -checked => defined(param("$player.sapper")),
              -value => 1,
              -label => 'Sapper',
              -onchange => "set_sapper_foxhole()",
          ),
          "<br>",
          span_popup_menu(-name => "$player.fatality",
              -values => $fatality,
              -default => param("$player.fatality") // '',
              -labels => $fatality_labels,
              -label => "Fatality",
          ),
          "<br>",
          span_popup_menu(-name => "$player.full_auto",
              -values => $full_auto,
              -default => param("$player.full_auto") // '',
              -labels => $full_auto_labels,
              -label => "Full Auto",
          ),
          "<br>",
          span_checkbox(-name => "$player.remote_presence",
              -checked => defined(param("$player.remote_presence")),
              -value => 1,
              -label => 'G: Remote Presence',
          ),
          "</div>\n";

    print "<div class='action'>
          <h3>Action</h3>",

          popup_menu(-name => "$player.action",
              -onchange => "set_action('$player')",
          ),
          "<br>",
          span_checkbox(-name => "$player.intuitive",
              -checked => defined(param("$player.intuitive")),
              -value => 1,
              -label => "Intuitive Attack",
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
          span_checkbox(-name => "$player.template",
              -checked => defined(param("$player.template")),
              -value => 1,
              -label => 'Template'),
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
          span_popup_menu(-name => "$player.ma",
              -label => "Martial Arts",
          ),
          "<br>",
          span_popup_menu(-name => "$player.guard",
              -label => "Guard",
          ),
          "<br>",
          span_popup_menu(-name => "$player.protheion",
              -label => "Protheion",
          ),
          "<br>",
          span_popup_menu(-name => "$player.nbw",
              -label => "Natural Born Warrior",
          ),
          "<br>",
          span_popup_menu(-name => "$player.gang_up",
              -values => $gang_up,
              -default => param("$player.gang_up") // '',
              -labels => $gang_up_labels,
              -label => "Gang Up",
          ),
          "<br>",
          span_popup_menu(-name => "$player.coordinated",
              -values => $coordinated,
              -default => param("$player.coordinated") // '',
              -labels => $coordinated_labels,
              -label => "Coordinated Order",
          ),
          "<br>",
          span_checkbox(-name => "$player.berserk",
              -checked => defined(param("$player.berserk")),
              -value => 3,
              -label => 'Berserk (+6 CC, Normal Rolls)'),
          "</div>\n";

    print "<div id='$player.sec_hack'>",
          "<h3>Hacking</h3>",
          span_popup_menu(-name => "$player.hacker",
              -label => "Hacking Device",
              -onchange => "set_hacker('$player')",
          ),
          "<br>",
          span_popup_menu(-name => "$player.hack_program",
              -label => "Hacking Program",
              -onchange => "set_hack_program('$player')",
          ),
          "<br>",
          span_popup_menu(-name => "$player.hack_b",
              -label => "B",
          ),
          "</div>\n";

    print "<div id='$player.sec_defense'>",
          "<h3>Defensive Modifiers</h3>",
          span_checkbox(-name => "$player.cover",
              -checked => defined(param("$player.cover")),
              -value => 3,
              -label => 'Cover (+3 ARM, -3 Opponent BS)'),
          "<br>",
          span_checkbox(-name => "$player.foxhole",
              -checked => defined(param("$player.foxhole")),
              -value => 1,
              -label => 'Foxhole (Cover, Mimetism, Courage)'),
          "<br>",
          span_checkbox(-name => "$player.firewall",
              -checked => defined(param("$player.firewall")),
              -value => 3,
              -label => 'Firewall (+3 BTS, -3 Opponent WIP)'),
          "</div>\n";
    print "<div id='$player.sec_other'>",
          "<h3>Other Modifiers</h3>",
          span_popup_menu(-name => "$player.misc_mod",
              -values => $misc_mod,
              -default => param("$player.misc_mod") // 0,
              -label => "Additional Modifier",
          ),
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

    # Array of probability that a certain number of wounds were inflicted.
    # Don't worry about calculating 0 wounds.
    my $results = {
        hits => [],
        cumul_hits => [],
    };

    if(scalar keys %{$output->{hits}{$player}} == 0){
        # empty list, nothing to print
        return $results;
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
    my $remote_presence = param("p$other.remote_presence") // 0;
    my $action = param("p$player.action") // '';
    my $immune = {};

    my $code;
    if($action eq 'hack'){
        my $program = param("p$player.hack_program") // '';
        $code = $hack_codes->{$program}{effect};
        $immunity = '';
        $marksmanship = 0;
        $fatality = 0;
    }else{
        $code = $skill_codes->{$action};
    }
    if(!defined $code){
        $code = $ammo_codes->{$ammo};
    }

    my $fatal = $code->{fatal} // 0;
    my $dam = $code->{dam} // 1;

    # pretty printing
    my $format = $code->{format} // '%s inflicts %d or more wounds on %s%s';

    # thresholds or state changes
    my $unconscious = $wounds;
    my $dead = $wounds + 1;
    my $symb_disabled = -1;
    my $eject = -1;
    my $spawn = -1;
    my $unconscious_2 = -1;

    if($symbiont == 2){
        $symb_disabled = $wounds;
        $unconscious++;
        $dead++;
        if($code->{fatal_symbiont}){
            $fatal = $code->{fatal_symbiont};
        }
    }

    if($symbiont){
        # Make Symbiont armor shock-immune.
        $immunity = 'shock';
    }

    if($operator_w){
        $unconscious += $operator_w;
        $dead += $operator_w;
        $eject = $wounds;
    }

    if($shasvastii){
        $spawn = $unconscious;
        $unconscious = -1;
    }

    if($nwi){
        $unconscious = -1;
        if($w_type eq 'STR' && $remote_presence){
            $dead++;
        }
    }

    if($unconscious != -1 && $w_type eq 'STR' && $remote_presence){
        $unconscious_2 = $unconscious + 1;
        $dead++;
    }

    if($fatal >= $wounds && !$immunities->{$immunity}{$ammo}){
        # This ammo is instantly fatal, and we are not immune
        $dead = 1;
    }

    my $cumul_hits = $output->{cumul_hits}{$player};
    my $hits = $output->{hits}{$player};
    for my $tag_name (keys %{$output->{tagged_cumul_hits}{$player}}){
        my $tag = $tag_codes->{$tag_name};
        if($tag->{fatal} >= $wounds && !$immunities->{$immunity}{$tag_name} && !($w_type eq 'STR' && $tag->{str_resist})){
            $hits = $output->{tagged_hits}{$player}{NONE};
            $cumul_hits = $output->{tagged_cumul_hits}{$player}{NONE};
        }else{
            $immune->{$tag_name} = 1;
        }
    }

    print "<h3>$player_labels->{$player}</h3>";
    print "<p>\n";

    my @labels;
    my @formats;
    my $max_h = 0;
    for my $h (sort {$a <=> $b} keys %$hits){
        my $done;

        $max_h = $h;
        my $w = $h * $dam + $w_taken;

        if($w >= $dead){
            $label = sprintf " (%s)", $code->{label} // 'Dead';
            $done = 1;
        }elsif($w == $symb_disabled){
            $label = ' (Symbiont Disabled)';
        }elsif($w == $eject){
            $label = ' (Operator Ejected)';
        }elsif($w == $unconscious){
            $label = ' (Unconscious)';
        }elsif($w == $unconscious_2){
            $label = ' (Unconscious 2)';
        }elsif($w == $spawn){
            $label = ' (Spawn Embryo)';
        }elsif($operator_w && $w > $eject){
            $label = ' (Operator ' . ($wounds + $operator_w - $w) . ' W)';
        }else{
            $label = ' (' . ($wounds - $w) . " $w_type)";
        }

        $results->{hits}[$h] = $hits->{$h};
        $results->{cumul_hits}[$h] = $cumul_hits->{$h};
        $labels[$h] = $label;
        $formats[$h] = $format;

        if($done){
            last;
        }
    }

    # 1+ hits with shock is instant death
    for my $tag_name (keys %{$output->{tagged_cumul_hits}{$player}}){
        my $tag = $tag_codes->{$tag_name};
        if(!$immune->{$tag_name}){
            # If the label is something, then they aren't killed
            my $i;
            if($tag->{label}){
                $i = 0;
                $results->{hits}[$i] = 0;
                $results->{cumul_hits}[$i] = 0;
            }else{
                $i = $dead;
            }
            $labels[$i] = sprintf " (%s)", $tag->{label} // 'Dead';
            $results->{hits}[$i] += $output->{tagged_cumul_hits}{$player}{$tag_name}{1};
            $results->{cumul_hits}[$i] += $output->{tagged_cumul_hits}{$player}{$tag_name}{1};
            if($tag->{format}){
                $formats[$i] = $tag->{format};
            }else{
                $formats[$i] = $format;
            }
        }
    }

    for(my $h = 0; $h < scalar @{$results->{cumul_hits}}; $h++){
        if(defined $results->{cumul_hits}[$h]){
            printf "<span class='p$player-hit-$h hit_chance'>%.2f%%</span> ", $results->{cumul_hits}[$h];
            printf "$formats[$h]<br>\n", $name, $h, $other_name, $labels[$h];
        }
    }

    print "</p>\n";

    return $results;
}

sub print_miss_output{
    my ($output, $text) = @_;

    print "<h3>Failures</h3>\n";
    printf "<span class='miss hit_chance'>%.2f%%</span> $text<br>\n", $output->{hits}{0};
}

sub print_hitbar_player{
    my ($output, $sort, $p, $results) = @_;

    if(!defined $results->{hits}){
        return;
    }

    for(my $i = 0; $i < scalar @{$results->{hits}}; $i++){
        my $h = $i;
        if($sort < 0){
            $h = scalar @{$results->{hits}} - $i - 1;
        }
        my $width = $results->{hits}[$h];
        if(defined $width){
            my $label = $h;
            if($h == scalar @{$results->{cumul_hits}} - 1){
                $width = $results->{cumul_hits}[$h];
                if($width > $results->{hits}[$h]){
                    $label .= '+';
                }
            }

            print "<td style='width: $width%;' class='p$p-hit-$h'>";
            if($width >= 3.0){
                print $label;
            }
            print "</td>\n";
        }
    }
}

sub print_hitbar_output{
    my ($output, $hits_1, $hits_2) = @_;

    print "<table class='hitbar'><tr>\n";

    print_hitbar_player($output, -1, 1, $hits_1);

    if($output->{hits}{0}){
        print "<td style='width: $output->{hits}{0}%;' class='miss'>";
        if($output->{hits}{0} >= 3.0){
            print "0";
        }
        print "</td>\n";
    }

    print_hitbar_player($output, 1, 2, $hits_2);

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
        my $hits_1 = print_player_output($output, 1, 2);

        print_miss_output($output, 'Neither player succeeds');

        my $hits_2 = print_player_output($output, 2, 1);

        print_hitbar_output($output, $hits_1, $hits_2);
    }
}

sub print_normal_output{
    my ($output) = @_;

    print "<h2>Normal Roll</h2>\n";
    print_roll_subtitle();

    if($output->{hits}){
        my $hits_1 = print_player_output($output, 1, 2);
        my $hits_2 = print_player_output($output, 2, 1);

        print_miss_output($output, 'No success');

        print_hitbar_output($output, $hits_1, $hits_2);
    }
}

sub print_simultaneous_output{
    my ($output) = @_;

    print "<h2>Simultaneous Normal Rolls</h2>\n";
    print_roll_subtitle();

    my ($hits_1, $hits_2);

    if($output->{A}{hits}){
        $hits_1 = print_player_output($output->{A}, 1, 2);

        print_miss_output($output->{A}, 'No success');
    }

    if($output->{B}{hits}){
        $hits_2 = print_player_output($output->{B}, 2, 1);

        print_miss_output($output->{B}, 'No success');
    }

    if($output->{A}{hits}){
        print_hitbar_output($output->{A}, $hits_1, undef);
    }

    if($output->{B}{hits}){
        print_hitbar_output($output->{B}, undef, $hits_2);
    }
}

sub print_none_output{
    my ($output) = @_;

    print "<h2>No Roll</h2>\n";
    if($output->{hits}){
        print_miss_output($output->{B}, 'Nothing happens');

        print_hitbar_output($output, undef, undef);
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
Please direct any feedback to <a href="mailto:infinity\@ghostlords.com">infinity\@ghostlords.com</a>.<br>
<a href="http://infinitythegame.com/">Infinity the Game</a> is &copy; Corvus Belli SLL.<br>
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

# Protheion requires both a skill and a weapon
sub check_protheion{
    my ($player) = @_;
    my $protheion = param("$player.protheion") // 0;
    my $ammo_name = param("$player.ammo") // '';
    if($ammo_name eq 'Striga'){
        return $protheion;
    }
    return 0;
}

sub gen_attack_args{
    my ($us, $them) = @_;
    my ($link_bs, $link_b) = (0, 0);
    my ($ap, $ammo, $cover, $ignore_cover, $save, $dam, $tag);
    my @dam;
    my @arm = ();
    my @tag = ();
    my $b;
    my ($stat_name, $stat);
    my ($ammo_name, $code, $immunity);
    my $type;
    my @mod_strings;

    if((param("$us.link") // 0) >= 3){
        $link_b = 1;
    }

    if((param("$us.link") // 0) >= 5){
        $link_bs = 3;
    }

    $ammo_name = param("$us.ammo") // 'Normal';
    $code = $ammo_codes->{$ammo_name};
    $immunity = param("$them.immunity") // '';

    $dam = param("$us.dam") // 0;

    my $ph_dam = 0;
    if($dam eq 'PH'){
        $dam = param("$us.ph") // 0;
        $ph_dam = 1;
    }elsif($dam eq 'PH-1'){
        $dam = (param("$us.ph") // 1) - 1;
        $ph_dam = 1;
    }elsif($dam eq 'PH-2'){
        $dam = (param("$us.ph") // 2) - 2;
        $ph_dam = 1;
    }

    # Total Immunity ignores most ammo types
    if($immunities->{$immunity}{$ammo_name}){
        $ap = 1;
        $save = $immunities->{$immunity}{$ammo_name};
        $ammo = 1;
        $tag = 'NONE';

        # Bioimmunity choses the higher of ARM or BTS vs. Shock
        if($immunity eq 'bio'){
            if(lc($ammo_name) eq 'shock'){
                my $arm = param("$them.arm") // 0;
                my $bts = param("$them.bts") // 0;
                if($bts > $arm){
                    $save = 'bts';
                }
            }
        }
    }else{
        $ap = $code->{ap} // 1;
        $save = $code->{save} // 'arm';
        $ammo = $code->{saves};
        $tag = $code->{tag} // 'NONE';
    }

    # convert dam into array
    if($ammo eq '2'){
        @dam = ($dam) x 2;;
    }elsif($ammo eq '3'){
        @dam = ($dam) x 3;
    }else{
        @dam = ($dam);
    }

    # also convert arm to array
    if(ref($save) eq 'ARRAY'){
        for(my $s = 0; $s < @$save; $s++){
            my $save_stat = $save->[$s];
            my $save_ap;
            if (ref($ap) eq 'ARRAY') {
                $save_ap = $ap->[$s];
            } else {
                $save_ap = $ap;
            }
            push @arm, ceil(abs(param("$them.$save_stat") // 0) * $save_ap);
        }
    }else{
        @arm = (ceil(abs(param("$them.$save") // 0) * $ap)) x scalar @dam;
    }

    # construct a tag array
    if(ref($tag) eq 'ARRAY'){
        for my $t (@$tag){
            push @tag, $t;
        }
    }else{
        @tag = ($tag) x scalar @dam;
    }

    # Monofilament and K1 have fixed damage
    if($code->{fixed_dam}){
        map { $_ = 0 } @arm;
        map { $_ = $code->{fixed_dam} } @dam;
    }

    my $sapper = (param("$them.sapper") // 0);
    my $foxhole = 0;
    if($sapper){
        $foxhole = (param("$them.foxhole") // 0);
    }

    $cover = (param("$them.cover") // 0);
    # Foxhole grants Cover
    if($foxhole){
        $cover = 3;
    }
    $ignore_cover = $code->{cover} // 1;
    $cover *= $ignore_cover;

    my $action = param("$us.action");
    my $other_action = param("$them.action");

    # look up their skill/ammo code
    my $other_code = $skill_codes->{$other_action};
    if(!defined $other_code){
        $other_code = $ammo_codes->{param("$them.ammo") // 'Normal'};
    }

    if($action eq 'bs' || $action eq 'supp'){
        # BS mods
        $type = 'ftf';

        # look up stat to use
        $stat_name = lc(param("$us.stat") // 'bs');
        $stat = param("$us.$stat_name") // 0;
        my $mod = 0;
        $stat_name = uc($stat_name);

        push @mod_strings, "Base $stat_name of $stat";

        my $marksmanship = param("$us.marksmanship") // 0;

        my $fatality = param("$us.fatality") // 0;

        my $full_auto = param("$us.full_auto") // 0;
        my $them_full_auto = param("$them.full_auto") // 0;

        my $camo = param("$them.ch") // 0;
        # Foxhole grants Mimetism
        if($foxhole && $camo == 0){
            $camo = -3;
        }

        $camo *= $ignore_cover;

        if($cover){
            if($marksmanship < 2){
                push @mod_strings, sprintf('Cover grants %+d %s', -$cover, $stat_name);
                $mod -= $cover;
            }else{
                push @mod_strings, sprintf('Marksmanship L2 negates Cover modifier to %s', $stat_name);
            }
        }

        if($marksmanship >= 1 && $stat_name eq 'BS' && !$code->{nonlethal}){
            if($save eq 'bts'){
                # Marksmanship L1 adds Shock; makes a second save if first is on BTS
                $save = [('bts') x scalar @dam, 'arm'];
                push @dam, $dam[0];
                push @arm, ceil(abs(param("$them.arm") // 0));
                push @tag, 'SHOCK';
                $ammo++;
                push @mod_strings, sprintf('Marksmanship L1 grants aditional ARM save at DAM %d', $dam[$#dam]);
            }else{
                for(my $i = 0; $i < scalar @tag; $i++){
                    $tag[$i] = 'SHOCK';
                }
            }
        }

        if($link_bs){
            push @mod_strings, sprintf('Link Team grants %+d %s', $link_bs, $stat_name);
            $mod += $link_bs;
        }

        my $msv = param("$us.msv") // 0;
        if($msv >= 1 && $camo == -3){
            push @mod_strings, "MSV ignores CH modifier";
            $camo = 0;
        }elsif($msv >= 2 && $camo < 0){
            push @mod_strings, "MSV ignores CH/ODD modifier";
            $camo = 0;
        }elsif($msv == 1 && $camo == -6){
            $camo += 3;
            push @mod_strings, sprintf('MSV reduces CH/ODD modifier to %+d %s', $camo, $stat_name);
            $mod += $camo;
        }elsif($camo < 0){
            push @mod_strings, sprintf('CH/ODD grants %+d %s', $camo, $stat_name);
            $mod += $camo;
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
            $mod += $viz;
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
        $mod += $range;

        my $misc_mod = param("$us.misc_mod") // 0;
        if($misc_mod){
            push @mod_strings, sprintf('Additional modifier grants %+d %s', $misc_mod, $stat_name);
            $mod += $misc_mod;
        }

        $b = (param("$us.b") // 1);
        if($link_b){
            push @mod_strings, sprintf('Link Team grants %+d B', $link_b);
            $b += $link_b;
        }

        if($cover){
            # template weapons ignore the ARM bonus of cover
            if(param("$us.template") // 0){
                push @mod_strings, sprintf('Template weapon ignores ARM bonus from cover');
            }elsif($ammo_name eq 'Monofilament'){
                push @mod_strings, sprintf('Monofilament ignored ARM bonus from cover.');
            }else{
                push @mod_strings, sprintf('Cover grants opponent %+d ARM', $cover);
                map { $_ += $cover} @arm;
            }
        }

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

        # CC modifiers affect us if they are using a CC skill
        if($other_action eq 'cc'){
            my $them_ma = param("$them.ma") // 0;
            my $them_guard = param("$them.guard") // 0;
            my $them_protheion = check_protheion($them);

            # Penalties from their CC skills
            if($them_ma){
                if(param("$us.nbw") != 1){
                    if(my $ma_att = $ma_codes->{$them_ma}{enemy}){
                        push @mod_strings, sprintf('Opponent Martial Arts grants %+d %s', $ma_att, $stat_name);
                        $mod += $ma_att;
                    }
                }else{
                    push @mod_strings, 'Opponent Martial Arts canceled by Natural Born Warrior A';
                }
            }
            if($them_guard){
                if(param("$us.nbw") != 1){
                    if(my $guard_att = $guard_codes->{$them_guard}{enemy}){
                        push @mod_strings, sprintf('Opponent Guard grants %+d %s', $guard_att, $stat_name);
                        $mod += $guard_att;
                    }
                }else{
                    push @mod_strings, 'Opponent Guard canceled by Natural Born Warrior A';
                }
            }
            if($them_protheion){
                if(param("$us.nbw") != 1){
                    if(my $protheion_att = $protheion_codes->{$them_protheion}{enemy}){
                        push @mod_strings, sprintf('Opponent Protheion grants %+d %s', $protheion_att, $stat_name);
                        $mod += $protheion_att;
                    }
                }else{
                    push @mod_strings, 'Opponent Protheion canceled by Natural Born Warrior A';
                }
            }
        }

        # Fatality
        if($fatality >= 1){
            if(!$code->{fixed_dam} && $stat_name eq 'BS'){
                push @mod_strings, "Fatality grants +1 DAM";
                map { $_ += 1 } @dam;
            }else{
                push @mod_strings, sprintf('Fatality DAM bonus ignored by %s', param("$us.weapon") // "");
            }
        }

        # Full Auto
        # Only applies burst bonus on active turn shooting
        if($full_auto >= 1 && $action eq 'bs'){
            if ($us eq 'p1') {
                if (!$link_b) {
                    push @mod_strings, 'Full Auto grants +1 B';
                    $b += 1;
                } else {
                    push @mod_strings, 'Full Auto B bonus does not stack with fireteams';
                }
            } else {
                push @mod_strings, 'Full Auto B bonus only applies to the active turn';
            }
        }

        # Full Auto L2 defensive bonus
        if($other_action eq 'bs' && $them_full_auto >= 2){
            $mod -= 3;
            push @mod_strings, "Opponent Full Auto grants -3 $stat_name";
        }

        # Enemy Suppressive Fire
        if($other_action eq 'supp'){
            $mod -= 3;
            push @mod_strings, "Opponent Suppressive Fire grants -3 $stat_name";
        }

        if($mod < -12){
            push @mod_strings, "Modifier capped at -12";
            $mod = -12;
        }elsif($mod > 12){
            push @mod_strings, "Modifier capped at 12";
            $mod = 12;
        }
        $stat = max($stat + $mod, 0);
        push @mod_strings, "Net $stat_name is $stat";

        if($fatality >= 2){
            if($stat_name eq 'BS'){
                push @mod_strings, "Weapon also crits on a 1";
                $stat .= "!";
            }else{
                push @mod_strings, sprintf('Fatality crit bonus ignored by %s', param("$us.weapon") // "");
            }
        }

    }elsif($action eq 'dtw'){
        # DTW mods
        $type = 'normal';

        if(param("$us.intuitive")){
            $stat = (param("$us.wip") // 0);
            # Intuitive is FtF roll.
            $type = 'ftf';
        }else{
            $stat = 'T';
        }

        $b = (param("$us.b") // 1);
        if($link_b){
            push @mod_strings, sprintf('Link Team grants %+d B', $link_b);
            $b += $link_b;
        }

        # templates are FTF against Dodge
        if($other_action eq 'dodge' || $other_action eq 'change_face'){
            $type = 'ftf';
        }

    }elsif($action eq 'deploy'){
        # DTW mods
        $type = 'normal';

        $stat = 'T';

        # One mine at a time, for now
        $b = 1;

        # templates are FTF against Dodge
        if($other_action eq 'dodge' || $other_action eq 'change_face'){
            $type = 'ftf';
        }

    }elsif($action eq 'spec'){
        # Speculative Shot
        $type = 'ftf';

        # look up stat to use
        $stat_name = lc(param("$us.stat") // 'bs');
        $stat = param("$us.$stat_name") // 0;
        $stat_name = uc($stat_name);
        my $them_full_auto = param("$them.full_auto") // 0;
        my $mod = 0;

        push @mod_strings, "Base $stat_name of $stat";

        push @mod_strings, sprintf('Speculative Shot grants -6 %s',  $stat_name);
        $mod -= 6;

        # Range comes in as 0-8/+3 OR +3
        # Select only the final number
        my $range = param("$us.range") // 0;
        $range =~ m/(-?\d+)$/;
        $range = $1;
        push @mod_strings, sprintf('Range grants %+d %s', $range,  $stat_name);
        $mod += $range;

        my $misc_mod = param("$us.misc_mod") // 0;
        if($misc_mod){
            push @mod_strings, sprintf('Additional modifier grants %+d %s', $misc_mod, $stat_name);
            $mod += $misc_mod;
        }

        $b = (param("$us.b") // 1);

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

        if($link_bs){
            push @mod_strings, sprintf('Link Team grants %+d %s', $link_bs, $stat_name);
            $mod += $link_bs;
        }

        # Full Auto L2 defensive bonus
        if($type eq 'ftf' && $other_action eq 'bs' && $them_full_auto >= 2){
            $mod -= 3;
            push @mod_strings, "Opponent Full Auto grants -3 $stat_name";
        }

        # Enemy Suppressive Fire
        if($type eq 'ftf' && $other_action eq 'supp'){
            $mod -= 3;
            push @mod_strings, "Opponent Suppressive Fire grants -3 $stat_name";
        }

        if($mod < -12){
            push @mod_strings, "Modifier capped at -12";
            $mod = -12;
        }elsif($mod > 12){
            push @mod_strings, "Modifier capped at 12";
            $mod = 12;
        }
        $stat = max($stat + $mod, 0);
        push @mod_strings, "Net $stat_name is $stat";

    }elsif($action eq 'cc'){
        # CC mods
        $type = 'ftf';

        $stat = param("$us.cc") // 0;
        push @mod_strings, "Base CC of $stat";
        my $mod = 0;

        my $us_ma = param("$us.ma") // 0;
        my $them_ma = param("$them.ma") // 0;
        my $us_guard = param("$us.guard") // 0;
        my $them_guard = param("$them.guard") // 0;
        my $us_protheion = check_protheion($us);
        my $them_protheion = check_protheion($them);
        my $us_nbw = param("$us.nbw") // 0;
        my $them_full_auto = param("$them.full_auto") // 0;

        # We must have berserk and they must not have NBW
        if(param("$us.has_berserk") && param("$us.berserk")){
            if(param("$them.nbw") != 1){
                $mod += 6;
                $type = 'normal';
                push @mod_strings, 'Berserk grants +6 CC';
            }else{
                push @mod_strings, 'Berserk canceled by Natural Born Warrior A';
            }
        }

        # iKohl does not work on models with STR
        my $ikohl = param("$them.ikohl") // 0;
        my $w_type = param("$us.w_type") // 'W';
        if($ikohl){
            if($w_type eq 'STR'){
                $ikohl = 0;
                push @mod_strings, 'STR ignores i-Kohl';
            }else{
                push @mod_strings, sprintf('i-Kohl grants %+d CC', $ikohl);
                $mod += $ikohl;
            }
        }

        $b = 1;

        # Bonuses from our CC skills
        if($us_ma){
            if(param("$them.nbw") != 1){
                if(my $ma_att = $ma_codes->{$us_ma}{attack}){
                    push @mod_strings, sprintf('Martial Arts grants %+d CC', $ma_att);
                    $mod += $ma_att;
                }
                if(my $ma_dam = $ma_codes->{$us_ma}{damage}){
                    if($ph_dam){
                        push @mod_strings, sprintf('Martial Arts grants %+d DAM', $ma_dam);
                        map { $_ += $ma_dam } @dam;
                    }else{
                        push @mod_strings, sprintf('Martial Arts DAM bonus ignored by %s', param("$us.weapon") // "");
                    }
                }
                if(my $ma_b = $ma_codes->{$us_ma}{burst}){
                    push @mod_strings, sprintf('Martial Arts grants %+d B', $ma_b);
                    $b += $ma_b;
                }
            }else{
                push @mod_strings, 'Martial Arts canceled by Natural Born Warrior A';
            }
        }
        if($us_guard){
            if(param("$them.nbw") != 1){
                if(my $guard_att = $guard_codes->{$us_guard}{attack}){
                    push @mod_strings, sprintf('Guard grants %+d CC', $guard_att);
                    $mod += $guard_att;
                }
                if(my $guard_dam = $guard_codes->{$us_guard}{damage}){
                    if($ph_dam){
                        push @mod_strings, sprintf('Guard grants %+d DAM', $guard_dam);
                        map { $_ += $guard_dam } @dam;
                    }else{
                        push @mod_strings, sprintf('Guard DAM bonus ignored by %s', param("$us.weapon") // "");
                    }
                }
            }else{
                push @mod_strings, 'Guard canceled by Natural Born Warrior A';
            }
        }
        if($us_protheion){
            if(param("$them.nbw") != 1){
                if(my $protheion_att = $protheion_codes->{$us_protheion}{attack}){
                    push @mod_strings, sprintf('Protheion grants %+d CC', $protheion_att);
                    $mod += $protheion_att;
                }
                if(my $protheion_dam = $protheion_codes->{$us_protheion}{damage}){
                    if($ph_dam){
                        push @mod_strings, sprintf('Protheion grants %+d DAM', $protheion_dam);
                        map { $_ += $protheion_dam } @dam;
                    }else{
                        push @mod_strings, sprintf('Protheion DAM bonus ignored by %s', param("$us.weapon") // "");
                    }
                }
                if(my $protheion_b = $protheion_codes->{$us_protheion}{burst}){
                    push @mod_strings, sprintf('Protheion grants %+d B', $protheion_b);
                    $b += $protheion_b;
                }
            }else{
                push @mod_strings, 'Protheion canceled by Natural Born Warrior A';
            }
        }
        if($us_nbw){
            if(param("$them.nbw") != 1){
                if(my $nbw_att = $nbw_codes->{$us_nbw}{attack}){
                    push @mod_strings, sprintf('Natural Born Warrior B grants %+d CC', $nbw_att);
                    $mod += $nbw_att;
                }
                if(my $nbw_dam = $nbw_codes->{$us_nbw}{damage}){
                    if($ph_dam){
                        push @mod_strings, sprintf('Natural Born Warrior B grants %+d DAM', $nbw_dam);
                        map { $_ += $nbw_dam } @dam;
                    }else{
                        push @mod_strings, sprintf('Natural Born Warrior B DAM bonus ignored by %s', param("$us.weapon") // "");
                    }
                }
            }else{
                push @mod_strings, 'Natural Born Warrior B canceled by Natural Born Warrior A';
            }
        }
        # Special case for D-Charges; -3 to CC roll
        if (param("$us.weapon") eq 'D-Charges (CC Mode)') {
            $mod -= 3;
            push @mod_strings, 'D-Charges grant -3 to CC';
        }

        # Penalties from their MA skill
        if($other_action eq 'cc'){
            if($them_ma){
                if(param("$us.nbw") != 1){
                    if(my $ma_att = $ma_codes->{$them_ma}{enemy}){
                        push @mod_strings, sprintf('Opponent Martial Arts grants %+d CC', $ma_att);
                        $mod += $ma_att;
                    }
                }else{
                    push @mod_strings, 'Opponent Martial Arts canceled by Natural Born Warrior A';
                }
            }
            if($them_guard){
                if(param("$us.nbw") != 1){
                    if(my $guard_att = $guard_codes->{$them_guard}{enemy}){
                        push @mod_strings, sprintf('Opponent Guard grants %+d CC', $guard_att);
                        $mod += $guard_att;
                    }
                }else{
                    push @mod_strings, 'Opponent Guard canceled by Natural Born Warrior A';
                }
            }
            if($them_protheion){
                if(param("$us.nbw") != 1){
                    if(my $protheion_att = $protheion_codes->{$them_protheion}{enemy}){
                        push @mod_strings, sprintf('Opponent Protheion grants %+d CC', $protheion_att);
                        $mod += $protheion_att;
                    }
                }else{
                    push @mod_strings, 'Opponent Protheion canceled by Natural Born Warrior A';
                }
            }
        }

        # gang up bonus
        my $gang_up = param("$us.gang_up") // 0;
        my $coordinated = param("$us.coordinated") // 0;
        if($gang_up){
            push @mod_strings, sprintf('Gang-up grants %+d B', $gang_up);
            $b += $gang_up;
        }
        # coordinated orders/antipodes
        elsif($coordinated){
            push @mod_strings, sprintf('Coordinated Order grants %+d B', $coordinated);
            $b += $coordinated;
            if($ph_dam){
                push @mod_strings, sprintf('Coordinated Order grants %+d DAM', $coordinated);
                map { $_ += $coordinated } @dam;
            }else{
                push @mod_strings, sprintf('Coordinated Order DAM bonus ignored by %s', param("$us.weapon") // "");
            }
        }
        
        # If we have MA 5 and they are coordinating, increase B to match
        my $them_b_bonus = param("$them.gang_up") // 0;
        if(!$them_b_bonus){
            $them_b_bonus = param("$them.coordinated") // 0;
        }
        if(my $them_ma_b = $ma_codes->{$them_ma}{burst}){
            $them_b_bonus += $them_ma_b;
        }
        if(my $them_protheion_b = $protheion_codes->{$them_protheion}{burst}){
            $them_b_bonus += $them_protheion_b;
        }
        if($other_action eq 'cc' && $us_ma >= 5 && ($them_b_bonus)){
            if(param("$them.nbw") != 1){
                push @mod_strings, sprintf('Martial Arts grants %+d B', $them_b_bonus);
                $b += $them_b_bonus;
            }else{
                push @mod_strings, 'Martial Arts 5 B bonus canceled by Natural Born Warrior A';
            }
        }

        my $misc_mod = param("$us.misc_mod") // 0;
        if($misc_mod){
            push @mod_strings, sprintf('Additional modifier grants %+d CC', $misc_mod);
            $mod += $misc_mod;
        }

        # Full Auto L2 defensive bonus
        if($other_action eq 'bs' && $them_full_auto >= 2){
            $mod -= 3;
            push @mod_strings, "Opponent Full Auto grants -3 CC";
        }

        # Enemy Suppressive Fire
        if($other_action eq 'supp'){
            $mod -= 3;
            push @mod_strings, "Opponent Suppressive Fire grants -3 CC";
        }

        if($mod < -12){
            push @mod_strings, "Modifier capped at -12";
            $mod = -12;
        }elsif($mod > 12){
            push @mod_strings, "Modifier capped at 12";
            $mod = 12;
        }
        $stat = max($stat + $mod, 0);
        push @mod_strings, "Net CC is $stat";
    }

    # @tag_dam contains (damage, tag) pairs.
    my @tag_dam;
    if(!$code->{alt_save}){
        while(@dam){
            push @tag_dam, max(shift(@dam) - shift(@arm), 0);
            push @tag_dam, shift(@tag);
        }
    }else{
        # Adhesive makes a PH saving throw instead of DAM - ARM check
        @tag_dam = (20 - max(param("$them.$code->{alt_save}") + $code->{alt_save_mod}, 0), @tag);
    }

    return (
        $type,
        \@mod_strings,
        $stat,
        $b,
        $ammo,
        @tag_dam,
    );
}

sub gen_hack_args{
    my ($us, $them) = @_;

    my $action = param("$us.action");
    my $other_action = param("$them.action");
    my $program = param("$us.hack_program") // "";
    my $code = $hack_codes->{$program};

    my @mod_strings;
    my $type = 'ftf';
    my $b = param("$us.hack_b") // 1;
    my $dam = $code->{dam} // 0;
    my $ammo = $code->{effect}{saves} // '1';
    my $ap = $code->{effect}{ap} // 1;
    my $bts = ceil((param("$them.bts") // 0) * $ap);
    my $tag = $code->{effect}{tag} // 'NONE';

    # Dodge does not protect against hacking
    if($other_action eq 'dodge' || $other_action eq 'change_face'){
        $type = 'normal';
    }

    my $stat = param("$us.wip") // 0;
    my $mod = 0;
    push @mod_strings, "Base WIP of $stat";

    if($code->{mod_att}){
        push @mod_strings, sprintf('Hacking program grants %+d WIP', $code->{mod_att});
        $mod += $code->{mod_att};
    }

    # Opponent's Hacking modifier
    if($other_action eq 'hack'){
        my $other_program = param("$them.hack_program") // "";
        my $other_code = $hack_codes->{$other_program};
        if($other_code->{mod_def}){
            push @mod_strings, sprintf('Opponent\'s hacking program grants %+d WIP', $other_code->{mod_def});
            $mod += $other_code->{mod_def};
        }
    }

    my $misc_mod = param("$us.misc_mod") // 0;
    if($misc_mod){
        push @mod_strings, sprintf('Additional modifier grants %+d WIP', $misc_mod);
        $mod += $misc_mod;
    }

    # Firewall is like cover for hacking.
    my $firewall = (param("$them.firewall") // 0);
    if($firewall){
        push @mod_strings, sprintf('Firewall grants %+d WIP', -$firewall);
        $mod -= $firewall;
        push @mod_strings, sprintf('Cover grants opponent %+d BTS', $firewall);
        $bts += $firewall
    }

    if($mod < -12){
        push @mod_strings, "Modifier capped at -12";
        $mod = -12;
    }elsif($mod > 12){
        push @mod_strings, "Modifier capped at 12";
        $mod = 12;
    }
    $stat = max($stat + $mod, 0);
    push @mod_strings, "Net WIP is $stat";

    $dam = max($dam - $bts, 0);
    # Icebreaker ignores BTS
    if($code->{fixed_dam}){
        $dam = $code->{fixed_dam};
    }
    my @dam;
    if($ammo eq '2'){
        @dam = ($dam, $dam);
    }elsif($ammo eq '3'){
        @dam = ($dam, $dam, $dam);
    }else{
        @dam = ($dam);
    }

    my @tag_dam;
    while(@dam){
        push @tag_dam, shift(@dam);
        push @tag_dam, $tag;
    }

    return (
        $type,
        \@mod_strings,
        $stat,
        $b,
        $ammo,
        @tag_dam,
    );
}

sub gen_reset_args{
    my ($us, $them) = @_;
    my $other_action = param("$them.action");
    my $mod = 0;
    my @mod_strings;

    my $stat = param("$us.wip") // 0;
    push @mod_strings, "Base WIP of $stat";

    # Reset only works against Hacking
    my $type = 'normal';
    if(param("$them.action") eq 'hack'){
        $type = 'ftf';
    }

    # Opponent's Hacking modifier
    if($other_action eq 'hack'){
        my $other_program = param("$them.hack_program") // "";
        my $other_code = $hack_codes->{$other_program};

        # Possessed TAGs have a restricted WIP
        if($other_code->{reset_wip}){
            push @mod_strings, sprintf('Possessed TAG limited to WIP %d', $other_code->{reset_wip});
            $stat = $other_code->{reset_wip};
        }

        if($other_code->{mod_def}){
            push @mod_strings, sprintf('Opponent\'s hacking program grants %+d WIP', $other_code->{mod_def});
            $mod += $other_code->{mod_def};
        }
    }

    my $misc_mod = param("$us.misc_mod") // 0;
    if($misc_mod){
        push @mod_strings, sprintf('Additional modifier grants %+d WIP', $misc_mod);
        $stat += $misc_mod;
    }

    if($mod < -12){
        push @mod_strings, "Modifier capped at -12";
        $mod = -12;
    }elsif($mod > 12){
        push @mod_strings, "Modifier capped at 12";
        $mod = 12;
    }
    $stat = max($stat + $mod, 0);
    push @mod_strings, "Net WIP is $stat";

    return (
        $type,
        \@mod_strings,
        $stat,
        1,
        '-',
        0,
        'NONE',
    );
}

sub gen_dodge_args{
    my ($us, $them, $change_face) = @_;
    my @mod_strings;

    my $dodge_unit = 0;
    my $unit_type = param("$us.type") // '';
    my $motorcycle = param("$us.motorcycle") // 0;
    if($unit_type eq 'REM' || $motorcycle){
        $dodge_unit = -3;
    } elsif($unit_type eq 'TAG'){
        $dodge_unit = -6;
    }

    my $stat = param("$us.ph") // 0;
    push @mod_strings, "Base PH of $stat";

    if($change_face){
        push @mod_strings, sprintf('Change facing grants %+d PH', $change_face);
        $stat += $change_face;
    }

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

    if(param("$them.action") eq 'dodge' || param("$them.action") eq 'change_face'){
        # double-dodge is normal rolls
        $type = 'normal';
    }

    if(param("$them.action") eq 'deploy' && !$change_face){
        # -3 penalty to dodge mines, but is already included in change facing
        $stat -= 3;
        push @mod_strings, sprintf('Dodging a deployable grants -3 PH');
    }

    my $misc_mod = param("$us.misc_mod") // 0;
    if($misc_mod){
        push @mod_strings, sprintf('Additional modifier grants %+d PH', $misc_mod);
        $stat += $misc_mod;
    }

    $stat = max($stat, 0);
    push @mod_strings, "Net PH is $stat";

    return (
        $type,
        \@mod_strings,
        $stat,
        1,
        '-',
        0,
        'NONE',
    );
}

sub gen_none_args{
    return (
        'none',
        [],
        0,
        1,
        '-',
        0,
        'NONE',
    );
}

sub gen_args{
    my ($us, $them) = @_;

    my $action = param("$us.action");
    if($action eq 'cc' || $action eq 'bs' || $action eq 'dtw' || $action eq 'deploy' || $action eq 'spec' || $action eq 'supp'){
        return gen_attack_args($us, $them);
    }elsif($action eq 'hack'){
        return gen_hack_args($us, $them);
    }elsif($action eq 'reset'){
        return gen_reset_args($us, $them);
    }elsif($action eq 'dodge'){
        return gen_dodge_args($us, $them, 0);
    }elsif($action eq 'change_face'){
        return gen_dodge_args($us, $them, -3);
    }else{
        return gen_none_args();
    }

    return ();
}

sub execute_backend{
    my (@args) = @_;
    my $output;

    if(!open DICE, '-|', '/usr/local/bin/inf-dice-n3', @args){
        $output->{error} = 'Unable to execute backend component.';
    }
    while(<DICE>){
        $_ =~ s/&/&amp;/g;
        $_ =~ s/</&lt;/g;

        $output->{raw} .= $_;
        if(m/^P(.) Scores +(\d+) Success\(es\): +([0-9.]+)%(?: (\w+))?/){
            if($4){
                $output->{tagged_hits}{$1}{$4}{$2} = $3;
            }else{
                $output->{hits}{$1}{$2} = $3;
            }
        }elsif(m/^P(.) Scores +(\d+)\+ Successes: +([0-9.]+)%(?: (\w+))?/){
            if($4){
                $output->{tagged_cumul_hits}{$1}{$4}{$2} = $3;
            }else{
                $output->{cumul_hits}{$1}{$2} = $3;
            }
        }elsif(m/^No Successes: +([0-9.]+)/){
            $output->{hits}{0} = $1;
        }elsif(m/^ERROR/ || m/Assertion/){
            my $cmd = join(' ', '/usr/local/bin/inf-dice-n3', @args);
            $output->{error} = $_ . '<br>' . $cmd;
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
