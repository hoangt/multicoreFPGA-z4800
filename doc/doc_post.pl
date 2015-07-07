#!/usr/bin/perl -w


use strict;

foreach my $fn (@ARGV){
   open(IN, '<', $fn) or die "Can't open $fn for reading";
   my @lines = <IN>;
   close(IN);
   open(OUT, '>', $fn) or die "Can't open $fn for writing";
   foreach(@lines){
      s/(^<\s*BODY\s*>$)/$1<div id="page_wrapper"><div id="content_wrapper">/;
      s/(^<\s*\/BODY\s*>$)/<\/div><\/div>$1/;
      print(OUT $_);
   }
   close(OUT);
}
