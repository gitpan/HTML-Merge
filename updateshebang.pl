use Config;

my $tmp = "tmp-$$";
foreach (glob("private/perl/*.pl")) {
	print "Updating shebang for $_\n";
	open(I, "+<$_") || die $!;
	open(O, "+>$tmp") || die $!;
	my $line = <I>;
	chop $line;
	$line =~ s/^#!.*/$Config{'startperl'}/;
	print O "$line\n";
	print O join("", <I>);
	seek(I, 0, 0) || die $!;
	seek(O, 0, 0) || die $!;
	print I join("", <O>) || die $!;
	truncate(I, tell(I)) || die $!;
	close(O);
	close(I);
}

unlink $tmp;
