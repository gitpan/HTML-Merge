use ExtUtils::MakeMaker;

sub MY::install {
	package MY;
	my $inherited = shift->SUPER::install;
	$inherited . <<'MAKE';
DATA = $(PREFIX)/share

install :: install-private

install-private ::
	$(PERL) updateshebang.pl
	$(MOD_INSTALL) private $(DATA)/merge/private

MAKE
}


WriteMakefile(
    'NAME'	=> 'HTML::Merge',
    'VERSION_FROM' => 'lib/HTML/Merge/Compile.pm', # finds $VERSION
    'EXE_FILES' => [qw(merge.cgi merge.conf mergecreateinstance)],
    'dist' => {'COMPRESS' => 'gzip --best --force'},
);
