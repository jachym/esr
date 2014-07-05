package gui;
#######################################################################
# esr_gui.pm
# 
# Program na v�po�et zastoupen� ekologick�ch skupin rostlin - knihovna esr_gui.pm
# star� se o grafick� u�iv. rozhran� k progr�mku esr.pl
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


use Tk;

my $vars_r = ''; # glob�ln� prom�nn�
my $prog_version = ''; # verze programu
my $prog_name = ''; # jeho jm�no

# nastavn� m�stn�ch glob�ln�ch prom�nn�ch
sub set_vars{
    $vars_r = shift;
    $prog_name = shift;
    $prog_version = shift;
}



my %entry= ();
my $mw = '';
my $text = '';

######################################################################
# sub gui
#
# star� se o vykreslen� grafick�ho rozhnra� programu
#
# return : null
# ##################################################################
sub gui
{
    # hlavn� okno
    $mw = MainWindow->new();
    my $font = $$vars_r{'GUI_FONT'}; # nastaven� fontu

    $mw->title("$prog_name $prog_version"); # titulek

    # �t�tky v okn�
    my %label=();
    $label{'soubor'} = $mw->Label(-text=>"Textov� soubor: ", -font=>$font);
    $label{'grafik'} = $mw->Label(-text=>"Soubor s grafem: ", -font=>$font);

    $entry{'soubor'}=$mw->Entry(-width=>20,);
    $entry{'grafik'}=$mw->Entry(-width=>20,);

    $text = $mw->Scrolled('Text',-width=>60,-height=>10,-scrollbars=>'e',-font=>$font);


    # tla��tka
    my %button = ();
    $button{'open'}= $mw->Button(-text=>"Otev��t soubor",-command=>[\&otevrit_soubor,'soubor'],-font=>$font);
    $button{'grafik'}= $mw->Button(-text=>"Ulo�it graf",-command=>[\&ulozit_graf,'grafik'],-font=>$font);
    $button{'run'}=$mw->Button(-text=>"ZESRuj!",-command=>\&run,-font=>$font);
    $button{'close'}=$mw->Button(-text=>"Zav��t",-command=>sub{exit();},-font=>$font);

    #############################
    #nastavn� rozlo�en�
    $mw->Label(-text=>"$prog_name $prog_version",-font=>"courier 14 bold")->grid("-","-");
    $label{'soubor'}->grid($entry{'soubor'},$button{'open'});
    $label{'grafik'}->grid($entry{'grafik'},$button{'grafik'});
    #$checkbox{'graf'}->grid($button{'run'},"x");
    $button{'run'}->grid("x","x");
    $text->grid("-","-");
    #$grafik_l->grid("-","-");
    $button{'close'}->grid("x","x");

    MainLoop();
}
####################################
sub otevrit_soubor{
    my $entry = shift;
    my $file = '';
    my $filetypes=[['Textov� soubory','.txt']];
    my $jmeno_grafu = '';

    
    $file = $mw->getOpenFile(-initialfile=>'*.txt',
                             -defaultextension=>'.txt',
			     #-filetypes => $filetypes, #FIXME
                             -initialdir=>$$vars_r{'OPEN_DIR'},
                         );
    unless($file eq '')
    {
        $entry{$entry}->delete("0","end");
        $entry{$entry}->Insert($file);
    }
    $file=~ s/(\\|\/)\w+\.\w{3}$/$1/;
    $$vars_r{'OPEN_DIR'} = $file; 
}

####################################
sub ulozit_graf {
    my $entry = shift;
    my $file = '';
    my $filetypes=[['Grafick� soubory','.png']];


    
    $file = $mw->getSaveFile(-initialfile=>'*.png',
                             -defaultextension=>'.png',
			     #-filetypes=>$filetypes,#FIXME
                             -initialdir=>$$vars_r{'SAVE_DIR'},
                         );
    unless($file eq '')
    {
        $entry{$entry}->delete("0","end");
        $entry{$entry}->Insert($file);
    }
    $file=~ s/(\\|\/)\w+\.\w{3}$/$1/;
    $$vars_r{'SAVE_DIR'}=$file;
}

##################################
sub run {
    my $file = $entry{'soubor'}->get();
    my $jmeno_grafu = $entry{'grafik'}->get();
    my $print = '';
    my $graf = 0;

    $text->delete("1.0","100.0");

    if($jmeno_grafu ne ''){
        $graf = 1
    } else {
        $graf = 0
    }
    $print = &esr::count_esrs($file,'txt',$graf,$jmeno_grafu);
    #print "$$print\n";

    $text->Insert("$$print{'RETURN_STRING'}");
    if($graf == 1 && $$print{'GRAF_STRING'} =~ m/error/i){
        # graf�k
        #    $grafik->configure(-file=>"graf.gif",);
        #/ graf�k
        $text->Insert("\n".'Graf ulo�en do souboru '.$jmeno_grafu."\n");
    } 
    elsif ($graf == 1) {
        $text->Insert("\nGraf snad ulo�en do souboru $$print{'GRAF_STRING'}\n");
    }

    #print "Ahoj Sv�t�!!\n";

    &main::write_variables($vars_r);
}
return 1;
