
use strict;
my $code = <<'ENDOFPERLCODE';
use CGI qw/:standard/;
use HTML::Merge::Compile;
use HTML::Merge::Error;
use HTML::Merge::Engine;
use strict qw(subs vars);
use vars qw(%code $mod_perl);

BEGIN {
my $stash = eval("*HTML::Merge::Ini::");
unless (%$stash) {
        print "Status: 501 Config file not found or incorrect\n";
        print "Content-type: text/plain\n\n";
        print "Merge could not find the configuration file.\n";
        exit;
}

if (exists $ENV{'GATEWAY_INTERFACE'}
    &&
    ($ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl\//)) {
	$mod_perl = 1;
}

}

&HTML::Merge::Engine::ReadConfig;

my $template = param('template') || $HTML::Merge::Ini::DEF_TEMPLATE;

unless ($mod_perl) {
	my $candidate = $ENV{'PATH_INFO'};
	if ($candidate) {
		$template = $candidate;
	}
}

my $input;
my $output;

if ($template) {
	$input = "$HTML::Merge::Ini::TEMPLATE_PATH/$template";
	$output = "$HTML::Merge::Ini::CACHE_PATH/$template.pl";
}

my $candidate;
my $private;
my $path;

my %candidates = ('log' => $HTML::Merge::Ini::MERGE_ERROR_LOG_PATH,
		  'error' => $HTML::Merge::Ini::MERGE_ERROR_PATH,
		  'toolbox' => $HTML::Merge::Ini::TOOLBOX_PATH);

while (($private, $path) = each %candidates) {
	$candidate = param("private_$private");
	last if $candidate;
}


if ($candidate && $HTML::Merge::Ini::DEVELOPMENT) {
	$template = $candidate;
	$input = "$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/$path/$template";
	$output = "$HTML::Merge::Ini::CACHE_PATH/private/$private/$template.pl";
}

foreach (split/\//, $template) {
	if ($_ eq '..') {
		print "Status: 403 Permission denied\n";
		print "Content-type: text/plain\n\n";
		print "Template name $template is invalid\n";
		exit;
	}
}

&HTML::Merge::Compile::safecreate($output);

my @keys = param;
foreach (@keys) {
	my $dummy = param($_);
}

unless (-f $input || !$input) {
	print "Status: 404 File not found\n";
	print "Content-type: text/plain\n\n";
	print "$template not found\n";
	exit;
}

my $source = &date($input);
my $dest = &date($output);

$HTML::Merge::context = [$template, 0];

if ($source > $dest || $HTML::Merge::Ini::ALWAYS_COMPILE) {
	eval {
		&HTML::Merge::Compile::CompileFile($input, $output);
	} if $input;
	if ($@) {
		print "Status: 501 Merge errors\n";
		print "Content-type: text/plain\n\n";
		print $@;
		unlink $output;
		exit;
	}
}

print "Content-type: text/html\n\n";

if ($HTML::Merge::Ini::DEVELOPMENT && !$candidate && $input) {
	HTML::Merge::Error::OpenMergeErrorLog();
}

if ($candidate || param('__MERGE_DEV_LIVE__')) {
	$HTML::Merge::Ini::STOP_ON_ERROR = undef;
}

$| = 1;

if ($input) {
	if ($mod_perl) {
		eval ' do $output; ';
	} else {
		eval ' require $output; ';
	}
} else {
	require HTML::Merge::Development;
	&HTML::Merge::Development::DefaultPage;
}

my $error = $@;

if ($@ && $@ !~ /STOP_ON_ERROR/) {
	eval 'HTML::Merge::Error::HandleError("ERROR", $@);';
}

if ($HTML::Merge::Ini::DEVELOPMENT && !$candidate) {
	HTML::Merge::Error::CloseMergeErrorLog() if $input;
	unless (param('__MERGE_DEV_LIVE__') || $candidate || $error) {
		if ($template =~ /\.$HTML::Merge::Ini::DEV_EXTENSION$/
				|| !$input) {
			require HTML::Merge::Development;
			HTML::Merge::Development::OpenToolBox();
		}
	}
}

sub date {
	my @s = stat(shift);
	$s[9];
}

ENDOFPERLCODE

use Config;
my $shebang = $Config{'startperl'};
open(O, ">$ARGV[0]") || die $!;
print O "$shebang\n$code";
close(O);
chmod 0755, $ARGV[0];
