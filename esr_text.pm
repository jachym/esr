package text;
#######################################################################
# esr.pl
# 
# Program na v�po�et zastoupen� ekologick�ch skupin rostlin -- modul esr_text.pm
# star� se o textov� rozhran� k programu (co� je mimochodem dost pohoda)
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


sub text
{
    my $graf = 0; $graf=1 if($main::opts{'g'});
    my $print = '';
    
    # nejd��v prom�nn�
    if(!$main::opts{'f'})
    {
        print "\n       ERROR: Nebyl zadan vstupni soubor (-f soubor.txt)\n";
        &main::help();
    } else {

        $print = &esr::count_esrs($main::opts{'f'},'txt',$graf,$main::opts{'g'});
        
        if($main::opts{'o'})
        {
            open(OUT,">$main::opts{'o'}") or die "Soubor $main::opts{'o'} nelze otev��t: $!\n";
            print OUT $$print{'RETURN_STRING'};
            close OUT;
            print "V�sledek zaps�n do souboru $main::opts{'o'}\n";
            
        } else {
            print "$$print{'RETURN_STRING'}";
        }
        
        if($graf == 1 && $$print{'GRAF_STRING'} =~ m/error/i)
        {
            print ("\n".$$print{'GRAF_STRING'}."\n");
        } elsif($graf== 1) {
            print ("Graf snad ulo�en do souboru $main::opts{'g'}"."\n");
        }

    }

}

return 1;
