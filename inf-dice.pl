#!/usr/bin/perl

use strict;
use warnings;
use CGI qw(param);

sub print_head{
    print <<EOF
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

sub print_input_section{
    my ($player) = @_;
    print <<EOF
            <div id="$player">
                <div class="type">
                    <label>Action:</label>
                    <select name="$player.type">
                        <option value="shoot">Shoot</option>
                    </select>
                </div>

                <div class="shoot">
                    <label>
                        BS:
                        <input type="text" name="$player.bs">
                    </label>

                    <label>
                        B:
                        <select name="$player.b">
                            <option value=1>1</option>
                            <option value=2>2</option>
                            <option value=3>3</option>
                            <option value=4>4</option>
                            <option value=5>5</option>
                        </select>
                    </label>

                    <label>
                        DAM:
                        <input type="text" name="$player.dam">
                    </label>

                    <label>
                        Ammo:
                        <select name="$player.ammo">
                            <option value='N'>Normal</option>
                            <option value='D'>DA</option>
                            <option value='E'>EXP</option>
                            <option value='F'>Fire</option>
                        </select>
                    </label>
                </div>
EOF
}

sub print_input{
    print <<EOF
        <div id="input">
EOF
    print_input_section("p1");
    print_input_section("p2");

    print <<EOF
            <div id="submit">
                <input type="submit">
            </div>
        </div>
EOF
}

sub print_output{
    print <<EOF
        <div id="output">
            output goes here
        </div>
EOF
}

sub print_tail{
    print <<EOF
    </body>
</html>
EOF
}

sub print_page{
    print_head();

    print_input();

    print_output();

    print_tail();
}

print_page();
