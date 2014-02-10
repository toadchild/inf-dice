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
    <body onload="set_ARM_BTS()">
EOF
}

my $action = ['shoot'];
my $action_labels = {shoot => 'Shoot'};

my $burst = [1, 2, 3, 4, 5];

my $ammo = ['Normal', 'AP', 'DA', 'EXP', 'AP+DA', 'AP+EXP', 'Fire', 'Viral', 'E/M', 'E/M2'];
my $ammo_codes = {
    Normal => {code => 'N', arm => 1},
    AP => {code => 'N', arm => 0.5},
    'AP+DA' => {code => 'D', arm => 0.5},
    'AP+EXP' => {code => 'E', arm => 0.5},
    DA => {code => 'D', arm => 1},
    EXP => {code => 'E', arm => 1},
    Fire => {code => 'F', arm => 1},
    Viral => {code => 'D', arm => 1},
    'E/M' => {code => 'N', arm => 1},
    'E/M2' => {code => 'D', arm => 1},
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

sub print_input_section{
    my ($player) = @_;

    print "<div id='$player'>\n";

    print "<div class='action'>
          <label>Action",
    
          popup_menu("$player.type", $action, param("$player.type") // '', $action_labels),
          "</label>
          </div>\n";

    print "<div class='shoot'>
          <h2>Model Stats</h2>
          <label>BS",
          textfield("$player.bs", param("$player.bs")),
          "</label>

          <label>B",
          popup_menu("$player.b", $burst, param("$player.b")),
          "</label>

           <label>Ammo",
           popup_menu(-name => "$player.ammo", 
               -values => $ammo, 
               -default => param("$player.ammo") // '',
               -onchange => "set_ARM_BTS()",
           ),
           "</label>

           <br>

           <label>DAM",
           textfield("$player.dam", param("$player.dam")),
           "</label>

           <label>
           <span id='$player.arm.label_arm'>ARM</span>
           <span id='$player.arm.label_bts'>BTS</span>
           ",
           textfield("$player.arm", param("$player.arm")),
           "</label>

           </div>\n";

    print "<div class='modifiers'>
           <h2>Modifiers</h2>
           <label>Range",
           popup_menu("$player.range", $range, param("$player.range") // '', $range_labels),
           "</label><br>",

           "<label>Link Team",
           popup_menu("$player.link", $link, param("$player.link") // '', $link_labels),
           "</label><br>",

           "<label>Visibility Penalty",
           popup_menu("$player.viz", $viz, param("$player.viz") // '', $viz_labels),
           "</label>",

           "<h2>Defensive Abilities</h2>
           <label>Camo",
           popup_menu("$player.ch", $ch, param("$player.ch") // '', $ch_labels),
           "</label><br>",

           checkbox("$player.cover", defined(param("$player.cover")), 3, 'Cover (+3 ARM, -3 Opponent BS)'),

           "</div>\n";

    print "</div>\n";
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

    if($output){
        print "<p>\n";
        for my $w (sort keys %{$output->{1}{hits}}){
            printf "P1 scores %d wounds %.2f%% %d+ wounds: %.2f%%<br>\n", $w, $output->{1}{hits}{$w}, $w, $output->{1}{cumul_hits}{$w};
        }
        print "</p>\n";

        printf "<p>No wounds: %.2f%%</p>\n", $output->{0};

        print "<p>\n";
        for my $w (sort keys %{$output->{2}{hits}}){
            printf "P2 scores %d wounds %.2f%% %d+ wounds: %.2f%%<br>\n", $w, $output->{2}{hits}{$w}, $w, $output->{2}{cumul_hits}{$w};
        }
        print "</p>\n";

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

sub gen_args{
    my ($us, $them) = @_;
    my ($link_bs, $link_b) = (0, 0);
    my ($arm, $ammo);

    if(param("$us.link") >= 3){
        $link_b = 1;
    }

    if(param("$us.link") >= 5){
        $link_bs = 3;
    }

    # Lookup number of saves, invert BTS sign if needed
    $arm = ceil(abs(param("$them.arm")) * $ammo_codes->{param("$us.ammo")}{arm});
    $ammo = $ammo_codes->{param("$us.ammo")}{code};

    max(param("$us.bs") + param("$them.ch") - param("$them.cover") + param("$us.range") + param("$us.viz") + $link_bs, 0),
    param("$us.b") + $link_b,
    max(param("$us.dam") - $arm - param("$them.cover"), 0),
    $ammo,
}

sub generate_output{
    my $output;
    my @args;

    if(param('p1.type') eq 'shoot' && param('p2.type') eq 'shoot'){
        # FtF shootout
        @args = (gen_args('p1', 'p2'), gen_args('p2', 'p1'));
    }

    if(@args){
        open DICE, '-|', 'inf-dice', @args;
        $output->{raw} = '';
        while(<DICE>){
            $output->{raw} .= $_;
            if(m/^P(.) Scores +(\d+) W[^0-9]*([0-9.]+)%.*(\d+)\+ W[^0-9]*([0-9.]+)%/){
                $output->{$1}{hits}{$2} = $3;
                $output->{$1}{cumul_hits}{$4} = $5;
            }elsif(m/^No Wounds: +([0-9.]+)/){
                $output->{0} = $1;
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
