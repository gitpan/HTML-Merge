package HTML::Merge::Compile;

use strict;
use vars qw($open %enders %printers %tokenizers $VERSION);
use Carp;
use Config;

$VERSION = 3.05;

BEGIN {
	eval 'use HTML::Merge::Ext;';
}

$open = '\$R';
#my @non_flow = qw(VAR SQL SET PSET PGET PIC STATE INDEX CFG);
#@non_flow{@non_flow} = @non_flow;
my @printers = qw(VAR SQL GET PGET INDEX PIC STATE CFG);
@printers{@printers} = @printers;
#my @stringers = qw(IF SET PSET SETCFG);
#@stringers{@stringers} = @stringers;
my @tokenizers = qw(COUNT);
@tokenizers{@tokenizers} = @tokenizers;

%enders = qw(END_IF IF END LOOP END_WHILE WHILE);


use subs qw(quotemeta);

sub WantPrinter {
	my ($self, $tag) = @_;
	my $ret = $self->WantTag($tag);
	return $ret if ($printers{$tag});
	$self->Die("$tag is not an output tag, perhaps you forgot to close a string? Output tags are " . join(", ", keys %printers));
}

sub WantTag {
	my ($self, $tag, $inv) = @_;
	my $candidate = $enders{$tag};
	if ($candidate && !$inv) {
		$tag = $candidate;
		$inv = 1;
	}
	my $un = $inv ? "Un" : "";
	my $code = UNIVERSAL::can($self, "Do$un$tag");
	return $code if $code;
	my @options = !$inv ? qw(API OAPI OUT) : qw(CAPI);
	foreach my $api (@options) {
		my $candidate = "${api}_$tag";
		$code = UNIVERSAL::can('HTML::Merge::Ext', $candidate);
		if ($code) {
			my $ref = ref($self);
			my $proto = prototype("HTML::Merge::Ext::$candidate");
			$proto =~ s/;.*$//;
			$self->Die("Prototype for $candidate may include only \$ signs")
				unless ($proto =~ /^\$*$/);
			my $n = length($proto);
			my $shift = join(", ",
				map {"\$param->[$_]";} (0 .. $n - 1));
			my $stack;
			if ($api eq 'OAPI') {
				$stack = qq!\$self->Push('api_$tag', \$engine);!;
			}
			if ($api eq 'CAPI') {
				$stack = qq!\$self->Expect(\$engine, 'api_$tag');!
			}
			my $extend = <<EOM;
package $ref;
sub Do$un$tag {
	my (\$self, \$engine, \$param) = \@_;
	my \$n = \@\$param;
	\$self->Die("$n parameters expected for $tag, gotten \$n") unless (\$n == $n);
	$stack
	\$HTML::Merge::Ext::ENGINE = \$engine;
	HTML::Merge::Ext::$candidate($shift);
}
EOM
			eval $extend;
			die $@ if $@;
			$printers{$tag} = ($api eq 'OUT');
			$tokenizers{$tag} = 1;
			return $self->WantTag($tag, $inv);
		}
	}
	$self->Die("$tag is not a valid Merge tag");
}

sub quotemeta {
	my $text = CORE::quotemeta(shift);
	$text =~ s/\\ / /g;
	$text =~ s/\\\t/\t/g;
	$text;
}

sub Compile {
	my $self = {'buffer' => '', 'scopes' => []};
	bless $self;
	$self->{'save'} = $self->{'source'} = shift;
	$self->{'name'} = shift;
	$self->Main;
	$self->{'buffer'};
}

sub Die {
	my ($self, $error) = @_;
	my $lines = scalar(split(/\n/, $self->{'save'}));
	my $left = substr($self->{'save'}, -length($self->{'source'}));
	my $ll = scalar(split(/\n/, $left));
	my $this = $lines - $ll + 1;
	my $s = (split(/\n/, $self->{'save'}))[$this - 1];
	my $name = $self->{'name'};
	if ($error < 0) {
		return unless $name;
		$self->{'buffer'} .= "\$HTML::Merge::context = [\"$name\", \"$this\"];\n";
		$self->{'buffer'} .= "#line $this $name\n";
		return;
	}

	$name =~ s|^.*/||;		
	die "Error: $error at $name line $this"
#	confess "Error: $error at $name line $this"
}

sub Main {
	my $self = shift;
	$self->{'source'} =~ s/<(BODY)/<META NAME="GENERATOR" CONTENT="Merge v. $VERSION (c) Raz Information systems www.raz.co.il">\n<$1/i;
	while ($self->{'source'} =~ s/^(.*?)\<(\/?)$open(\[\w+?\]\.)?([A-Z_]+)//si) {
		my ($head, $close, $engine, $tag, $param) = ($1, $2, $3, uc($4));
		$engine =~ s/^\[(.*)\]\./$1/;
		$self->Print($head);
		my $code = $self->WantTag($tag, $close);
		$param = $self->EatParam($tokenizers{$tag});
		$self->Die("Closing tags may not have parameters") if (($close || $enders{$tag}) && ($param && !ref($param) || ref($param) && $#$param >= 0));
		$self->Die(-1);
		if ($printers{$tag}) {
			$self->{'buffer'} .= "print (";
		}
		$self->{'buffer'} .= &$code($self, $engine, $param);
		if ($printers{$tag}) {
			$self->{'buffer'} .= ");\n";
		}
	}
	$self->Print($self->{'source'});
	$self->{'source'} = '';
	if (@{$self->{'scopes'}}) {
		my @scopes = map {join("/", @$_);} @{$self->{'scopes'}};
		my $stack = join(", ", @scopes);
		$self->Die("Stack not empty: $stack");
	}
}

sub Print {
	my ($self, $string) = @_;
	my @lines = split(/\n/, $string);
	my $last = pop @lines;
	foreach (@lines) {
		$self->{'buffer'} .= 'print "' . quotemeta($_) . '\n";' . "\n";
	}
	$self->{'buffer'} .= 'print "' . quotemeta($last) . '";' . "\n";
	$self->{'buffer'} .= 'print "\n";' . "\n" if ($string =~ /\n$/);
}

sub EatParam {
	my ($self, $tokens) = @_;
	my $state = '';
	my $text = '';
	my @tokens;
	for (;;) {
		my $ch;
		if ($self->{'source'} =~ s/^(.)//s) {
			$ch = $1;
		} else {
			$self->Die("Could not close tag");
		}
		if ($ch eq "'" && $state ne '"') {
			$text .= "\\'";
			$state = ($state eq "'" ? '' : "'");
			next;
		}
		if ($ch eq '"' && $state ne "'") {
			$text .= "\\\"";
			$state = ($state eq '"' ? '' : '"'); #'"
			next;
		}
		if ($ch eq "\\") {
			$self->{'source'} =~ s/^(.)//s;
			$ch = $1;
			$text .= "\\$ch";
			next;
		}
		if ($ch eq '>' && !$state) {
			return qq!$text! unless $tokens;	
			return [] unless @tokens;
			my $pre = shift @tokens;
			$self->Die("Illegal prefix $pre") if $pre;
			push(@tokens, $text);
			return \@tokens;
		}
		if ($ch eq '.' && !$state && $tokens) {
			push(@tokens, $text);
			$text = '';
			next;
		}
		if ($ch eq "<") {
			unless ($self->{'source'} =~ s/^$open//) {
				$text .= "<"; 
				next;
			}
			$self->{'source'} =~ s/(\[\w+?\]\.)?([A-Z_]+)//;
			my $engine = $1;
			my $tag = uc($2);
			$engine =~ s/^\[(.*)\]\./$1/;
			my $code = $self->WantPrinter($tag);
			my $sub = $self->EatParam($tokenizers{$tag});
			$text .= '" . ' . &$code($self, $engine, $sub) . ' . "';	
		} else {
			$text .= quotemeta($ch);
		}
	}
}

sub Expect {
	my ($self, $engine, @options) = @_;
	my $current = pop @{$self->{'scopes'}};
	$self->Die("Stack underflow") unless ($current);
	my ($scope, $teng) = @$current;
	$self->Die("Expected engine '$engine', got '$teng'") unless ($teng eq $engine);
	foreach (@options) {
		return if ($_ eq $scope);
	}
	$self->Die("Unexpected scope $scope, expecting: " . join(", ", @options));
}

sub Push {
	my ($self, $scope, $engine) = @_;
	push(@{$self->{'scopes'}}, [$scope, $engine]);
}

sub DoLOOP {
	my ($self, $engine, $param) = @_;
	my $limit = undef;
	if ($param =~ /^\\\.LIMIT\\=(['"]?)(.*)\1$/s) { #'
		$limit = $2;
	}
	my $text;
	unless ($limit) {
		$text = <<EOM;
for (;;) {
EOM
	} else {
		$text = <<EOM;
foreach (1 .. "$limit") {
EOM
	}
	$text .= <<EOM;
	last unless (\$engines{"$engine"}->HasQuery);
	last unless (\$engines{"$engine"}->Fetch);
EOM
	$self->Push('loop', $engine);
	$text;
}

*DoEPEAT = \&DoITERATION;
*DoUnEPEAT = \&DoUnITERATION;

sub DoITERATION {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.LIMIT\\=(['"]?)(.*)\1$/s) { #'
		$self->Syntax;
	}
	my $limit = $2;
	$self->Push('iteration', $engine);
<<EOM;
foreach (1 .. "$limit") {
EOM
}

sub DoUnITERATION {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'iteration');
	"}\n";
}

sub DoBREAK {
	my ($self, $engine, $param) = @_;
	$self->Syntax if ($param);
	"last;";
}

sub DoCONT {
	my ($self, $engine, $param) = @_;
	$self->Syntax if ($param);
	"next;";
}


sub DoUnLOOP {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'loop');
	"}\n";
}

sub DoFETCH {
	my ($self, $engine, $param) = @_;
	$self->Syntax if ($param);
	"\$engines{\"$engine\"}->Fetch;";
}

sub DoCFG {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.*)$//s) {
		$self->Syntax;
	}
	"\${\"HTML::Merge::Ini::\"  . \"$1\"}";
}

*DoINIGET = *DoINI = *DoCFGGET = \&DoCFG;
*DoINISET = \&DoCFGSET;

sub DoCFGSET {
        my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.*?)\\=\\(['"])(.*?)\\\2$//) {
		$self->Syntax;
	}
	"\${\"HTML::Merge::Ini::\"  . \"$1\"} = eval(\"$3\");\n";
}


sub DoVAR {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.*)$//s) {
		$self->Syntax;
	}
	return "\$vars{\"$1\"}";
}

sub DoSQL {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.*)$//s) {
		$self->Syntax;
	}
	"\$engines{\"$engine\"}->Var(\"$1\")";
}

sub DoIF {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\[\.=]\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	my $cond = quotemeta($2);
	my $text = <<EOM;
HTML::Merge::Error::HandleError('INFO', "$2", 'IF');
my \$__test = eval("$2");
HTML::Merge::Error::HandleError('ERROR', \$@) if (\$@);
if (\$__test) {
EOM
	$self->Push('if', $engine);
	$text;
}

sub DoUnIF {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'if', 'else');
	"}\n";
}

sub DoELSE {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	$self->Expect($engine, 'if');
	$self->Push('else', $engine);
	"} else {\n";
}

sub DoWHILE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\[\.=]\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	my $cond = quotemeta($2);
	my $text = <<EOM;
HTML::Merge::Error::HandleError('INFO', "$2", 'WHILE');
for (;;) {
	my \$__test = eval("$2");
	HTML::Merge::Error::HandleError('ERROR', \$@) if (\$@);
	last unless \$__test;
EOM
	$self->Push('while', $engine);
	$text;
}

sub DoUnWHILE {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'while');
	"}\n";
}

sub DoQ {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\[=\.]\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	"\$engines{\"$engine\"}->Query(\"$2\");\n";
}

sub DoS {
        my ($self, $engine, $param) = @_;
        unless ($param =~ s/^\\[\.=]\\(['"])(.*)\\\1$//s) {
                $self->Syntax;
        }
        "\$engines{\"$engine\"}->Statement(\"$2\");\n";
}

sub DoPERL {
        my ($self, $engine, $param) = @_;
	my $type;
	if ($param =~ s/^\\\.([ABC])$//i) {
		$type = uc($1);
	}
	$self->Syntax if $param;
	my $code = "";
	if (!$type || $type eq 'B' || $type eq 'C') {
		my $flag;
		while ($self->{'source'} =~ s/^(.*?)\<($open(?:\[\w+\])?[A-Z_]+|\/${open}PERL\>)//is) {
			my $let = quotemeta($1);
			$code .= qq!"$let" . !;
			my $tag = $2;
			if ($tag =~ m|^/${open}PERL>$|) {
				$flag = 1;
				last;
			}
			$tag =~ s/^$open//;
			my $engine = '';
			if ($tag =~ s/^\[(\w+?)\]\.//) {
				$engine = $1;
			}
			my $coder = $self->WantPrinter($tag);
			my $param = $self->EatParam($tokenizers{$tag});
			my $codet = &$coder($self, $engine, $param);
			$code .= "$codet . ";
		}
		$self->Die("End of PERL not found") unless $flag;
		$code .= q!""!;
	} else {
		unless ($self->{'source'} =~ s/^(.*?)\<\/${open}PERL\>//is) {
			$self->Die("End of PERL not found");
		}
		$code = '"' . quotemeta($1) . '"';
	}
	my $name = $self->{'name'};
	my $text = <<EOM;
\$__result = $code;
HTML::Merge::Error::HandleError('INFO', \$__result, 'PERL');
\$__result = eval(\$__result);
HTML::Merge::Error::HandleError('ERROR', \$@) if \$@;
EOM
	if ($type eq 'A' || $type eq 'C') {
		$text .= <<EOM;
use HTML::Merge::Compile;
\$__result = &HTML::Merge::Compile::Compile(\$__result, "$name");
HTML::Merge::Error::HandleError('ERROR', \$@) if \$@;
\$__result = eval(\$__result);
HTML::Merge::Error::HandleError('ERROR', \$@) if \$@;
EOM
	}
	$text;
}

sub DoSET {
        my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.*?)\\=\\(['"])(.*?)\\\2$//) {
		$self->Syntax;
	}
	"\$vars{\"$1\"} = eval(\"$3\");\n";
}

sub DoPSET {
        my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.*?)\\=\\(['"])(.*?)\\\2$//) {
		$self->Syntax;
	}
	"\$engines{\"$engine\"}->SetPersistent(\"$1\", eval(\"$3\"));\n";
}

sub DoPGET {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.(.*)$//s) {
		$self->Syntax;
	}
	return "\$engines{\"$engine\"}->GetPersistent(\"$1\")";
}

*DoPVAR = \&DoPGET;
*DoGET = \&DoVAR;

*DoREM =&DoEM;
sub DoEM {}

sub DoTRACE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	my $line = $2;
	<<EOM;
HTML::Merge::Error::HandleError('INFO', "$line", 'TRACE');
EOM
}

sub DoINCLUDE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	my $inc = $2;
	$inc =~ s/\\(.)/$1/g;

#	require Cwd;
#	my $curr = &Cwd::cwd;
#	my @tokens = split(/\//, $self->{'name'});
#	pop @tokens;
#	my $dir = join("/", @tokens);
#	chdir $dir if $dir;
#	open(I, $inc) || $self->Die("Can't open $inc at $dir");
#	my $text = join("", <I>);
#	close(I);
#	chdir $curr;
#	$self->{'source'} = $text . $self->{'source'};
	my $name = $self->{'name'};
	my $text = <<EOM;
	my \$__input = "\$HTML::Merge::Ini::TEMPLATE_PATH/$inc";
	my \$__script = "\$HTML::Merge::Ini::CACHE_PATH/$inc.pl";
	my \$__source = (stat(\$__input))[9];
	my \$__output = (stat(\$__script))[9];
	if (\$__source > \$__output) {
		require HTML::Merge::Compile;
		HTML::Merge::Compile::safecreate(\$__script);
		eval '	HTML::Merge::Compile::CompileFile(\$__input, \$__script, 1); ';
		HTML::Merge::Error::HandleError('ERROR', \$@) if \$@;
	}
	do \$__script;
EOM
	$text;
}

sub DoWEBINCLUDE {
	my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.\\(['"])(.*)\\\1$//s) {
		$self->Syntax;
	}
	my $url = $2;
<<EOM;
if (\$HTML::Merge::Ini::WEB) {
	require LWP;
	require HTTP::Request::Common;
	import HTTP::Request::Common;

	my \$__ua = new LWP::UserAgent;
	my \$__req = GET("$url");
	my \$__resp = \$__ua->request(\$__req);
	if (\$__resp->is_success) {
		print \$__resp->content;
	} else {
		die "Web GET to URL $url returned code " . \$__resp->code;
	}
}
EOM
}

sub DoINDEX {
        my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	"\$engines{\"$engine\"}->Index";
}

sub DoCOUNT {
	my ($self, $engine, $param) = @_;
	$self->Die("COUNT must have four arguments") if ($#$param != 3);
	my ($var, $from, $to, $step) = @$param;
	my $i = "\$vars{\"$var\"}";
	$self->Push('count', $engine);
	qq!for ($i = "$from"; $i <= "$to"; $i += "$step") {\n!;
}

sub DoUnCOUNT {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'count');
	"}\n";
}

sub DoPIC {
        my ($self, $engine, $param) = @_;
	unless ($param =~ s/^\\\.([FRN])(.*)$//is) {
		$self->Syntax;
	}
	my ($type, $param) = (uc($1), $2);
	my $code = &UNIVERSAL::can($self, "Picture$type");
	&$code($self, $param);
}

sub PictureF {
	my ($self, $param) = @_;
	unless ($param =~ /^(\\?.)\\(['"])(.*?)\\\2$/) {
		$self->Syntax;
	}
	my ($ch, $text) = ($1, $3);
	<<EOM;
"" . (\$__s = "$text", \$__s =~ s/\\s/$ch/g, \$__s)[-1];
EOM
}

sub PictureR {
	my ($self, $param) = @_;
	my @ary;
	my $flag;
	while ($param =~ s/^\s*\\(['"])(.*?)\\\1\s*\\=\s*\\(['"])(.*?)\\\3\s*//s) {
		push(@ary, [$2, $4]);
		if ($param =~ s/^\\\.//) {
			$flag = 1;
			last;
		}
		unless ($param =~ s/^\\,//) {
			$self->Syntax;
		}
	}
	$self->Die("Syntax error in PIC.R") unless ($flag);
	unless ($param =~ s/^\\(["'])(.*?)\\\1$//) {
		$self->Syntax;
	}
	my $text = $2;
	my $code = <<EOM;
"" . (\$__s = "$text",
EOM
	foreach (@ary) {
		my ($from, $to) = @$_;
		$code .= <<EOM;
\$__s =~ s/$from/$to/g,
EOM
	}
	$code . ", \$__s)[-1]";
}

sub PictureN {
	my ($self, $param) = @_;
	my $zero = 0;
	if ($param =~ s/^Z//) {
		$zero = 1;
	}
	unless ($param =~ s/^\\\((.*?)\\\)//) {
		$self->Syntax;
	}
	my $format = $1;
	unless ($param =~ s/^\\\.\\(["'])(.*?)\\\1$//) {
		$self->Syntax;
	}
	my $text = $2;
	<<EOM;
"" . (\$__s = "$text" || !$zero ? sprintf("\%${format}f", "$text") : "&nbsp;",
	\$__s)[-1]
EOM
}

sub DoINC {
        my ($self, $engine, $param) = @_;
	unless ($param =~ /^\\\.(.*?)([+-]\d+)?$/) {
		$self->Syntax;
	}
	my ($var, $step) = ($1, defined($2) ? $2 : 1);
	<<EOM;
\$vars{"$var"} += "$step";
EOM
}

sub DoSTATE {
	my ($self, $engine, $param) = @_;
	$self->Syntax if $param;
	"\$engines{\"$engine\"}->State";
}

sub DoMAIL {
	my ($self, $engine, $param) = @_;
        unless ($param =~ /^\\\.\\(['"])(.*?)\\\1\\\.\\(['"])(.*?)\\\3(.*)$/) {
		$self->Syntax;
	}
	my ($from, $to, $rem, $subject) = ($2, $4, $5);
	if ($rem) {
		unless ($rem =~ /^\\\.\\(['"])(.*?)\\\1$/) {
			$self->Syntax;
		}
		$subject = $2;
	}
	$self->Push('mail', $engine);
<<EOM;
	\$__from = "$from";
	\$__from =~ s/^.*\<(.*)\>\$/\$1/;
	\$__from =~ s/^(.*?)\s+\(\".*\"\)\$/\$1/;
	\$__to = "$to";
	\$__to =~ s/^.*\<(.*)\>\$/\$1/;
	\$__to =~ s/^(.*?)\s+\(\".*\"\)\$/\$1/;
	use HTML::Merge::Mail;
	eval '\$__mail = OpenMail(\$__from, \$__to, \$HTML::Merge::Ini::SMTP_SERVER);';

	HTML::Merge::Error::HandleError('WARN', 'Mail failed: \$\@') if \$\@;
	\$__prev = select \$__mail;

	print "From: $from\\r\\n";
	print "To: $to\\r\\n";
	print "Subject: $subject\\r\\n";
	print "X-Mailer: Merge v. $VERSION (c) http://www.raz.co.il\\r\\n";
	print "\\r\\n";
EOM
}
sub DoUnMAIL {
	my ($self, $engine, $param) = @_;
	$self->Expect($engine, 'mail');
	<<EOM;
	eval ' CloseMail(\$__mail); ';
        HTML::Merge::Error::HandleError('WARN', 'Mail failed: \$\@') if \$\@;
	select \$__prev;
EOM
}


sub DoDB {
	my ($self, $engine, $param) = @_;
	unless ($param =~ /^"\\[\.=]\\(['"])(.*?)\\\1"$/) {
		$self->Syntax;
	}
	my $dsn = $2;
	my ($dsn1, $user, $pass) = split(/\s*\\,\s*/, $dsn);
	unless ($dsn1) {
		$self->Die("DSN not specified");
	}
	$dsn1 =~ s/^dbi\\://;
	my ($type, $db, $host) = split(/\\:/, $dsn1);
	($type, $db) = ($db, undef) unless ($db);
	<<EOM;
\$engines{"$engine"}->Connect("$type", "$db", "$host", "$user", "$pass");
EOM
}

sub safecreate {
        my @tokens = split(/\//, shift);
        pop @tokens;
        my $dir;
        foreach (@tokens) {
                $dir .= "/$_";
                mkdir $dir, 0755;
        }
}


sub CompileFile {
	my ($file, $out, $sub) = @_;

	open(I, $file);
	my $text = join("", <I>);
	close(I); 
	
	open(O, ">$out") || die "Can't write $out: $!";
	my $prev = select O;
	
	unless ($sub) {
		print $Config{'startperl'}, "\n";
		print <<'EOM';
	use HTML::Merge::Engine;
	use HTML::Merge::Error;
	no strict;

	tie %engines, HTML::Merge::Engine;
	use CGI qw/:standard/;
	@keys = param();
	%vars = ();
	foreach (@keys) {
		$vars{$_} = param($_);
	}
	
EOM
	}

	eval {	
		print &Compile($text, $file);
	};
	my $code = $@;
	
	unless ($sub) {
		print <<'EOM';
	HTML::Merge::Engine::DumpSuffix;
	untie %engines;

	1;
EOM
	}

	select $prev;
	close(O);
	die $code if $code;
	chmod 0755, $out;
	
}

sub Syntax {
	my $self = shift;
	&DB::Syntax($self);
}

package DB;

sub Syntax {
	my $self = shift;
	my $step = 0;
	my $sub;
	my $pkg = ref($self);
	do {
		$step++;
		my @c = caller($step);
		$sub = $c[3];
	} until ($sub =~ s/^${pkg}\::Do//);
	$self->Die("Syntax error on $sub: $DB::args[2]");
}


1;
