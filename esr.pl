#!/usr/bin/perl -w
#######################################################################
# esr.pl
# 
# Program na v�po�et zastoupen� ekologick�ch skupin rostlin
# 
# Copyright (C)2004 Jachym Cepicky
# jachym.cepicky (zavinac) centrum (tecka) cz
#
# Posledni zmena:       23.12.2004
# Verze:                0.2.0
# URL:                  http://www.fle.czu.cz/~jachym/programs/esr.html
#
# LICENCE:
# Tento program je svobodn� software; m��ete jej ���it a modifikovat podle
# ustanoven� GNU General Public License, vyd�van� Free Software
# Foundation; a to bu� verze 2 t�to licence anebo (podle va�eho uv�en�)
# kter�koli pozd�j�� verze.
# 
# Tento program je roz�i�ov�n v nad�ji, �e bude u�ite�n�, av�ak BEZ
# JAK�KOLI Z�RUKY; neposkytuj� se ani odvozen� z�ruky PRODEJNOSTI anebo
# VHODNOSTI PRO UR�IT� ��EL. Dal�� podrobnosti hledejte ve GNU General Public License.
# 
# Kopii GNU General Public License jste m�l obdr�et spolu s t�mto
# programem; pokud se tak nestalo, napi�te o ni Free Software Foundation,
# Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#######################################################################

# pou�it� knihovny
use strict;
use Cwd;
use Getopt::Std;

# pou�it� prom�nn�
use vars qw(%opts);

my $prog_version = 0.2; # verze
my $prog_name= "ESRBuilder"; # n�zev
my $vars_r = &read_variables(); # odkaz na prom�nn� p�ed�v� funkce, kter� je
                                # na�te ze souboru

# dal�� knihovny a prom�nn�
use esr; 
&esr::set_vars($vars_r);
use esr_gui;
&gui::set_vars($vars_r,$prog_name,$prog_version);
use esr_text;

#
# vlastn� program za��n� zde
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
# ukl�d� hodnoty prom�nn�ch
#
# $var - prom�nn�, $val - jej� hodnota
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
## na��t� hodnoty prom�nn�ch
## 
## return: odkaz na hash s prom�nn�mi
############################################
#sub load_env{
#    
#        # otev�ten� souboru s prom�nn�mi
#        open(ENV,"environment.txt") or 
#            print "\n\n\nSoubor environment.txt nelze otev��t, nebudu na��tat ��dn� prom�nn� prost�ed�.\n\n\n";
#        my %vars = ();
#        my $var = '';
#        my $val = '';
#
#        # pro ka�d� ��dek souboru
#        while(<ENV>){
#            next if(m/^#/); # p�esko� koment��
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
# tiskne help a ukon�� program
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
# vyzvedne aktu�ln� hodnoty prom�nn�ch prost�ed� z konfigura�n�ho souboru
#
#######################################################################
sub read_variables {
    my %vars = ();
 
    if(-e "etc/esr.conf")
    {
        my $var = '';
        my $val = '';
        
        open (ENV, "etc/esr.conf") or die "Soubor etc/esr.conf nelze otev��t:$!\n\n";
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
   
        print "Soubor etc/env.conf bude vytvo�en\n";

        %vars=('OPEN_DIR'=>'./',
               'SAVE_DIR'=>'./',
               'GUI_FONT'=>'-biznet-*-*-r-*-*-*-80-*-*-*-*-iso8859-2',
               'R_PATH'=>'/usr/bin/R'
           );        
   }

   if(%vars eq  '0'){
     print "Soubor etc/env.conf bude vytvo�en\n";

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
# zap�e aktu�ln� hodnoty prom�nn�ch prost�ed� do konfigura�n�ho souboru
#
#######################################################################
sub write_variables {
    my @config_file = ();
    my $vars_r = shift;
    my %kontrola = ('OPEN_DIR'=>0,'SAVE_DIR'=>0,'GUI_FONT'=>0,'R_PATH'=>0);

    
    # otev��t soubor a na��st z n�j prom�nn�
    open (ENV, "etc/esr.conf") or print "Soubor etc/esr.conf nelze otev��t: $!\n\n";
    @config_file = <ENV>;
    close ENV;

    # otev��t ho znovu, ale pro z�pis
    open(ENV,">etc/esr.conf") or die "Soubor etc/esr.conf nelze otev��t: $!\n\n";
    
    # pokud je v�echno v po��dku,
    # 1) na ka�d�m ��dku se zkontroluje jm�no prom�nn� a 
    # 2) vyskytujeli-se, tak se nastav� hodnota kontroly na 1
    foreach my $line (@config_file)
    {
        if($line =~ m/\s*\w/i && !($line =~ m/^#/))
        {
               if($line =~ m/OPEN_DIR/){$line =~ s/=.*$/==$$vars_r{'OPEN_DIR'}/;$kontrola{'OPEN_DIR'}=1;}
            elsif($line =~ m/SAVE_DIR/){$line =~ s/=.*$/==$$vars_r{'SAVE_DIR'}/;$kontrola{'SAVE_DIR'}=1;}
            elsif($line =~ m/GUI_FONT/){$line =~ s/=.*$/==$$vars_r{'GUI_FONT'}/;$kontrola{'GUI_FONT'}=1;}
            elsif($line =~ m/R_PATH/ ) {$line =~ s/=.*$/==$$vars_r{'R_PATH'}/;$kontrola{'R_PATH'}=1;}

            print ENV $line;
            
        # to je tady jenom kv�li koment���m a tak
        } else {
            print ENV $line;
        }
    }

    # a nyn� vypi�, co tam podle kontroly nebylo, na co se zapom�lo
    foreach (keys %kontrola){
        if($kontrola{$_} == 0)
        {
            print ENV "$_==$$vars_r{$_}\n";
        }
    }

    # pokud ten soubor neexistuje, tak ho prost� vytvo�
    unless(-e "etc/esr.conf")
    {
        foreach(keys %$vars_r)
        {
            print ENV "$_=$$vars_r{$_}\n";
        }
    }

    close ENV;
}


