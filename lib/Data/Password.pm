package Data::Password;

# Ariel Brosh, January 2002, for Raz Information Systems

use Symbol;
use strict;
require Exporter;
use vars qw($DICTIONARY $FOLLOWING $GROUPS $MINLEN $MAXLEN
		$FOLLOWING_KEYBOARD
		$VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

@EXPORT_OK = qw($DICTIONARY $FOLLOWING $GROUPS $FOLLOWING_KEYBOARD
	$MINLEN $MAXLEN IsBadPassword IsBadPasswordForUNIX);
%EXPORT_TAGS = ('all' => [@EXPORT_OK]);
@ISA = qw(Exporter);

$VERSION = '1.01';

$DICTIONARY = 5;
$FOLLOWING = 3;
$FOLLOWING_KEYBOARD = 1;
$GROUPS = 2;

$MINLEN = 6;
$MAXLEN = 8;

sub OpenDictionary {
	my $sym = gensym;
	foreach (qw(/usr/dict/web2 /usr/dict/words)) {
		return $sym if (open($sym, $_));
	}
	undef;
}

sub CheckDict {
	return undef unless $DICTIONARY;
	my $pass = shift;
	my $dict = OpenDictionary();
	return undef unless $dict;
	while (<$dict>) {
		chop;
		next if length($_) < $DICTIONARY;
		if ($pass =~ /$_/i) {
			close($dict);
			return $_;
		}
	}
	close($dict);
	undef;
}

sub CheckSort {
	return undef unless $FOLLOWING;
	my $pass = shift;
	foreach (1 .. 2) {
		my @letters = split(//, $pass);
		my $diffs;
		my $last = shift @letters;
		foreach (@letters) {
			$diffs .= chr((ord($_) - ord($last) + 256 + 65) % 256);
			$last = $_;
		}
		my $len = $FOLLOWING - 1;
		return 1 if $diffs =~ /([\@AB])\1{$len}/;
		return undef unless $FOLLOWING_KEYBOARD;

		my $mask = $pass;
		$pass =~ tr/A-Z/a-z/;
		$mask ^= $pass;
		$pass =~ tr/qwertyuiopasdfghjklzxcvbnm/abcdefghijKLMNOPQRStuvwxyz/;
		$pass ^= $mask;
	}
	undef;
}

sub CheckTypes {
	return undef unless $GROUPS;
	my $pass = shift;
	my @groups = qw(a-z A-Z 0-9 ^A-Za-z0-9);
	my $count;
	foreach (@groups) {
		$count++ if $pass =~ /[$_]/;
	}
	$count < $GROUPS;
}

sub CheckCharset {
	my $pass = shift;
	$pass =~ /[\0-\x1F \x7F]/; 
}

sub CheckLength {
	my $pass = shift;
	my $len = length($pass);
	return 1 if ($MINLEN && $len < $MINLEN);
	return 1 if ($MAXLEN && $len > $MAXLEN);
	undef;
}

sub IsBadPassword {
	my $pass = shift;
	return "Not between $MINLEN and $MAXLEN characters"
		if CheckLength($pass);
	return "contains bad characters" if CheckCharset($pass);
	return "contains less than $GROUPS character groups"
		if CheckTypes($pass);
	return "contains over $FOLLOWING leading characters in sequence"
		if CheckSort($pass);
	my $dict = CheckDict($pass);
	return "contains the dictionary word '$dict'" if $dict;
	undef;
}

sub IsBadPasswordForUNIX {
	my ($user, $pass) = @_;
	my $reason = IsBadPassword($pass);
	return $reason if $reason;
	my $tuser = $user;
	$tuser =~ s/[^a-zA-Z]//g;
	return "is based on the username" if ($pass =~ /$tuser/i);

	my ($name,$passwd,$uid,$gid,
       		$quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam($user);
	return undef unless $comment;
	foreach ($comment =~ /([A-Z]+)/ig) {
		return "is based on the finger information" if ($pass =~ /$_/i);
	}
	undef;
}

1;
__END__

=head1 NAME

Data::Password - Perl extension for assesing password quality.

=head1 SYNOPSIS

	use Data::Password qw(IsBadPassword);

	print IsBadPassword("clearant");

	# Bad password - contains the word 'clear', only lowercase

	use Data::Password qw(:all);

	$DICTIONARY = 0;

	$GROUPS = 0;

	print IsBadPassword("clearant");

=head1 DESCRIPTION

This modules checks potential passwords for crackability.
It checks that the password is in the appropriate length,
that it has enough character groups, that it does not contain the same 
chars repeatedly or ascending or descending characters, or charcters
close to each other in the keyboard.
It will also attempt to search the ispell word file for existance 
of whole words.
The module's policies can be modified by changing its variables.  (Check L<"VARIABLES">).
For doing it, it is recommended to import the ':all' shortcut
when requiring it:

I<use Data::Password qw(:all);>

=head1 FUNCTIONS

=over 4

=item 1

IsBadPassword(password)

Returns undef if the password is ok, or a textual description of the fault if any.

=item 2

IsBadPasswordForUNIX(user, password)

Performs two additional checks: compares the password against the
login name and the "comment" (ie, real name) found on the user file.

=back

=head1 VARIABLES

=over 4

=item 1

$DICTIONARY

Minimal length for dictionary words that are not allowed to appear in the password. Set to false to disable dictionary check.

=item 2

$FOLLOWING

Maximal length of characters in a row to allow if the same or following.
If $FOLLOWING_KEYBOARD is true (default), the module will also check
for alphabetical keys following, according to the English keyboard
layout.
Set $FOLLOWING to false to bypass this check.

=item 3

$GROUPS

Groups of characters are lowercase letters, uppercase letters, digits
and the rest of the allowed characters. Set $GROUPS to the number
of minimal character groups a password is required to have.
Setting to false or to 1 will bypass the check.

=item 4

$MINLEN

$MAXLEN

Minimum and maximum length of a password. Both can be set to false.

=back

=head1 FILES

=over 4

=item *

/usr/dict/web2

=item *

/usr/dict/words

=item *

/etc/passwd

=back

=head1 AUTHOR

Raz Information Systems, B<razinf@cpan.org>, B<raz@raz.co.il>.

=cut
