# Infinity Dice Calculator
Dice probability tool for the miniatures game Infinity

## Copyright Notice
Infinity the game is copyright Corvus Belli SLL.  All game data is used with permission.

## Usage instructions
Should you wish to use this tool, it is available at http://inf-dice.ghostlords.com/

If you wish to install your own copy, follow these steps:

1. Clone this repository to a local directory.
2. Install the required Perl modules: GD, CGI, Time::HiRes, Data::Dumper
3. Run `add_infinitydata_git.sh` to clone the InfinityData repository, used for unit data.  This may require a Bitbucket account and/or membership in the InfinityData project on that site.
4. Run `make update_data` to fetch the current unit data.
5. Run `make` to build all targets.
6. Run `make install` to install the backend (`inf-dice-n4`) to `/usr/local/bin` and the web resources to `/var/www/inf-dice`.
7. Ensure that your web server is configured to execute Perl scripts.  Apache's mod_perl is not required or used.
