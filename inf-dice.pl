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

my $action = ['bs', 'dtw', 'cc', 'dodge', 'none'];
my $action_labels = {
    bs => 'Attack - Shoot (Roll against BS, PH, or WIP)',
    cc => 'Attack - Close Combat (Roll against CC)',
    dtw => 'Attack - Direct Template Weapon (Automaticall hits)',
    dodge => 'Dodge (Roll against PH)',
    none => 'No Action',
};

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
        # TODO verify what happens when a TI model is hit with E/M2
    },
};

my $w_type = ['W', 'STR'];

my $symbiont_armor = [0, 2, 1];
my $symbiont_armor_labels = {
    0 => 'None',
    1 => 'Inactive',
    2 => 'Active',
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

my $dodge_unit = [0, -6];
my $dodge_unit_labels = {
    0 => 'None',
    -6 => 'REM/TAG/Motorcycle (-6 PH to Dodge)',
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

sub span_popup_menu{
    my (%args) = @_;
    my $label = $args{-label};
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
    printf "<h2>Player %d</h2>\n", $player_num;

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
          "<tr><th>Type</th><th>CC</th><th>BS</th><th>PH</th><th>WIP</th><th>ARM</th><th>BTS</th><th id='$player.statline_w_type'>W</th></tr>",
          "<tr><td id='$player.statline_type'></td><td id='$player.statline_cc'></td><td id='$player.statline_bs'></td><td id='$player.statline_ph'></td><td id='$player.statline_wip'></td><td id='$player.statline_arm'></td><td id='$player.statline_bts'></td><td id='$player.statline_w'></td></tr>",
          "</table>",
          "<div>Skills/Equipment:</div>",
          "<div id='$player.statline_skills' class='skills'></div>",
          "</div>\n";

    print "<div id='$player.attributes' style='display: none;'>\n",
          "<h4>Model Attributes</h4>\n",
          span_popup_menu(-name => "$player.bs",
              -values => [1 .. 22],
              -default => param("$player.bs") // 11,
              -label => "BS",
          ),
          span_popup_menu(-name => "$player.ph",
              -values => [1 .. 22],
              -default => param("$player.ph") // 11,
              -label => "PH",
          ),
          span_popup_menu(-name => "$player.cc",
              -values => [1 .. 22],
              -default => param("$player.cc") // 11,
              -label => "CC",
          ),
          span_popup_menu(-name => "$player.wip",
              -values => [1 .. 22],
              -default => param("$player.wip") // 11,
              -label => "WIP",
          ),
          "<br>",
          span_popup_menu(-name => "$player.arm",
              -values => [0 .. 10],
              -default => param("$player.arm") // '',
              -label => "ARM",
          ),
          span_popup_menu(-name => "$player.bts",
              -values => [0, -3, -6, -9],
              -default => param("$player.bts") // '',
              -label => "BTS",
          ),
          "<br>",
          "<h4>Wounds</h4>",
          span_popup_menu(-name => "$player.w",
              -values => [1 .. 4],
              -default => param("$player.w") // '',
              -label => "Base Wounds",
          ),
          span_popup_menu(-name => "$player.w_taken",
              -values => [0 .. 4],
              -default => param("$player.w_taken") // '',
              -label => "Wounds Taken",
          ),
          span_popup_menu(-name => "$player.w_type",
              -values => $w_type,
              -default => param("$player.w_type") // '',
              -label => "Wound Type",
          ),
          "<br>",
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
          "<h4>Special Skills and Equipment</h4>",
          span_popup_menu(-name => "$player.immunity",
              -values => $immunity,
              -default => param("$player.immunity") // '',
              -labels => $immunity_labels,
              -label => "Immunity",
          ),
          "<br>",
          span_popup_menu(-name => "$player.dodge_unit",
              -values => $dodge_unit,
              -default => param("$player.dodge_unit") // '',
              -labels => $dodge_unit_labels,
              -label => "Unit Type",
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
          "</div>\n";

    print "<div class='action'>
          <h3>Action</h3>",

          popup_menu(-name => "$player.action",
              -values => $action,
              -default => param("$player.action") // '',
              -labels => $action_labels,
              -onchange => "set_action('$player')",
          ),
          "</div>\n";

    print "<h3>Weapon</h3>",
          span_popup_menu(-name => "$player.weapon",
              -onchange => "set_weapon('$player')",
              -label => 'Weapon',
          ),
          "<br>",
          span_popup_menu(-name => "$player.stat",
              -label => "Stat",
          ),
          span_popup_menu(-name => "$player.ammo",
              -onchange => "set_ammo('$player')",
              -label => "Ammo",
          ),
          span_popup_menu(-name => "$player.b",
              -label => "B",
          ),
          span_popup_menu(-name => "$player.dam",
              -label => 'DAM',
          );

    print "<div class='modifiers'>
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
           "<br>",
           span_checkbox(-name => "$player.cover",
               -checked => defined(param("$player.cover")),
               -value => 3,
               -label => 'Cover (+3 ARM, -3 Opponent BS)'),
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
}

sub print_input_head{
    print <<EOF
    <div id="input" class="databox">
    <div class='content'>
    <h1>Infinity Dice Calculator</h1>
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
    my $label = '';
    my $w = param("p$other.w") // 1;
    my $w_taken = param("p$other.w_taken") // 0;
    my $immunity = param("p$other.immunity") // '';
    my $ammo = param("p$player.ammo") // 'Normal';
    my $nwi = param("p$other.nwi");
    my $shasvastii = param("p$other.shasvastii");
    my $w_type = param("p$other.w_type") // 'W';
    my $name = param("p$player.unit") // 'Model';
    my $other_name = param("p$other.unit") // 'Model';
    my $code = $ammo_codes->{$ammo};
    my $fatal = $code->{fatal} // 0;
    my $symbiont = param("p$other.symbiont") // 0;
    my $dead = $w + 1;

    if($symbiont && $code->{fatal_symbiont}){
        $fatal = $code->{fatal_symbiont};
    }

    if($symbiont == 2){
        $dead++;
        $w++;
    }

    if($shasvastii){
        $dead++;
    }

    if($fatal >= $w && !$immunities->{$immunity}{$ammo} && !($w_type eq 'STR' && $code->{str_resist})){
        # This ammo is instantly fatal, and we are not immune
        $dead = $w - $fatal;
    }

    if($code->{ignore_nwi}){
        $nwi = 0;
    }

    if(scalar keys %{$output->{hits}{$player}} == 0){
        # empty list, nothing to print
        return;
    }

    print "<h3>Player $player</h3>";
    print "<p>\n";

    for my $h (sort {$a <=> $b} keys %{$output->{hits}{$player}}){
        my $done;

        if($h + $w_taken >= $dead){
            $label = sprintf " (%s)", $code->{label} // 'Dead';
            $done = 1;
        }elsif($h + $w_taken == $w - 1 && $symbiont == 2){
            $label = ' (Symbiont Disabled)';
        }elsif($h + $w_taken == $w && !$nwi){
            $label = ' (Unconscious)';
        }elsif($h + $w_taken == $w + 1 && $shasvastii){
            $label = ' (Spawn Embryo)';
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

    if($mode eq 'ftf'){
        print_hitbar_player($output, -1, 1);
    }else{
        print_hitbar_player($output, -1, 1);
        print_hitbar_player($output, -1, 2);
    }

    print "<td style='width: $output->{hits}{0}%;' class='miss center'>";
    if($output->{hits}{0} >= 3.0){
        printf "0";
    }
    print "</td>\n";

    if($mode eq 'ftf'){
        print_hitbar_player($output, 1, 2);
    }

    print "</tr></table>\n"
}

sub print_ftf_output{
    my ($output) = @_;

    print "<h2>Face to Face Roll</h2>\n";
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

    if($output->{A}{hits}){
        print_player_output($output->{A}, 1, 2);

        print_miss_output($output->{A}, 'No success');

        print_hitbar_output('normal', $output->{A});
    }

    if($output->{B}{hits}){
        print_player_output($output->{B}, 2, 1);

        print_miss_output($output->{B}, 'No success');

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
    if($action eq 'bs'){
        # BS mods
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
        $stat = 'T';
        $b = (param("$us.b") // 1) + $link_b;
        $arm += $cover;
    }elsif($action eq 'cc'){
        # CC mods

        # berserk only works if they CC or Dodge in response
        my $berserk = 0;
        if(param("$us.berserk") && (param("$them.action") eq 'cc' || param("$them.action") eq 'dodge' || param("$them.action") eq 'none')){
            $berserk = 9;
        }

        $stat += (param("$them.ikohl") // 0) + (param("$us.gang_up") // 0) + $berserk;
        $stat = max($stat, 0);

        $b = 1;

        $stat = param("$us.cc") // 0;
    }

    if(!$code->{alt_save}){
        $dam = max($dam - $arm, 0);
    }else{
        # Adhesive makes a PH saving throw instead of DAM - ARM check
        $dam = 20 - max(param("$them.$code->{alt_save}") + $code->{alt_save_mod}, 0);
    }

    return (
        $stat,
        $b,
        $dam,
        $ammo,
    );
}

sub gen_dodge_args{
    my ($us, $them) = @_;

    my $stat = param("$us.ph") // 0;
    $stat += param("$us.dodge_unit") // 0;
    $stat += param("$us.gang_up") // 0;
    $stat += param("$us.hyperdynamics") // 0;

    # -6 to dodge templates
    if(param("$them.action") eq 'dtw'){
        $stat -= 6;
    }

    return (
        max($stat, 0),
        1,
        0,
        '-',
    );
}

sub gen_none_args{
    my ($us, $them) = @_;

    return (
        0,
        1,
        0,
        '-',
    );
}

sub gen_args{
    my ($us, $them) = @_;

    my $action = param("$us.action");
    if($action eq 'cc' || $action eq 'bs' || $action eq 'dtw' || $action eq 'throw'){
        return gen_attack_args($us, $them);
    }elsif($action eq 'dodge'){
        return gen_dodge_args($us, $them);
    }else{
        return gen_none_args($us, $them);
    }

    return ();
}

sub execute_backend{
    my (@args) = @_;
    my $output;
    my %dam;

    $dam{1} = $ammo_codes->{param('p1.ammo') // 'Normal'}{dam} // 1;
    $dam{2} = $ammo_codes->{param('p2.ammo') // 'Normal'}{dam} // 1;

    if(!open DICE, '-|', '/usr/local/bin/inf-dice', @args){
        $output->{error} = 'Unable to execute backend component.';
    }
    $output->{raw} = '';
    while(<DICE>){
        $output->{raw} .= $_;
        if(m/^P(.) Scores +(\d+) S[^0-9]*([0-9.]+)%[^\d]*(\d+)\+ S[^0-9]*([0-9.]+)%/){
            $output->{hits}{$1}{$2 * $dam{$1}} = $3;
            $output->{cumul_hits}{$1}{$4 * $dam{$1}} = $5;
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

    $o1 = execute_backend('BS', @$args1, gen_none_args());
    $o2 = execute_backend('BS', gen_none_args(), @$args2);

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
    my (@args1, @args2);

    if(!defined param('p1.action') || !defined param('p2.action')){
        return;
    }
    my $act_1 = param('p1.action');
    my $act_2 = param('p2.action');

    @args1 = gen_args('p1', 'p2');
    @args2 = gen_args('p2', 'p1');

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
    }elsif(($act_1 eq 'dtw' && $act_2 eq 'dodge') || ($act_1 eq 'dodge' && $act_2 eq 'dtw')){
        # Dodge vs. Template
        # This is the only time a template can be a FtF roll
        $output = execute_backend('BS', @args1, @args2);
        $output->{type} = 'ftf';
    }elsif($act_1 eq 'dtw' || $act_2 eq 'dtw' ||
            ($act_1 ne 'bs' && $act_1 ne 'cc' && $act_1 ne 'throw' &&
            $act_2 ne 'bs' && $act_2 ne 'cc' && $act_2 ne 'throw')){
        # neither player is attacking
        # Simultaneous Normal Rolls
        $output = execute_backend_simultaneous(\@args1, \@args2);
    }elsif(($act_1 eq 'cc' && param('p1.berserk') &&
            ($act_2 eq 'cc' || $act_2 eq 'dodge' || $act_2 eq 'none')) ||
            ($act_2 eq 'cc' && param('p2.berserk') &&
            ($act_1 eq 'cc' || $act_1 eq 'dodge' || $act_1 eq 'none'))){
        # Berserk CC
        # Pair of Normal Rolls.  No CC ARM bonus.
        $output = execute_backend_simultaneous(\@args1, \@args2);
    }else{
        # Face to Face Roll

        # Determine if we should use BS or CC backend
        # The only difference is that the CC backend allows
        # the loser an ARM bonus when hit.
        my $mode;
        if($ammo_codes->{param('p1.ammo') // 'Normal'}{no_arm_bonus} || $ammo_codes->{param('p2.ammo') // 'Normal'}{no_arm_bonus}){
            # Use of Monofilament CCW prevents CC ARM bonus
            $mode = 'BS';
        }elsif($act_1 eq 'cc' && $act_2 eq 'cc'){
            # otherwise if both are in CC use CC backend
            $mode = 'CC';
        }else{
            # BS backend is default for all other skills
            $mode = 'BS';
        }

        $output = execute_backend($mode, @args1, @args2);
        $output->{type} = 'ftf';
    }

    return $output;
}

sub print_page{
    my $start = time();

    my $output = generate_output();

    print_head();

    print_input();

    print_output($output);

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
