#!/usr/bin/perl

while(<>){
    s/(clear.+?;link 0 \d+).+?tlink 3 .+?;/$1;/;
    print;
}
