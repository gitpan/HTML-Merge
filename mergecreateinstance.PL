use strict;
my $code = <<'ENDOFPERLCODE';
use strict;
use Term::ReadLine;

my %param;

my $term = new Term::ReadLine('');

print "Warning: this script works ONLY on UNIX systems!\n\n";

my $cgi_bin = $term->readline("Enter your cgi-bin directory, full path: ");

$cgi_bin =~ s|/$||;

die "$cgi_bin does not exist" unless (-d $cgi_bin);

$param{'cgi_bin'} = $cgi_bin;

print "\n";

my $default = $cgi_bin;
$default =~ s|^.*/|/|;

my $url = $term->readline("Enter the web url (without http://server)
for that cgi-bin directory [$default]: ");
$url =~ s|/$||;

$url ||= $default;
$url =~ s|^http://[^/]+||;

$param{'url'} = $url;

print "\n";
my $user = $term->readline("Enter the user id for your web server [www]: ");
$user ||= 'www';

my @data = getpwnam($user);
die "No user $user" unless (@data);

my $uid = $data[2];

print "\n";
my $group = $term->readline("Enter the group id for your web server [www]: ");
$group ||= 'www';
@data = getgrnam($group);
die "No group $group" unless (@data);
my $gid = $data[2];

print "\n";
my $ext = $term->readline("Enter suffix to use for CGI [pl]: ");

$ext ||= "pl";
my $script = "merge.$ext";


my $merge;
foreach (split(/[:;]/, $ENV{'PATH'})) {
	my $candidate = "$_/merge.cgi";
	if (-x $candidate) {
		$merge = $candidate;
		last;
	}
}
 
die "Could not fing merge.cgi in PATH" unless (-x $merge);

my $private = $merge;
$private =~ s|/bin/merge.cgi|/share/merge|;

die "Could not find merge data at $private" unless (-d $private);

my $choice;
do {
	print "\nDo you wish to <C>opy $private/private 
into $cgi_bin or create a symbolic <L>ink? [C/L] ";
	system "stty raw";
	$choice = uc(getc(STDIN));
	system "stty -raw";
	die "Aborted" if ($choice eq "\x3" || $choice eq "\e");
	$choice =~ s/^(.).*$/$1/;
} until ($choice =~ /[CL]/);

if ($choice eq 'C') {
	system "\\cp -r $private/private $cgi_bin/";
} else {
	system "\\rm -rf $cgi_bin/private";
	symlink	"$private/private", "$cgi_bin/private" ||
		die "Could not link $private/private to $cgi_bin/private: $!";
}

print "\n\n";

unlink "$cgi_bin/$script";
symlink $merge, "$cgi_bin/$script" || 
	die "Could not link $merge to $cgi_bin/$script: $!";
print "You must configure your webserver to alias $url 
as $cgi_bin and run .pl files over there 
as CGI scripts\n";

my $source = $merge;
$source =~ s/\.\w+?$/.conf/;

open(I, $source) || die "Cannot find $source";
my $cfg = join("", <I>);
close(I);

my $set = $param{'S_FROM'} = join("", 'A' .. 'Z', 'a' .. 'z', '-_',
					'0' .. '9');

while ($set) {
	my $r = int(rand(length($set)));
	$param{'S_TO'} .= substr($set, $r, 1);
	substr($set, $r, 1) = '';
}

foreach (qw(S_FROM S_TO)) {
	$param{$_} = join("", map {sprintf("%02X", $_);} unpack("C*", $param{$_}));
}

while (my ($var, $val) = each %param) {
	$cfg =~ s/\@$var\@/$val/gi;
}

open(O, ">$cgi_bin/merge.conf");
print O $cfg;
close(O);

mkdir "$cgi_bin/template", 0755;
mkdir "$cgi_bin/cache", 0755;
mkdir "$cgi_bin/logs", 0755;
foreach (qw(template cache logs merge.conf)) {
	chown $uid, $gid, "$cgi_bin/$_" || die  "Could not change ownership on $cgi_bin/$_ to $user.$group: $!";
}

print "\007You must edit $cgi_bin/merge.conf!!!\n";
ENDOFPERLCODE

use Config;
my $shebang = $Config{'startperl'};
open(O, ">$ARGV[0]") || die $!;
print O "$shebang\n$code";
close(O);
chmod 0755, $ARGV[0];


