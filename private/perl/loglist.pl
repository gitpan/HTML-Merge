#!/usr/bin/perl
##################################################################
# loglist.pl - prints the loglist.html page with the             #
#              files that are in the log directory               #
# author : Eial Solodki                                          #
# All right reserved - Raz Information Systems Ltd.(c) 1999-2001 #
# date : 15/02/2001                                              #
# updated :                                                      #
##################################################################

use CGI;

##################################################################

my $cginst = new CGI;
my %file_list;
my @dir_list;
my $filename;
my $logfile; 
my $counter = 1;
my $ctime; 
my $key;
my $value;
my $LIST_SIZE = $cginst->param('log_list_size');
my $log_dir = $cginst->param('log_dir');
my $merge_path = $cginst->param('merge_path');
my $rel = $cginst->param('rel_path');
$rel = "$rel/" if $rel;

my $base = "$ENV{'SCRIPT_NAME'}?merge_path=$merge_path&log_list_size=$LIST_SIZE&log_dir=$log_dir";

while(glob("$log_dir/$ENV{'REMOTE_ADDR'}/$rel*"))
{
	$filename = $_; # just for being it clear
	$ctime = (stat($filename))[10]; # the time of creation of the file
									# in the stat array
    # the logfile is the clean filename,without the path									
	$logfile = substr($filename,rindex($filename,'/')+1);

	if (-d $filename) {
		push(@dir_list, $logfile);
		next;
	}

	$logfile =~ s/\.\w+?$//;
	# hash table which the key is the creation time
	# and the value is the cleaned file name
#	$file_list{$ctime}=$logfile;
	$file_list{$logfile} = $ctime;
}

$counter = 0;

print "Content-type: text/html\n\n";
print <<HTML;
<HTML>
<HEAD>
<TITLE>Log List</TITLE>
<STYLE>.userData { BEHAVIOR: url(#default#userdata)	} </STYLE>
<STYLE TYPE="text/css">
<!--
	A:link {color:"#003399";}
	A:visited {color:"#800080";}
	A:hover {color:"#FF3300";}
-->
</STYLE>
</HEAD>
<BODY BGCOLOR="Silver">
<SCRIPT LANGUAGE="JavaScript">
<!--
///////////////////////////////////////////////////////////////////////
function ShowMergeErrorLog(file)
{
	var dt = new Date();
	var merge_path = '$merge_path';
	var myWin=open(merge_path+"?private_log="+file+"&__MERGE_DEV_LIVE__=ON&dt="+dt,"MergeErrorLogPage","top=20,screenY=20,left=250,screenX=250,width=450,height=500,status=no,scrollbars=yes,toolbar=no,menubar=no,copyhistory=no,resizable=yes");			
	myWin.focus();
}	
///////////////////////////////////////////////////////////////////////
//-->
</SCRIPT>
<div id="HPFrameDLContent" style="width:100%;border-bottom:#ffffff 1px solid;border-left:#ffffff 1px solid;border-right:#ffffff 1px solid;">
<table class="HPFrameTab" width="100%" border="0" cellpadding="0" cellspacing="0">
<tr id="HPFrameDLTab" valign="middle" bgcolor="#CCCCCC">
<td align="left" width="100%" height="10">
<font id="HPFrameDLTab2" face="verdana,arial,helvetica" size="1" color="#336699">
<CENTER><B>Log List</B></CENTER>
</font>
</td> 
</tr>
HTML

if ($rel) {
	my $prev = "/$rel"; # Make sure first token can be erased
	$prev =~ s|/.*?$||;
	$prev =~ s|^/||;
	print"<tr>";
	print"<td><font face='verdana,arial,helvetica' size=1>\n";
    	print "&nbsp;&nbsp;<B><A HREF=\"$base&rel_path=$prev\">[Back]</A></B>&nbsp;<br></td>\n";
 	print"</font></tr>\n";
	print"<tr><td colspan=3 height=3></td></tr>\n";
}

foreach (@dir_list) {
	print"<tr>";
	print"<td><font face='verdana,arial,helvetica' size=1>\n";
    	print "&nbsp;&nbsp;<B><A HREF=\"$base&rel_path=$rel$_\">$_/</A></B>&nbsp;<br></td>\n";
 	print"</font></tr>\n";
	print"<tr><td colspan=3 height=3></td></tr>\n";
}

for $key (sort {$file_list{$b} <=> $file_list{$a}} keys %file_list)
{
	if($counter++ >= $LIST_SIZE) { last };
	print"<tr>";
	print"<td><font face='verdana,arial,helvetica' size=1>\n";
    	print "&nbsp;&nbsp;<A HREF=javascript:ShowMergeErrorLog('$ENV{'REMOTE_ADDR'}/$rel/$key.html')>$key</A>&nbsp;<br></td>\n";
 	print"</font></tr>\n";
	print"<tr><td colspan=3 height=3></td></tr>\n";
}
print"<tr><td colspan=3 height=10></td></tr>\n";
print"<tr><td colspan=3>
      <font id='HPFrameDLTab2' face='verdana,arial,helvetica' size='1' color='#336699'>
      <A HREF='javascript:close()' title='Exit'><B>Close Log List</B></A>
      </font> </td></tr>\n";
print"<tr><td colspan=3 height=7></tr>\n";
print"</table>\n";
print"</div>\n";
print"</td>\n";
print"</table>\n";
print $cginst->end_html();
