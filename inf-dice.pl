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

my $action = ['bs', 'cc', 'dodge', 'none'];
my $action_labels = {
    bs => 'BS Attack',
    cc => 'CC Attack',
    dodge => 'Dodge',
    none => 'No Action',
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
    Viral => {code => 'D', save => 'bts'},
    'E/M' => {code => 'N', save => 'bts'},
    'E/M2' => {code => 'D', save => 'bts'},
    'Smoke' => {code => '-', cover => 0},
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
    -3 => 'L1 (-3 Opponent CC)',
    -6 => 'L2 (-6 Opponent CC)',
    -9 => 'L3 (-9 Opponent CC)',
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

sub span_popup_menu{
    my (%args) = @_;
    my $label = $args{-label};
    delete $args{-label};

    return "<span id='$args{-name}'><label>$label " .  popup_menu(%args) .  "</label></span>\n";
}

sub print_input_section{
    my ($player_num) = @_;
    my $player = "p" . $player_num;

    print "<div id='$player'>\n";
    printf "<h1>Player %d</h1>\n", $player_num;

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
          <h2>Model Attributes</h2>",
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
              -values => [6 .. 15],
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
           <h2>Skill Modifiers</h2>",
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
           "<h2>Defensive Abilities</h2>",

           "<span id='$player.cover'>",
           checkbox("$player.cover", defined(param("$player.cover")), 3, 'Cover (+3 ARM, -3 Opponent BS)'),
           "</span>
           <br>",
           span_popup_menu(-name => "$player.ch",
               -values => $ch,
               -default => param("$player.ch") // '',
               -labels => $ch_labels,
               -label => "Camo",
           ),
           "<br>",
           span_popup_menu(-name => "$player.ikohl",
               -values => $ikohl,
               -default => param("$player.ikohl") // '',
               -labels => $ikohl_labels,
               -label => "i-Kohl",
           ),
           "<br>",

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
    print_input_section(1);
    print_input_section(2);
    print_input_tail();
}

sub print_output{
    my ($output) = @_;

    if(!$output){
        return;
    }

    print "<div id='output'>\n";

    if($output->{error}){
        print "<div class='output_error'>$output->{error}</div>\n";
    }

    if($output->{hits}){
        my %all_keys;

        for my $h (keys %{$output->{hits}{1}}, keys %{$output->{hits}{2}}){
            $all_keys{$h} = 1;
        }

        # make sure there is at least one row
        if(!keys %all_keys){
            $all_keys{0} = 1;
        }

        print "<table id='output_data'>\n";
        print "<tr><th colspan=4 width='33%'>Player 1</th><th colspan=2 width='33%'>vs.</th><th colspan=4 width='33%'>Player 2</th></tr>\n";

        my $first_row = 1;
        for my $h (sort {$a <=> $b} keys %all_keys){
            print "<tr>";

            if(exists $output->{hits}{1}{$h}){
                printf "<td>%d success%s</td><td class='p1-hit-$h num'>%.2f%%</td>", $h, ($h > 1 ? 'es' : ''), $output->{hits}{1}{$h};
                if(scalar keys $output->{hits}{1} > 1){
                    printf "<td>%d or more</td><td class='p1-cumul-hit-$h num'>%.2f%%</td>", $h, $output->{cumul_hits}{1}{$h};
                }else{
                    print "<td colspan='2'></td>";
                }
            }else{
                print "<td colspan=4></td>";
            }

            if($first_row){
                printf "<td>No successes</td><td class='miss num'>%.2f%%</td>", $output->{hits}{0};
                $first_row = 0;
            }else{
                print "<td colspan=2></td>";
            }

            if(exists $output->{hits}{2}{$h}){
                printf "<td>%d success%s</td><td class='p2-hit-$h num'>%.2f%%</td>", $h, ($h > 1 ? 'es' : ''), $output->{hits}{2}{$h};
                if(scalar keys $output->{hits}{2} > 1){
                    printf "<td>%d or more</td><td class='p2-cumul-hit-$h num'>%.2f%%</td>", $h, $output->{cumul_hits}{2}{$h};
                }else{
                    print "<td colspan='2'></td>";
                }
            }else{
                print "<td colspan=4></td>";
            }

            print "</tr>\n";
        }

        print "</table>\n";

        print "<table class='hitbar'><tr>\n";
        for my $h (sort {$b <=> $a} keys %{$output->{hits}{1}}){
            print "<td width='$output->{hits}{1}{$h}%' class='p1-hit-$h center'>";
            if($output->{hits}{1}{$h} >= 5.0){
                printf "%d%%", $output->{hits}{1}{$h};
            }
            print "</td>\n";
        }
        print "<td width='$output->{hits}{0}%' class='miss center'>";
        if($output->{hits}{0} >= 5.0){
            printf "%d%%", $output->{hits}{0};
        }
        print "</td>\n";
        for my $h (sort {$a <=> $b} keys %{$output->{hits}{2}}){
            print "<td width='$output->{hits}{2}{$h}%' class='p2-hit-$h center'>";
            if($output->{hits}{2}{$h} >= 5.0){
                printf "%d%%", $output->{hits}{2}{$h};
            }
            print "</td>\n";
        }
        print "</tr></table>\n"
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
    my ($arm, $ammo, $cover, $save);
    my $mods;

    if(param("$us.link") >= 3){
        $link_b = 1;
    }

    if(param("$us.link") >= 5){
        $link_bs = 3;
    }

    # Lookup number of saves, invert BTS sign if needed
    $arm = $ammo_codes->{param("$us.ammo")}{arm} // 1;
    $save = $ammo_codes->{param("$us.ammo")}{save} // 'arm';
    $arm = ceil(abs(param("$them.$save")) * $arm);
    $ammo = $ammo_codes->{param("$us.ammo")}{code};
    $cover = $ammo_codes->{param("$us.ammo")}{cover} // 1;
    $cover = param("$them.cover") * $cover;

    if(param("$us.action") eq 'bs'){
        # BS mods
        $mods = param("$them.ch") - $cover + param("$us.range") + param("$us.viz") + $link_bs;
    }elsif(param("$us.action") eq 'cc'){
        # CC mods
        $mods = param("$them.ikohl") + $link_bs;
    }

    return (
        max(param("$us.stat") + $mods, 0),
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
        max(param("$us.stat") + param("$us.dodge_unit"), 0),
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

    if(param("$us.action") eq 'cc' || param("$us.action") eq 'bs'){
        return gen_attack_args($us, $them);
    }elsif(param("$us.action") eq 'dodge'){
        return gen_dodge_args($us, $them);
    }elsif(param("$us.action") eq 'none'){
        return gen_none_args($us, $them);
    }

    return ();
}

sub generate_output{
    my $output;
    my (@args1, @args2);
    my $mode;

    if(!defined param('p1.action') || !defined param('p2.action')){
        return;
    }

    if(param('p1.action') eq 'cc' && param('p2.action') eq 'cc'){
        $mode = 'CC';
    }else{
        $mode = 'BS';
    }

    @args1 = gen_args('p1', 'p2');
    @args2 = gen_args('p2', 'p1');

    if(@args1 && @args2){
        open DICE, '-|', 'inf-dice', ($mode, @args1, @args2);
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

#my $IN;
#open $IN, "test.in" or die;
#restore_parameters($IN);
#close $IN;

print_page();
