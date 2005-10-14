#
#HTML::Merge - Embedded HTML/SQL/Perl (c) RAZ Information Systems.
#
use strict;
use HTML::Merge::Compile;
push @INC,'lib';

my $gen_time = localtime();

open(O, ">docs/samples/samples.html") || die $!;

print O <<HTML;
<HTML>
<HEAD>
<TITLE>Samples</TITLE>
</HEAD>
<BODY BGCOLOR=#FFFFFF>
<!-- Generated by $0 $gen_time --->
<H4>HTML::Merge $HTML::Merge::Compile::VERSION Samples</H4>
<UL>
HTML

my %hash;
foreach (glob("docs/samples/*.html")) {
	next if ($_ =~ /samples.html/);
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
	my $tname = $_;
	$tname =~ s|^(.*)/||;	
	print O qq!\t<LI><A HREF="<\$RMERGE>?template=$tname">$hash{$_}</A>&nbsp;-&nbsp;\n!;
	print O qq!\t\t<\$RSOURCE.'$tname'>view source</\$RSOURCE>\n!;
}

print O <<HTML;
</UL>
</BODY>
</HTML>
HTML
