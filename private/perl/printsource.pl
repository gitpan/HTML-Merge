#!/usr/bin/perl

use HTML::Merge::Development;
use HTML::Merge::Error;
use HTML::Merge::Compile;
use CGI qw/:standard :netscape/;
use strict;

my $open = $HTML::Merge::Compile::open;

ReadConfig();

my $template = param('template');

print header;
print start_html({-bgcolor => 'Silver'}, "Source for $template");

unless ($template) {
	&HTML::Merge::Error::ForceError("No template specified");
	exit;
}
my $fn = "$HTML::Merge::Ini::TEMPLATE_PATH/$template";

print h2("Source for $template");

open(I, $fn);
my $text = join("", <I>);
close(I);

$text =~ s/&/&amp;/g;
$text =~ s/"/&quot;/g;
$text =~ s/</&lt;/g;
$text =~ s/>/&gt;/g;

print pre($text);
print end_html;
