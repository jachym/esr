package text;
#######################################################################
# esr.pl
# 
# Program na výpoèet zastoupení ekologických skupin rostlin -- modul esr_text.pm
# stará se o textové rozhraní k programu (co¾ je mimochodem dost pohoda)
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


sub text
{
    my $graf = 0; $graf=1 if($main::opts{'g'});
    my $print = '';
    
    # nejdøív promìnný
    if(!$main::opts{'f'})
    {
        print "\n       ERROR: Nebyl zadan vstupni soubor (-f soubor.txt)\n";
        &main::help();
    } else {

        $print = &esr::count_esrs($main::opts{'f'},'txt',$graf,$main::opts{'g'});
        
        if($main::opts{'o'})
        {
            open(OUT,">$main::opts{'o'}") or die "Soubor $main::opts{'o'} nelze otevøít: $!\n";
            print OUT $$print{'RETURN_STRING'};
            close OUT;
            print "Výsledek zapsán do souboru $main::opts{'o'}\n";
            
        } else {
            print "$$print{'RETURN_STRING'}";
        }
        
        if($graf == 1 && $$print{'GRAF_STRING'} =~ m/error/i)
        {
            print ("\n".$$print{'GRAF_STRING'}."\n");
        } elsif($graf== 1) {
            print ("Graf snad ulo¾en do souboru $main::opts{'g'}"."\n");
        }

    }

}

return 1;
