########################################

use ExtUtils::MakeMaker;
use strict;

########################################
sub MY::dist_core
{
	package MY;
	my $inherited = shift->SUPER::dist_core;
	$inherited =~ s/dist : /dist : update_private /;
		
$inherited .= << 'DMAKE';
#
update_private : 
	$(CP) lib/HTML/Merge.pm private/perl/HTML/Merge.pm
	$(CP) lib/HTML/Merge/*.pm private/perl/HTML/Merge/
	$(CP) lib/HTML/Merge/*.pod private/perl/HTML/Merge/
	$(CP) lib/HTML/Merge/App/*.pm private/perl/HTML/Merge/App/

DMAKE

$inherited;
}
########################################
sub MY::install 
{
	package MY;
	my $inherited = shift->SUPER::install;
	$inherited . <<'MAKE';
#
DATA = $(PERLPREFIX)/share

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
	$(MOD_INSTALL) docs/samples $(DATA)/merge/docs/samples

.SUFFIXES: .txt .pm .html .pod

docs/%.txt: lib/HTML/Merge/%.pm 
	@$(PERL) -MPod::Text -e "pod2text('$<');" > $@

docs/%.html: lib/HTML/Merge/%.pm 
	@$(PERL) -MPod::Html -e "pod2html('$<');" | perl -np -e 's|/HTML/(Merge/)?||g' > $@

docs/%.txt: lib/HTML/Merge/%.pod
	@$(PERL) -MPod::Text -e "pod2text('$<');" > $@

docs/%.html: lib/HTML/Merge/%.pod
	@$(PERL) -MPod::Html -e "pod2html('$<');" | perl -np -e 's|/HTML/(Merge/)?||g' > $@

docs/%.txt: lib/HTML/%.pm  
	@$(PERL) -MPod::Text -e "pod2text('$<');" > $@

docs/%.html: lib/HTML/%.pm 
	@$(PERL) -MPod::Html -e "pod2html('$<');" | perl -np -e 's|/HTML/(Merge/)?||g' > $@

docs :
	$(MKPATH) docs

# DOCUMENTS_NEEDED = docs/Merge.txt docs/Tags.txt docs/Ext.txt 
# README :: docs $(DOCUMENTS_NEEDED) $(DOCUMENTS_NEEDED:.txt=.html)
#	cat $(DOCUMENTS_NEEDED) > $@

MAKE
}
########################################
sub MY::dist_dir 
{
	package MY;
	my $inherited = shift->SUPER::dist_dir;
#	$inherited =~ s/^\s*distdir\s*\:/distdir : README/;
	$inherited;
}
########################################

print "\n";
eval{ require Data::Password; };
print "Install Data::Password if you need strong password checking\n" if $@;
eval{ require DBI; require DBD::SQLite; };
print "DBD::SQLite is highly recomanded!\n You should have good understanding of HTML::Merge \n",
      " if you decide to install with out it or you will not be able use built in security\n",
      " and context management.\n"  if $@;

WriteMakefile(
    'NAME'	=> 'HTML::Merge',
    'VERSION_FROM' => 'lib/HTML/Merge/Compile.pm', # finds $VERSION
    'EXE_FILES' => [qw(merge.cgi merge.conf mergecreateinstance)],
    'dist' => {'COMPRESS' => 'gzip --best --force'},
    'PREREQ_PM'  => { 'DBI' => 0,
                        'Term::ReadLine' => 0,
			'DBD::SQLite' => 0,
			}
);
