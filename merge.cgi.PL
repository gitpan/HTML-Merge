#########################################
# merge.pl - merge main script 	 	#
# written by: Roi Illouz	 	#
# Updated: Ariel Brush , Roi Illouz	#
#########################################
use strict;
my $code = <<'ENDOFPERLCODE';
# Modules ###############################

use lib qw(private/perl);
use strict; 

use UNIVERSAL;
use CGI qw/:standard/;

# My modules ############################

use HTML::Merge::Compile;
use HTML::Merge::Constants;
use HTML::Merge::Error;
use HTML::Merge::Engine;
use HTML::Merge::Development;

# Globals ###############################

$HTML::Merge::context = []; # holds the template and 
			    # current line num in run time

# Main ##################################

my $template = param('template') || $HTML::Merge::Ini::DEF_TEMPLATE;
my $input;              # the input template
my $output;             # the perl compiled output
my $candidate;
my $private;
my $path;
my $sub;
my $fun;
my $code;
my (@keys,$dummy);
my $is_compiled = $FALSE;
my $comp;
my $res;

# inits
$HTML::Merge::context = [$template, 0];

# read the merge conf file
unless(ReadConfig()) 	
{
	# error handling here
	exit(1);
}

# build all extensiones nedded
unless(BuildExtensions())
{
	# error handling here
	exit(1);
}

# if internal page is called
if (param('__default__')) 
{
	unless(RunInternalPage())
	{
		HTML::Merge::Development::DefaultError("Improper use of Merge internal");
		exit(1);
	}

	exit(0);
}

unless ($template)
{
	# run default page
	HTML::Merge::Development::DefaultPage();
}

# check for security britch
foreach (split/\//, $template) 
{
	if ($_ eq '..') 
	{
		HTML::Merge::Error::ForceError("Template name $template is invalid");
		exit(1); # Under mod_perl calls Apache::exit
	}
}

# put all posible paths in importents order for checking
$input = HTML::Merge::Compile::GetTemplateFromPath($template);
$output = "$HTML::Merge::Ini::CACHE_PATH/$template.pl";

# create all sub directories from path in the cache dir
&HTML::Merge::Compile::SafeCreate($output) unless -e $output;

# Force parameters to be extracted
#my @keys = param;
#foreach (@keys) 
#{
#	$dummy = param($_);
#}

unless (-f $input || !$input) 
{
	Fail("$template not found");
}

# Clear extensions in case we are under mod_perl
foreach (keys %HTML::Merge::Ext) 
{
	undef &{"HTML::Merge::Ext::$_"};
}

# compile the template if nedded
$comp = new HTML::Merge::Compile($input, $output);
$res = $comp->CompileFile($TRUE);

if($res == $TRUE)
{
	$is_compiled = $TRUE;
}
elsif($res == $FALSE)
{
        $is_compiled = $FALSE;
}
else
{
	# on error
	if($res)
	{
		unlink $output;
		Fail("$template: $@");
	}
}

# open an error log file if nedded
if ($HTML::Merge::Ini::DEVELOPMENT &&  $input) 
{
	HTML::Merge::Error::OpenMergeErrorLog($template);
}

if ($candidate || param('__MERGE_DEV_LIVE__')) 
{
	$HTML::Merge::Ini::STOP_ON_ERROR = undef;
}

# run the page
if($is_compiled)
{
	do $output;
}
else
{
	eval{ require $output };
}

# on error
if ($@ && $@ !~ /STOP_ON_ERROR/) 
{
	HTML::Merge::Error::HandleError("ERROR", $@);
}


if ($HTML::Merge::Ini::DEVELOPMENT) 
{
	HTML::Merge::Error::CloseMergeErrorLog();

	# need to open only if web ext
	HTML::Merge::Development::OpenToolBox();
}

# Functions #################################
sub Fail 
{
	my ($err_str) = @_;

	HTML::Merge::Error::ForceError($err_str);

        exit(1); # Under mod_perl calls Apache::exit
}
############################################
sub ReadConfig
{
	my $conf = $0;	# the merge script
	my @conf; 	# all possible conf in priorety order

        $conf =~ s/\.\w+$/.conf/;
        @conf = ($conf, "/etc/merge.conf", &GetHome . "/.merge");

	foreach (@conf)
	{
		if(-r $_)
		{
			# init the res var
			$@ = undef;
		
			# eval in case of errors
			eval{ require $_ };

			# on error
			return $FALSE if $@;

			return $TRUE;
		}
	}
	
	return $FALSE;
}
############################################
sub BuildExtensions
{
	my $ext = $0;	# the merge script

	$ext =~ s/\.\w+$/.ext/;

        foreach  (($ext, "/etc/merge.ext"))
        {
                if (-r $ext)
                {
			# differ scoping in any case 
                  	package HTML::Merge::Ext;

			# init the res var
			$@ = undef;
		
			# eval in case of errors
                        eval{ require $ext };

			# on error
			return $::FALSE if $@;
                }
        }
	
	return $TRUE;
}
############################################
sub GetHome
{
	# win system compat
        return if ($^O =~ /Win/);
                                                                                
        my ($name,
	    $passwd,
	    $uid,
	    $gid,
            $quota,
	    $comment,
	    $gcos,
	    $dir,
	    $shell,
	    $expire) = getpwuid($>);
                                                                                
        return $dir;
}
############################################
sub RunInternalPage
{
	my $sub = param("sub");
	my $fun = "Default$sub";
	my $code = UNIVERSAL::can('HTML::Merge::Development', $fun);

	if ($code) 
	{
		&$code();
		return $TRUE;
	}

	return $FALSE;
}
############################################
ENDOFPERLCODE

use Config;
my $shebang = $Config{'startperl'};
$ARGV[0] = 'merge.cgi' unless $ARGV[0];
open(O, ">$ARGV[0]") || die $!;
print O "$shebang\n$code";
close(O);
chmod 0755, $ARGV[0];
