use strict;
my $code = <<'ENDOFPERLCODE';
##################################
# Modules ########################

use lib qw(private/perl);
use strict qw(subs vars);
use FileHandle;
use Term::ReadLine;
use Data::Dumper;
use Config;
use Term::InKey;

# My Modules ######################

use HTML::Merge::Engine qw(:unconfig);
use HTML::Merge::App::Repository;

# Def #############################
# auto flush
$| = 1;

# which auto flush is better ?
#STDOUT->autoflush(1);
#STDERR->autoflush(1);

# Main ############################

my %param;
my $term = new Term::ReadLine('');
my @files;
my $unix = 1;
my $win32 =1;
my $is_internal = 0;
my $buf;
my $flag;
my @drivers;
my $i;
my @databases;
my $dbh;
my $local = $ARGV[0] =~ /^-l|--local$/ ? 1 : 0;
my $is_root;
my $merge;
my $private;
my ($conf,$default,$nextdef);
my $cgi_bin;
my $tmp;
my $root;
my @apache = qw(/home/httpd 
		/usr/local/www 
		/var/www 
		/usr/local/httpd
		/usr/local/apache 
		/usr/local/etc/apache 
		/usr/local/etc/httpd
		/usr/local/etc/www);
my $have_data_password;
                                                                                
# require Data password if installed
$@ = undef;
eval{ require Data::Password; };
$have_data_password = 1 unless $@;


foreach (qw(in32 vms os390 os2 dos amiga mac))
{
	$unix = undef if ($^O =~ /$_/);
}

$win32 = undef unless ($^O =~ /in32/);

unless ($unix || $win32)
{
	print "Warning: this script works ONLY on UNIX systems!\n\n";
 	print "Some support for win32 and apache.\n\n";
	print "Press enter:";
	scalar(<STDIN>);
}

print <<EOM;
Raz Information Systems presents:

 M M  EEEEE RRR   GGG  EEEEE
M M M E     R  R G     E
M   M EEE   RRR  G  GG EEE
M   M E     R  R G   G E
M   M EEEEE R  R  GGG  EEEEE

This script will create an instance for HTML::Merge. 
An instance is a definition of HTML::Merge application and URL. 
Please consult the documentation about instances.

Notes: 
* In order to work with HTML::Merge you MUST create at least one instance.
* To force blank input when a default is suggested, type: NONE
* If Term::ReadLine::Gnu is installed, directory paths could be
  easily navigated using the TAB key.

For any information, please refer to http://rmerge.sourceforge.net
or send mail to raz\@raz.co.il

Hit [ENTER] to continue:
EOM

# wait for enter
getc();

$is_root =  IsRoot($>);

# get default paths
$tmp = $local;
$merge = findpath('merge.cgi', $Config{'installscript'});
die "Could not find merge.cgi in PATH" unless (-f $merge);

if($local)
{
	if(!$tmp)
	{
		$buf = "There is no system wide HTML::Merge installation, switching to local mode";
		BoldPrint($buf);
		print "\n";
	}

	if(-d './private' && -d './public') 
	{
		$private = '.';
	}
	else
	{
		die "Could not find merge data in the current directory";
	}
}
else
{
	$private = $merge;
	$private =~ s|/bin/merge.cgi|/share/merge|;
	$private =~ s|\\bin\\merge.cgi|\\share\\merge| if $win32;

	die "Could not find merge data at $private" unless (-d $private);
}

# let's look for a default cgi-bin dir
foreach (@apache) 
{
	if (-d "$_/cgi-bin") 
	{
		$default = "$_/cgi-bin";
		last;
	}
}

$cgi_bin = &getone("Enter your cgi-bin directory, full path", 
		'CGI_BIN', $default, sub 
{
	s/^\s+//;
	s/\s+$//;
	s|/$||;

	die "$_ does not exist" unless (-d $_);
});

while (-f "$cgi_bin/merge.conf") 
{
	require "$cgi_bin/merge.conf";

	last if $@;

	while (my ($var, $val) = each %$HTML::Merge::Ini::FACTORY) 
	{
		$param{$var} = $val;
	}

	open(I, "$private/private/perl/input.frm") || last;
	while (<I>) 
	{
		chop;
		my ($title, $name, $type, $opts, $default) = split(/\|/);
		if ($default =~ s/\@(.*?)\@/\0/) 
		{
			my $item = $1;
			my $re = quotemeta($default);
			$re =~ s/\\\0/(.*)/;
			my $val = ${"HTML::Merge::Ini::$name"};
			if ($val =~ /^$re$/) 
			{
				$param{$item} = $1;
			}
		}
	}
	close(I);

	$param{'__DB_PASS'}=HTML::Merge::Engine::Convert($param{'DB_PASSWORD'});

	last;
}

print "\n";

$default = $cgi_bin;
$default =~ s|^.*[/\\]|/|;

my $url = getone("Enter the web url (without http://server)
for that cgi-bin directory", 
		'URL', 
		$default, 
		sub {
	 		s|/$||;
			$_ ||= $default;
			s|^http://[^/]+||;
		});

if($is_root)
{
	($conf,$default,$nextdef) = @{ EditHttpdConf()};
}
else
{
	$default = 'nobody';
}

my @data;

my $user;
my $uid;
my $gid = 100;
my $group = 'nobody';

if ($win32) 
{
	$user = $default;
	$uid = 100;
}
else 
{
  	$user = &getone("Enter the user id for your web server" , 
			'WWW_U', 
			$default,
			sub {
				@data = getpwnam($_);
				die "No user $_" unless (@data);
			});

	$uid = $data[2];
	print "\n";
}

$default = $nextdef;

unless ($default) 
{
	$default = $user;
	@data = getgrnam($default)  unless $win32;;
	$default = '' unless (@data);
}

$default ||= 'nobody';

$group = &getone("Enter the group id for your web server",
		'WWW_G', 
		$default, 
		sub {
			@data = getgrnam($_);
			die "No group $_" unless (@data);
		}) unless $win32;

$gid = $data[2] unless $win32;

print "\n";

($param{'SUFFIX'}) = (split(/\./, $param{'SCRIPT'}))[-1];

print "\n";

my $ext = getone("Enter suffix to use for CGI script", undef, 'pl');

delete $param{'SUFFIX'};

my $script = $ext ? "merge.$ext" : 'merge';
$param{'SCRIPT'} = $script;

foreach (qw(template cache logs)) 
{
	mkdir "$cgi_bin/$_", 0755;
	chown $uid, $gid, "$cgi_bin/$_";
}

my ($choice, $def, $cd, $c2);

if (-f "$cgi_bin/$script") 
{
	$def = "/.No change.";
	$c2 = "\n\r";
}

if ($win32 || $local) 
{
	$cd = 'C';
}
else 
{
	print "

Symbolic <L>inks are recommended , but will work only 
on UNIX systems and Apache servers that have the FollowSymLinks 
directive applied. 
If they are not appliacble, choose <C>opy.
If you choose <N>one or <C>opy, $cgi_bin/$script
will be created as a copy of $merge 
if you choose Link it will be a symbolic link.
Do you wish to <C>opy HTML::Merge files into $cgi_bin 
or create a symbolic <L>ink? \n";
print "\n[C/L/None$def]: ";

	$choice = nChoice("CLN", $cd);
}

$choice = $cd if $win32 || $local;


if ($choice eq 'C') 
{
	print "Copy\n";
	&scrape($cgi_bin);

	require ExtUtils::Install;
	require File::Copy;

	ExtUtils::Install::install({"$private/private" => "$cgi_bin/private"}, 1, 0);
	ExtUtils::Install::install({"$private/public" => "$cgi_bin/public"}, 1, 0);
	unlink "$cgi_bin/$script";
	File::Copy::copy($merge, "$cgi_bin/$script");
	chmod 0755, "$cgi_bin/$script";
	chown $uid, $gid, "$cgi_bin/$script";
} 
elsif ($choice eq 'L') 
{
	print "Link\n";
	&scrape($cgi_bin);

	symlink	"$private/private", "$cgi_bin/private" ||
		die "Could not link $private/private to $cgi_bin/private: $!";
	chmod 0755, "$cgi_bin/private";
	chown $uid, $gid, "$cgi_bin/private";

	symlink	"$private/public", "$cgi_bin/public" ||
		die "Could not link $private/public to $cgi_bin/public: $!";
	chmod 0755, "$cgi_bin/public";
	chown $uid, $gid, "$cgi_bin/public";

	unlink "$cgi_bin/$script";
	symlink $merge, "$cgi_bin/$script" || 
		die "Could not link $merge to $cgi_bin/$script: $!";
	chmod 0755, "$cgi_bin/$script";
	chown $uid, $gid, "$cgi_bin/$script";
} 
elsif ($choice eq 'N') 
{
	print "None\n";
	unless (-x "$cgi_bin/$script") 
	{
		require File::Copy;
		File::Copy::copy($merge, "$cgi_bin/$script");
		chmod 0755, "$cgi_bin/$script";
	}
} 
elsif ($choice ne "\r") 
{
	die "Unknown choice $choice";
}

if ($win32) 
{
	$choice = 'N';
}
else 
{
  print "\n\nWould you like to install the samples? [.Y./N]: ";
  $choice = nChoice("YN\3", 'Y');
  exit if $choice eq "\3";
}

$param{'DEFAULT'} = '';

if ($choice eq 'Y') 
{
	print "Yes\n";
	require File::Copy;

	system('perl createsamples.pl') if($local);
		
	foreach (glob("$private/docs/samples/*.html")) 
	{
		my $dest = $_;
		$dest =~ s|^$private/docs/samples|$cgi_bin/template|;
		File::Copy::copy($_, $dest);
	}

	$param{'DEFAULT'} = 'samples.html';
} 
else 
{
	print "No\n";
}

eval {
	require DBI;

	for (;;) 
	{
		@drivers = DBI->available_drivers;
		$i = 0;

		print "
Note: Please choose a database driver for your instance
From the available DBI drivers or type NONE 
if you don't want to configure a database at the moment:\n";

		foreach (@drivers) 
		{
			print ++$i, ") $_\n";
		}
	
		my $drv = &getone("Choose DBI driver",
			'DRIVER', undef, undef, 1);
		if ($drv =~ /^\d+$/) 
		{
			$drv = $drivers[$drv - 1];
		}
		last unless ($drv);

   		last if (uc($drv) eq 'NONE');

		print "$drv chosen.\n\n";

		eval { @databases = DBI->data_sources($drv); 
			foreach(@databases) 
			{
				s/^.*?:.*?://;
			}
		};

		$i = 0;

		if (@databases) 
		{
			foreach (@databases) 
			{
				print ++$i, ") $_\n";
			}
		}

		my $default = $drv eq $param{'DRIVER'} ? $param{'DB'} : '';
		my $db = getone("Choose application database:",undef, $default);

		if ($db =~ /^\d+$/) 
		{
			$db = $databases[$db - 1];
		}

		print "DSN is dbi:$drv:$db\n\n";

		print "Note: on some databases username and password could be
left blank. Type NONE to override the default by an empty string.\n\n";
	
		my $duser = getone("Username to connect to database", 
			'DB_USER', $user, undef, 1);

		$default = $param{'__DB_PASS'};
		$default =~ s/./*/g;
  	my $dpass;
		if ($win32) 
		{
			$dpass = getone("Password for username '$duser'",'__DB_PASS', $duser, undef, 1);
		}
		else 
		{
			print "Password for username '$duser' [$default]: ";
			$dpass = &ReadPassword;
		}
   
		exit unless defined $dpass;
		$dpass ||= $param{'__DB_PASS'};
		$dpass =~ s/^none$//i;

		print "\n\nTrying...";

		$@ = undef;
		eval { $dbh = DBI->connect("dbi:$drv:$db", $duser, $dpass) 
			|| die $DBI::errstr;};

		if ($@) 
		{
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
		if (@databases) 
		{
			foreach (@databases) 
			{
				print ++$i, ") $_\n";
			}
		}

		$@ = undef;

		eval {
        		require DBD::SQLite;
		};

		print "
Note: Choose an existing database or type the name of a new one\n";

		if($@)
		{
			print "
Note: as you don't have DBD::SQLite if you choose NONE you will not be able
to use HTML::Merge's security and session features.\n\n"; 
		}
		else
		{
			print "
Note: if you want HTML::Merge to handle security and session features internally
choose NONE and HTML::Merge will use DBD::SQLite for system database\n\n";
		}

		my $mergedb = getone("Choose system database",
			'MERGE_DB', 'merge');

		if ($mergedb) 
		{
			&Clear;

			if ($mergedb =~ /^\d+$/) 
			{
				$mergedb = $databases[$mergedb - 1];
				$param{'MERGE_DB'} = $mergedb;
			}

			eval { $dbh->do("CREATE DATABASE $mergedb") };
		}
		else
	  	{
			my $internal_dbh;
                	eval { $internal_dbh = DBI->connect("dbi:SQLite:dbname=$cgi_bin/merge.db","","") 
				|| die $DBI::errstr;};
	 
                	if ($@)
                	{
                        	print "\nError: $DBI::errstr\n";
                        	next;
                	}

			$internal_dbh->disconnect();

			$is_internal=1;
		}	

		$dbh->disconnect();
		last;
	}
};

@param{qw(DB_USER DB_PASS DRIVER DB MERGE_DB)} = () unless $flag;

my $savep = $param{'ROOT_PASSWORD'};
my $nextp = '';

for (;;) 
{
	my $p;
	my $save = $param{'ROOT_USER'};
	my $ru = getone("Enter Merge instance root user",'ROOT_USER','admin');
	my ($default, $s_default);

	print "
Note: You must define an instance superuser user this user has unlimeted access
to the instance applications and develpment toolbox\n"; 

	if (exists $param{'ROOT_PASSWORD'} && $save eq $ru) 
	{
		$s_default = '<no change>';
	} 
	else 
	{
		$s_default = $default = $ru;
	}

	if ($win32) 
	{
		$p = getone("Enter superuser password [$s_default]: ",
			'ROOT_PASSWORD',
		 	$ru);
	}
	else 
	{
		print "Enter superuser password [$s_default]: ";
		$p = &ReadPassword;
	}	
	exit unless defined $p;

	if ($p && $p !~ /^none$/i && ! $win32 && $have_data_password)
	{
		my $reason = Data::Password::IsBadPassword($p);
		if ($reason) 
		{
			print "Bad password: It $reason\7\n";
			next;
		}

		print "Reenter root password: ";
		my $pp = &ReadPassword;
		exit unless defined $pp;
		if ($p ne $pp) 
		{
			print "Not identical!\7\n";
			next;
		}
	}

        $p ||= $default;
	$p =~ s/^none$//i;

	unless ($p) 
	{
		$nextp = $param{'ROOT_PASSWORD'} = '';
		last;
	}
 
 	if ($win32) 
	{
 		$param{'ROOT_PASSWORD'} = $p;
 		$nextp = $p;
  	}
	else 
	{
		$param{'ROOT_PASSWORD'} = crypt($p, pack("CC", rand(26) + 65,
				rand(26) + 65));
		$nextp = crypt($p, pack("CC", rand(26) + 65,
				rand(26) + 65));
 	}
	last;
}

print "\n\nYou must configure your webserver to alias $url 
as $cgi_bin and run .pl files over there 
as CGI scripts\n";

if ($conf & $is_root)
{
	my $temp = "merge-httpd.$$";
        $temp = "/tmp/$$-merge-httpd" if $unix;
	open(I, $conf) || die "Cannot open $conf: $!";
	open(O, ">$temp") || die "Cannot open $temp: $!";
	my $need = 1;
	my $flag = undef;

	while (<I>) 
	{
		if (/^\s*(Script)?Alias\s+$url\/?\s/i) 
		{
			$need = undef;
		}

		$flag = 1 if (/^#\s*BEGIN MERGE $cgi_bin\b/);
		print O unless $flag;
		$flag = undef if (/^#\s*END MERGE $cgi_bin\b/);
	}

	print O "# BEGIN MERGE $cgi_bin\n";

	if ($need) 
	{
		print O "ScriptAlias $url/ $cgi_bin/\n";
	}

	my $pwd = "$cgi_bin/.htmerge";
	print O <<EOM;

# this is a simple cgi directory definition. 
# uncomment this if you haven't defined a Merge instance directory.
# ScriptAlias $url/ "$cgi_bin/"
# <Directory "$cgi_bin">
#        AllowOverride None
#        Options +ExecCGI
#        Order allow,deny      
#        Allow from all
# </Directory>

<Location $url/.htmerge>
    Order deny,allow
    Deny from all
</Location>
<Directory $cgi_bin/public>
        SetHandler default-handler
</Directory>
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

	if ($savep ne $param{'ROOT_PASSWORD'}) 
	{
		open(O, ">>$pwd") || die "Cannot open $pwd: $!";
		close(O);
		my @save;

		open(I, "$pwd") || die "Cannot open $pwd: $!";
		while (<I>) 
		{
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

while ($set) 
{
	my $r = int(rand(length($set)));
	$param{'S_TO'} .= substr($set, $r, 1);
	substr($set, $r, 1) = '';
}

foreach (qw(S_FROM S_TO)) 
{
	$param{$_} = join("", map {sprintf("%02X", $_);} unpack("C*", $param{$_}));
	${"HTML::Merge::Ini::$_"} = $param{$_};
}

my @params;
foreach(@lines) 
{
	chomp;
	unless (/;\s*#/) 
	{
		push(@params, undef);
	} 
	else 
	{
		my $pos = length($_) - length($') - 1;
		my $extra = substr($_, $pos);
		substr($_, $pos) = "";
		push(@params, [$pos, $extra]);
	}
	s/\s+$//;
}

my $cfg = join("\n", @lines);

$param{'DB_PASSWORD'} = HTML::Merge::Engine::Convert($param{'__DB_PASS'}, 1);
delete $param{'__DB_PASS'};
$param{'SCRIPT'} = $script;

while (my ($var, $val) = each %param) 
{
	$cfg =~ s/\@$var\@/$val/gi;
}

@lines = split(/\n/, $cfg);

my $i = 0;
foreach (@lines) 
{
	s/\s+$//;
	my $this = $params[$i];

	if ($this) 
	{
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

do "$cgi_bin/merge.conf";
require HTML::Merge::Engine;

# *** Clear();

if($param{'DB'}) 
{
	print "Your $param{'MERGE_DB'} database will be created now.\n";
	print "Please ignore any error messages.\n";
	HTML::Merge::Engine::InitDatabase();
	HTML::Merge::App::Repository::InitDatabase();
  	print "\n\n\n\n\n\n\n\n\n";
}

@files = qw(template cache logs merge.conf);

push(@files,'merge.db') if $is_internal;

foreach (@files) 
{
	chown $uid, $gid, "$cgi_bin/$_" || die  "Could not change ownership on $cgi_bin/$_ to $user.$group: $!";
}

print "\007You must edit $cgi_bin/merge.conf!!!\n";

print <<EOM;

* READ THIS FIRST * READ THIS FIRST * READ THIS FIRST * READ THIS FIRST *

*** You must edit $cgi_bin/merge.conf !!! ***
It is recommended that templates are stored in a directory where they cannot be
retrieved by simple HTTP requests. The simplest way is if the installation
directory is a CGI enabled (or mod perl enabled) directory.
If the script is enabled per directory or per location, it is recommended to
change it in the configuration.

If you installed the development environment, you may now access 
http://<server>$url/$script to view and edit your
configuration.
It is essential that you protect the directory $cgi_bin/private to
be password protected. If you linked your instance (and not copied it)
it is better to modify the central configuration, as creating an .htaccess
file will share it between all instances.

If you let HTML::Merge edit your httpd.conf you will find a commented sample 
of your bin directory configuration. Uncomment it if you havn't configured it
yet. 

* READ THIS FIRST * READ THIS FIRST * READ THIS FIRST * READ THIS FIRST *

EOM

suggest_edit($conf) if $conf && $is_root;
suggest_edit("$cgi_bin/merge.conf");

print "\n*** Configuration ended ***\n";

# Functions ##################################
sub scrape 
{
	my ($path) = @_;

	require File::Path;

	# unlink any old installation
	File::Path::rmtree(["$path/private","$path/public"]);
}
#############################################
sub getone 
{
	my ($msg, $key, $default, $code, $dont) = @_;
	$default = $param{$key} if (exists $param{$key} && defined($key));
	$default = "NONE" unless ($default || $default =~ /0/);
	local ($_);

	for (;;) 
	{
		$_ = $term->readline("$msg [$default]: ");
		exit unless defined $_;
		$_ = $default if ($_ eq "");
		s/^none$//i;
		if ($code) 
		{
			eval '&$code;';
			if ($@) 
			{
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
#############################################
sub findpath
{
	my ($prog) = @_;

	my $candidate;

	foreach (split(/[:;]/, $ENV{'PATH'}))
	{
		if($win32) 
		{
			$candidate = "$_\\$prog";
		}
		else
		{
			$candidate = "$_/$prog";
		}

		return source($candidate) if (-f $candidate);
	}

	# last check local
	$candidate = "./$prog";

	if(-f $candidate)
	{
		$local = 1;
		return source($candidate);
	}

	return undef;
}
#############################################
sub source 
{
	my ($file) = @_;

	while (my $next = readlink($file)) 
	{
		$file = $next;
	}

	return $file;
}
#############################################
sub suggest_edit 
{
	my $file = shift;
	my $editor = $ENV{'EDITOR'} || 'vi';
	$editor = findpath($editor) unless -x $editor;
	return unless -x $editor;
	print "Would you like to edit $file? (Y/N): [N] ";
	my $ch = nChoice("YN\3", 'N');
	exit if $ch eq "\3";

	if ($ch eq 'N') 
	{
		print "No\n";
		return;
	}
	print "Yes\n";
	system "$editor", $file;
}
#############################################
sub nChoice ($;$$)
{
	my $sOptions = uc(shift);
	my $sDefault = uc(shift);
	my $iLength = shift;

	my $sResult= "";

	$sOptions = ':' . join(':',split(/ */,$sOptions)).':' unless ($sOptions =~ /\:/);

  	$iLength = 1 unless $iLength;

    	while(1)
     	{
     		read (STDIN, $sResult, $iLength);
     		$sResult = uc($sResult);

		if ($sResult eq "\n" && $sDefault) 
		{
     			$sResult = $sDefault;
			last; 
                }
     		if ($sOptions =~ /\:${sResult}\:/) 
		{
                	last; 
		}
	 	else 
		{
                   	print "\r\a";

                   	while ($sResult ne "\n") 
			{
                   		print ' ' x length ($sResult);
                        	read (STDIN, $sResult, 1);
                        }

                   	print "\r";
                   	next;
          	} # else

     	}

 	return ($sResult);
}
#############################################
sub BoldPrint
{
	my ($buf) =@_;

	print '*' x length($buf),"\n";
	print "$buf\n";
	print '*' x length($buf),"\n";
}
#############################################
# check for the euid of the proccess
# exit on root fix in the futere
sub IsRoot
{
	my ($euid) = @_; 

	my $buf;

	if ($euid)
	{
		# you are not root
		$buf = "you are not running as root, some configuration options will be available !!!";
		BoldPrint($buf);

		return 0;
	}

	return 1;
}
#############################################
sub EditHttpdConf
{
	my $root = `httpd -V | grep HTTPD_ROOT` unless $win32;
	my $default;

	if ($win32) 
	{
		open (HTTPD,'apache -V |');

		while (<HTTPD>) 
		{
			$root = $_ if /HTTPD\_ROOT/;
                        $default = $_ if /SERVER_CONFIG_FILE/;
		}

		close (HTTPD);
	}

	$root =~ s/^\s*-D\s+HTTPD_ROOT=\"(.*)\"\s*$/$1/;

	$default = `httpd -V | grep SERVER_CONFIG_FILE` unless $win32;
	$default =~ s/^\s*-D\s+SERVER_CONFIG_FILE=\"(.*)\"\s*$/$1/;
	$default = "$root/$default" if (-f "$root/$default");

	unless ($default && -e $default) 
	{
		foreach (@apache) 
		{
			if (-f "$_/conf/httpd.conf") 
			{
				$default = "$_/conf/httpd.conf";
			}
		}
	}

	print "\n";

	print "Note: enter NONE if you do not wish to modify your httpd.conf!\n\n";

	my $conf = getone("Enter the location of your httpd.conf", 
			'HTTP_CONFIG',
			$default, 
			sub { die "$_ not found" if $_ && ! -f; });

	$default = 'nobody';

	foreach (qw(apache www httpd)) 
	{
		my @data = getpwnam($_)  unless $win32;;
		if (@data) 
		{
			$default = $_;
			last;
		}
	}	

	print "\n";

	my $nextdef;
	if ($conf) 
	{
		open(I, $conf) || die "Cannot open $conf: $!";
		while (<I>) 
		{
			if (/^\s*User\s+(.*?)\s*((?:#.*)?)$/) 
			{
				$default = $1;
			}
			if (/^\s*Group\s+(.*?)\s*((?:#.*)?)$/) 
			{
				$nextdef = $1;
			}
		}
		close(I);
	}

	return [$conf ,$default, $nextdef];
}
#############################################
ENDOFPERLCODE

use Config;
my $shebang = $Config{'startperl'};
$ARGV[0] = "mergecreateinstance" unless $ARGV[0];
open(O, ">$ARGV[0]") || die $!;
print O "$shebang\n$code";
close(O);
chmod 0755, $ARGV[0];

# END #######################################
