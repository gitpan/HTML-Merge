<$RSET.__pos_dir__='(uc("<$RVAR.dir>") eq "RTL")?"right":"left"'>

<$REM - Build the Macro hash>
<$RIF.'!"<$RVAR.__loaded__macros__>"'>
	<$R[__macro__].DB='SYSTEM'>
	<$R[__macro__].Q='SELECT name,note FROM tbl WHERE tbl="MACROS" '>
	<$R[__macro__].LOOP>
		<$RSET.__macro_<$R[__macro__].SQL.name>__=' "<$R[__macro__].SQL.note>" '>
	</$R[__macro__].LOOP>
	<$RSET.__loaded__macros__='1'>
</$RIF>

<$REM - Do the page build>

<$RINCLUDE.'Repository/repush.inc'>

<$RINCLUDE.'Repository/repository_query.inc'>
<$R[<$RVAR.repository_query_engine>].LOOP>
	<$RSET.__pos_x_fld__=' <$RDECIDE.'<$RPIC.N(.0)."<$R[<$RVAR.repository_query_engine>].SQL.isfield>">'?'<$R[<$RVAR.repository_query_engine>].SQL.pos_x> + <$R[<$RVAR.repository_query_engine>].SQL.pos_delta>':'<$R[<$RVAR.repository_query_engine>].SQL.pos_x>'> '>
	<$RSET.__border__=' <$RDECIDE.'<$RPIC.N(.0)."<$RVAR.__DEBUG__>">'?' "thin solid" ':' "<$R[<$RVAR.repository_query_engine>].SQL.border>'>" '>
	<$RSET.__visibility__=' <$RDECIDE.' "<$R[<$RVAR.repository_query_engine>].SQL.fldstatus>" eq "hidden"  '?' "hidden" ':''> '>
	<div id="<$R[<$RVAR.repository_query_engine>].SQL.field_name>_fld" class="<$R[<$RVAR.repository_query_engine>].SQL.class>" dir="<$RVAR.dir>" style="position: absolute;<$RVAR.__pos_dir__>: <$RVAR.__pos_x_fld__>px; top: <$R[<$RVAR.repository_query_engine>].SQL.pos_y>px; width:<$R[<$RVAR.repository_query_engine>].SQL.width>px; height:<$R[<$RVAR.repository_query_engine>].SQL.height>px; border: <$RVAR.__border__>; visibility: <$RVAR.__visibility__>;">
	<$RPERL.A>
		# my $__x__='<$R[<$RVAR.repository_query_engine>].SQL.field_template>';
		my $__x__ = getfield('field_template', getvar('repository_query_engine'));
		$__x__=~ s/\@(.*?)\@/getvar("__macro_$1__")/ge;
		$__x__=~ s/#(.*?)#/getfield($1, getvar('repository_query_engine'))/ge;
		$__x__=~ s/``/\"/g;
		$__x__=~ s/`/\'/g;
	    
		return $__x__."\n";      
	</$RPERL>
	</div>
	<$RIF.' <$RPIC.N(.0)."<$R[<$RVAR.repository_query_engine>].SQL.isfield>"> '>
		<$RSET.__pos_y_cap__='<$R[<$RVAR.repository_query_engine>].SQL.pos_y> + 0'>
		<$RSET.__border__=' <$RDECIDE.'<$RPIC.N(.0)."<$RVAR.__DEBUG__>">'?' "thin solid" ':''> '>	
		<div id="<$R[<$RVAR.repository_query_engine>].SQL.field_name>_cap" class="<$R[<$RVAR.repository_query_engine>].SQL.class>" style="position: absolute;<$RVAR.__pos_dir__>: <$R[<$RVAR.repository_query_engine>].SQL.pos_x>px; top: <$RVAR.__pos_y_cap__>px; border: <$RVAR.__border__>; visibility: <$RVAR.__visibility__>;">
			<$R[<$RVAR.repository_query_engine>].SQL.caption>
		</div>
	</$RIF>
</$R[<$RVAR.repository_query_engine>].LOOP>

<$RINCLUDE.'Repository/repop.inc'>
