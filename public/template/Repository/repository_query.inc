<$RIF.' "<$RVAR.repository_query_engine>" eq "" '>
	<$RTRACE.' Default engine (setting repository_query_engine var ) is not supported anymore change your code !!! '>
	<$RSET.repository_query_engine=' "repository" '>
</$RIF>

<$RIF.' "<$RVAR.repository_template>" eq "" '>
	<$RSET.repository_template=' "<$RTEMPLATE>" '>
</$RIF>

<$REM - get all of the user realms >
<$RIF.'!"<$RVAR.user_realms>"'>
	<$RINCLUDE.'Repository/get_user_realms.inc'>
</$RIF>

<$R[<$RVAR.repository_query_engine>].DB='SYSTEM'>

<$R[<$RVAR.repository_query_engine>].Q="SELECT fldtyp_code,field_name,value,c.note fldstatus,
             b.langug_code labgug_code,caption,field_data,pos_x,pos_y,pos_delta,e.name field_type,
			 e.note field_template,e.number isfield,size,maxlength,onBlur,onClick,
			 onDblClick,onChange,src,class,width,height,background,border
	  	FROM repository_t a
		LEFT JOIN repository_language_matrix b ON b.repository_id=a.rid 
                                                AND b.langug_code='<$RVAR.langug_code>'
		LEFT JOIN tbl c ON c.code=a.fldsts_code 
						AND c.tbl='FLDSTS'
		LEFT JOIN tbl e ON e.code=a.fldtyp_code 
						AND e.tbl='FLDTYP'
		INNER JOIN templates_t f ON f.id=a.template_id
		INNER JOIN instances_t g ON g.id=f.instance_id
		WHERE f.templatename='<$RVAR.repository_template>' 
		AND g.instancename LIKE '<$RCFG.MERGE_ABSOLUTE_PATH>%'
		AND a.realm_id IN (<$RVAR.user_realms>) 
		AND a.status_code > 1
		ORDER BY a.arrangement">
