#!/usr/bin/perl

use strict;
use warnings;
use Time::HiRes qw(time);
use CGI qw/:standard/;
$CGI::POST_MAX=1024 * 100;  # max 100K posts
$XGI::DISABLE_UPLOADS = 1;  # no uploads


sub print_head{
    print <<EOF
Content-Type: text/html; charset=utf-8

<!DOCTYPE HTML>
<html>
    <head>
        <meta charset="UTF-8">
        <title>Infinity Dice Calculator</title>
        <link href="inf-dice.css" rel="stylesheet" type="text/css">
    </head>
    <body>
EOF
}

my $action = ['shoot'];
my $action_labels = {shoot => 'Shoot'};
my $burst = [1, 2, 3, 4, 5];
my $ammo = ['N', 'D', 'E', 'F'];
my $ammo_lables = {
    N => 'Normal', 
    D => 'DA',
    E => 'EXP',
    F => 'Fire',
};
my $ch = ['0', '-3', '-6'];
my $ch_labels = {
    0 => 'None',
    -3 => 'Mimetism/Camo',
    -6 => 'TO Camo/ODD/ODF',
};
my $range = ['+3', '0', '-3', '-6'];
my $viz = ['0', '-3', '-6'];

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
           popup_menu("$player.ammo", $ammo, param("$player.ammo") // '', $ammo_lables),
           "</label>

           <br>

           <label>DAM",
           textfield("$player.dam", param("$player.dam")),
           "</label>

           <label>ARM/BTS (positive)",
           textfield("$player.arm", param("$player.arm")),
           "</label>

           </div>\n";

    print "<div class='modifiers'>
           <label>Range",
           popup_menu("$player.mod_range", $range, param("$player.mod_range") // ''),
           "</label>",

           "<h2>Defensive Abilities</h2>
           <label>Camo",
           popup_menu("$player.mod_ch", $ch, param("$player.mod_ch") // '', $ch_labels),
           "</label>",

           checkbox("$player.mod_cover", defined(param("$player.mod_cover")), 3, 'Cover'),

           "<h2>Other Penalties</h2>
           <label>Visibility",
           popup_menu("$player.mod_viz", $viz, param("$player.mod_viz") // ''),
           "</label>",

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
    print <<EOF
        <div id="output">
        <pre>
$output
        </pre>
        </div>
EOF
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

    max(param("$us.bs") + param("$them.mod_ch") - param("$them.mod_cover") + param("$us.mod_range") + param("$us.mod_viz"), 0),
    param("$us.b"),
    max(param("$us.dam") - param("$them.arm") - param("$them.mod_cover"), 0),
    param("$us.ammo"),
}

sub generate_output{
    my $output='';
    my @args;

    if(param('p1.type') eq 'shoot' && param('p2.type') eq 'shoot'){
        # FtF shootout
        @args = (gen_args('p1', 'p2'), gen_args('p2', 'p1'));
    }

    if(@args){
        open DICE, '-|', 'inf-dice', @args;
        while(<DICE>){
            $output .= $_;
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
