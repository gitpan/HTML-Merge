__END__

=head1 NAME

HTML::Merge::Tags - Tag summary for Merge.

=head1 DATABASE TAGS

=item

<$RDB='[B<Database type>:]B<Database name>[:B<Host>][,B<User>[,B<Password>]]'>

Connect to alternative database. Defaults are taken from the configuration 
file. If two parameters are given in the first token, the database type takes
precedence.

=item

<$RS='B<SQL statement>'>

Perform a non query SQL statement.

=item

<$RQ='SELECT B<SQL statement>'>

Perform a query. First row of result is immediately available.
Query can be iterated with <$RLOOP> tags.

=item

<$RLOOP[.LIMIT=B<number>]>

</$RLOOP> or <$REND>

Performs a loop over fetched query elements. Last row remains valid after
iteration.
Iteration number can be limited.

=item

<$RSQL.B<variable>>

Derferences a column from the current fetch.

=item

<$RINDEX>

Substitues for the number of the row currently fetched.

=item

<$RFETCH>

Fetches another row. Increments the index.

=item

<$RSTATE>

Returns the SQL state of the last statement.

=head1 FLOW TAGS

=item

<$RITERATION.LIMIT=B<number>>

</$RITERATION>

Performs a counted loop.

=item

<$RIF.'B<perl code>'>

<$RELSE> (optional)

<$REND_IF> or </$RIF>

Perform the code if the perl code evaluates to true.


=item

<$RWHILE.'B<perl code>'>

</$RWHILE> or <$REND_WHILE>

Perform a while loop.

=item

<$RBREAK>

Break out of a loop.

<$RCONT>

Jump to the next iteration of the loop.

<$RCOUNT.B<variable>.B<from>.B<to>.B<step>>

</$RCOUNT>

Perform a classic variable iteration loop. All parameters are mandatory.

=head1 FUNCTIONAL TAGS

<$RPIC>

Documentation soon.

=item

<$RMAIL.'B<From address>','B<To address>'[,'B<Subject>']>

</$RMAIL>

Send email, utilizing SMTP connection to localhost.

=item

<$RPERL>

</$RPERL>

Embed perl code. print() may be used.

=item

<$RPERL.A>

<$RPERL.B>

<$RPERL.C>

Documentation soon.

=head1 SOURCE TAGS

=item

<$REM.'B<string>'>

Add a server side comment.

=item

<$RTRACE.'B<string>'>

Send a string to the log file.

=item

<$RINCLUDE.'B<template name>'>

Include a template in compile time.

=item

<$RWEBINCLUDE.'B<url>'>

Include an external web page in run time.

=head1 VARIABLE TAGS

=item

<$RVAR.B<variable>>

Dereferences a local variable, or a CGi variable. (Precedence to the former).

=item

<$RSET.B<variable>='B<perl code>'>

Set a variable to the result of a perl code segment.
CGI variables may be overwritten.

=item

<$RINC.B<variable>>

<$RINC.B<variable>+B<number>>

<$RINC.B<variable>-B<number>>

Modify a variable.

=item

<$RPSET.B<variable>='B<perl code>'>

<$RPGET.B<variable>>

Store and retrive session variables. Must be configured in the configuration
file manually.

=item

<$RCFG.B<variable>>

Retrieve a variable from Merge configuration.

=item

<$RCFGSET.B<variable>='B<perl code>'>

Forge a temporary value instead of a configuration variable. Does B<NOT> change the configuration file!

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut

