package HTML::Merge::Engine;

use HTML::Merge::Error;
use Carp;
use strict;
use vars qw($suffix);

sub AddSuffix {
	$suffix .= shift;
}

sub DumpSuffix {
	my ($template, $line_num) = @$HTML::Merge::context;
	eval '
	        if ($template =~ /\.$HTML::Merge::Ini::DEV_EXTENSION$/) {
			print $suffix;
		}
	';
}

sub new {
	my ($class) = @_;
	my $self = {'dbh' => undef, 'sth' => undef};
	bless $self, $class;
}

sub TIEHASH {
	my ($class) = @_;
	my $this = {'storage' => {}};
	bless $this, $class;
}

sub FETCH {
	my ($self, $key) = @_;
	$key ||= '0';
	my $class = ref($self);
	my $storage = $self->{'storage'};
	if (exists $storage->{$key} && &UNIVERSAL::isa($storage->{$key},
			$class)) {
		return $storage->{$key};
	}
	
	$storage->{$key} = $class->new;
	$storage->{$key}->Preconnect;
	return $storage->{$key};
}				

sub Preconnect {
	my ($self, $dbtype, $db, $dbhost, $user, $password) = @_;
	$dbtype ||= $HTML::Merge::Ini::DB_TYPE;
	$dbhost ||= $HTML::Merge::Ini::DB_HOST;
	$user ||= $HTML::Merge::Ini::DB_USER;
	$password ||= &Convert($HTML::Merge::Ini::DB_PASSWORD2)
			|| $HTML::Merge::Ini::DB_PASSWORD;
	$db ||= $HTML::Merge::Ini::DB_DATABASE;

	$self->{'dsn'} = ['dbi', $dbtype, $db, $dbhost];
	$self->{'cred'} = [$user, $password];
	$self->{'dbh'} = undef;
	$self->{'sth'} = undef;
}

sub DoConnect {
	my $self = shift;
	return if $self->{'dbh'};
	require DBI;
	my $dsn = join(":", @{$self->{'dsn'}});
	my ($user, $password) = @{$self->{'cred'}};
	my $dbh = DBI->connect($dsn, $user, $password, {'AutoCommit' =>
 		$HTML::Merge::Ini::AUTO_COMMIT}) || die $DBI::errstr;
	$self->{'dbh'} = $dbh;
	$self->{'sth'} = undef;
}

sub Statement {
	my ($self, $sql) = @_;
	$self->DoConnect;
	HTML::Merge::Error::HandleError('INFO', $sql, 'SQL');
	$self->{'dbh'}->do($sql) ||
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
}

sub Query {
	my ($self, $sql) = @_;
	$self->DoConnect;
	HTML::Merge::Error::HandleError('INFO', $sql, 'SQL');
	$self->{'sth'} = undef;
	$self->{'fields'} = {};
	my $sth = $self->{'dbh'}->prepare($sql) ||
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
	$sth->execute ||
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
	$self->{'sth'} = $sth;
	$self->{'fields'} = $sth->fetchrow_hashref;
	$self->{'fields'} ||= {};
	$self->{'buffer'} = [$self->{'fields'}];
	$self->{'index'} = 0;
}

sub HasQuery {
	my $self = shift;
	$self->{'sth'} ? 1 : 0;
}

sub Fetch {
	my $self = shift;
	my $sth = $self->{'sth'};
	return HTML::Merge::Error::HandleError('WARN', 'ILLEGAL_FETCH') unless ($sth);
	$self->{'index'}++;
	my $candidate = $self->{'buffer'};
	if ($candidate) {
		$self->{'buffer'} = undef;
		$self->{'fields'} = $candidate->[0];
		return %{$self->{'fields'}} ? 1 : undef;
	}
	my $hash = $sth->fetchrow_hashref;

	unless ($hash) {
		$self->{'index'}--;
#		$self->{'fields'} = {};
		return undef;
	}
	$self->{'fields'} = $hash;
	1;
}

sub Var {
	my ($self, $key) = @_;
	return HTML::Merge::Error::HandleError('WARN', 'ILLEGAL_FETCH') && '' unless ($self->{'fields'});
	return HTML::Merge::Error::HandleError('WARN', 'NO_SQL_MATCH') && '' unless (exists $self->{'fields'}->{$key});
	$self->{'fields'}->{$key};
}

sub Index {
	my $self = shift;
	$self->{'index'};
}

sub GetPersistent
{
	my ($self, $var) = @_;
	my ($sql, $val);
	my $id;
	my $table = $HTML::Merge::Ini::SESSION_TABLE;
	$self->ValidatePersistent;
	$id = $self->{session_id};
	$sql = "SELECT vardata
                FROM $table
                WHERE session_id = '$id'
                AND varname = '$var'";
	($val) = $self->{dbh}->selectrow_array($sql);
	
	return (defined($val)) ? $val : ''; 
}
###############################################################################
sub SetPersistent
{
	my ($self, $var, $val) = @_;
	
	$self->ValidatePersistent;
	$self->SetField($var, $val);
	"";
}
###############################################################################
sub ValidatePersistent
{
	my $self = shift;
	my ($id, $sql);
	my $now = time;
	my $table = $HTML::Merge::Ini::SESSION_TABLE;
	my ($sql, $sth, @other, $other);
	my $expire = YMD(time - 60 * $HTML::Merge::Ini::SESSION_TIMEOUT);
	$self->DoConnect;
	$self->CheckSessionTable;
	$self->GetSessionID;
	$id = $self->{session_id};
	$self->SetField("", YMD(time));
	$sql = "SELECT session_id
                FROM $table
                WHERE varname = ''
                AND vardata < '$expire'";
	$sth = $self->{dbh}->prepare($sql) || 
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
	$sth->execute ||
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
	while (($other) = $sth->fetchrow_array) 
	{
		push(@other, "'$other'");
	}
	return unless @other;
	$sql = "DELETE FROM $table WHERE session_id IN (" .
		join(",", @other) . ")";
	$self->{dbh}->do($sql);
}
###############################################################################
sub CreateSessionTable
{
	my $self = shift;
	my $table = $HTML::Merge::Ini::SESSION_TABLE;
	my $ddl = "CREATE TABLE $table (
			session_id VARCHAR(20) NOT NULL,
			varname VARCHAR(30) NOT NULL,
			vardata VARCHAR(30) NOT NULL
		   )";
	my $db = lc($self->{dsn}->[1]);
	if ($db eq 'mysql') {
		$ddl .= " TYPE=Heap";
	}
	$self->{dbh}->do($ddl) || croak $DBI::errstr;	
	$ddl = "CREATE UNIQUE INDEX ux_var 
                ON $table (session_id, varname)";
	eval { $self->{dbh}->do($ddl); };
}
###############################################################################
sub CheckSessionTable
{
	my $self = shift;
	my $table = $HTML::Merge::Ini::SESSION_TABLE;
	my $sql = "SELECT Count(*) FROM $table";
	my $sth;
	return if ($self->{checked_session_table}++ > 1);
	$@ = undef;
	eval {
		$sth = $self->{dbh}->prepare($sql) || 
			return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
		$sth->execute ||
			return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
	};
	$self->CreateSessionTable if $@;
}
###############################################################################
sub GetSessionID 
{
	my $self = shift;
	my ($cookie, $key, $val);
	my %cookies;
	my $sql;
	return if $self->{session_id};
	my $table = $HTML::Merge::Ini::SESSION_TABLE;

	unless ($HTML::Merge::Ini::SESSION_COOKIE) {
		$self->{session_id} = $ENV{'REMOTE_ADDR'};
		return;
	} 
	$cookie = $ENV{HTTP_COOKIE};
	foreach (split(/;\s*/, $cookie)) {
		($key, $val) = split(/=/, $_);
		$cookies{$key} = $val;
	}
	$self->{session_id} = $cookies{$HTML::Merge::Ini::SESSION_COOKIE};
	unless ($self->{session_id}) {
		$self->{session_id} = substr($ENV{'REMOTE_ADDR'}, -8) . $$ . time % (3600 * 24);
	$self->{session_id} =~ tr/0-9//cd;
		AddSuffix("<META HTTP-EQUIV=\"Set-Cookie\" CONTENT=\"$HTML::Merge::Ini::SESSION_COOKIE=" . $self->{session_id} . "\">\n");
		return;
	}
	my $id = $self->{session_id};
	$sql = "SELECT Count(*) 
		FROM $table
                WHERE session_id = '$id'
                AND varname = ''";
	my ($valid) = $self->{dbh}->selectrow_array($sql);
	&HTML::Merge::Error::TimeOut unless $valid;
}
###############################################################################
sub SetField
{
	my ($self, $key, $val) = @_;
	my ($sql, $count, $sth);
	my $table = $HTML::Merge::Ini::SESSION_TABLE;
	my $id = $self->{session_id};
	
	$sql = "SELECT Count(*)
                FROM $table
                WHERE session_id = '$id'
		AND varname = '$key'";
	($count) = $self->{dbh}->selectrow_array($sql);
	
	if ($count) 
	{
		$sql = "UPDATE $table 
                        SET vardata = ? 
        	        WHERE session_id = '$id'
			AND varname = '$key'";
	} 
	else 
	{
		$sql = "INSERT INTO $table (session_id, varname, vardata)
			VALUES ('$id', '$key', ?)";
	}
	
	$sth = $self->{dbh}->prepare($sql) ||
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
	
	#$val ||= '';
	$val=(defined $val)?$val:''; 
	
	$sth->execute($val) ||
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
}
###############################################################################
sub State
{
	my $self=shift;

	$self->{sth} ? $self->{sth}->state : (
		$self->{'dbh'} ? $self->{'dbh'}->state : '');
}
##############################################################################
sub YMD {
	my @t = localtime(shift());
	sprintf("%04d" . "%02d" x 5, $t[5] + 1900, $t[4] + 1, 
		$t[3], $t[2], $t[1], $t[0]);
}
###############################################################################
sub ReadConfig {
	my $self = $0;
	$self =~ s/\.\w+$/.conf/;
	my @conf = ($self, "/etc/merge.conf", &GetHome . "/.merge");

	foreach my $f (@conf) {
        	if (open(CFG, $f)) {
			no strict;
			my $code = join("", <CFG>);
			close(CFG);
			eval $code;
			if ($@) {
				print "Status: 501 Server error\n";
				print "Content-type: text/plain\n\n";
				print "$f caused error: $@";
				exit;
			}
			$HTML::Merge::config = $f;
        	        last;
	        }
	}
	$self =~ s/\.\w+$/.ext/;
	if (-f $self) {
		package HTML::Merge::Ext;
		eval 'require $self;';
		if ($@) {
			print "Status: 501 Server error\n";
			print "Content-type: text/plain\n\n";
			print "$self caused error: $@";
			exit;
		}
	}
}

sub GetHome {
	return if ($^O =~ /Win/);
	my ($name,$passwd,$uid,$gid,
        $quota,$comment,$gcos,$dir,$shell,$expire) = getpwuid($>);
	$dir;
}

sub import {
	&ReadConfig;
}

sub Convert {
	my ($db_pass, $rev) = @_;

        my $from = pack("C*", map {hex($_)} ($HTML::Merge::Ini::S_FROM =~ /(..)/g));
        my $to = pack("C*", map {hex($_)} ($HTML::Merge::Ini::S_TO =~ /(..)/g));        $from =~ s/-/\\-/;
        $to =~ s/-/\\-/;
	($from, $to) = ($to, $from) if $rev;
        eval "\$db_pass =~ tr/$to/$from/;";
	$db_pass;
}

1;
################################################################################
