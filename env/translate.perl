#!/usr/bin/perl

$arguments = "@ARGV";
$mesdel = 0;
if ($arguments =~ /-m (\d+)/){
    $mesdel = $1;
    shift @ARGV;
    shift @ARGV;
}
$prodcomp = 0;
if ($arguments =~ /-p (\d+)/){
    $prodcomp = $1;
    shift @ARGV;
    shift @ARGV;
}

while(<>){
    chomp;
    if (/^#(\S+?):\s+(\S.+)/){
	printf "\n$_";
	$type = $1;
	$unittmp = $2;
	$unittmp =~ s/:\S+ / /g;
	$unittmp =~ s/ +/ /g;
#	printf "\n$unittmp";
	for $i (split(/ /,$unittmp)){
	    $mapLabelUnit{"$type $i"} = $unitcount{$type}++;
#	    printf " $type $i $unitcount{$type}";
	}
    }
    
    if (/^(mess:.+)/){
	$mess = $1;
	$_ = <>;chomp;
	$sent = "$_.";
	$sent =~ s/^sent:\s+//;

	$prodbool = 0;
	$prodbool = 1 if rand(100) < $prodcomp;
	$mesbool = 0;
	$mesbool = 1 if rand(100) < $mesdel;

	printf "\nname:{ $sent }";
	printf "\n#$mess";
#	print " mesbool $mesbool del $mesdel";
	$mess =~ s/^mess:\s+//;
	## event semantics
	if ($mess =~ / E=(\S+)/){
	    $evsemstring = ",$1";
	    @evsempart = split(/,/,$evsemstring); 
	    
	    for $x (@evsempart){
		if ($x =~ /[A-z]+/){
		    $num = $mapLabelUnit{"eventsemantics $x"};
#		    print "\none $x $num $evsemstring";
		    $evsemstring =~ s/,$x/ $num/;
		}
	    }
	    $mess =~ s/ E=(\S+) +/ ;tlink$evsemstring /;
	}
	## roles
	$mess =~ s/L=\S*//;

	for $x (0 .. $unitcount{"roles"}){
	    $num = $mapLabelUnit{"roles $1"} if $mess =~ /([A-Z])=/;
	    $mess =~ s/([A-Z])=/;link $num /;
	}
	## lexical semantics
	$mess =~ s/,/ /g;
	for $x (0 .. $unitcount{"semantics"}){
	    $num = $mapLabelUnit{"semantics $1"} if $mess =~ /([A-Z]+) /;
#	    printf "\n ### ERROR $x $num $1 " if $num == 0;
	    $mess =~ s/([A-Z]+) /$num /;
	}
	$mess = "" if $mesbool;
	printf "\nproc:{ clear $mess;} ";

	@sentlist = split(/ /,$sent);
	printf "\n%d",$#sentlist + 1;
	for $word (@sentlist){
	    printf "\ni:{targ 1.0} %d",$mapLabelUnit{"lexicon $word"} if !$prodbool;
	    printf "\nt:{word 1.0} %d",$mapLabelUnit{"lexicon $word"};
	    printf " # ERROR word '$word' is not in lexicon " if !$mapLabelUnit{"lexicon $word"};
	}
	printf ";";
    }
}
	
