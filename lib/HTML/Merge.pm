__END__

=head1 NAME

Merge - Embedded HTML/SQL/Perl system by Raz Information Systems.

=head1 INSTALLATION

After installing the package, activate B<mergecreateinstance> to create an instance in your cgi-bin (or modperl) directory.
Follow the directions you get from B<mergecreateinstance> in order to configure
your web server.

You must edit the merge.conf created for you.

=head1 SYNOPSIS

	<HTML>
	<$RQ.'SELECT * FROM customers'>
	<$RLOOP>
	<$RVAR.name> owes <$RVAR.debt><BR>
	</$RLOOP>
	<A HREF="/cgi-bin/merge.pl?template=main_menu.html">
	</HTML>

=head1 DESCRIPTION

Merge is an embedded HTML/Perl/SQL tool used to create dynamic web content.
All Merge pages are refered to by B<cgi-bin-dir>/merge.pl?template=B<file.html>
although on CGI mode you can define merge.pl as an handler with the Action
directive in Apache.

Using merge.pl under Apache::Registry will utilize Perl's built-in caching to
cache pages using the B<do> command.

Merge uses a configuration file to retrieve information about database
connectivity and debugging. It has an embedded debugging tool and on-line
configuration. To turn that option on, set DEVELOPMENT to 1 in the 
configuration file. Don't forget to set it off before deployment.

Alternate configuration files can appear in B</etc/merge.conf> and B<$HOME/.merge>.

=head1 FILES

	B<merge.pl> Main script, usually a symbolic link to each instance.

	B<merge.conf> Configuration, unique per each instance.

	B<$PREFIX/share/merge/private> Internal scripts.

	B<$PREFIX/bin/merge.cgi> Main script, central.

	B<$PREFIX/bin/merge.conf> Template for configuration files.

	B<$PREFIX/bin/mergecreateinstance> Instance creating script.

=head1 AUTHOR

=over 4

=item *

Initial design by Oded Resnik, B<oded@raz.co.il>.

=item *

Versions 1 and 2 written by Roi Illouz, B<roi@raz.co.il>.

=item *

Version 3 written by Ariel Brosh, B<ariel@raz.co.il>.

=item *

Toolbox written by Eial Solodki.

=back

=head1 COPYRIGHT

Copyright (c) 1999, 2000, 2001, 2002 Raz Information Systems Ltd.
http://www.raz.co.il

This package is distributed under the same terms as Perl itself, see the 
Artistic License on Perl's home page.

=head1 SEE ALSO

perl(1), L<HTML::Merge::Tags>, L<HTML::Merge::Ext>.

=cut
