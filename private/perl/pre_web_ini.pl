#!/usr/bin/perl
##################################################################
# web_ini.pl - gets the data to update in the ini.pm             #
#              from the Merge Configuration Web page             #
# author : Eial Solodki                                          #
# All right reserved - Raz Information Systems Ltd.(c) 1999-2001 #
# date : 07/05/2001                                              #
# updated :                                                      #
##################################################################

use HTML::Merge::Engine;
use CGI qw/:standard/;
use strict qw(vars subs);
use vars qw($tab);

##################################################################

my $merge_path = param('merge_path');
my $merge_script = $merge_path;
$merge_script =~ s|^.*/||;
my $merge_absolute_path = param('merge_absolute_path');


my $file = "$merge_absolute_path/$merge_script";
$file =~ s/\.\w+$/.conf/;

do $file;

my $date = localtime();
my $value;
	
$HTML::Merge::Ini::DB_PASSWORD 
	= HTML::Merge::Engine::Convert($HTML::Merge::Ini::DB_PASSWORD2);


print "Content-type: text/html\n\n";
print <<HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<HTML>
<HEAD>
<TITLE>Configuration</TITLE>
<META HTTP-EQUIV="Content-Type" CONTENT="text/html;charset=windows-1255">
<STYLE TYPE="text/css">
<!--
	.bText
	{
		font-size : 9pt;
		font-weight : bold;
		color : #000000;
		font-family : Arial;	
		text-decoration : none;
	}
	
	.sText
	{
		font-size : 9pt;
		font-weight : normal;
		color : #000000;
		font-family : Arial (hebrew);	
		text-decoration : none;
	}
-->
</STYLE>
</HEAD>

<BODY BGCOLOR="Silver" onLoad="Initialize()">
<form action="$HTML::Merge::Ini::MERGE_PATH/private/perl/web_ini.pl" method="GET" target="_self" name="iniForm" onSubmit="ChkSubmit()">

HTML
print <<HTML;
<table class="HPFrameTab" width="100%" border="0" cellpadding="0" cellspacing="0" style="cursor:hand" onmouseover="setBorder('HPFrameDL',true);" onmouseout="setBorder('HPFrameDL',false);">
<tr id="HPFrameDLTab" valign="middle" bgcolor="#CCCCCC">
<td></td>
<td align="left" width="100%" height="10">
<font id="HPFrameDLTab2" face="verdana,arial,helvetica" size="1" color="#336699">
<BIG><CENTER><B>Merge Configuration Web page</B></CENTER></BIG>
</font>
</td>
</tr>
</table>
<BR>
<div id="HPFrameDLContent" style="width:100%;border-bottom:#ffffff 1px solid;border-left:#ffffff 1px solid;border-right:#ffffff 1px solid;">
<TABLE BORDER=0 WIDTH=100% ALIGN="LEFT" CELLSPACING=0 cellpadding="0">
HTML

open(I, "input.frm");
while (<I>) {
	chop;
	my ($desc, $name, $type, $extra) = split(/\|/);
	my $fun = "fun" . uc($type);
	next unless (UNIVERSAL::can(__PACKAGE__, $fun));
	my $val = ${"HTML::Merge::Ini::$name"};
	&$fun($desc, $name, $val, $extra);

}

foreach (qw(MERGE_SCRIPT DB_PASSWORD2)) {
	print "<INPUT TYPE=\"HIDDEN\" NAME=\"$_\" VALUE=\"${qq!HTML::Merge::Ini::$_!}\">\n";
}

print <<HTML;
<TR>
        <TD ALIGN="LEFT" COLSPAN=8 HEIGHT=10></TD>
</TR>
<TR>
        <TD ALIGN="LEFT"></TD>
        <TD ALIGN="CENTER"><input type="Submit" value="Save"></TD>
        <TD ALIGN="CENTER"><input type="Button" value="Close" onClick="window.close()"></TD>
        <TD ALIGN="LEFT"></TD>
</TR>
<TR>
        <TD ALIGN="LEFT" COLSPAN=8 HEIGHT=5></TD>
</TR>
</TABLE>
</FORM>
</BODY>
</HTML>
HTML

sub funS {
	my ($desc) = @_;
	print <<HTML;
<tr id="HPFrameDLTab" valign="middle" bgcolor="#CCCCCC">
<td></td>
<td align="left" width="100%" height="10" colspan=2>
<font id="HPFrameDLTab2" face="verdana,arial,helvetica" size="1" color="#336699">
<BIG><CENTER><B>$desc</B></CENTER></BIG>
</font>
</td>
<td></td>
</tr>
HTML
}

sub funT {
	my ($desc, $name, $val) = @_;
	$tab++;
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText"><INPUT NAME="$name" VALUE="$val" SIZE=25 MAXLENGTH=100 TABINDEX=$tab></div></td>
<td></td>
</tr>
HTML
}

sub funP {
	my ($desc, $name, $val) = @_;
	$tab++;
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText"><INPUT TYPE=PASSWORD NAME="$name" VALUE="$val" SIZE=25 MAXLENGTH=100 TABINDEX=$tab></div></td>
<td></td>
</tr>
HTML
}


sub funB {
	my ($desc, $name, $val) = @_;
	my ($on, $off) = ('', ' CHECKED');
	($off, $on) = ($on, $off) if $val;
	my $tab1 = ++$tab;
	my $tab2 = ++$tab;
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText">
<INPUT NAME="$name" TYPE=RADIO VALUE="0"$off> No
<INPUT NAME="$name" TYPE=RADIO VALUE="1"$on> Yes
</div></td>
<td></td>
</tr>
HTML
}

sub funC {
	my ($desc, $name, $val, $opts) = @_;
	my %hash;
	foreach (split(/,\s*/, $val)) {
		$hash{$_}++;
	}
        print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText">
HTML
        foreach(split(/,\s*/, $opts)) {
                $tab++;
                my $it = ucfirst(lc($_));
                my $chk = $hash{$_} ? " CHECKED" : "";
                print "<INPUT TYPE=CHECKBOX NAME=\"$name\" VALUE=\"$_\"$chk TABINDEX=$tab> $it\n";
        }
        print <<HTML;
<INPUT TYPE=HIDDEN NAME="$name" VALUE="">
</div></td>
<td></td>
</tr>
HTML
}

sub funR {
	my ($desc, $name, $val, $opts) = @_;
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText">
HTML
	foreach(split(/,\s*/, $opts)) {
		$tab++;
		my $it = ucfirst(lc($_));
		my $chk = $_ eq $val ? " CHECKED" : "";
		print "<INPUT TYPE=RADIO NAME=\"$name\" VALUE=\"$_\"$chk TABINDEX=$tab> $it\n";
	}
	print <<HTML;
</div></td>
<td></td>
</tr>
HTML
}
	
sub funL {
	my ($desc, $name, $val, $opts) = @_;
	$tab++;
	print <<HTML;
<tr>
<td></td>
<td><div class="bText">$desc</div></td>
<td><div class="sText">
<SELECT NAME="$name" TABINDEX=$tab>
HTML
	foreach(split(/,\s*/, $opts)) {
		my ($key, $data) = split(/:\s*/, $_);
		my $sel = $val eq $key ? ' SELECTED' : '';
		print "<OPTION VALUE=\"$key\"$sel>$data\n";
	}
        print <<HTML;
</SELECT>
</div></td>
<td></td>
</tr>
HTML

}
