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
    EXP => {code => 'E'},
    Fire => {code => 'F', fatal_symbiont => 9},
    Monofilament => {code => 'N', fixed_dam => 12, no_arm_bonus => 1, fatal => 9},
    K1 => {code => 'N', fixed_dam => 12},
    Viral => {code => 'D', save => 'bts', fatal => 1, str_resist => 1, ignore_nwi => 1},
    Nanotech => {code => 'N', save => 'bts'},
    Flash => {code => 'N', save => 'bts', fatal => 9, label => 'Blinded'},
    'E/M' => {code => 'N', save => 'bts', fatal => 9, label => 'Disabled'},
    'E/M2' => {code => 'D', save => 'bts', fatal => 9, label => 'Disabled'},
    'Smoke' => {code => '-', cover => 0},
    'Zero-V Smoke' => {code => '-', cover => 0},
    'Adhesive' => {code => 'N', alt_save => 'ph', alt_save_mod => -6, fatal => 9, label => 'Immobilized'},
    # Placeholders for unimplemented ammos
    'Plasma' => {code => 'N'},
    'N+E/M(12)' => {code => 'N'},
    'Stun' => {code => 'N', save => 'bts'},
};

my $skill_codes = {
    'hack_imm' => {fatal => 9, label => 'Immobilized', title => 'Hack to Immobilize'},
    'hack_ahp' => {dam => 'w', title => 'Anti-Hacker Protocols'},
    'hack_def' => {title => 'Defensive Hacking'},
    'hack_pos' => {fatal => 9, label => 'Possessed', threshold => 2, title => 'Hack to Possess'},
    'dodge' => {title => 'Dodge'},
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
    -6 => 'TO Camo/ODD/ODF (-6 Opponent BS)',
};

my $ikohl = ['0', '-3', '-6', '-9'];
my $ikohl_labels = {
    0 => 'None',
    -3 => 'Level 1 (-3 Opponent CC)',
    -6 => 'Level 2 (-6 Opponent CC)',
    -9 => 'Level 3 (-9 Opponent CC)',
};

my $range = ['3', '0', '-3', '-6'];
my $range_labels = {
    3 => '+3 BS',
    0 => '+0 BS',
    -3 => '-3 BS',
    -6 => '-6 BS',
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
          "</div>\n";

    print "<div class='action'>
          <h3>Action</h3>",

          popup_menu(-name => "$player.action",
              -onchange => "set_action('$player')",
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
              -values => $range,
              -default => param("$player.range") // 0,
              -labels => $range_labels,
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

    print "<div id='$player.sec_cover'>",
          "<h3>Cover</h3>",
          span_checkbox(-name => "$player.cover",
              -checked => defined(param("$player.cover")),
              -value => 3,
              -label => 'Cover (+3 ARM, -3 Opponent BS)'),
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

    my $code = $skill_codes->{$action};
    if(!defined $code){
        $code = $ammo_codes->{$ammo};
    }
    my $fatal = $code->{fatal} // 0;
    my $dam = $code->{dam} // 1;
    my $threshold = $code->{threshold} // 1;

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

    for my $h (sort {$a <=> $b} keys %{$output->{hits}{$player}}){
        my $done;

        my $w = $h * $dam + $w_taken;

        if($w < $threshold){
            next;
        }

        if($w >= $dead){
            $label = sprintf " (%s)", $code->{label} // 'Dead';
            $done = 1;
        }elsif($w == $symb_disabled){
            $label = ' (Symbiont Disabled)';
        }elsif($w == $eject){
            $label = ' (Operator Ejected)';
        }elsif($w == $unconscious){
            $label = ' (Unconscious)';
        }elsif($w == $spawn){
            $label = ' (Spawn Embryo)';
        }else{
            $label = '';
        }

        printf "<span class='p$player-hit-$h hit_chance'>%.2f%%</span> %s inflicts %d or more successes on %s%s<br>", $output->{cumul_hits}{$player}{$h}, $name, $h, $other_name, $label;

        # Stop once we print a line about them being dead
        if($done){
            last;
        }
    }

    print "</p>\n";
}

sub print_miss_output{
    my ($output, $text) = @_;

    print "<h3>Failures</h3>\n";
    printf "<p><span class='miss hit_chance'>%.2f%%</span> $text</p>\n", $output->{hits}{0};
}

sub print_hitbar_player{
    my ($output, $sort, $p) = @_;

    for my $h (sort {$a * $sort <=> $b * $sort} keys %{$output->{hits}{$p}}){
        print "<td style='width: $output->{hits}{$p}{$h}%;' class='p$p-hit-$h'>";
        if($output->{hits}{$p}{$h} >= 3.0){
            printf "%d", $h;
        }
        print "</td>\n";
    }
}

sub print_hitbar_output{
    my ($mode, $output) = @_;

    # mode is normal or ftf
    # ftf has p1 (decreasing) - miss - p2 (increasing)
    # normal has p1 (decreasing) - p2 (decreasing) - miss

    print "<table class='hitbar'><tr>\n";

    print_hitbar_player($output, -1, 1);

    print "<td style='width: $output->{hits}{0}%;' class='miss center'>";
    if($output->{hits}{0} >= 3.0){
        printf "0";
    }
    print "</td>\n";

    print_hitbar_player($output, 1, 2);

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
        print_player_output($output, 1, 2);

        print_miss_output($output, 'Neither player succeeds');

        print_player_output($output, 2, 1);

        print_hitbar_output('ftf', $output);
    }
}

sub print_normal_output{
    my ($output) = @_;

    print "<h2>Normal Roll</h2>\n";
    print_roll_subtitle();

    if($output->{hits}){
        print_player_output($output, 1, 2);
        print_player_output($output, 2, 1);

        print_miss_output($output, 'No success');

        print_hitbar_output('normal', $output);
    }
}

sub print_simultaneous_output{
    my ($output) = @_;

    print "<h2>Simultaneous Normal Rolls</h2>\n";
    print_roll_subtitle();

    if($output->{A}{hits}){
        print_player_output($output->{A}, 1, 2);

        print_miss_output($output->{A}, 'No success');
    }

    if($output->{B}{hits}){
        print_player_output($output->{B}, 2, 1);

        print_miss_output($output->{B}, 'No success');
    }

    if($output->{A}{hits}){
        print_hitbar_output('normal', $output->{A});
    }

    if($output->{B}{hits}){
        print_hitbar_output('normal', $output->{B});
    }
}

sub print_none_output{
    my ($output) = @_;

    print "<h2>No Roll</h2>\n";
    if($output->{hits}){
        print_miss_output($output->{B}, 'Nothing happens');

        print_hitbar_output('ftf', $output);
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

    if($output->{raw}){
        print "<button onclick='raw_output()'>
            Toggle raw output
            </button>
            <div id='raw_output' style='display: none;'>
            <pre>
$output->{raw}
            </pre>
            </div>\n";
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
    my $stat;
    my ($ammo_name, $code, $immunity);
    my $type;

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
    if($action eq 'bs'){
        # BS mods
        $type = 'ftf';

        my $camo = param("$them.ch") // 0;
        my $msv = param("$us.msv") // 0;
        if($msv >= 1 && $camo >= -3){
            $camo = 0;
        }elsif($msv >= 2 && $camo >= -6){
            $camo = 0;
        }

        my $viz = param("$us.viz") // 0;
        if($msv >= 1 && $viz >= -3){
            $viz = 0;
        }elsif($msv >= 2 && $viz >= -6){
            $viz = 0;
        }

        # look up stat to use
        $stat = lc(param("$us.stat") // 'bs');
        $stat = param("$us.$stat") // 0;

        $stat += $camo - $cover + (param("$us.range") // 0) + $viz + $link_bs;
        $stat = max($stat, 0);

        $b = (param("$us.b") // 1) + $link_b;
        $arm += $cover;
    }elsif($action eq 'dtw'){
        # DTW mods
        $type = 'normal';

        $stat = 'T';
        $b = (param("$us.b") // 1) + $link_b;
        $arm += $cover;

        # templates are FTF against Dodge
        if($other_action eq 'dodge'){
            $type = 'ftf';
        }
    }elsif($action eq 'cc'){
        # CC mods
        $type = 'ftf_cc';

        $stat = param("$us.cc") // 0;

        # monofilament allows no CC ARM bonus
        if($code->{no_arm_bonus}){
            $type = 'ftf';
        }

        # berserk only works if they CC or Dodge in response
        if(param("$us.berserk") && ($other_action eq 'cc' || $other_action eq 'dodge' || $other_action eq 'none')){
            $stat += 9;
            $type = 'normal';
        }

        # iKohl does not work on models with STR
        my $ikohl = param("$them.ikohl") // 0;
        my $w_type = param("$us.w_type") // 'W';
        if($w_type eq 'STR'){
            $ikohl = 0;
        }
        $stat += $ikohl;

        $stat += (param("$us.gang_up") // 0);
        $stat = max($stat, 0);

        $b = 1;
    }

    if(!$code->{alt_save}){
        $dam = max($dam - $arm, 0);
    }else{
        # Adhesive makes a PH saving throw instead of DAM - ARM check
        $dam = 20 - max(param("$them.$code->{alt_save}") + $code->{alt_save_mod}, 0);
    }

    return (
        $type,
        $stat,
        $b,
        $dam,
        $ammo,
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

    if($action eq 'hack_imm'){
        my $unit_type = param("$them.type") // '';
        my $faction = param("$them.faction") // '';

        if($unit_type eq 'REM' || $unit_type eq 'TAG'){
            $can_hack = 1;
        }elsif($unit_type eq 'HI' && $faction ne 'Ariadna'){
            # Ariadna HI are unhackable
            $can_hack = 1;
        }

        # Immobilization does not protect against hacking attacks
        if($other_action eq 'hack_imm' || $other_action eq 'hack_ahp'){
            $type = 'normal';
        }
    }elsif($action eq 'hack_pos'){
        my $unit_type = param("$them.type") // '';
        my $faction = param("$us.faction") // '';
        my $other_faction = param("$them.faction") // '';

        # CA TAGs cannot be possessed by humans
        if($unit_type eq 'TAG' && ($other_faction ne 'Combined Army' || $faction eq 'Combined Army')){
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
    }elsif($action eq 'hack_ahp'){
        my $hacker = param("$them.hacker") // 0;
        if($hacker > 0){
            $can_hack = 1;
        }
    }elsif($action eq 'hack_def'){
        # Defensive Hacking is only useful against hacking attacks
        if($other_action eq 'hack_ahp' || $other_action eq 'hack_imm'){
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

    # EVO support bonuses
    if($evo eq 'sup_1'){
        $stat += 3;
    }elsif($evo eq 'sup_2'){
        $stat += 6;
    }elsif($evo eq 'sup_3'){
        $stat += 9;
    }elsif($evo eq 'ice'){
        $bts = -ceil(abs($bts / 2));
    }

    $stat += $bts;

    return (
        $type,
        max($stat, 0),
        $b,
        0,
        '-',
    );
}

sub gen_dodge_args{
    my ($us, $them) = @_;

    my $dodge_unit = 0;
    my $unit_type = param("$us.type") // '';
    my $motorcycle = param("$us.motorcycle") // 0;
    if($unit_type eq 'REM' || $unit_type eq 'TAG' || $motorcycle){
        $dodge_unit = -6;
    }

    my $stat = param("$us.ph") // 0;
    $stat += $dodge_unit;
    $stat += param("$us.gang_up") // 0;
    $stat += param("$us.hyperdynamics") // 0;

    my $type = 'ftf';

    # -6 to dodge templates
    if(param("$them.action") eq 'dtw'){
        $stat -= 6;
    }elsif(param("$them.action") eq 'dodge'){
        # double-dodge is normal rolls
        $type = 'normal';
    }

    return (
        $type,
        max($stat, 0),
        1,
        0,
        '-',
    );
}

sub gen_none_args{
    return (
        'none',
        0,
        1,
        0,
        '-',
    );
}

sub gen_args{
    my ($us, $them) = @_;

    my $action = param("$us.action");
    if($action eq 'cc' || $action eq 'bs' || $action eq 'dtw'){
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
    $output->{raw} = '';
    while(<DICE>){
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

    my ($none, @args_none) = gen_none_args();

    $o1 = execute_backend('BS', @$args1, @args_none);
    $o2 = execute_backend('BS', @args_none, @$args2);

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

    my ($act_1, @args1) = gen_args('p1', 'p2');
    my ($act_2, @args2) = gen_args('p2', 'p1');

    # determine if it's FtF or Normal
    my $type;
    if($act_1 eq 'none' && $act_2 eq 'none'){
        # There is no roll
        $output->{type} = 'none';
        $output->{hits}{0} = 100;
    }elsif($act_1 eq 'none' || $act_2 eq 'none'){
        # One player is making a Normal Roll
        $output = execute_backend('BS', @args1, @args2);
        $output->{type} = 'normal';
    }elsif($act_1 eq 'normal' || $act_2 eq 'normal'){
        # Simultaneous Normal Rolls
        $output = execute_backend_simultaneous(\@args1, \@args2);
    }elsif($act_1 eq 'ftf_cc' && $act_2 eq 'ftf_cc'){
        # The CC backend allows the loser an ARM bonus when hit.
        $output = execute_backend('CC', @args1, @args2);
        $output->{type} = 'ftf';
    }else{
        # Face to Face Roll
        $output = execute_backend('BS', @args1, @args2);
        $output->{type} = 'ftf';
    }

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
