#########################################################
package HTML::Merge::Compile;
#########################################################
# Modules ############################################### 

use strict;
use Config;

# My Modules ############################################

use HTML::Merge::Constants;
use HTML::Merge::Ext;

# Globals ###############################################

use vars qw($VERSION);

$VERSION = '3.43';

#########################################################
sub new 
{
	my ($class, $in, $out) = @_;

	my $self = {};

	# class vars
	$self->{in_file} = $in;
	$self->{out_file} = $out;
	$self->{in_data} = undef;
	$self->{in_mtime} = GetFileMtime($in);
        $self->{out_mtime} = GetFileMtime($out);
	$self->{f_in} = undef;
	$self->{f_out} = undef;
	$self->{comp_str} = 'Raz Information Systems Ltd.(c) 1999 - ' . GetYear();

	return bless($self,$class);
}
#########################################################
# will work on perl 5.6.0 or heigher
sub CompileFile
{
	my ($self,$sub) = @_;

	my $dummy;

	# return if we don't need to compile 
	return $FALSE if ($self->{in_mtime} <= $self->{out_mtime} && 
				!$HTML::Merge::Ini::ALWAYS_COMPILE);
	open($self->{f_in}, $self->{in_file}) || return "Cannot open $self->{in_file}: $!";

	# can't get the syntax to work with dereferencing
	$dummy = $self->{f_in};
	$self->{in_data} = join("",<$dummy>);
	close($self->{in_file}); 
	
	open($self->{f_out}, ">$self->{out_file}") || return "Can't write $self->{out_file}: $!";
	
	if($sub) 
	{
		$self->Print($self->DefaultHeader());
	}

	$self->Print("in data: $self->{in_data}\n");
#	eval 
#	{	
#		print &Compile($text, $file);
#	};
#	my $code = $@;
	
	if($sub) 
	{
		$self->Print($self->DefaultFooter());
	}

	# finish and cleanups
	close($self->{f_out}); 
	chmod 0755, $self->{out_file};

	return $TRUE;
}
#########################################################
sub DefaultHeader
{
	my ($self) = @_;

	my ($file) = $self->{out_file} =~ /.*\/(.*)/;
	my $file_line = sprintf("# %-53.53s #",$file);
	my $comp_str_line = sprintf("# %-53.53s #",$self->{comp_str});

	my $buf = <<EOM;
$Config{'startperl'}
#########################################################
$file_line
$comp_str_line
#########################################################
# Modules ###############################################

use strict;

# My Modules ############################################

use HTML::Merge::PageUtils;

# Globals ###############################################

# Main ##################################################
EOM

	return $buf;
}
#########################################################
sub DefaultFooter
{
	my ($self) = @_;

	my $buf = <<EOM;
#########################################################
1;
#########################################################
EOM
	return $buf;
}
#########################################################
sub Print
{
	my ($self,$buf) = @_;

	print STDOUT $buf;
	print { $self->{f_out} } $buf;
}
########################################################
# locate the template from the various paths
sub GetTemplateFromPath
{
        my ($template) = @_;

        my @input = ("$HTML::Merge::Ini::TEMPLATE_PATH/$template",
                     "$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/public/template/$template");
                                                                                
        # let lets find the input
        foreach (@input)
        {
                if (-f)
                {
                        return $_;
                }
        }
                                                                                
        return $FALSE;
}
########################################################

sub GetFileMtime
{
	my ($file) = @_;

        my @stat = stat($file);

        return $stat[9];
}
########################################################
sub GetYear
{
	my @time = localtime();

	return $time[5] + 1900;
}
########################################################
sub SafeCreate 
{
	my ($tokens) = @_;

        my @tokens = split(/\//, $tokens);
        my $dir;

        pop(@tokens);

        foreach (@tokens) 
	{
                $dir .= "/$_";
                mkdir($dir, 0755);
        }
}
########################################################
1;
########################################################
