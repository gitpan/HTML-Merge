<script language="javascript">
<!--
var __grid_obj__ = new Object;
var __i = 2; //because 2 is the row num of the data

<$RPERL.C>
	# order the table by order by	
	my $sql=getvar('grid_query');
	my $sql_part='ORDER\s+BY';
	my @sql_parts_post=qw(LIMIT PROCEDURE FOR\s+UPDATE $);
	my $sql_parts_post=join('|',@sql_parts_post);
	my $res=1 if $sql =~ m/$sql_part/si;
	
	return if(!$sql);
	
	# if there is an order by clause replace it
	
	if(getvar("order_by"))
	{
		if($res)
		{
			$sql=~ s/$sql_part.*?(?=$sql_parts_post)/ ORDER BY <$RVAR.order_by> <$RVAR.order_by_dir> /si;
		}
		else
		{
			$sql=~ s/(?=$sql_parts_post)/ ORDER BY <$RVAR.order_by> <$RVAR.order_by_dir> /si;
		}
	}
	
	return "<\$R[grid].Q='$sql'>";
</$RPERL>

<$RINCLUDE.'Repository/repush.inc'>
<$RINCLUDE.'Repository/repository_query.inc'>

<$REM ----- the header section ----- >
<$RIF.'!<$RPIC.N(.0).'<$RVAR.suppress_header_rebuild>'>'>
	__grid_obj__.grid_delete='<input type="checkbox" value="all" onClick="javascript:<$RVAR.grid_class>.MarkChkRow(this)"><span class="<$RDECIDE.' "<$R[<$RVAR.repository_query_engine>].SQL.class>" '?'<$R[<$RVAR.repository_query_engine>].SQL.class>':'gridsText__'>"><$R[<$RVAR.repository_query_engine>].SQL.caption></span>';
</$RIF>
<$R[<$RVAR.repository_query_engine>].FETCH>
	
<$R[<$RVAR.repository_query_engine>].LOOP>
	<$RIF.'!<$RPIC.N(.0).'<$RVAR.suppress_header_rebuild>'>'>
__grid_obj__.<$R[<$RVAR.repository_query_engine>].SQL.field_name>='<A class="<$RDECIDE.' "<$R[<$RVAR.repository_query_engine>].SQL.class>" '?'<$R[<$RVAR.repository_query_engine>].SQL.class>':'gridsText__'>" col_maxlength="<$R[<$RVAR.repository_query_engine>].SQL.maxlength>" href="#" onClick="javascript:<$RVAR.grid_class>.OrderTable(\'<$RVAR.grid_class>_<$R[<$RVAR.repository_query_engine>].SQL.field_name>\')" style="width:<$R[<$RVAR.repository_query_engine>].SQL.width>; height:<$R[<$RVAR.repository_query_engine>].SQL.height>; text-decoration : none;" title="<$RVAR.cap_sort>"><img src="<$RVAR.__image_path__>/space.gif" name="<$RVAR.grid_class>_<$R[<$RVAR.repository_query_engine>].SQL.field_name>" alt="<$RVAR.cap_sort>" border=0 width=0 height=0><$R[<$RVAR.repository_query_engine>].SQL.caption></A>';
	</$RIF>

<$RSET.__PIC_<$R[<$RVAR.repository_query_engine>].SQL.field_name>=' "<$R[<$RVAR.repository_query_engine>].SQL.value>" '>
</$R[<$RVAR.repository_query_engine>].LOOP>

<$RIF.'!<$RPIC.N(.0).'<$RVAR.suppress_header_rebuild>'>'>
	<$RVAR.grid_ref><$RVAR.grid_class>.SetData(__grid_obj__,0);
</$RIF>
<$REM ----- end the header section ----- >

__grid_obj__ = new Object();

<$REM ----- the body section ----- >						  
<$REM - run till start>
<$R[grid].LOOP.LIMIT=<$RPIC.N(.0).'<$RVAR.start>'>>
</$R[grid].LOOP>

<$R[grid].LOOP.LIMIT=<$RPIC.N(.0).'<$RVAR.step>'>>
    <$RSET.i=' <$R[grid].INDEX>-<$RPIC.N(.0).'<$RVAR.start>'> '>
	
	__grid_obj__.grid_delete='<input type="checkbox" name="del_check_<$RVAR.i>" value="<$R[grid].SQL.<$RVAR.uid>>" onClick="<$RVAR.grid_class>.DoChk(this,\'<$RVAR.i>\')">';
		
	<$R[grid].ENUMQUERY.var=val>
		<$RIF.' "<$RVAR.__PIC_<$RVAR.var>>" '>
			<$RPERL.B>
				print "\n__grid_obj__.<$RVAR.var> = '";
				merge("<\$RPIC.<$RVAR.__PIC_<$RVAR.var>>.'<$RVAR.val>'>");
				print "';";
			</$RPERL>
		<$RELSE>
__grid_obj__.<$RVAR.var> = '<$RVAR.val>'; 
		</$RIF>
	</$R[grid].ENUMQUERY>
	
	<$RVAR.grid_ref><$RVAR.grid_class>.SetData(__grid_obj__,__i++);
	
	__grid_obj__ = new Object();
</$R[grid].LOOP>

<$REM ----- end the body section ----- >
<$REM - kill the grid query var >
<$RSET.grid_query=''>
<$R[grid].DISCONNECT>

<$RINCLUDE.'Repository/repop.inc'>
//-->
</script>
