##################################################################
package HTML::Merge::Development;
##################################################################
# Development.pm - Contains functions for the developmnet        #
# Author : Eial Solodki                                          #
# All right reserved - Raz Information Systems Ltd.(c) 1999-2001 #
# Date : 15/02/2001                                              #
# Updated :                                                      #
##################################################################

# perl modules ###################################################

use strict;

##################################################################
sub OpenToolBox
{
print <<EOM;
<SCRIPT LANGUAGE="JavaScript">
<!--
open("$HTML::Merge::Ini::MERGE_PATH/$HTML::Merge::Ini::MERGE_SCRIPT?private_toolbox=$HTML::Merge::Ini::TOOLBOX&merge_path=$HTML::Merge::Ini::MERGE_PATH&log_dir=$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/$HTML::Merge::Ini::MERGE_ERROR_LOG_PATH&merge_absolute_path=$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH&__MERGE_DEV_LIVE__=1&log_list_size=$HTML::Merge::Ini::LOG_LIST_SIZE&merge_script=$HTML::Merge::Ini::MERGE_SCRIPT","MergeToolBoxTarget","screenY=20,top=20,screenX=20,left=20,width=180,height=360,status=no,scrollbars=yes,toolbar=no,menubar=no,copyhistory=no,resizable=no");
// --->
</SCRIPT>
EOM
}
##############################################################################

sub DefaultPage {
	print <<HTML;

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">

<HTML>
<HEAD>
	<TITLE>Merge</TITLE>
</HEAD>

<BODY BGCOLOR='white'>

<FONT FACE=Arial SIZE=6 COLOR=black><CENTER><B>Merge</B>
</CENTER></FONT><BR>
<CENTER><TABLE BGCOLOR=yellow><TR><TD><FONT FACE=Arial SIZE=5 COLOR=black>
RAZ Information System LTD.
</TD></TR></TABLE></CENTER></FONT>
<BR><BR>
<FONT FACE=Arial SIZE=4 COLOR=black><CENTER>
</CENTER></FONT>
<BR><BR><BR><BR><BR><BR><BR><BR><BR><BR>
<CENTER>
<BR>
<BR>
<FONT FACE=Arial SIZE=2 COLOR=black>
Merge(c) 1999-2001&nbsp;&nbsp;</FONT>
<A HREF="http://www.raz.co.il"><FONT FACE=Arial SIZE=2 COLOR=black>
http://www.raz.co.il
</FONT></A><BR>
</CENTER>
</FORM>
</BODY>
</HTML>
HTML
}
##############################################################################
1;
##############################################################################
