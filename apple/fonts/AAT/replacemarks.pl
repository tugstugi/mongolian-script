#!/usr/bin/perl

use strict;

my $file = "MongolianScript.mif";
my $start_glyph_nr = 1000;

my $line;

open(INFILE, $file);
while (<INFILE>) {
	$line = $_;
	while ($line =~ m/uni(....)\.marked/) {
		my $nr = $start_glyph_nr + hex($1);
		$line =~ s/uni(....)\.marked/$nr/;
	}
	print $line;
}
close(INFILE);
