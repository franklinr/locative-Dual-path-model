#!/usr/bin/perl

sub readGramHash{
    open(GRAM,"< gramhash");
    while(<GRAM>){
	chomp;
	$gramhash{$_}++;
    }
    $gramhash{"read"}++;
    close(GRAM);
}

sub readLexicon{
    my ($lexicon) = @_;
    my @lex = split(/ /,$lexicon);
    my $cat = "NOUN";
    for $i (@lex){
	$wcat = "";
	if ($i =~ /:([a-z]+)/){
	    $cat = uc $1;
	}
	$wcat = "PER" if $i =~ /^per$/;
	$wcat = "MOD" if $i =~ /-par/;
	$wcat = "PRON" if $i =~ /^(he|she|her|him|i|me|you|it|they|them)$/;
	$wcat = "AUX" if $i =~ /^(is|are|was|were|am)$/;
	$wcat = $cat if $wcat eq "";
	$mapsyncat{"$i"} = $wcat;
#	printf "\ni $i cat $wcat";
    }
    ## result $mapsyncat
}

readGramHash if -f "gramhash";

sub tagUtt{
    my ($utter) = @_;
    my @utt = split(/ /,$utter);
    my $synutt = "";
    my $mesutt = "";
    for $i (@utt){
	next if $i !~ /\S/;
	last if $i eq "per";
	$synutt .= $mapsyncat{$i}." ";
	
	$mesutt .= $mapsyncat{$i}.":".$i." ";
    }
    return($synutt,$mesutt,@utt);
}

sub messProcess{
    my ($type) = @_;
    my $structure = "";
    #mes is set already

    $mes{$type} = " $mes{$type} ";

    ## create noun phrases
    $mes{$type} =~ s/(DET:\S+) NOUN:/$1,NOUN:/g;
    $mes{$type} =~ s/(DET:\S+) ADJ:/$1,ADJ:/g;
    $mes{$type} =~ s/(ADJ:\S+) NOUN:/$1,NOUN:/g;
    $mes{$type} =~ s/ PRON:/ NP:PRON:/g;
    $mes{$type} =~ s/ (DET:\S+NOUN:)/ NP:$1/g;
    $mes{$type} =~ s/ (NOUN:)/ NP:$1/g;
    
    $mes{$type} =~ s/ NUM:\S+//g;   # remove number 
    $mes{$type} =~ s/NP:DET:\S+?,/NP:/g; # remove determiners
    
#    $mes{$type} =~ s/ PREP:with/ WITH:with/g;

    if ($mestype =~ /p|t/){ ## record structure for synprime
	$structure{"$type$mestype"} = $mes{$type};
	$structure{"$type$mestype"} =~ s/ NP:\S+/ NP/g;
	$structure{"$type$mestype"} =~ s/ MOD:-ing/ ING/g;
	$structure{"$type$mestype"} =~ s/ MOD:-par/ PAR/g;
	$structure{"$type$mestype"} =~ s/ MOD:\S+//g;
	$structure{"$type$mestype"} =~ s/ PAR PREP:by/ PAR BY/g;
#	$structure{"$type$mestype"} =~ s/ PREP:with/ WITH/g;
	$structure{"$type$mestype"} =~ s/ V\S+/ VERB/g;
	$structure{"$type$mestype"} =~ s/ AUX VERB NP/ VERB NP/g;
	$structure{"$type$mestype"} =~ s/:[a-z-]+//g;
	$structure{"$type$mestype"} =~ s/^ +//g;
	$structure{"$type$mestype"} =~ s/ +$//g;
    }
    
    $mes{$type} =~ s/ (SS|ED|ING):-(ed|ss|ing)//g; # remove modifier
    
    ## equate alternations
    $mes{$type} =~ s/(NP:\S+) AUX:\S+ (VTRAN:\S+) MOD:-par PREP:by (NP:\S+) (.*)/$3 $2 $1 $4 FLIP/;
    $mes{$type} =~ s/((VDAT|VBENE):\S+) (NP:\S+) PREP:(to|for) (NP:\S+)/$1 $5 $3 FLIP/;
    $mes{$type} =~ s/((VTRAN|VSPRAY):\S+) (NP:\S+) PREP:\S+ (NP:\S+)/$1 $4 WITH:with $3 FLIP/;

    $mes{$type} =~ s/(VERB)(A|B|C):(\S+) (NP:\S+) PREP:\S+ (NP:\S+)/$1$2:$3 $5 WITH:with $4 FLIP/;

    $flip{$type} = 0;
    $flip{$type} = 2 if $mes{$type} =~ /FLIP.+?FLIP/;
    $flip{$type} = 1 if $mes{$type} =~ /FLIP/;
    $mes{$type} =~ s/ FLIP//g;

    $mes{$type} =~ s/AUX:\S+ (V\S+)/$1/;
    
    if ($type eq "act"){  ## process starts after both tar and act are retrieved
	printf "\nmestar: $mes{tar}";
	printf "\nmesact: $mes{act}";

	### mark possible island
	$islandverb = "";
	$islandstruct = $synutt{"tar"};
	$islandstruct =~ s/ NUM//g;
	$islandstruct =~ s/DET NOUN/NP/g;
	$islandstruct =~ s/DET ADJ NOUN/NP/g;
	$islandstruct =~ s/PRON/NP/g;
	$islandstruct =~ s/NOUN/NP/g;
	$islandstruct =~ s/(VTRAN|VBENE)/VERB/g;
	if ($islandstruct =~ /NP VERB( MOD)* NP *$/){
	    $islandverb = $1 if $mes{"tar"} =~ /V\S+?:([a-z]+)/;
	    $count{" island $islandverb all"}++;
	}
	###

	if ($mes{"tar"} eq $mes{"act"}){  ## message same
	    printf " mescorr";
	    $count{"mes=$verb-$verbtype-A"}++;
	    $count{"mes=overall"}++;

	    if ($flip{"tar"} != $flip{"act"}){
		printf " flipped";
		$count{"flip=$verb-$verbtype-A"}++;
	    }
	    $count{"flip=$verb-$verbtype-A all"}++;
	}else{
	    printf " meswrong";
	}
	$count{"mes=$verb-$verbtype-A all"}++;
	$count{"mes=overall all"}++;
    }
    # results mes count
}

sub gramProcess{
    my ($type) = @_;
    # prepare utterance for grammatical check
    $gramutt{$type} = " $synutt{$type} ";
    $gramutt{$type} =~ s/ V\S+/ VERB/g;
    
    if ($type eq "act"){  ## print out results
	
	$gramhash{$gramutt{"tar"}}++;
	
	printf "\nsyntar: $synutt{tar} ";
	printf "\nsynact: $synutt{act} ";
	
	if ($gramhash{$gramutt{"act"}}){
	    printf "= gram";
	    $count{"gram=$mestype"}++;
	}else{
	    printf "= ungram";
	}
	$count{"gram=$mestype all"}++;

    }
}

while(<>){
    chomp;
    readLexicon($1) if (/^\#lexicon: (.+)/);
    if (/name:/){
	$mestype = "_";
	$mestype = "$1" if / \#([^} ])/;
        $sse = $1 if /sse=(\S+)/;
    }

    printf "\n$_";
    if (/(tar|act): (.+)/){
	$type = $1;
	my @uttcopy;
	($synutt{$type},$mes{$type},@uttcopy) = tagUtt($2);
	if (/^tar:/){
	    $verbtype = $1 if $synutt{"tar"} =~ / (VERB\S*)/;
	    @scat = split(" ",$synutt{"tar"});
	    for $i (0 .. $#scat){
		if ($scat[$i] eq $verbtype){
		    $verb = $uttcopy[$i];
		}
	    }
	}

#	print "verb $verbtype $verb";
	gramProcess($type);
	$locstruct = "TL" if $synutt{"tar"} =~ /VERB\S* .+? NOUN (PREP)/;
	$locstruct = "LT" if $synutt{"tar"} =~ /VERB\S* .+? NOUN (WITH)/;
	printf " $locstruct ";

	messProcess($type);

	$sentcorr = 1;
	if ($type eq "act"){

	    for $i (0 .. $#lastuttcopy){
#		if ($lastuttcopy[$i] ne "per"){
		    if ($uttcopy[$i] eq $lastuttcopy[$i]){
			$count{"word=$mestype"}++;
	                $count{"word=$verb-$verbtype-$locstruct"}++;
		    }else {
			$sentcorr = 0;
		    }
		    $count{"word=$mestype all"}++;
	            $count{"word=$verb-$verbtype-$locstruct all"}++;
#		}
	    }
	    printf " sentWRONG " if !$sentcorr;
	    $count{"zsent=v-$verbtype-$locstruct"}++ if $sentcorr;
	    $count{"zsent=v-$verbtype-$locstruct all"}++;

	    $count{"zsent=$verb-$verbtype-$locstruct"}++ if $sentcorr;
	    $count{"zsent=$verb-$verbtype-$locstruct all"}++;

	    $count{"sse=$verb-$verbtype-$locstruct"}+=$sse;
	    $count{"sse=$verb-$verbtype-$locstruct all"}++;

#	    $count{"struct $synutt{tar}"}++ if $sentcorr;
#	    $count{"struct $synutt{tar} all"}++;
	}
	@lastuttcopy = @uttcopy;
    }

}

sub writeGramHash{
    printf "\nwriting gramhash";
    open(GRAM,"> gramhash");
    for $i (sort keys %gramhash){
	printf GRAM "$i\n";
    }
    close(GRAM);
}

writeGramHash if ! -f "gramhash";

printf "\n##results ";
for $i (sort keys %count){
    next if $i !~ /synprime/;
    next if $i =~ / all/;
    $d = $i;
    $d =~ s/ target .+? (prime .+)/ $1 all/;
#    $d =~ s/ prime .+/ all/;
    $count{$i} = 0 if !$count{$i};
    if ($count{$d} > 0 ){
	printf "\n##$i corr c %d t %d",$count{$i},$count{$d};
	printf " perc %d%",$count{$i}/$count{$d}*100;
    }
}
for $d (sort keys %count){
    next if $d !~ / all/;
    next if $d =~ /synprime/;
    $i = $d;$i =~ s/ all//;
    $count{$i} = 0 if !$count{$i};
    $label = $i.",,,";
    $label =~ s/(=|-| )/,/g;
    $label =~ s/([^,]+,[^,]*,[^,]*,[^,]*),*/$1/;
    printf "\n##$label,%d,%d",$count{$i},$count{$d};
    if ($count{$d} > 0){
	$prop = $count{$i}/$count{$d};
	printf ",%f",$prop;
    }
}
