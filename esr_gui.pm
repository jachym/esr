package gui;
#######################################################################
# esr_gui.pm
# 
# Program na výpoèet zastoupení ekologických skupin rostlin - knihovna esr_gui.pm
# stará se o grafické u¾iv. rozhraní k prográmku esr.pl
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


use Tk;

my $vars_r = ''; # globální promìnné
my $prog_version = ''; # verze programu
my $prog_name = ''; # jeho jméno

# nastavní místních globálních promìnných
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
# stará se o vykreslení grafického rozhnraí programu
#
# return : null
# ##################################################################
sub gui
{
    # hlavní okno
    $mw = MainWindow->new();
    my $font = $$vars_r{'GUI_FONT'}; # nastavení fontu

    $mw->title("$prog_name $prog_version"); # titulek

    # ¹títky v oknì
    my %label=();
    $label{'soubor'} = $mw->Label(-text=>"Textový soubor: ", -font=>$font);
    $label{'grafik'} = $mw->Label(-text=>"Soubor s grafem: ", -font=>$font);

    $entry{'soubor'}=$mw->Entry(-width=>20,);
    $entry{'grafik'}=$mw->Entry(-width=>20,);

    $text = $mw->Scrolled('Text',-width=>60,-height=>10,-scrollbars=>'e',-font=>$font);


    # tlaèítka
    my %button = ();
    $button{'open'}= $mw->Button(-text=>"Otevøít soubor",-command=>[\&otevrit_soubor,'soubor'],-font=>$font);
    $button{'grafik'}= $mw->Button(-text=>"Ulo¾it graf",-command=>[\&ulozit_graf,'grafik'],-font=>$font);
    $button{'run'}=$mw->Button(-text=>"ZESRuj!",-command=>\&run,-font=>$font);
    $button{'close'}=$mw->Button(-text=>"Zavøít",-command=>sub{exit();},-font=>$font);

    #############################
    #nastavní rozlo¾ení
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
    my $filetypes=[['Textové soubory','.txt']];
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
    my $filetypes=[['Grafické soubory','.png']];


    
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
        # grafík
        #    $grafik->configure(-file=>"graf.gif",);
        #/ grafík
        $text->Insert("\n".'Graf ulo¾en do souboru '.$jmeno_grafu."\n");
    } 
    elsif ($graf == 1) {
        $text->Insert("\nGraf snad ulo¾en do souboru $$print{'GRAF_STRING'}\n");
    }

    #print "Ahoj Svìtì!!\n";

    &main::write_variables($vars_r);
}
return 1;
