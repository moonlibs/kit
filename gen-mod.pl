#!/usr/bin/env perl

use strict;
use File::Find;
use FindBin;

my @all;
chdir $FindBin::Bin;
my $max = 0;
File::Find::find { wanted => sub {
	next unless /\.lua$/;
	s{^\./}{};
	next if /^init\.lua$/;
	# print $_,"\n";
	my $m = s{\.lua$}{}r =~ s{/}{.}gr;
	push @all, [$m,$_];
	$max = length($m) if length($m) > $max;
	# print qq{\t["$a"] = "$_";};
	# print $File::Find::name,"\n";
}, no_chdir => 1 }, '.';
# find . -name '*.lua' | grep -vF 'init.lua' | perl -lnE 's{^\./}{}; $a=s{\.lua$}{}r=~ s{/}{.}gr; print qq{\t["$a"] = "$_";};'

for (@all) {
	my ($m,$f) = @$_;
	printf "\t\t%-*s = '%s';\n", $max+4,"['$m']",$f;
}