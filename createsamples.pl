use strict;

open(O, ">samples/samples.html") || die $!;

print O <<HTML;
<HTML>
<HEAD>
<TITLE>Samples</TITLE>
</HEAD>
<BODY BGCOLOR=#FFFFFF>
<H4>Samples</H4>
<UL>
HTML

my %hash;
foreach (glob("samples/*.html")) {
	s|^samples/||;
	next if ($_ eq 'samples.html');
	open(I, "samples/$_") || die $!;
	my $text = join("", <I>);
	close(I);
	my $title = "Sample: $_";
	if ($text =~ /\<TITLE\>(.*?)\<\/TITLE\>/i) {
		$title = $1;
		$title =~ s/[\r\n\s]+/ /g;
		$title =~ s/^\s+//;
		$title =~ s/\s+$//;
		$title =~ s/^(.)/uc($1)/e;
        }
	$hash{$_} = $title;
}

foreach (sort {$hash{$a} cmp $hash{$b}} keys %hash) {
	print O qq!\t<LI><A HREF="<\$RMERGE>?template=$_">$hash{$_}</A>\n!;
	print O qq!\t\t<\$RSOURCE.'$_'>view source</\$RSOURCE>\n!;
}

print O <<HTML;
</UL>
</BODY>
</HTML>
HTML
