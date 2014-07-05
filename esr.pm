package esr;
#######################################################################
# esr.pm
# 
# Program na v�po�et zastoupen� ekologick�ch skupin rostlin - knihovna esr.pm
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

# glob�ln� prom�nn� pro prom�nn�
my $vars_r = '';

# nastav� hodnotu prom�nn� $vars_r
sub set_vars{
    $vars_r = shift;
}

###################################################
# count_esr
# spo��t� zastoupen� jednotliv�ch esr
#
# dost�v�:      $file: jm�no vstupn�ho souborou
#               $type: jeho typ (rtf/txt)
#               $graf: d�lat graf? (0,1)
#               $jmeno_grafu: kam se ma graf ulo�it
#               
# return:       odkaz na hash s v�sledky
# ##################################################
sub count_esrs {
    my @result_group = (); # pole pro v�echny skupiny ESR
    my $file = shift;   # jm�no souboru
    my $type = shift;   # typ souboru (txt/rtf)
    my $graf = shift;   # d�lat graf - 1/0
    my $jmeno_grafu = shift; # �et�zec, ve kterym je ulo�eno, kam se m� graf ulo�it
    my $line = '';      # prom�nn� obsahuj�c� po �ad� ka�d� ��dek ze souboru
    my %results = ();
    
    my @line = (); # �et�zec pro p�smeknka v ��dku split(m//,$line);
    my $number_till_50th_character = 0;  # boolean, bude-li na ��dku do 50t�ho p�smeknka ��slo
    my $i = 0; # b�ha�...

    # pokud je typ souboru rtf, p�ev�st
    # v ka�d�m p��pad� otev��t soubor FILE a na��st ho do prom�nn� @file_content
    # 
    if($type eq 'rtf'){
        
        system("./rtfreader $file > $file.txt");
        open(FILE,"$file.txt") or die "Nelze otev��t soubor $file".":$!\n";
        
    } else {
    open (FILE,"$file") or die "Nelze otev��t soubor $file".": $!\n";
    
     @result_group = ();
    }

    # pro ka�d� ��dek v souboru
    foreach $line (<FILE>){
        chomp($line);
        
        # jestli�e najde� n�co jako '1Z2', bude z toho nadpis v grafu
        if($line =~ m/[0-9][A-Z][0-9]/){
            $lt = $line;
            $lt =~ s/.*([0-9][A-Z][0-9]).*/$1/;
        
        # kdy� najde� n�co jako [6], je to ��dek, kter� n�s zaj�m�, t�eba n�co
        # jako
        # Athyrium filix-femina 5/6                   [6]           8     .
        # rod      druh         esr1/esr2             et�         pokryvnost
        # veskupin�1 pokryvnost ve skupin�2
        } elsif($line =~ m/\[[0-9]\]/){
            
            # next, pokud se na ��dku nenajde ��slo do 50t�ho p�smenka...
            substr($line,0,50) =~ m/\d/ ?  &save_esr($line) : next;

        } #/ elsif
        elsif($line =~ s/^[1-3]:(.*)/$1/){
            chomp $line;
            $line =~ s/p8ir/p�ir/; # p�evod na �e�tinu
            $line =~ s/^\s*//;
            if(length($line) <12){
                my $kolik_mezer=12-length($line);
                for(my $a = 0;$a<=$kolik_mezer;$a++){$line =~ s/$/ /;}
            }
            push @stupne_prirozenosti, $line;
        }
    }#/foreach $line

    close FILE;


    # vytiskni v�slekdy
    $results{'RETURN_STRING'} = &print_results();

    # pokud si to srdce p�eje, vyrob graf�k
    $results{'GRAF_STRING'} = &print_graph($jmeno_grafu) if($graf == 1);
    

    return \%results ;
}

#################################################################
# sub save_esr
# rozplizne ka�dej ��dek do pot�ebnejch prom�nnejch a v�sledek inteligentn�
#
# Athyrium filix-femina 5/6                   [6]           8     .
# rod      druh         esr1/esr2             et�         pokryvnost
# veskupin�1 pokryvnost ve skupin�2
#
# ulo�� do pole @result_group
#
# $result_group[pocet_skupin_snimku]->{esr1} = plochaESR1
#                                   ->{esr2} = plochaESR2
#                                   ->{esr3} = plochaESR3
#                                   -> ...
#                                   ->{esr20}= plochaESR20
#                                   
#                                   ->{area} = plochaSKUPINY
#
#                                   plochaESRX m��e b�t i 0 nebo undef
#################################################################

sub save_esr{
    my $line = shift;

    my ($genus,$species,$esr,$layer) = '';
    my @groups = ();
    my $group = 0;
    my @esrs = ();
    my $no_of_esr = 0;
    my $area = 0;

    
    # separace komplex� druh�
    $line =~ s/\s+agg\./_agg\./;
    $line =~ s/\s+s\.str\./_s.str./;
    $line =~ s/\s+s\.lat\./_s.lat./;

       

    # rozd�l�me ��dek na jednotliv� polo�ky
    ($genus,$species,$esr,$layer,@groups) = split(m/\s+/,$line);

    # pro ka�dou skupinu na ��dku
    for($group = 0;$group< @groups;$group++){

        # pokud se tam najde lomn�ko v ESRech, tak bude v�c Ekologickecj skupin
        # rostlin
        if($esr =~ m/\//){
               @esrs = split(m/\//,$esr);
           } else {
               @esrs = $esr;
           }

        # nahrazujeme te�ku za 0
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
# star� se o tisk v�sledk�
#################################################################
sub print_results {
###################
    my $group_no = 0;   # ��slo skupiny
    my $esr = 0;        # ��slo ESR
    my $print_number = ''; # prom�nn�, kter� se tiskne - pokryvnost pro ESR a skupinu
    my $return_string = ''; # prom�nn�, kter� se vrac�

    # tisk hlavi�ky tabulky
           $return_string .= sprintf "ESR\\sk.\t";
    
    # pro ka�dou skupinu  vytisknout jej� ��slo
    for($group_no=0;$group_no<@result_group;$group_no++){
        $return_string .= sprintf ("%d\t",$group_no+1);
    }
    # /tisk hlavi�ky tabulky
    

    #tisk obsahu tabulky
    # pro ka�dou ESR
    for($esr = 1;$esr <= 20; $esr++){

        # pro ka�dou skupinu sn�mk�
        for($group_no=0;$group_no<@result_group;$group_no++){
            
        
            # plocha pro esrX nemus� b�t definov�na, pak nem� smysl tisknout
            # cel� ��dek
            if(defined($result_group[$group_no]->{"esr$esr"})){
                
                # pokud se jedn� o prvn� skupinu sn�mk�, tak je�t� nebylo
                # vytisknuto ��slo ESR (��dek)
                if($group_no == 0){$return_string .= sprintf("\n%d\t", $esr);}

                # nesm� se d�lit 0!
                if($result_group[$group_no]->{"area"} != 0){

                    # prom�nn� print_number v sob� obsahuje pod�l
                    # plocha_ESR_pro_skupinu_snimku/plocha_skupiny_celkem
                    $print_number = $result_group[$group_no]->{"esr$esr"}/$result_group[$group_no]->{"area"};
                
                } else {
                   # nesm� se d�lit 0, proto print_number obsahuje 0 rovnou, a
                   # bez d�len�
                   $print_number = 0;
               }
               
               # tisk procentick�ho pod�lu*100
               $return_string .= sprintf("%.1f%%\t",$print_number*100);
           }#/if(defined...
       }#/for($group_no=0...
   }#/for($esr=1
   $return_string .=  "\n";
  return $return_string; 
}#/sub print_results



#################################################################
# sub print_graph
# star� se o tisk grafu
#################################################################
sub print_graph{
    my $jmeno_grafu = shift; # �et�zec, kam se m� graf ulo�it
    my $group_no = 0; # ��slo skupiny sn�mk�
    my $esr = 0;      # ��slo ESR
    my $graf = '';    # �et�zec obsahuj�c� definici grafu pro Rko
    my $system = '';  # �et�zec, kter� se nakonec po�le syst�mu
    my ($legenda,$popisky_y,$barvy) = ''; #prom�nn� pro graf

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

    # legenda k jednotliv�m ESR pro graf
    my @legends = split(m/\n/,"
1 - +/- v�pnomiln�
2 - such�, bohat�
3 - vys�chav�, bohat�
4 - m�rn� vlhk�, bohat�
5 - �erstv�, bohat�
6 - nitrofiln�
7 - velmi chud�
8 - such�, chud�
9 - m�rn� vlhk�, chud�
10 - �erstv�, st�. bohat�
11 - st��dav� vlhk�
12 - vlhk�, st�. bohat�
13 - vlhk�, bohat�
14 - mokr�, proud�c� voda
15 - mokr�, stagnuj�c� voda
16 - ra�elinn�
17 - +/- subalpinsk�");
    
    # pracujeme se souborem -- soubor
    open(RDATA,">$rdata") or die "Nelze otev��t soubor $rdata".": $!";


    # inicializace prom�nn�ch pro legendu a pro barvy
    $legenda = 'legenda<-c(';
    $barvy = 'barvy<-c(';
        
    # pro ka�dou ESR
    for($esr = 1;$esr <= 20; $esr++){

        # inicializace popisk� na ose Y
        $popisky_y = 'popisky<-c(';
        
        # pro ka�dou skupinu sn�mk�
        for($group_no=0;$group_no<@result_group;$group_no++){
            
                # p�idat do popisk� pro osu y ��slo skupiny sn�mk�
                if(defined($stupne_prirozenosti[$group_no])){
                    $popisky_y .= "'".$stupne_prirozenosti[$group_no]."',";
                } else {
                    $popisky_y .= sprintf("%d, ",$group_no+1);
                }

                # pokud je co p�id�vat - plocha pro dannou ESR je != 0
                if(defined($result_group[$group_no]->{"esr$esr"})){
                    
                    # tisk souboru data pro Rko
                    if($result_group[$group_no]->{"area"} != 0){
                        $print_number = $result_group[$group_no]->{"esr$esr"}/$result_group[$group_no]->{"area"};
                    } else {
                        $print_number = 0;
                    }
                    printf RDATA ("%.3f ",$print_number*100);

                    #uzav��t ��dek v souboru s daty
                    print RDATA "\n" if($group_no == @result_group-1);
                    
                    # p�idat do legendy a barev popisek k ESR a k barv�m
                    $legenda .= "'$legends[$esr]'," if($group_no == 0);
                    $barvy .=   "'$colors[$esr]',"  if($group_no == 0);
                }#/if(defined
            }#!for($group_no
            
            # uzav��t skupiny
            $popisky_y .=");";
    }#/for($esr = 1

    #uzav��t barvy, legendu, soubor s daty pro graf
    $legenda.=");";
    $barvy.=");";
    close RDATA;

   # prom�nn�, ve kter� je cel� soubor pro Rko
   my $ylim = 60+(@result_group-1)*15;
   # p�i�ti 10, pokud je v prom�nn� OPEN_DIR n�co jako c:\
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
    main='LT $lt - ekologick� spektrum synuzie podrostu',
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

    # ukl�d�me skript do souboru, a� to m��e j�t ven
    open(RPROG,">$rskript") or 
                die "Nelze otev��t soubor $rskript".": $!";
                
    # vy�istit z prom�nn� graf prom�nnou 
    print RPROG $graf;
    close RPROG;
    
    $system= "$$vars_r{'R_PATH'} --vanilla  -q < $rskript\n";
    
    #prom�nn� system jde ven
    #system($system);
    
    `$system`;

    return $jmeno_grafu;
}

return 1;
