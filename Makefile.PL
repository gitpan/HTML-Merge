use ExtUtils::MakeMaker;
use strict;

sub MY::install {
	package MY;
	my $inherited = shift->SUPER::install;
	$inherited . <<'MAKE';
DATA = $(PREFIX)/share

install :: install-private install-public install-docs install-samples

install-private ::
	$(PERL) updateshebang.pl private/perl
	$(MOD_INSTALL) private $(DATA)/merge/private

install-public :: 
	$(PERL) updateshebang.pl public/perl
	$(MOD_INSTALL) public $(DATA)/merge/public

install-docs :: docs README
	$(MOD_INSTALL) docs $(DATA)/merge/docs

install-samples :: docs README
	$(PERL) createsamples.pl	
	$(MOD_INSTALL) samples $(DATA)/merge/docs/samples

.SUFFIXES: .txt .pm .html

docs/%.txt: lib/HTML/Merge/%.pm
	@$(PERL) -MPod::Text -e "pod2text('$<');" > $@

docs/%.html: lib/HTML/Merge/%.pm
	@$(PERL) -MPod::Html -e "pod2html('$<');" | perl -np -e 's|/HTML/(Merge/)?||g' > $@

docs/%.txt: lib/HTML/%.pm 
	@$(PERL) -MPod::Text -e "pod2text('$<');" > $@

docs/%.html: lib/HTML/%.pm
	@$(PERL) -MPod::Html -e "pod2html('$<');" | perl -np -e 's|/HTML/(Merge/)?||g' > $@

docs :
	$(MKPATH) docs

DOCUMENTS_NEEDED = docs/Merge.txt docs/Tags.txt docs/Ext.txt
README :: docs $(DOCUMENTS_NEEDED) $(DOCUMENTS_NEEDED:.txt=.html)
	cat $(DOCUMENTS_NEEDED) > $@

MAKE
}

sub MY::dist_dir {
	package MY;
	my $inherited = shift->SUPER::dist_dir;
	$inherited =~ s/^\s*distdir\s*\:/distdir : README/;
	$inherited;
}

eval { require Term::ReadLine; };

WriteMakefile(
    'NAME'	=> 'HTML::Merge',
    'VERSION_FROM' => 'lib/HTML/Merge/Compile.pm', # finds $VERSION
    'EXE_FILES' => [qw(merge.cgi merge.conf mergecreateinstance)],
    'dist' => {'COMPRESS' => 'gzip --best --force'},
    'PREREQ_PM'  => {'Term::ReadLine::Gnu' => 0,
			'DBI' => 0,
			'DBD::SQLite' => 0}
);
