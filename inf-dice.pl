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
        <script type="text/javascript" src="inf-dice.js"></script>
    </head>
    <body onload="init_on_load()">
EOF
}

my $action = ['attack', 'dodge'];
my $action_labels = {
    attack => 'Attack',
    dodge => 'Dodge',
};

my $burst = [1, 2, 3, 4, 5];

my $ammo = ['Normal', 'AP', 'DA', 'EXP', 'AP+DA', 'AP+EXP', 'Fire', 'Viral', 'E/M', 'E/M2', 'Smoke'];
my $ammo_codes = {
    Normal => {code => 'N'},
    AP => {code => 'N', arm => 0.5},
    'AP+DA' => {code => 'D', arm => 0.5},
    'AP+EXP' => {code => 'E', arm => 0.5},
    DA => {code => 'D'},
    EXP => {code => 'E'},
    Fire => {code => 'F'},
    Viral => {code => 'D'},
    'E/M' => {code => 'N'},
    'E/M2' => {code => 'D'},
    'Smoke' => {code => '-', cover => 0},
};

my $ch = ['0', '-3', '-6'];
my $ch_labels = {
    0 => 'None',
    -3 => 'Mimetism/Camo (-3 Opponent BS)',
    -6 => 'TO Camo/ODD/ODF (-6 Opponent BS)',
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
    -6 => 'REM/TAG/Motorcycle (-6 PH)',
};

sub print_input_section{
    my ($player) = @_;

    print "<div id='$player'>\n";

    print "<div class='action'>
          <label>Action",
    
          popup_menu(-name => "$player.action",
              -values => $action,
              -default => param("$player.action") // '',
              -labels => $action_labels,
              -onchange => "set_action('$player')",
          ),
          "</label>
          </div>\n";

    print_input_attack_section($player);

    print "</div>\n";
}

sub print_input_attack_section{
    my ($player) = @_;

    print "<div class='attack'>
          <h2>Model Stats</h2>
          <label>
          <span id='$player.bs.label_bs'>BS</span>
          <span id='$player.bs.label_ph'>PH</span>
          ",
          textfield("$player.bs", param("$player.bs")),
          "</label>

          <span id='$player.b'>
          <label>B",
          popup_menu("$player.b", $burst, param("$player.b")),
          "</label>
          </span>

          <span id='$player.ammo'>
          <label>Ammo",
          popup_menu(-name => "$player.ammo", 
              -values => $ammo, 
              -default => param("$player.ammo") // '',
              -onchange => "set_ammo('$player')",
          ),
          "</label>
          </span>

          <br>

          <span id='$player.dam'>
          <label>DAM",
          textfield("$player.dam", param("$player.dam")),
          "</label>
          </span>

          <span id='$player.arm'>
          <label>
          <span id='$player.arm.label_arm'>ARM</span>
          <span id='$player.arm.label_bts'>BTS</span>
          ",
          textfield("$player.arm", param("$player.arm")),
          "</label>
          </span>

          </div>\n";

    print "<div class='modifiers'>
           <h2>Modifiers</h2>
           <span id='$player.mods.attack'>
           <label>Range",
           popup_menu("$player.range", $range, param("$player.range") // '', $range_labels),
           "</label><br>",

           "<label>Link Team",
           popup_menu("$player.link", $link, param("$player.link") // '', $link_labels),
           "</label><br>",

           "<label>Visibility Penalty",
           popup_menu("$player.viz", $viz, param("$player.viz") // '', $viz_labels),
           "</label>",
           "</span>
           <span id='$player.mods.dodge'>
           <label>Unit Type",
           popup_menu("$player.dodge_unit", $dodge_unit, param("$player.dodge_unit") // '', $dodge_unit_labels),
           "</label>",
           "</span>",

           "<h2>Defensive Abilities</h2>
           <label>Camo",
           popup_menu("$player.ch", $ch, param("$player.ch") // '', $ch_labels),
           "</label><br>",

           checkbox("$player.cover", defined(param("$player.cover")), 3, 'Cover (+3 ARM, -3 Opponent BS)'),

           "</div>\n";
}

sub print_input_head{
    print <<EOF
    <div id="input">
    <form method="get">
EOF
}

sub print_input_tail{
    print <<EOF
    <div id="submit">
        <input type="submit">
    </div>
    </form>
</div>
EOF
}

sub print_input{
    print_input_head();
    print_input_section('p1');
    print_input_section('p2');
    print_input_tail();
}

sub print_output{
    my ($output) = @_;

    print "<div id='output'>\n";

    if($output->{error}){
        print "<div class='output_error'>$output->{error}</div>\n";
    }

    if($output->{hits}){
        my %all_keys;
        for my $h (keys %{$output->{hits}{1}}, keys %{$output->{hits}{2}}){
            $all_keys{$h} = 1;
        }

        print "<table id='output_data'>\n";
        print "<tr><th colspan=4>Player 1</th><th colspan=2>vs.</th><th colspan=4>Player 2</th></tr>\n";

        my $first_row = 1;
        for my $h (sort {$a <=> $b} keys %all_keys){
            print "<tr>";

            if(exists $output->{hits}{1}{$h}){
                printf "<td>%d success%s</td><td>%.2f%%</td><td>%d or more successes</td><td>%.2f%%</td>", $h, ($h > 1 ? 'es' : ''), $output->{hits}{1}{$h}, $h, $output->{cumul_hits}{1}{$h};
            }else{
                print "<td colspan=4></td>";
            }

            if($first_row){
                printf "<td>No successes</td><td>%.2f%%</td>", $output->{hits}{0};
                $first_row = 0;
            }else{
                print "<td colspan=2></td>";
            }

            if(exists $output->{hits}{2}{$h}){
                printf "<td>%d success%s</td><td>%.2f%%</td><td>%d or more successes</td><td>%.2f%%</td>", $h, ($h > 1 ? 'es' : ''), $output->{hits}{2}{$h}, $h, $output->{cumul_hits}{2}{$h};
            }else{
                print "<td colspan=4></td>";
            }

            print "</tr>\n";
        }

        print "</table>\n";
    }

    if($output->{raw}){
        print "<button onclick='toggle_display(\"raw_output\")'>
            Toggle raw output
            </button>
            <div id='raw_output' style='display: none;'>
            <pre>
$output->{raw}
            </pre>
            </div>\n";
    }

    print "</div>\n";
}

sub print_tail{
    my ($time) = @_;

    print <<EOF
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
    my ($arm, $ammo, $cover);

    if(param("$us.link") >= 3){
        $link_b = 1;
    }

    if(param("$us.link") >= 5){
        $link_bs = 3;
    }

    # Lookup number of saves, invert BTS sign if needed
    $arm = $ammo_codes->{param("$us.ammo")}{arm} // 1;
    $arm = ceil(abs(param("$them.arm")) * $arm);
    $ammo = $ammo_codes->{param("$us.ammo")}{code};
    $cover = $ammo_codes->{param("$us.ammo")}{cover} // 1;
    $cover = param("$them.cover") * $cover;

    return (
        max(param("$us.bs") + param("$them.ch") - $cover + param("$us.range") + param("$us.viz") + $link_bs, 0),
        param("$us.b") + $link_b,
        max(param("$us.dam") - $arm - param("$them.cover"), 0),
        $ammo,
    );
}

sub gen_dodge_args{
    my ($us, $them) = @_;

    # TODO
    # -6 if template
    return (
        max(param("$us.bs") + param("$us.dodge_unit"), 0),
        1,
        0,
        '-',
    );
}

sub generate_output{
    my $output;
    my (@args1, @args2);

    if(!defined param('p1.action') || !defined param('p2.action')){
        return;
    }

    if(param('p1.action') eq 'attack'){
        @args1 = gen_attack_args('p1', 'p2')
    }elsif(param('p1.action') eq 'dodge'){
        @args1 = gen_dodge_args('p1', 'p2')
    }else{
        die "Unknown action";
    }

    if(param('p2.action') eq 'attack'){
        @args2 = gen_attack_args('p2', 'p1')
    }elsif(param('p2.action') eq 'dodge'){
        @args2 = gen_dodge_args('p2', 'p1')
    }else{
        die "Unknown action";
    }

    if(@args1 && @args2){
        open DICE, '-|', 'inf-dice', (@args1, @args2);
        $output->{raw} = '';
        while(<DICE>){
            $output->{raw} .= $_;
            if(m/^P(.) Scores +(\d+) S[^0-9]*([0-9.]+)%.*(\d+)\+ S[^0-9]*([0-9.]+)%/){
                $output->{hits}{$1}{$2} = $3;
                $output->{cumul_hits}{$1}{$4} = $5;
            }elsif(m/^No Successes: +([0-9.]+)/){
                $output->{hits}{0} = $1;
            }elsif(m/^ERROR/ || m/Assertion/){
                $output->{error} = $_;
            }
        }
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

print_page();
