package HTML::Merge::Ext;

## preset examples

sub OUT_CHOMPIE ($) {
	my ($param) = @_;
	qq!"shalom $param on engine $ENGINE\\n"!;
}

sub OAPI_EYNSHEM ($$$$) {
	my ($var, $from, $to, $step) = @_;
	qq!for (\$vars{"$var"} = "$from"; \$vars{"$var"} <= "$to"; \$vars{"$var"} += "$step") {\n!;
}

sub CAPI_EYNSHEM () {
	"}\n";
}

sub OUT_SASSI () {
	qq!"* \\. *"!;
}

sub OUT_YONA ($$) {
	my ($a, $b) = @_;
	qq!"$a and $b"!;
}

1;
