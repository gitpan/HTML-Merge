use strict;
my $code = <<'ENDOFPERLCODE';
use strict qw(subs vars);
use Term::ReadLine;
use HTML::Merge::Engine qw(:unconfig);
use Data::Dumper;
use Term::InKey;
use Data::Password qw(IsBadPassword);
use Config;

my %param;

my $term = new Term::ReadLine('');

&Clear;

print "Warning: this script works ONLY on UNIX systems!\n\n";

my $default;

my @apache = qw(/home/httpd /usr/local/www /var/www /usr/local/httpd
	/usr/local/apache /usr/local/etc/apache /usr/local/etc/httpd
		/usr/local/etc/www);
foreach (@apache) {
	if (-d "$_/cgi-bin") {
		$default = "$_/cgi-bin";
		last;
	}
}

my $cgi_bin = &getone("Enter your cgi-bin directory, full path", 
		'CGI_BIN', $default, sub {
	s/^\s+//;
	s/\s+$//;
	s|/$||;

	die "$_ does not exist" unless (-d $_);
});

my $merge = findpath('merge.cgi', $Config{'installscript'});

die "Could not find merge.cgi in PATH" unless (-x $merge);

my $private = $merge;
$private =~ s|/bin/merge.cgi|/share/merge|;

die "Could not find merge data at $private" unless (-d $private);
while (-f "$cgi_bin/merge.conf") {
	require "$cgi_bin/merge.conf";
	last if $@;
	while (my ($var, $val) = each %$HTML::Merge::Ini::FACTORY) {
		$param{$var} = $val;
	}
	open(I, "$private/private/perl/input.frm") || last;
	while (<I>) {
		chop;
		my ($title, $name, $type, $opts, $default) = split(/\|/);
		if ($default =~ s/\@(.*?)\@/\0/) {
			my $item = $1;
			my $re = quotemeta($default);
			$re =~ s/\\\0/(.*)/;
			my $val = ${"HTML::Merge::Ini::$name"};
			if ($val =~ /^$re$/) {
				$param{$item} = $1;
			}
		}
	}
	close(I);
	$param{'__DB_PASS'} = 
		HTML::Merge::Engine::Convert($param{'DB_PASSWORD'});
	last;
}

mkdir "$cgi_bin/template", 0755;
mkdir "$cgi_bin/cache", 0755;
mkdir "$cgi_bin/logs", 0755;

print "\n";

$default = $cgi_bin;
$default =~ s|^.*[/\\]|/|;

my $url = getone("Enter the web url (without http://server)
for that cgi-bin directory", 'URL', $default, sub {
	 s|/$||;

	$_ ||= $default;
	s|^http://[^/]+||;
});


$default = `httpd -V | grep SERVER_CONFIG_FILE`;
$default =~ s/^\s*-D\s+SERVER_CONFIG_FILE=\"(.*)\"\s*$/$1/;

unless ($default) {
	foreach (@apache) {
		if (-f "$_/conf/httpd.conf") {
			$default = "$_/conf/httpd.conf";
		}
	}
}

print "\n";

my $conf = getone("Enter the location of your httpd.conf", 'HTTP_CONFIG',
	$default, sub { die "$_ not found" if $_ && ! -f; });

$default = 'nobody';

foreach (qw(apache www httpd)) {
	my @data = getpwnam($_);
	if (@data) {
		$default = $_;
		last;
	}
}

print "\n";

my $nextdef;
if ($conf) {
	open(I, $conf) || die "Cannot open $conf: $!";
	while (<I>) {
		if (/^\s*User\s+(.*?)\s*((?:#.*)?)$/) {
			$default = $1;
		}
		if (/^\s*Group\s+(.*?)\s*((?:#.*)?)$/) {
			$nextdef = $1;
		}
	}
	close(I);
}

my @data;

my $user = &getone("Enter the user id for your web server" , 'WWW_U', $default,
	sub {

	@data = getpwnam($_);
	die "No user $_" unless (@data);
});

my $uid = $data[2];

$default = $user;
@data = getgrnam($default);
unless (@data) {
	$default = 'nobody';
}

print "\n";
my $group = &getone("Enter the group id for your web server",
	'WWW_G', $nextdef, sub {

	@data = getgrnam($_);
	die "No group $_" unless (@data);
});

my $gid = $data[2];

print "\n";

($param{'SUFFIX'}) = (split(/\./, $param{'SCRIPT'}))[-1];

my $ext = getone("Enter suffix to use for CGI",
	'SUFFIC', 'pl');

delete $param{'SUFFIX'};

my $script = $ext ? "merge.$ext" : 'merge';
$param{'SCRIPT'} = $script;

my ($choice, $def);
do {
	if ($^O =~ /Win/i) {
		$choice = 'C';
		last;
	}

	if (-x "$cgi_bin/$script") {
		$def = "/.No change.";
	}
	print "


Symbolic links are easier to maintain, but will work only 
on UNIX systems and Apache servers that have the FollowSymLinks 
directive applied. If they are not an option, choose Copy.
If you are recreating an existent instance with a linked directory,
or if you do not wish to have development mode on, choose None.
If you chosse None or Copy, $cgi_bin/$script will be created
as a copy of $merge; if you choose Link it will be a symbolic link.

Do you wish to <C>opy $private/private 
into $cgi_bin or create a symbolic <L>ink? [C/L/None$def]: ";
	$choice = uc(&ReadKey);
	die "Aborted" if ($choice eq "\x3" || $choice eq "\e");
	$choice =~ s/^(.).*$/$1/;
} until ($choice =~ /[CLN]/ || $choice eq "\r" && $def);

print $choice if ($choice =~ /\S/);
print "\n\n";

if ($choice eq 'C') {
	print "Copy\n";
	&scrape;
	require ExtUtils::Install;
	ExtUtils::Install::install({"$private/private" => $cgi_bin}, 1, 0);
	unlink "$cgi_bin/$script";
	require File::Copy;
	File::Copy::copy($merge, "$cgi_bin/$script");
	chmod 0755, "$cgi_bin/$script";
} elsif ($choice eq 'L') {
	print "Link\n";
	&scrape;
	symlink	"$private/private", "$cgi_bin/private" ||
		die "Could not link $private/private to $cgi_bin/private: $!";

	unlink "$cgi_bin/$script";
	symlink $merge, "$cgi_bin/$script" || 
		die "Could not link $merge to $cgi_bin/$script: $!";
} elsif ($choice eq 'N') {
	print "None\n";
	unless (-x "$cgi_bin/$script") {
		require File::Copy;
		File::Copy::copy($merge, "$cgi_bin/$script");
		chmod 0755, "$cgi_bin/$script";
	}
} elsif ($choice ne "\r") {
	die "Unknown choice $choice";
}

do {
	print "\n\nWould you like to install the samples? [.Y./N]: ";
	$choice = uc(&ReadKey);
	$choice =~ s/[\r\n]/Y/;
	print "$choice\n";
} until ($choice =~ /^[YN]$/);

my $createdb;

$param{'DEFAULT'} = '';
if ($choice eq 'Y') {
	require File::Copy;
	foreach (glob("$private/docs/samples/*.html")) {
		my $dest = $_;
		$dest =~ s|^$private/docs/samples|$cgi_bin/template|;
		File::Copy::copy($_, $dest);
	}
	$param{'DEFAULT'} = 'samples.html';
}

my $flag;
eval {
	require DBI;
	for (;;) {
		my @drivers = DBI->available_drivers;
		print "Available DBI drivers:\n";
		my $i = 0;
		foreach (@drivers) {
			print ++$i, ") $_\n";
		}
	
		my $drv = &getone("Choose DBI driver",
			'DRIVER', undef, undef, 1);
		if ($drv =~ /^\d+$/) {
			$drv = $drivers[$drv - 1];
		}
		last unless ($drv);
		print "$drv chosen.\n";
		my @databases;
		eval { @databases = DBI->data_sources($drv); 
			foreach(@databases) {
				s/^.*?:.*?://;
			}
		};
		$i = 0;
		if (@databases) {	
			foreach (@databases) {
				print ++$i, ") $_\n";
			}
		}
		my $default = $drv eq $param{'DRIVER'} ? $param{'DB'} : '';
		my $db = getone("Choose application database:",
			undef, $default);
		if ($db =~ /^\d+$/) {
			$db = $databases[$db - 1];
		}
		print "DSN is dbi:$drv:$db\n\n";

		print "Note: on some databases username and password could be
left blank. Type NONE to override the default by an empty string.\n\n";
	
		my $duser = getone("Username to connect to database", 
			'DB_USER', $user, undef, 1);

		$default = $param{'__DB_PASS'};
		$default =~ s/./*/g;
		print "Password for username '$duser' [$default]: ";
		my $dpass = &ReadPassword;
		exit unless defined $dpass;
		$dpass ||= $param{'__DB_PASS'};
		$dpass =~ s/^none$//i;

		print "\n\nTrying...";
		my $dbh;
		eval { $dbh = DBI->connect("dbi:$drv:$db", $duser, $dpass) 
			|| die $DBI::errstr;};
		if ($@) {
			print "\nError: $DBI::errstr\n";
			next;
		}

		$param{'DRIVER'} = $drv;
		$param{'DB'} = $db;
		$param{'DB_USER'} = $duser;
		$param{'__DB_PASS'} = $dpass;
		$flag = 1;

		print "\n";

		$i = 0;
		if (@databases) {	
			foreach (@databases) {
				print ++$i, ") $_\n";
			}
		}

		my $mergedb = getone("Choose system database",
			'MERGE_DB', 'merge');

		if ($mergedb) {

			&Clear;

			if ($mergedb =~ /^\d+$/) {
				$mergedb = $databases[$mergedb - 1];
			}
			eval { $dbh->do("CREATE DATABASE $mergedb") };

			$dbh->disconnect;
			$createdb = 1;
		}
		last;
	}
};

@param{qw(DB_USER DB_PASS DRIVER DB MERGE_DB)} = () unless $flag;

my $savep = $param{'ROOT_PASSWORD'};
my $nextp = '';

for (;;) {
	my $p;
	my $save = $param{'ROOT_USER'};
	my $ru = getone("Enter default root user" , 'ROOT_USER', 'admin');

	my ($default, $s_default);
	if (exists $param{'ROOT_PASSWORD'} && $save eq $ru) {
		$s_default = '<no change>';
	} else {
		$s_default = $default = $ru;
	}

	print "Choose root password [$s_default]: ";
	$p = &ReadPassword;
	exit unless defined $p;
	if ($p && $p !~ /^none$/i) {
		my $reason = IsBadPassword($p);
		if ($reason) {
			print "Bad password: It $reason\7\n";
			next;
		}

		print "Reenter root password: ";
		my $pp = &ReadPassword;
		exit unless defined $pp;
		if ($p ne $pp) {
			print "Not identical!\7\n";
			next;
		}
	}
        $p ||= $default;
	$p =~ s/^none$//i;
	unless ($p) {
		$nextp = $param{'ROOT_PASSWORD'} = '';
		last;
	}
	$param{'ROOT_PASSWORD'} = crypt($p, pack("CC", rand(26) + 65,
			rand(26) + 65));
	$nextp = crypt($p, pack("CC", rand(26) + 65,
			rand(26) + 65));
	last;
}

print "\n\nYou must configure your webserver to alias $url 
as $cgi_bin and run .pl files over there 
as CGI scripts\n";

if ($conf) {
	open(I, $conf) || die "Cannot open $conf: $!";	
	my $temp = "/tmp/$$-merge-httpd";
	open(O, ">$temp") || die "Cannot ope $temp: $!";
	my $need = 1;
	my $flag = undef;
	while (<I>) {
		if (/^\s*(Script)?Alias\s+$url\/?\s/i) {
			$need = undef;
		}
		$flag = 1 if (/^#\s*BEGIN MERGE $cgi_bin\b/);
		print O unless $flag;
		$flag = undef if (/^#\s*END MERGE $cgi_bin\b/);
	}
	print O "# BEGIN MERGE $cgi_bin\n";
	if ($need) {
		print O "ScriptAlias $url/ $cgi_bin/\n";
	}
	my $pwd = "$cgi_bin/.htmerge";
	print O <<EOM;
<Location $url/.htmerge>
    Order deny,allow
    Deny from all
</Location>
<Directory $cgi_bin/private>
  AuthType Basic
  AuthName "Merge instance $url"
  AuthUserFile $pwd
  AuthGroupFile /dev/null

  <Limit GET POST>
    require valid-user
  </Limit>
</Directory>
EOM
	print O "\n# END MERGE $cgi_bin\n";
	close(O);
	open(I, $temp) || die "Cannot open $temp: $!";
	open(O, ">$conf") || die "Cannot open $conf: $!";
	print O <I>;
	close(O);
	close(I);

	if ($savep ne $param{'ROOT_PASSWORD'}) {
		open(O, ">>$pwd") || die "Cannot open $pwd: $!";
		close(O);
		my @save;
		open(I, "$pwd") || die "Cannot open $pwd: $!";
		while (<I>) {
			push(@save, $_) unless (/^$param{'ROOT_USER'}:/);
		}
		close(I);
		open(O, ">$pwd") || die "Cannot open $pwd: $!";
		print O "$param{'ROOT_USER'}:$nextp\n";
		print O join("", @save);
		close(O);
	}
}

my $source = $merge;
$source =~ s/\.\w+?$/.conf/;

open(I, $source) || die "Cannot open $source: $!";
my @lines = <I>;
close(I);

my $set = $param{'S_FROM'} = join("", 'A' .. 'Z', 'a' .. 'z', '-_',
					'0' .. '9');

$param{'S_TO'} = '';

while ($set) {
	my $r = int(rand(length($set)));
	$param{'S_TO'} .= substr($set, $r, 1);
	substr($set, $r, 1) = '';
}

foreach (qw(S_FROM S_TO)) {
	$param{$_} = join("", map {sprintf("%02X", $_);} unpack("C*", $param{$_}));
	${"HTML::Merge::Ini::$_"} = $param{$_};
}

my @params;
foreach(@lines) {
	unless (/;\s*#.*$/) {
		push(@params, undef);
	} else {
		my $pos = length($_) - length($');
		my $extra = substr($_, $pos);
		substr($_, $pos) = "";
		push(@params, [$pos, $extra]);
	}
}

my $cfg = join("\n", @lines);

$param{'DB_PASSWORD'} = HTML::Merge::Engine::Convert($param{'__DB_PASS'}, 1);
delete $param{'__DB_PASS'};
$param{'SCRIPT'} = $script;

while (my ($var, $val) = each %param) {
	$cfg =~ s/\@$var\@/$val/gi;
}

@lines = split(/\n/, $cfg);

my $i = 0;
foreach (@lines) {
	s/\s+$//;
	my $this = $params[$i];

	if ($this) {
		my ($pos, $extra) = @$this;

		$_ = sprintf("%-${pos}s", $_);

		$_ .= $extra;
	}

	$i++;
}

$cfg = join("\n", @lines);

open(O, ">$cgi_bin/merge.conf") || die $!;
print O "$cfg\n";
print O '$FACTORY = ' . Dumper(\%param) . "\n1;\n";
close(O);
chmod 0644, "$cgi_bin/merge.conf";

if ($createdb) {
	Clear();
	print "Your $param{'MERGE_DB'} database will be created now.\n";
	print "Please ignore any error messages\n.";

	require HTML::Merge::Engine;
	do "$cgi_bin/merge.conf";
	HTML::Merge::Engine::InitDatabase;
	Clear();
}
foreach (qw(template cache logs merge.conf)) {
	chown $uid, $gid, "$cgi_bin/$_" || die  "Could not change ownership on $cgi_bin/$_ to $user.$group: $!";
}

print "\007You must edit $cgi_bin/merge.conf!!!\n";

print <<EOM;

* READ THIS FIRST * READ THIS FIRST * READ THIS FIRST * READ THIS FIRST *

It is recommended that templates are stored in a directory where they cannot be
retrieved by simple HTTP requests. The simplest way is if the installation
directory is a CGI enabled (or mod perl enabled) directory.
If the script is enabled per directory or per location, it is recommended to
change it in the configuration.

If you installed the internal scripts, you may now access 
http://<server>$url/$script to view and edit your
configuration.
It is essential that you protect the directory $cgi_bin/private to
be password protected. If you linked your instance (and not copied it)
it is better to modify the central configuration, as creating an .htaccess
file will share it between all instances.

* READ THIS FIRST * READ THIS FIRST * READ THIS FIRST * READ THIS FIRST *

EOM

sub scrape {
	unlink "$cgi_bin/private" && return; # Erase symlink if any
	require File::Path;
	File::Path::rmtree("$cgi_bin/private");
}

sub getone {
	my ($msg, $key, $default, $code, $dont) = @_;
	$default = $param{$key} if (exists $param{$key} && defined($key));
	$default = "NONE" unless ($default || $default =~ /0/);
	local ($_);
	for (;;) {
		$_ = $term->readline("$msg [$default]: ");
		exit unless defined $_;
		$_ = $default if ($_ eq "");
		s/^none$//i;
		if ($code) {
			eval '&$code;';
			if ($@) {
				$@ =~ s/at \S+ line.*$//;
				print "\007Error: $@\n";
				next;
			}
		}
		last;
	}
	$param{$key} = $_ if defined($key) && !$dont;
	$_;
}

sub findpath {
	my $prog = shift;
	foreach (@_, split(/[:;]/, $ENV{'PATH'})) {
		my $candidate = "$_/$prog";
		return source($candidate) if (-x $candidate);
	}
	undef;
}

sub source {
	my $file = shift;
	while (my $next = readlink($file)) {
		$file = $next;
	}
	$file;
}
 
ENDOFPERLCODE

use Config;
my $shebang = $Config{'startperl'};
open(O, ">$ARGV[0]") || die $!;
print O "$shebang\n$code";
close(O);
chmod 0755, $ARGV[0];

