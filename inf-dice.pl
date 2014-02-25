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
    </head>
    <body onload="init_on_load()">
EOF
}

my $action = ['bs', 'dtw', 'cc', 'dodge', 'none'];
my $action_labels = {
    bs => 'Attack - Shoot (Roll against BS or other attribute)',
    cc => 'Attack - Close Combat (Roll against CC)',
    dtw => 'Attack - Direct Template Weapon (Automaticall hits)',
    dodge => 'Dodge (Roll against PH)',
    none => 'No Action',
};

my $burst = [1, 2, 3, 4, 5];

my $ammo = ['Normal', 'AP', 'DA', 'EXP', 'AP+DA', 'AP+EXP', 'Fire', 'Viral', 'Monofilament', 'K1', 'Nanotech', 'E/M', 'E/M2', 'Smoke'];
my $ammo_codes = {
    Normal => {code => 'N'},
    AP => {code => 'N', ap => 0.5},
    'AP+DA' => {code => 'D', ap => 0.5},
    'AP+EXP' => {code => 'E', ap => 0.5},
    DA => {code => 'D'},
    EXP => {code => 'E'},
    Fire => {code => 'F'},
    Monofilament => {code => 'N', fixed_dam => 12, no_arm_bonus => 1, not_immune => 1},
    K1 => {code => 'N', fixed_dam => 12, not_immune => 1},
    Viral => {code => 'D', save => 'bts', not_immune => 1},
    Nanotech => {code => 'N', save => 'bts'},
    'E/M' => {code => 'N', save => 'bts', not_immune => 1},
    # TODO verify what happens when a TI model is hit with E/M2
    'E/M2' => {code => 'D', save => 'bts', not_immune => 1},
    'Smoke' => {code => '-', cover => 0, not_immune => 1},
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
    -3 => '-3 BS',
    -6 => '-6 BS',
};

my $link = [0, 3, 5];
my $link_labels = {
    0 => 'None',
    3 => '3 (+1 B)',
    5 => '5 (+1 B, +3 BS)',
};

my $dodge_unit = [0, -6];
my $dodge_unit_labels = {
    0 => 'None',
    -6 => 'REM/TAG/Motorcycle (-6 PH to Dodge)',
};

my $immunity = [0, 2];
my $immunity_labels = {
    0 => 'None',
    2 => 'Total',
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

    print "<div class='action'>
          <h3>Action</h3>",

          popup_menu(-name => "$player.action",
              -values => $action,
              -default => param("$player.action") // '',
              -labels => $action_labels,
              -onchange => "set_action('$player')",
          ),
          "</div>\n";

    print_input_attack_section($player);

    print "</div>\n";
    print "</div>\n";
}

sub print_input_attack_section{
    my ($player) = @_;

    print "<div class='attack'>
          <h3>Model Attributes</h3>",
          span_popup_menu(-name => "$player.stat",
              -values => [1 .. 22],
              -default => param("$player.stat") // 11,
              -label => "Stat",
          ),
          span_popup_menu(-name => "$player.b",
              -values => $burst,
              -default => param("$player.b") // '',
              -label => "B",
          ),
          "<br>",
          span_popup_menu(-name => "$player.ammo",
              -values => $ammo,
              -default => param("$player.ammo") // '',
              -onchange => "set_ammo('$player')",
              -label => "Ammo",
          ),
          span_popup_menu(-name => "$player.dam",
              -values => [6 .. 20],
              -default => param("$player.dam") // 13,
              -label => 'DAM',
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
          "</div>\n";

    print "<div class='modifiers'>
           <h3>Skill Modifiers</h3>",
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
           "<h3>CC Modifiers</h3>",
           span_popup_menu(-name => "$player.gang_up",
               -values => $gang_up,
               -default => param("$player.gang_up") // '',
               -labels => $gang_up_labels,
               -label => "Gang Up",
           ),
           "<br>",
           span_popup_menu(-name => "$player.ikohl",
               -values => $ikohl,
               -default => param("$player.ikohl") // '',
               -labels => $ikohl_labels,
               -label => "i-Kohl",
           ),
           "<br>",
           span_checkbox(-name => "$player.berserk",
               -checked => defined(param("$player.berserk")),
               -value => 3,
               -label => 'Berserk (+9 CC, Normal Rolls)'),
           "<h3>Defensive Modifiers</h3>",
           span_checkbox(-name => "$player.cover",
               -checked => defined(param("$player.cover")),
               -value => 3,
               -label => 'Cover (+3 ARM, -3 Opponent BS)'),
           "<br>",
           span_popup_menu(-name => "$player.ch",
               -values => $ch,
               -default => param("$player.ch") // '',
               -labels => $ch_labels,
               -label => "Camo",
           ),
           "<br>",
           span_popup_menu(-name => "$player.immunity",
               -values => $immunity,
               -default => param("$player.immunity") // '',
               -labels => $immunity_labels,
               -label => "Immunity",
           ),

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
    my ($output, $p) = @_;

    if(scalar keys %{$output->{hits}{$p}} == 0){
        # empty list, nothing to print
        return;
    }

    print "<tr><th colspan=2>Player $p Successes</th>";
    if(scalar keys %{$output->{hits}{$p}} > 1){
        print "<th colspan=2>Player $p Cumulative Successes</th>";
    }else{
        print "<th colspan='2'></th>";
    }
    print "</tr>\n";

    for my $h (sort {$a <=> $b} keys %{$output->{hits}{$p}}){
        print "<tr>";

        printf "<td class='p$p-hit-$h num'>%.2f%%</td><td>%d success%s</td>", $output->{hits}{$p}{$h}, $h, ($h > 1 ? 'es' : '');

        if(scalar keys %{$output->{hits}{$p}} > 1){
            printf "<td class='p$p-cumul-hit-$h num'>%.2f%%</td><td>%d or more successes</td>", $output->{cumul_hits}{$p}{$h}, $h;
        }else{
            print "<td colspan='2'></td>";
        }

        print "</tr>\n";
    }
}

sub print_miss_output{
    my ($output, $text) = @_;

    print "<tr><th colspan=2>Failures</th></tr>\n";
    printf "<tr><td class='miss num'>%.2f%%</td><td>$text</td></tr>\n", $output->{hits}{0};
}

sub print_hitbar_player{
    my ($output, $sort, $p) = @_;

    for my $h (sort {$a * $sort <=> $b * $sort} keys %{$output->{hits}{$p}}){
        print "<td style='width: $output->{hits}{$p}{$h}%' class='p$p-hit-$h center'>";
        if($output->{hits}{$p}{$h} >= 5.0){
            printf "%d%%", $output->{hits}{$p}{$h};
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

    print "<td style='width: $output->{hits}{0}%' class='miss center'>";
    if($output->{hits}{0} >= 5.0){
        printf "%d%%", $output->{hits}{0};
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
        print "<table id='output_data'>\n";

        print_player_output($output, 1);

        print_miss_output($output, 'Neither player succeeds');

        print_player_output($output, 2);

        print "</table>\n";

        print_hitbar_output('ftf', $output);
    }
}

sub print_normal_output{
    my ($output) = @_;

    print "<h2>Normal Roll</h2>\n";
    if($output->{hits}){
        print "<table id='output_data'>\n";

        print_player_output($output, 1);
        print_player_output($output, 2);

        print_miss_output($output, 'No success');

        print "</table>\n";

        print_hitbar_output('normal', $output);
    }
}

sub print_simultaneous_output{
    my ($output) = @_;

    print "<h2>Simultaneous Normal Rolls</h2>\n";

    if($output->{A}{hits}){
        print "<table id='output_data'>\n";

        print_player_output($output->{A}, 1);

        print_miss_output($output->{A}, 'No success');

        print "</table>\n";

        print_hitbar_output('normal', $output->{A});
    }

    if($output->{B}{hits}){
        print "<table id='output_data'>\n";

        print_player_output($output->{B}, 2);

        print_miss_output($output->{B}, 'No success');

        print "</table>\n";

        print_hitbar_output('normal', $output->{B});
    }
}

sub print_none_output{
    my ($output) = @_;

    print "<h2>No Roll</h2>\n";
    if($output->{hits}){
        print "<table id='output_data'>\n";

        print_miss_output($output->{B}, 'Nothing happens');

        print "</table>\n";

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
This tool was created by Jonathan Polley to help enhance your enjoyment of <a href="http://infinitythegame.com/">Infinity the Game</a>.
Infinity is &copy; by Corvus Belli SLL.
Please direct any issues or feedback to <a href="mailto:inf-dice\@ghostlords.com">inf-dice\@ghostlords.com</a>.
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
    my ($code, $immunity);

    if((param("$us.link") // 0) >= 3){
        $link_b = 1;
    }

    if((param("$us.link") // 0) >= 5){
        $link_bs = 3;
    }

    $code = $ammo_codes->{param("$us.ammo") // 'Normal'};
    $immunity = param("$them.immunity") // 0;

    # Total Immunity ignores most ammo types
    if($immunity >= 2 && !$code->{not_immune}){
        $ap = 1;
        $save = 'arm';
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

    $stat = param("$us.stat") // 0;

    # Monofilament and K1 have fixed damage
    if($code->{fixed_dam}){
        $arm = 0;
        $dam = $code->{fixed_dam};
    }

    my $action = param("$us.action");
    if($action eq 'bs'){
        # BS mods
        $stat += (param("$them.ch") // 0) - $cover + (param("$us.range") // 0) + (param("$us.viz") // 0) + $link_bs;
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
    }

    return (
        $stat,
        $b,
        max($dam - $arm, 0),
        $ammo,
    );
}

sub gen_dodge_args{
    my ($us, $them) = @_;

    my $stat = param("$us.stat") // 0;
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
    if($action eq 'cc' || $action eq 'bs' || $action eq 'dtw'){
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
            ($act_1 ne 'bs' && $act_1 ne 'cc' &&
            $act_2 ne 'bs' && $act_2 ne 'cc')){
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
