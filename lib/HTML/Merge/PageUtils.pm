#################################################################
package HTML::Merge::PageUtils;
#################################################################
# PageUtils.pm - Compiled page utilities and func               #
# Authors : Roi Illouz			                        #
# Raz Information Systems Ltd.(c) 1999		                #
# Date : 04/04/2004                                             #
# Updated :                                                     #
#################################################################
                                                                                
# Perl modules ##################################################

use strict;

# Globals #######################################################

# Functiones ####################################################
=line
sub getvar ($)
{
	my ($var) = @_;

	return $vars{$var};
}
#################################################################
sub setvar ($$)
{
	my ($var,$val) = @_;

	$vars{$var} = $val;
}
#################################################################
sub incvar ($$)
{
	my ($var,$val) = @_;

	$vars{$var} += $val;
}
#################################################################
sub getfield ($;$)
{
	my ($field, $engine) = @_;

        return $engines{$engine}->Var($field);
}
#################################################################
sub merge ($)
{
	my ($code) = @_;

	my $text;

	$@ = undef;
        eval { $text = HTML::Merge::Compile::Compile($code, __FILE__); };

        HTML::Merge::Error::HandleError('ERROR', $@) if $@;

	# bad need to be fied
        #eval $text;

        #HTML::Merge::Error::HandleError('ERROR', $@) if $@;
}
#################################################################
sub dbh ()
{
	return $engines{""}->{'dbh'};
}
=cut
#################################################################
1;
#################################################################
