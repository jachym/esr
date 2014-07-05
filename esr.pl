#!/usr/bin/perl -w
#######################################################################
# esr.pl
# 
# Program na výpoèet zastoupení ekologických skupin rostlin
# 
# Copyright (C)2004 Jachym Cepicky
# jachym.cepicky (zavinac) centrum (tecka) cz
#
# Posledni zmena:       23.12.2004
# Verze:                0.2.0
# URL:                  http://www.fle.czu.cz/~jachym/programs/esr.html
#
# LICENCE:
# Tento program je svobodný software; mù¾ete jej ¹íøit a modifikovat podle
# ustanovení GNU General Public License, vydávané Free Software
# Foundation; a to buï verze 2 této licence anebo (podle va¹eho uvá¾ení)
# kterékoli pozdìj¹í verze.
# 
# Tento program je roz¹iøován v nadìji, ¾e bude u¾iteèný, av¹ak BEZ
# JAKÉKOLI ZÁRUKY; neposkytují se ani odvozené záruky PRODEJNOSTI anebo
# VHODNOSTI PRO URÈITÝ ÚÈEL. Dal¹í podrobnosti hledejte ve GNU General Public License.
# 
# Kopii GNU General Public License jste mìl obdr¾et spolu s tímto
# programem; pokud se tak nestalo, napi¹te o ni Free Software Foundation,
# Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#######################################################################

# pou¾ité knihovny
use strict;
use Cwd;
use Getopt::Std;

# pou¾ité promìnné
use vars qw(%opts);

my $prog_version = 0.2; # verze
my $prog_name= "ESRBuilder"; # název
my $vars_r = &read_variables(); # odkaz na promìnné pøedává funkce, která je
                                # naète ze souboru

# dal¹í knihovny a promìnné
use esr; 
&esr::set_vars($vars_r);
use esr_gui;
&gui::set_vars($vars_r,$prog_name,$prog_version);
use esr_text;

#
# vlastní program zaèíná zde
# 

#pokud zavolan bez parametru, tak se spusti ve forme GUI
if (!getopts('g:hf:o:',\%opts)) { 
    die "Zadne promenne nebyly nacteny\n";
} 

if (%opts eq '0') {
    $vars_r = &gui::gui();
}
elsif($opts{'h'}) {
    &help;
} 
else {
    &text::text();
}

###########################################
# save_env
# ukládá hodnoty promìnných
#
# $var - promìnná, $val - její hodnota
#
# return : null
# #########################################
#sub save_env{
#    my $var = shift;
#    my $val = shift;
#
#    if($var eq 'OPEN_DIR'|| $var eq 'SAVE_DIR'){
#        $val =~ s/(\\|\/)\w+\.\w{3}$/$1/;
#    }
#    print ENV "$var=$val\n";
#
#}
############################################
## load_env
## naèítá hodnoty promìnných
## 
## return: odkaz na hash s promìnnými
############################################
#sub load_env{
#    
#        # otevøtení souboru s promìnnými
#        open(ENV,"environment.txt") or 
#            print "\n\n\nSoubor environment.txt nelze otevøít, nebudu naèítat ¾ádné promìnné prostøedí.\n\n\n";
#        my %vars = ();
#        my $var = '';
#        my $val = '';
#
#        # pro ka¾dý øádek souboru
#        while(<ENV>){
#            next if(m/^#/); # pøeskoè komentáø
#            chomp;
#            ($var,$val) = split(m/=/); 
#            $vars{$var}=$val;
#        }
#         
#        close ENV;
#        return \%vars;
#}
#
###################################################
# help
# tiskne help a ukonèí program
# 
###################################################
sub help
{
    print qq(
    $prog_name $prog_version je urcen pro pocitani prumernych cisel
    ekologickych skupin rostlin.

    Pouziti:
        esr.pl -h -f soubor.txt -g soubor.png -o soubor.txt

        kde
        -h              vytiskne tuto napovedu
        -f soubor.txt   jmeno vstupniho textoveho souboru
        -g soubor.png   volitelne jmeno vysledneho grafu
        -o soubor.txt   jmeno souboru, do ktereho se maji ulozit vysledky

    Autor: Jachym Cepicky
           http://les-ejk.cz
           jachym.cepicky\@centrum.cz\n);
       exit;

    
}
#######################################################################
# sub read_variables
#
# vyzvedne aktuální hodnoty promìnných prostøedí z konfiguraèního souboru
#
#######################################################################
sub read_variables {
    my %vars = ();
 
    if(-e "etc/esr.conf")
    {
        my $var = '';
        my $val = '';
        
        open (ENV, "etc/esr.conf") or die "Soubor etc/esr.conf nelze otevøít:$!\n\n";
        while(<ENV>)
        {
            next if(m/^#/);
            next if(m/^$/);
            chomp;
            ($var,$val) = split(m/==/);
            $vars{$var}=$val;
        }
         
        close ENV;
       
    } else {
   
        print "Soubor etc/env.conf bude vytvoøen\n";

        %vars=('OPEN_DIR'=>'./',
               'SAVE_DIR'=>'./',
               'GUI_FONT'=>'-biznet-*-*-r-*-*-*-80-*-*-*-*-iso8859-2',
               'R_PATH'=>'/usr/bin/R'
           );        
   }

   if(%vars eq  '0'){
     print "Soubor etc/env.conf bude vytvoøen\n";

        %vars=('OPEN_DIR'=>'./',
               'SAVE_DIR'=>'./',
               'GUI_FONT'=>'-biznet-*-*-r-*-*-*-80-*-*-*-*-iso8859-2',
               'R_PATH'=>'/usr/bin/R',
               'R_GRAPH_FONT'=>'options(X11fonts =c(\"-adobe-helvetica-%s-%s-*-*-%d-*-*-*-*-*-iso8859-2\",\"-adobe-symbol-*-*-*-*-%d-*-*-*-*-*-iso8859-2\"))\n'
           );        
       }

   return \%vars;

}
#######################################################################
# sub write_variables
#
# zapí¹e aktuální hodnoty promìnných prostøedí do konfiguraèního souboru
#
#######################################################################
sub write_variables {
    my @config_file = ();
    my $vars_r = shift;
    my %kontrola = ('OPEN_DIR'=>0,'SAVE_DIR'=>0,'GUI_FONT'=>0,'R_PATH'=>0);

    
    # otevøít soubor a naèíst z nìj promìnné
    open (ENV, "etc/esr.conf") or print "Soubor etc/esr.conf nelze otevøít: $!\n\n";
    @config_file = <ENV>;
    close ENV;

    # otevøít ho znovu, ale pro zápis
    open(ENV,">etc/esr.conf") or die "Soubor etc/esr.conf nelze otevøít: $!\n\n";
    
    # pokud je v¹echno v poøádku,
    # 1) na ka¾dém øádku se zkontroluje jméno promìnné a 
    # 2) vyskytujeli-se, tak se nastaví hodnota kontroly na 1
    foreach my $line (@config_file)
    {
        if($line =~ m/\s*\w/i && !($line =~ m/^#/))
        {
               if($line =~ m/OPEN_DIR/){$line =~ s/=.*$/==$$vars_r{'OPEN_DIR'}/;$kontrola{'OPEN_DIR'}=1;}
            elsif($line =~ m/SAVE_DIR/){$line =~ s/=.*$/==$$vars_r{'SAVE_DIR'}/;$kontrola{'SAVE_DIR'}=1;}
            elsif($line =~ m/GUI_FONT/){$line =~ s/=.*$/==$$vars_r{'GUI_FONT'}/;$kontrola{'GUI_FONT'}=1;}
            elsif($line =~ m/R_PATH/ ) {$line =~ s/=.*$/==$$vars_r{'R_PATH'}/;$kontrola{'R_PATH'}=1;}

            print ENV $line;
            
        # to je tady jenom kvùli komentáøùm a tak
        } else {
            print ENV $line;
        }
    }

    # a nyní vypi¹, co tam podle kontroly nebylo, na co se zapomìlo
    foreach (keys %kontrola){
        if($kontrola{$_} == 0)
        {
            print ENV "$_==$$vars_r{$_}\n";
        }
    }

    # pokud ten soubor neexistuje, tak ho prostì vytvoø
    unless(-e "etc/esr.conf")
    {
        foreach(keys %$vars_r)
        {
            print ENV "$_=$$vars_r{$_}\n";
        }
    }

    close ENV;
}


