package HTML::Merge::Ext;

use vars qw($ENGINE);

## preset examples

sub OUT_CHOMPIE ($) {
	my ($param) = @_;
	qq!"shalom $param on engine $ENGINE\\n"!;
}

sub OAPI_EYNSHEM ($$$$) {
	my ($var, $from, $to, $step) = @_;
	qq!for (\$vars{"$var"} = "$from"; \$vars{"$var"} <= "$to"; \$vars{"$var"} += "$step") {\n!;
}

sub CAPI_EYNSHEM () {
	"}\n";
}

sub OUT_SASSI () {
	qq!"* \\. *"!;
}

sub OUT_YONA ($$) {
	my ($a, $b) = @_;
	qq!"$a and $b"!;
}

1;
__END__

=head1 NAME

Merge extensions - Writing your own tags to be used in Merge pages.

=head1 DESCRIPTION

This file contains instructions as to how to create your own Merge tags.

=head1 TYPES OF TAGS

Generally, there are four types of tags in Merge.

=head2 Output tags

Tags such as <$RVAR> or others, that are substituted by values that appear
in the output. For example: <$RVAR.x> is substituted by the value of the
vairable x.

=head2 Non block tags

Tags that perform an action, and have no corresponding closing tags.
For example: <$RSET.x='8'> sets the value 8 into the variable x.

=head2 Opening block tags

Tags that usually handle the flow of the template. These tags, together with
the closing tags, encapsulate a block of HTML and tags between them.
The data inside the block will be treated as regular output statements.
If you wish to capture it for a different use, a capturing mechanism
(for example, using the Perl select() statement) needs to be used.
For example, <$RITERATION.LIMIT=4> .. </$RITERATION> will print everything
inside the block 4 times.

=head2 Closing block tags

The tags that close blocks beginning in the opening tags.
The tags <$REND>, <$REND_IF> and <$REND_WHILE> are privilleged as closing
tags. Other closing tags use the SGML like notation of specifying a slash
before the name of the tag, for example: </$RCOUNT> is the closing tag for
<$RCOUNT>

=head1 COMPILATION PROCESS

B<Do not execute, create code!>

When Merge scans the template, it does not interprete the program, but
creates Perl code to run it. The HTML code is converted to print() statements.
Non block tags are inserted as generated Perl code. Block tags are added as 
generated code, that encapsulate a perl operation on the code within.
Output tags depend on connotation: when specified in the middle of HTML code,
the generated code will be used as a parameter for print(). When specified
as part of a parameter for another tag, string concatenation is used to
create one string.
For example:

<$RVAR.x> is translated to : print ($vars{"x"});

<$RQ.'<$RVAR.x>'> is translated to: $engines{""}.Query("" . ($vars{"x"}) . "")

In both cases, the code generated by <$RVAR> is an expression, not a list
of statements.

Notice, that when using *any* parameter gotten for a tag, either assumed to
be string or not, it must be encapsulated in double quotes.
Consider we are writing a tag <$RSQR> and generating the code
"sqr($x)". If the user tried <$RSQR.<$RVAR.x>>, we will get
sqr(" . $vars{"x"} . ") which is not what we intended.
Therefore we should create the code:
"sqr(\"$x\")"
Which can be sqr("3") for <$RSQR.3> or sqr("" . $vars{"x"} . "") for
<$RSQR.<$RVAR.x>>.

Hint: sometimes you need to perform a few sentences for generating an output
tag. In this case it is better to create a function to run in runtime
in the extension module, for example:

	sub Proper {
		my $str = shift;
		$str =~ s/(\w+)/ucfirst(lc($1))/ge;
		$str;
	}

and generate the code: "HTML::Merge::Ext::Proper(\"$x\")".
Note that all the functions in the extension files reside under
the namespace HTML::Merge::Ext.

You can access the variable $HTML::Merge::Ext::ENGINE, or simply
$ENGINE, to determine which engine was called for the tag.
The engine API is not documented yet and might change without a warning.

=head1 EXTENSION FILES

Extension files are created per site, as a file called merge.ext, residing
in the instance directory, or per server, in the file /etc/merge.ext.

=head1 EXTENDED TAGS SYNTAX

Every tag is defined as a function returning the Perl code for the tag.
The function must have a prototype cotaining only scalars, to represent
the number of input parameters.

If we defined a tag called <$RUSER> with two parameters, it will be called
as <$RUSER.<first parameter>.<second parameter>>. If parameters were
encapsulated with quotes, it's the job of the user defined function to
strip them.

All special chars in the parameters will be quoted with a leading backslash
using the function quotemeta. Special chars that were not quoted belong to
the generated code the parameters might already contain. We basically
encourage that you don't alter the parameters, except of stripping quotes
if necessary.

Here is an example for a tag called PLUS, that accepts two parameters,
and is substituted by the result of their addition in the output.
Notice that the function prototype is crucial.

	sub OUT_PLUS ($$) {
		my ($a, $b) = @_;
		"\"$a\" + \"$b\""; # Return perl code to perform the operation
	}

Notes:

=over 4

=item 1

The prototype defines two parameters.

=item 2

The parameters must be encapsulated with B<double> quotes, even though we
expect numbers.

Here is how B<***NOT***> to implement the tag:

	sub OUT_PLUS ($$) {
		my ($a, $b) = @_;
		return $a + $b; # or equally WRONG:
		return '"' . ($a + $b) . '"''; 
	}

You should not perform the operation in compilation time, but enable it to
perform in run time. The second version will work for
<$RPLUS.4.5> but B<NOT> for <$RPLUS.5.<$RVAR.a>>, which will result in a
hard coded zero.

=back

=head1 IMPLEMENTING VARIOUS TAGS

Functions should be in all uppercase, and consist of a prefix describing
the type of the tag, an underscore, and the tag name. 
Merge is case insensitive, so don't try to define tags with lowercase names.

	For a non block tag, use the prefix B<API>.
	For a block opening tag, use the prefix B<OAPI>.
	For a block ending tag, use the prefix B<CAPI>.
	For an output tag, use the prefix B<OUT>.

You can use the perl functions setvar, getvar and incvar to manipulate Merge
variables.

Here are some examples:

	sub OAPI_CSV ($) {
		my $filename = shift;
		$filename =~ s/^\\(["'])(.*)\\\1$/$2/; # Drop the quotes
						# in compilation time!
		<<EOM;
		open(I, "$filename"); # Must use double quotes!
		local (\$__headers) = scalar(<I>); # Do not use my() ! 
		chop \$__headers;
		local (\@__fields) = split(/,\\s*/, \$__headers);
		# Notice that we must escape variable names with backslashes
		while (<I>) {
			chop;
			my \@__data = split(/,\\s*/);
			foreach my \$i (0 .. \$#__fields) {
				setvar(\$__fields[\$i], \$__data[\$i]);
			}
	EOM
	}

	sub CAPI_CSV () {
		"}";
	}

	Here is how we would use it:

	<$RCSV.'/data/<$RVAR.name>'>
		<$RVAR.worker> has salary <$RVAR.salary><BR>
	</$RCSV>

	name could be 'workers.dat', and the file /data/workers.dat could be:

	worker, salary, office
	Bill, 9999999999999, Redmond
	George, 0, White House

=head1 MACRO TAGS

Macro tags define a tag by simply grouping merge code to be susbtituted under 
it. Suppose we have two tags, <$RFIRST> that takes two parameters, and 
<$RSECOND> that takes two as well, we could define the tag <$RCOMBINED>
this way:

	sub MACRO_COMBINED ($$$) {
		<<'EOM';
	First $1 and $2: <$RFIRST.$1.$2><BR>
	Second $2 and $3: <$RSECOND.$2.$3><BR>
	EOM
	}

This tag can now be called with three parameters.
Note: You do not need to parse the parameters yourself in a Macro tag.
You need to return a string containing Merge code and references to the
parameters like in a shell script. Writing a prototype is still mandatory.

=head1 DESCRIBED TAGS

Until now, extension tags could be called only with a list of parameters separated by commas. But merge enables defining tags that take a syntax similar to Merge native tags.

Suppose we define a tag:

	sub OUT_MINUS ($$) {
		my ($a, $b) = @_;
		qq!("$a") - ("$b")!;
	}

Now suppose we define a description function:

	sub DESC_MINUS {
		'U-U';
	}

We can now call the new tag: <$RMINUS.7-6> or <$RMINUS.<$RVAR.x>-1>
and so on.

All the non alpha characters in the description string stand for themselves.
The following letters are assigned:

	U - Unquoted parameters (e.g. 9, ball, <$RVAR.a> etc).
	Q - Quote parameter, (e.g. 'building', "quoted string", 'a "parameter" with <$RVAR.a> inside')
	E - Call can end here, rest of the parameters optional. For example, a tag with the description QE:Q-QE*Q can be called as either 'first', 'first':'second'-'third' or 'first':'second'-'third'*'fourth'.
	D - Either a dot or equal sign.

=head1 MOD PERL COMPLIANCE NOTICE

Merge implements the extensions by compiling them as Perl code into
Merge itself. Therefore, on a mod_perl driven web server with several
instances, extensions will be shared among all instances.

=head1 SYNOPSIS

=cut
