
<SCRIPT language=JavaScript src="<$RCFG.MERGE_PATH>/public/javascript/Repository/Grid/scrollbar.js"></SCRIPT>
<SCRIPT language=JavaScript  src="<$RCFG.MERGE_PATH>/public/javascript/Repository/Grid/dynlayer.js"></SCRIPT>
<SCRIPT language=JavaScript  src="<$RCFG.MERGE_PATH>/public/javascript/razglobal.js"></SCRIPT>
<SCRIPT language=JavaScript  src="<$RCFG.MERGE_PATH>/public/javascript/Repository/Grid/grid.js"></SCRIPT>

<style>
	.gridsText__ {
	font-size : 10pt;
	font-weight : bold;
	color : #000000;
	font-family : Arial (hebrew);	
	text-decotation : none;
	}
	
	.gridRepText__ {
	font-size : 9pt;
	font-weight : normal;
	color : #000000;
	font-family : Arial (hebrew);	
	text-decotation : none;
	}
	
	.gridCntrlText__ {
	font-size : 9pt;
	font-weight : bold;
	color : #000000;
	font-family : Arial (hebrew);	
	text-decotation : none;
	}
	
	a.gridsText__:visited {
	color : black;
	text-decoration : none;
	}
	
	a.gridsText__:link {
	color : black;
	text-decoration : none;
	}
	
	a.gridsText__:hover {
		color : white;
		background-color : black;
		text-decoration : none;
	}
</style>

<script language="javascript">
<!--
// create the class init struct 
var grid_init = new Object;

<$RPERL.B>
my $str='<$R[<$RVAR.repository_query_engine>].SQL.field_data>';
my (@val,@tmp);

return if !$str;

@val=split(/;\s*/,$str);

foreach (@val)
{
        @tmp=split(/\s*=\s*/);
		print qq!grid_init.$tmp[0]='$tmp[1]';\n!;
		setvar($tmp[0],$tmp[1]);
}              
</$RPERL>

<$REM - map all captions to class and VARS - >
<$R[grid_captions].DB='SYSTEM'>
<$R[grid_captions].Q='SELECT name,note
		      FROM tbl 
		      WHERE tbl='FRMSTR' 
		      AND langug_code='<$RVAR.langug_code>' 
		      AND note IN ('cap_sort','cap_record') '>
<$R[grid_captions].LOOP>
<$RSET.<$R[grid_captions].SQL.note>=' "<$R[grid_captions].SQL.name>" '>
grid_init.<$R[grid_captions].SQL.note>='<$R[grid_captions].SQL.name>';
</$R[grid_captions].LOOP>

<$REM - lets give default values>
<$RSET.step=' <$RDECIDE.' "<$R[<$RVAR.repository_query_engine>].SQL.maxlength>" '?'<$R[<$RVAR.repository_query_engine>].SQL.maxlength>':'50'> '>
<$RSET.langug_code=' <$RDECIDE.' "<$RVAR.langug_code>" '?' "<$RVAR.langug_code>" ':'en'> '>
<$RSET.uid=' <$RDECIDE.' "<$RVAR.uid>" '?'<$RVAR.uid>':'rid'> '>
<$RSET.__image_path__=' "public/gif" '>

grid_init.name = '<$R[<$RVAR.repository_query_engine>].SQL.field_name>';
grid_init.size = <$RPIC.N(.0).'<$R[<$RVAR.repository_query_engine>].SQL.size>'>;
grid_init.width = <$RPIC.N(.0).'<$R[<$RVAR.repository_query_engine>].SQL.width>'>;
grid_init.background = '<$R[<$RVAR.repository_query_engine>].SQL.background>'
grid_init.mode = '<$RVAR.mode>';
grid_init.note = '<$RVAR.note>';
grid_init.span = '<$R[<$RVAR.repository_query_engine>].SQL.field_name>_fld';
grid_init.dir = '<$RVAR.dir>';
grid_init.charset = '<$RVAR.charset>';
grid_init.step = <$RVAR.step>;
grid_init.start = 1;
grid_init.bnd_src = '<$R[<$RVAR.repository_query_engine>].SQL.src>';
grid_init.langug_code = '<$RVAR.langug_code>';
grid_init.dbl_click_func='<$R[<$RVAR.repository_query_engine>].SQL.onDblClick>';
grid_init.on_change_func='<$R[<$RVAR.repository_query_engine>].SQL.onChange>';
grid_init.merge='<$RMERGE>';
grid_init.image_path='<$RVAR.__image_path__>';
grid_init.js_class='<$R[<$RVAR.repository_query_engine>].SQL.class>';

<$REM - create the grid class>
<$RSET.grid_class=' "c_<$R[<$RVAR.repository_query_engine>].SQL.field_name>" '>

// init the grid class
var <$RVAR.grid_class>=new Grid(grid_init);
//-->
</script>

<$RSET.repository_template=' "<$R[<$RVAR.repository_query_engine>].SQL.src>" '>

<$RINCLUDE.'Repository/Grid/grid_build_data.inc'>

<script language="javascript">
<!--
	<$REM - create the grid>
	<$RIF.'"<$R[<$RVAR.repository_query_engine>].SQL.src>"'>
		<$RVAR.grid_class>.Draw();
	</$RIF>
//-->
</script>
</div>
