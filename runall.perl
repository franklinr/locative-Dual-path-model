#!/usr/bin/perl

#system("rm epochout* train*.ex test*.ex");

sub updatecmdfile{
# updates cmdfile and returns cmd
    open(CMD,"cmdfile");
    $newout = "";
    while(<CMD>){
	last if !/^#/;
	$newout .= $_;
    }
    chomp;
    $cmd = $_;
    if ($cmd =~ /SET .+? ([0-9]+)/){
	$num = $1;
	if ($num <29){
	    $num++;
#	    print "\nnum $num $newout";
	    $nextcmd = $cmd;
	    $nextcmd =~ s/(SET .+?) ([0-9]+)/$1 $num/;
	    $newout .= "$nextcmd\n";
	}else{
	    $newout .= "#$cmd\n";
	}
	$cmd =~ s/SET //;
    }else{
	$newout .= "#$cmd\n";
    }
    
    while(<CMD>){
	$newout .= $_;
    }
    close(CMD);
    open(CMD," > cmdfile");
    print CMD "$newout";
    close(CMD);
    return($cmd);
}    

sub docmd{
    ($c) = @_;
    print "\n$c";
    system $c;
}

sub runcmd{
    ($gencmd,$savefolder,$transpar) = @_;
    docmd("cd env;generate2.perl -n 40000 $gencmd | translate.perl $transpar - > ../trainl.ex");
    docmd("cd env;generate2.perl -n 1000 envgramtest |  translate.perl -p 100 - > ../testprodl.ex");
    docmd("head -5 trainl.ex > tmp1");
    docmd("head -5 testprodl.ex > tmp2");
#    docmd("cat tmp*");
    docmd("diff tmp1 tmp2 > diffheaders");
    print("If you see diff text below, then the headers are different!");
    docmd("cat diffheaders");
    docmd("rm -f tmp1 tmp2");
    docmd("/usr/local/bin/lens -b dualpathloc5.in \"trainSave l;exit\" > outsum "); 
    sleep(10);
    docmd("arcthis.perl $savefolder");
    sleep(10);
    $grfolder = $savefolder;
    $grfolder =~ s/s[0-9]+env//;
    print "\ngr $grfolder ";
#    docmd("gr sim*$grfolder &");
    docmd("echo $grfolder > dout");
}


$cmd = updatecmdfile;

if ($cmd =~ /\S/){  # if cmd is not empty
    @parts = split(/\&/,$cmd);
#    print @parts;
    open(MODEL,"> model.tcl");
    print MODEL "$parts[1]";
    print "\n model.tcl: $parts[1]";
    close MODEL;

    $env = $parts[0];

    $trans = $parts[2];
    if ($trans !~ /\S/){
	$trans = "-m 50";
    }

    $save = $cmd;
    $save =~ s/rmtransmes2.perl//;
    $save =~ s/\&//g;
    $save =~ s/set //g;
    $save =~ s/;//g;
    $save =~ s/ +//g;
    $save =~ s/envgram/env/;
    $save =~ s/hiddenSize/hid/;
    $save =~ s/[^A-z0-9]+//g;
    runcmd($env,$save,$trans);
    print ("\nrun next $env $trans $cmd save $save");
    system("nohup nice -n 10 runall.perl >> epochout 2> /tmp/foo.err < /dev/null &");
}
