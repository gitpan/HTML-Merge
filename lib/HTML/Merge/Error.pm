##################################################################
package HTML::Merge::Error;
##################################################################
# Error.pm -   Contains functions DoError & DoWarning            #
# Authors : Roi Illouz & Eial Solodki                            #
# All right reserved - Raz Information Systems Ltd.(c) 1999-2001 #
# Date : 12/06/2000                                              #
# Updated : 03/07/2000 14/02/2001 10/10/2001                     #
##################################################################

# perl modules ###################################################

use HTML::Merge::Compile;
use strict;
use vars qw($OPEN_BOX $CLOSE_BOX $mergerrLogFlag);

# Constants ######################################################

#$OPEN_BOX = "<HR><PRE>";
#$CLOSE_BOX = "</PRE><HR>";
$OPEN_BOX = "<TEXTAREA ROWS=15 COLS=80>";
$CLOSE_BOX = "</TEXTAREA>";

##################################################################
sub HandleError
{
	my ($type,$message,$info)=@_;

	return unless $HTML::Merge::Ini::DEBUG =~ /$type/i;
		
	$type = ucfirst(lc($type));
	my $code = UNIVERSAL::can(__PACKAGE__, "Do$type");
	if ($code) {
		&$code($message, $info);
	} 
}


##################################################################
sub DoWarn
{
	my ($message)=@_;
	my ($template, $line_num) = @$HTML::Merge::context;
	my $date = localtime();
	my $buf = '';
	my $file = GetLogName();
	
	# case statement for all the warning messages
	my %hash = ('NO_PARAM', "No parameters were found matching the vars",
		    'ILLEGAL_FETCH', "Fetch attempted on an unopen cursor",
		    'INVALID_ENG', "Number of engin is illegal",
		    'NO_SQL_MATCH', "One of the vars specified in the line is not in the select clause",
		    'CANT_OUTPUT', "cannot write Merge Error log file - $file - probably no write permissions.");

	$buf = "[$date] [warn] $hash{$message}";
	if ($message eq 'CANT_OUTPUT') {
		$mergerrLogFlag = undef;
	} else {
		$buf .= " at $template line $line_num";
	}

	if($HTML::Merge::Ini::DEVELOPMENT) # debug in an html page
	{
		$buf="\n<BR>".$buf."\n<BR><BR>";
		print OUTPUT $buf;	
	}	
}
###############################################################################
sub DoInfo
{
	my ($message,$type)=@_;
	my ($template, $line_num) = @$HTML::Merge::context;
	my $date = localtime();
	my $buf = '';
	
	my %hash = ('SQL', "SQL statement",
		    'PERL', "Perl code",
		    'MAIL', "Mail message",
		    'IF', "If statement",
		    'TIME_OUT', "Session timeout",
		    'TRACE', "Trace at");


	$buf = "[$date] [info] $hash{$type} at $template line $line_num";
	if ($type ne 'TIME_OUT') {
		$message = "if $message" if ($type eq 'IF');
		$buf .= ":\n${OPEN_BOX}$message$CLOSE_BOX<BR>";
	}
	
	if($HTML::Merge::Ini::DEVELOPMENT) # debug in an html page
	{
		print OUTPUT $buf;	
	}
}
###############################################################################
sub DoError
{
	my ($message)=@_;
	my ($template, $line_num) = @$HTML::Merge::context;
	my $date = localtime();
	my $buf = '';
	my $template_path;
	
	die 'STOP_ON_ERROR' if ($message =~ /STOP_ON_ERROR/);
	$buf = "[$date] [error] $message at $template line $line_num\n";				
	print STDERR $buf;
		
	if($HTML::Merge::Ini::DEVELOPMENT) # debug in an html page
	{
		$buf="<BR>$buf\n<BR><BR>";
		print OUTPUT $buf;	
	}
	
	if($HTML::Merge::Ini::STOP_ON_ERROR)
	{
		# spaces are needed to be replaced by '+' in a parameter
		# sended to a web page	
		$buf =~ s/([^ a-zA-Z0-9_-])/sprintf("%%%02X", ord($1))/ge;
		$buf =~ s/ /+/mg; 

		# calling to the web error page,just before crashing...
		print "// -->\n</SCRIPT></STYLE>\n";
		print qq!<META HTTP-EQUIV="Refresh" CONTENT="0; URL=$HTML::Merge::Ini::MERGE_PATH/$HTML::Merge::Ini::MERGE_SCRIPT?private_error=$HTML::Merge::Ini::ERROR_MESSAGE&message=$buf&__MERGE_DEV_LIVE__=1">\n!; 

		die "STOP_ON_ERROR";
	}
}

sub TimeOut {
		DoInfo('', 'TIME_OUT');
		print <<EOM;
// -->
</SCRIPT></STYLE>
<META HTTP-EQUIV="Set-Cookie" CONTENT="$HTML::Merge::Ini::SESSION_COOKIE=0">
<META HTTP-EQUIV="Refresh" CONTENT="0; URL=$HTML::Merge::Ini::MERGE_PATH/$HTML::Merge::Ini::MERGE_SCRIPT?template=$HTML::Merge::Ini::SESSION_TIME_OUT_TEMPLATE">
EOM
		die "STOP_ON_ERROR";
}
############################################################################# 
# open the log file for the Merge Error log
sub OpenMergeErrorLog
{
        my ($template, $line_num) = @$HTML::Merge::context;
	$template =~ s|^.*/||;
	my $file = GetLogName();
	
	HTML::Merge::Compile::safecreate($file);
	if(open(OUTPUT,">$file"))
	{
		$mergerrLogFlag = 1;
	}
	else
	{
	 	DoWarn('CANT_OUTPUT');
	}	

	if($mergerrLogFlag)
	{
		print OUTPUT CGI::start_html("Merge Log - $template") . "\n";
 		require HTML::Merge::Compile;
        print OUTPUT <<EOM;
<BODY BGCOLOR='white' onLoad=window.focus()>
<FORM NAME=MergeLogForm>
<FONT FACE=Arial SIZE=6 COLOR=black><CENTER><B>Merge Log</B></CENTER></FONT><BR><FONT FACE=Arial SIZE=5 COLOR=black><CENTER><I>$template</I></FONT></CENTER><BR>
<CENTER><TABLE BGCOLOR=yellow><TR><TD><FONT FACE=Arial SIZE=5 COLOR=black>RAZ Information System LTD.</TD></TR></TABLE></CENTER></FONT><BR>
<FONT FACE=Arial SIZE=5 COLOR=black><CENTER>Version $HTML::Merge::Compile::VERSION</CENTER></FONT><BR>
<FONT FACE=Arial SIZE=2 COLOR=black>Merge(c) 1999-2001&nbsp;&nbsp;</FONT><A HREF='$HTML::Merge::Ini::SUPPORT_SITE'><FONT FACE=Arial SIZE=2 COLOR=black>http://$HTML::Merge::Ini::SUPPORT_SITE</FONT></A><BR>
<META HTTP-EQUIV="ContentType" CONTENT="text/html; charset=windows-1255"><BR><BR>
<META NAME="GENERATOR" CONTENT="MERGE v. $HTML::Merge::Compile::VERSION (c) Raz Information Systems www.raz.co.il">
EOM
	}	
}	
###############################################################################
# close the log file for the Merge Error log
sub CloseMergeErrorLog
{
	print OUTPUT "</FORM>\n";			
	print OUTPUT CGI::end_html() . "\n";
	close(OUTPUT);
}
############################################################################
# get the file name for the Merge Log
sub GetLogName
{
	my $i = undef;
	my $file = undef;
        my ($template, $line_num) = @$HTML::Merge::context;
	$template =~ s/^$HTML::Merge::Ini::TEMPLATE_PATH//;
		
	return "$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/$HTML::Merge::Ini::MERGE_ERROR_LOG_PATH/$ENV{'REMOTE_ADDR'}/$template.html";
}
############################################################################
1;
############################################################################

