#
#HTML::Merge - Embedded HTML/SQL/Perl system by Raz Information Systems.
#
use strict;

open(O, ">docs/samples/samples.html") || die $!;

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
foreach (glob("docs/samples/*.html")) {
	s|^samples/||;
	next if ($_ eq 'samples.html');
	open(I, "$_") || die $!;
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
	print O qq!\t<LI><A HREF="<\$RMERGE>?template=$_">$hash{$_}</A>&nbsp;-&nbsp;\n!;
	print O qq!\t\t<\$RSOURCE.'$_'>view source</\$RSOURCE>\n!;
}

print O <<HTML;
</UL>
</BODY>
</HTML>
HTML
