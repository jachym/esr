package esr;
#######################################################################
# esr.pm
# 
# Program na výpoèet zastoupení ekologických skupin rostlin - knihovna esr.pm
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

# globální promìnná pro promìnné
my $vars_r = '';

# nastaví hodnotu promìnné $vars_r
sub set_vars{
    $vars_r = shift;
}

###################################################
# count_esr
# spoèítá zastoupení jednotlivých esr
#
# dostává:      $file: jméno vstupního souborou
#               $type: jeho typ (rtf/txt)
#               $graf: dìlat graf? (0,1)
#               $jmeno_grafu: kam se ma graf ulo¾it
#               
# return:       odkaz na hash s výsledky
# ##################################################
sub count_esrs {
    my @result_group = (); # pole pro v¹echny skupiny ESR
    my $file = shift;   # jméno souboru
    my $type = shift;   # typ souboru (txt/rtf)
    my $graf = shift;   # dìlat graf - 1/0
    my $jmeno_grafu = shift; # øetìzec, ve kterym je ulo¾eno, kam se má graf ulo¾it
    my $line = '';      # promìnná obsahující po øadì ka¾dý øádek ze souboru
    my %results = ();
    
    my @line = (); # øetìzec pro písmeknka v øádku split(m//,$line);
    my $number_till_50th_character = 0;  # boolean, bude-li na øádku do 50tého písmeknka èíslo
    my $i = 0; # bìhaè...

    # pokud je typ souboru rtf, pøevést
    # v ka¾dém pøípadì otevøít soubor FILE a naèíst ho do promìnné @file_content
    # 
    if($type eq 'rtf'){
        
        system("./rtfreader $file > $file.txt");
        open(FILE,"$file.txt") or die "Nelze otevøít soubor $file".":$!\n";
        
    } else {
    open (FILE,"$file") or die "Nelze otevøít soubor $file".": $!\n";
    
     @result_group = ();
    }

    # pro ka¾dý øádek v souboru
    foreach $line (<FILE>){
        chomp($line);
        
        # jestli¾e najde¹ nìco jako '1Z2', bude z toho nadpis v grafu
        if($line =~ m/[0-9][A-Z][0-9]/){
            $lt = $line;
            $lt =~ s/.*([0-9][A-Z][0-9]).*/$1/;
        
        # kdy¾ najde¹ nìco jako [6], je to øádek, který nás zajímá, tøeba nìco
        # jako
        # Athyrium filix-femina 5/6                   [6]           8     .
        # rod      druh         esr1/esr2             etá¾         pokryvnost
        # veskupinì1 pokryvnost ve skupinì2
        } elsif($line =~ m/\[[0-9]\]/){
            
            # next, pokud se na øádku nenajde èíslo do 50tého písmenka...
            substr($line,0,50) =~ m/\d/ ?  &save_esr($line) : next;

        } #/ elsif
        elsif($line =~ s/^[1-3]:(.*)/$1/){
            chomp $line;
            $line =~ s/p8ir/pøir/; # pøevod na èe¹tinu
            $line =~ s/^\s*//;
            if(length($line) <12){
                my $kolik_mezer=12-length($line);
                for(my $a = 0;$a<=$kolik_mezer;$a++){$line =~ s/$/ /;}
            }
            push @stupne_prirozenosti, $line;
        }
    }#/foreach $line

    close FILE;


    # vytiskni výslekdy
    $results{'RETURN_STRING'} = &print_results();

    # pokud si to srdce pøeje, vyrob grafík
    $results{'GRAF_STRING'} = &print_graph($jmeno_grafu) if($graf == 1);
    

    return \%results ;
}

#################################################################
# sub save_esr
# rozplizne ka¾dej øádek do potøebnejch promìnnejch a výsledek inteligentnì
#
# Athyrium filix-femina 5/6                   [6]           8     .
# rod      druh         esr1/esr2             etá¾         pokryvnost
# veskupinì1 pokryvnost ve skupinì2
#
# ulo¾í do pole @result_group
#
# $result_group[pocet_skupin_snimku]->{esr1} = plochaESR1
#                                   ->{esr2} = plochaESR2
#                                   ->{esr3} = plochaESR3
#                                   -> ...
#                                   ->{esr20}= plochaESR20
#                                   
#                                   ->{area} = plochaSKUPINY
#
#                                   plochaESRX mù¾e být i 0 nebo undef
#################################################################

sub save_esr{
    my $line = shift;

    my ($genus,$species,$esr,$layer) = '';
    my @groups = ();
    my $group = 0;
    my @esrs = ();
    my $no_of_esr = 0;
    my $area = 0;

    
    # separace komplexù druhù
    $line =~ s/\s+agg\./_agg\./;
    $line =~ s/\s+s\.str\./_s.str./;
    $line =~ s/\s+s\.lat\./_s.lat./;

       

    # rozdìlíme øádek na jednotlivé polo¾ky
    ($genus,$species,$esr,$layer,@groups) = split(m/\s+/,$line);

    # pro ka¾dou skupinu na øádku
    for($group = 0;$group< @groups;$group++){

        # pokud se tam najde lomníko v ESRech, tak bude víc Ekologickecj skupin
        # rostlin
        if($esr =~ m/\//){
               @esrs = split(m/\//,$esr);
           } else {
               @esrs = $esr;
           }

        # nahrazujeme teèku za 0
        $groups[$group] =~ s/^\.$/0/;

            for($no_of_esr = 0;$no_of_esr<@esrs;$no_of_esr++){ 

                if($no_of_esr == 0 && @esrs >1){$area = 0.6*$groups[$group];}
                elsif($no_of_esr == 1 && @esrs > 1){$area = 0.4*$groups[$group];}
                elsif(@esrs == 1){
                    $area = $groups[$group];
                }
                #print "Rostlina $genus skupina $group esr $esrs[$no_of_esr] plocha $area\n";#!!!zk

                $result_group[$group]->{"esr$esrs[$no_of_esr]"} += $area;
                $result_group[$group]->{"area"} += $area;
                
                }
    }

}

#################################################################
# sub print_results
# stará se o tisk výsledkù
#################################################################
sub print_results {
###################
    my $group_no = 0;   # èíslo skupiny
    my $esr = 0;        # èíslo ESR
    my $print_number = ''; # promìnná, která se tiskne - pokryvnost pro ESR a skupinu
    my $return_string = ''; # promìnná, která se vrací

    # tisk hlavièky tabulky
           $return_string .= sprintf "ESR\\sk.\t";
    
    # pro ka¾dou skupinu  vytisknout její èíslo
    for($group_no=0;$group_no<@result_group;$group_no++){
        $return_string .= sprintf ("%d\t",$group_no+1);
    }
    # /tisk hlavièky tabulky
    

    #tisk obsahu tabulky
    # pro ka¾dou ESR
    for($esr = 1;$esr <= 20; $esr++){

        # pro ka¾dou skupinu snímkù
        for($group_no=0;$group_no<@result_group;$group_no++){
            
        
            # plocha pro esrX nemusí být definována, pak nemá smysl tisknout
            # celý øádek
            if(defined($result_group[$group_no]->{"esr$esr"})){
                
                # pokud se jedná o první skupinu snímkù, tak je¹tì nebylo
                # vytisknuto èíslo ESR (øádek)
                if($group_no == 0){$return_string .= sprintf("\n%d\t", $esr);}

                # nesmí se dìlit 0!
                if($result_group[$group_no]->{"area"} != 0){

                    # promìnná print_number v sobì obsahuje podíl
                    # plocha_ESR_pro_skupinu_snimku/plocha_skupiny_celkem
                    $print_number = $result_group[$group_no]->{"esr$esr"}/$result_group[$group_no]->{"area"};
                
                } else {
                   # nesmí se dìlit 0, proto print_number obsahuje 0 rovnou, a
                   # bez dìlení
                   $print_number = 0;
               }
               
               # tisk procentického podílu*100
               $return_string .= sprintf("%.1f%%\t",$print_number*100);
           }#/if(defined...
       }#/for($group_no=0...
   }#/for($esr=1
   $return_string .=  "\n";
  return $return_string; 
}#/sub print_results



#################################################################
# sub print_graph
# stará se o tisk grafu
#################################################################
sub print_graph{
    my $jmeno_grafu = shift; # øetìzec, kam se má graf ulo¾it
    my $group_no = 0; # èíslo skupiny snímkù
    my $esr = 0;      # èíslo ESR
    my $graf = '';    # øetìzec obsahující definici grafu pro Rko
    my $system = '';  # øetìzec, který se nakonec po¹le systému
    my ($legenda,$popisky_y,$barvy) = ''; #promìnné pro graf

    my $rdata = "rdata.txt";       # soubor s daty
    my $rskript = "rskript.txt";       # soubor s daty
    #my $nazev_grafu = $lt."graf";
    my $nazev_grafu = "graf";

    my $print_number = 0;

    # barvy ESR pro graf
    my @colors = split (m/\n/,"         
Red
lightcyan
lightblue
skyblue
RoyalBlue
LawnGreen
khaki1
Yellow
Gold1
Navy
violetred4
Plum
Aquamarine2
Darkcyan
gray75
gray20
green4");

    # legenda k jednotlivým ESR pro graf
    my @legends = split(m/\n/,"
1 - +/- vápnomilné
2 - suché, bohaté
3 - vysýchavé, bohaté
4 - mírnì vlhké, bohaté
5 - èerstvé, bohaté
6 - nitrofilní
7 - velmi chudé
8 - suché, chudé
9 - mírnì vlhké, chudé
10 - èerstvé, stø. bohaté
11 - støídavì vlhké
12 - vlhké, stø. bohaté
13 - vlhké, bohaté
14 - mokré, proudící voda
15 - mokré, stagnující voda
16 - rašelinné
17 - +/- subalpinské");
    
    # pracujeme se souborem -- soubor
    open(RDATA,">$rdata") or die "Nelze otevøít soubor $rdata".": $!";


    # inicializace promìnných pro legendu a pro barvy
    $legenda = 'legenda<-c(';
    $barvy = 'barvy<-c(';
        
    # pro ka¾dou ESR
    for($esr = 1;$esr <= 20; $esr++){

        # inicializace popiskù na ose Y
        $popisky_y = 'popisky<-c(';
        
        # pro ka¾dou skupinu snímkù
        for($group_no=0;$group_no<@result_group;$group_no++){
            
                # pøidat do popiskù pro osu y èíslo skupiny snímkù
                if(defined($stupne_prirozenosti[$group_no])){
                    $popisky_y .= "'".$stupne_prirozenosti[$group_no]."',";
                } else {
                    $popisky_y .= sprintf("%d, ",$group_no+1);
                }

                # pokud je co pøidávat - plocha pro dannou ESR je != 0
                if(defined($result_group[$group_no]->{"esr$esr"})){
                    
                    # tisk souboru data pro Rko
                    if($result_group[$group_no]->{"area"} != 0){
                        $print_number = $result_group[$group_no]->{"esr$esr"}/$result_group[$group_no]->{"area"};
                    } else {
                        $print_number = 0;
                    }
                    printf RDATA ("%.3f ",$print_number*100);

                    #uzavøít øádek v souboru s daty
                    print RDATA "\n" if($group_no == @result_group-1);
                    
                    # pøidat do legendy a barev popisek k ESR a k barvám
                    $legenda .= "'$legends[$esr]'," if($group_no == 0);
                    $barvy .=   "'$colors[$esr]',"  if($group_no == 0);
                }#/if(defined
            }#!for($group_no
            
            # uzavøít skupiny
            $popisky_y .=");";
    }#/for($esr = 1

    #uzavøít barvy, legendu, soubor s daty pro graf
    $legenda.=");";
    $barvy.=");";
    close RDATA;

   # promìnná, ve které je celý soubor pro Rko
   my $ylim = 60+(@result_group-1)*15;
   # pøièti 10, pokud je v promìnné OPEN_DIR nìco jako c:\
   $ylim +=10 if($$vars_r{'OPEN_DIR'} =~ m/^[a-z]:\//i);
   #$ylim=80;
   $graf = '';
   #$graf .= "options(X11fonts =c(\"-adobe-helvetica-%s-%s-*-*-%d-*-*-*-*-*-iso8859-2\",\"-adobe-symbol-*-*-*-*-%d-*-*-*-*-*-iso8859-2\"))\n"; # !!!UNIX
   $graf .= $$vars_r{'R_GRAPH_FONT'}."\n";
    
   #$graf .=    "par(font=c('-microsoft-tahoma-medium-r-*-*-11-*-*-*-*-*-iso8859-2'))\n"; #!!!WINDOWS

    $graf .= $popisky_y."\n".$legenda."\n"."$barvy\n".
               qq/
png('$jmeno_grafu',width=550,height=335,);

   
b<-barplot(as.matrix(read.table('$rdata')),
    beside=F,axisnames=F,
    main='LT $lt - ekologické spektrum synuzie podrostu',
    font.main=2,
    cex.main=0.8,
    names.arg=popisky,
    ylim=c(-5,$ylim),xlim=c(0,100),
    horiz=T,width=c(15),
    col=barvy,
    space=c(4.1,/;
    
    for($i =0;$i<@result_group-1;$i++){
        $graf .= '0.2,';
    }
                            
     $graf .= qq/),axes=F,cex.names=0.75)

a<-axis(1,labels=F,tick=T,line=5,pos=60,outer=F,cex.axis=0.7,)
text(y=50,x=c(20,40,60,80,),labels=c('20%','40%','60%','80%',),cex=0.7,);
text(y=50,x=0,labels='0%',cex=0.7,adj=0);
text(y=50,x=100,labels='100%',cex=0.7,adj=1);
text(b, labels = popisky, srt = 0, , pos=2,offset=1, xpd = TRUE,cex=0.60)

legend(-0,50,legenda,col=barvy,ncol=3,cex=0.65,xjust=0.,text.width=27,trace=T,bty=c(\"n\"),fill=barvy,adj=0)
dev.off(2)
/;

    # ukládáme skript do souboru, a» to mù¾e jít ven
    open(RPROG,">$rskript") or 
                die "Nelze otevøít soubor $rskript".": $!";
                
    # vyèistit z promìnný graf promìnnou 
    print RPROG $graf;
    close RPROG;
    
    $system= "$$vars_r{'R_PATH'} --vanilla  -q < $rskript\n";
    
    #promìnná system jde ven
    #system($system);
    
    `$system`;

    return $jmeno_grafu;
}

return 1;
