//////////////////////////////////
// Grid js class		//
// Written by: Roi Illouz	//
// Date: 10/03/2002		//
// Raz Information Systems	//
//////////////////////////////////
function Grid(grid_init)
{
	// gui vars
	this.background=grid_init.background?grid_init.background:'silver';
	this.width=grid_init.width;
	this.width_str=!grid_init.veriable_width*1?'width='+this.width:'';
	this.tbl_header='<table border="1" cellspacing="0" cellpadding="1" bgcolor="white" '+this.width_str+' class="gridRepText__" id="oTbl_'+ grid_init.name +'" style="border-color: Black; border: thin;" name="oTbl_'+ grid_init.name +'">';
	this.tbl_header_row='<tr bordercolor="black" bgcolor="'+this.background+'">'; //#0D9CF2
	this.tbl_row='<tr>';
	this.tbl_index=0;
	this.len=grid_init.size?grid_init.size:5;
	this.toolbar_width=13;
	this.toolbar_height;
	this.td_size=25;
	this.js_class=grid_init.js_class?grid_init.js_class:'gridCntrlText__';
	this.sort_item = new Object();
	
	// init vars
	this.name=grid_init.name;
	this.bnd_src=grid_init.bnd_src;
	this.mode=grid_init.mode;
	this.note=grid_init.note;
	this.span=grid_init.span;
	this.dir=grid_init.dir?grid_init.dir:'LTR';
	this.charset=grid_init.charset?grid_init.charset:'ISO-8859-1';
	this.step=grid_init.step?grid_init.step:20;
	this.start=grid_init.start?grid_init.start:1;
	this.uid=grid_init.uid?grid_init.uid:'rid';
	this.langug_code=grid_init.langug_code;
	this.merge=grid_init.merge;
	this.image_path=grid_init.image_path;
	this.table;
	this.quote_data=(grid_init.quote_data)?true:false;
	
	// event func
	this.dbl_click_func = grid_init.dbl_click_func;
	this.on_change_func = grid_init.on_change_func;

	// cursor defines
	this.clr_cursor="#cccccc";
	this.clr_cursor_zoom="#ffff99";
	this.clr_cursor_mark="#aaaaaa";
	this.clr_cursor_base="";
	
	// cursor data structs
	this.marked_obj = "";
	this.marked = new Array();
	this.grayed = new Array();
	
	// data vars
	this.obj = new Object();
	this.str_obj = new Object;
	this.grid_arr = new Array();
	this.tbl_index = 0;
	this.db_from = 1;
	this.db_to = this.len;
	this.order_by='';
	this.order_by_dir='';
	this.dir_gif='';
	
	// scroolbar handlers
	this.vbar;
	this.current_step = this.step;
	
	// grid captions
	this.cap_record = grid_init.cap_record;
	this.cap_sort = grid_init.cap_sort;
}
{var p=Grid.prototype
	p.Draw = GridDraw
	p.DoGridEvents = GridDoGridEvents
	p.DoUp = GridDoUp
	p.DoDown = GridDoDown
	p.AddRecord = GridAddRecord
	p.RemoveRecord = GridRemoveRecord
	p.DoChk = GridDoChk
	p.DoDelMark = GridDoDelMark
	p.DoMark = GridDoMark
	p.MarkChkRow = GridMarkChkRow
	p.DoLineChk = GridDoLineChk
	p.DoDblClick = GridDoDblClick
	p.DoOnContextMenu = GridDoOnContextMenu
	p.DoMouseMove = GridDoMouseMove 
	p.DoMouseOut = GridDoMouseOut 
	p.Refresh = GridRefresh
	p.Rebuild = GridRebuild
	p.SetData = GridSetData
	p.OrderTable = GridOrderTable
	p.DoSortArrow = GridDoSortArrow
	p.ClearImg = GridClearImg
	p.GetMarkedUid = GridGetMarkedUid
	p.GetMarkedUidAsStr = GridGetMarkedUidAsStr
	p.GetMarkedRowid = GridGetMarkedRowid
	p.GetMarkedRowidAsStr = GridGetMarkedRowidAsStr
	p.GetZoomUid = GridGetZoomUid
	p.GetZoomRowid = GridGetZoomRowid
	p.SetHeaderCaptionByID = GridSetHeaderCaptionByID
	p.SetHeaderCaptionByFieldName = GridSetHeaderCaptionByID
	p.GetHeaderCaptionByID = GridGetHeaderCaptionByID
	p.GetHeaderCaptionByFieldName = GridGetHeaderCaptionByID
	p.GetFieldByRowAndCol = GridGetFieldByRowAndCol
	p.GetTable = GridGetTable
	p.RunGrid = GridRunGrid
	p.SyncScrollBar = GridSyncScrollBar
	p.InitNavStr = GridInitNavStr
	p.InitNavVars = GridInitNavVars
	p.UnMarkRow = GridUnMarkRow
	p.DelCoulmnByID = GridDelCoulmnByID
	p.DelCoulmnByFieldName = GridDelCoulmnByID
	p.DelCoulmnOnEmptyHeader = GridDelCoulmnOnEmptyHeader
	p.GetZoomColor = GridGetZoomColor
	p.SetZoomColor = GridSetZoomColor
	p.GetCursorColor = GridGetCursorColor
	p.SetCursorColor = GridSetCursorColor
}
/////////////////////////////
function GridDoUp()
{
	var obj = new Object();
	var tmp;
	
	// if the gris is less then the grid size disable all
	if(this.grid_arr.length-2 < this.len && event.srcElement.name != this.name+'_up')
		return;
	
	// if no more data fetch new from the db
	if(!this.tbl_index && this.start > 1)
	{
		tmp=this.start-this.step-2;		
		obj.start=(tmp>=0)?tmp:0;
		obj.step=(!obj.start)?this.step:this.step+this.len-1;

		this.Rebuild('',obj,true,obj.step-this.len);
		
		this.current_step=obj.step;
		this.start-=this.step;
		
		// init the scrollbar
		this.vbar.boxlyr.moveTo(0,this.toolbar_height-this.vbar.boxH);
		
		// init the navegation string
		this.InitNavStr('UP');
		
		return;
	}

	if(!this.grid_arr[this.tbl_index+1] ||
		this.tbl_index <= 0)
			return;
				
	this.AddRecord('first');
	this.RemoveRecord('last');
		
	this.tbl_index--;

	// sync scrollbar
	if(event.srcElement.name == this.name+'_up')
		this.SyncScrollBar(false);
		
	// init the navegation string
	this.InitNavStr('UP');
}
/////////////////////////////
function GridDoDown()
{
	var tmp = this.tbl_index+this.len+2;
	var obj = new Object();
	
	// if the gris is less then the grid size disable all
	if(this.grid_arr.length-2 < this.len)
		return;
	
	// if no more data fetch new from the db
	if(!this.grid_arr[tmp] && event.srcElement.name == this.name+'_down')
	{
		// if no more data in query
		if(this.grid_arr.length-2 < this.current_step)
			return;

		obj.start=this.step+this.start-this.len+1;
		obj.step=this.step+this.len-1;

		this.Rebuild('',obj,true);
		
		this.current_step=obj.step;
		this.start+=this.step;
		
		// init the scrollbar
		this.vbar.boxlyr.moveTo(0,0);
		
		// init the navegation string
		this.InitNavStr('DOWN');
		
		return;
	}
			
	this.tbl_index++;

	this.AddRecord('last');
	this.RemoveRecord('first');
	
	// sync scrollbar
	if(event.srcElement.name == this.name+'_down')
		this.SyncScrollBar(true);
		
	// init the navegation string
	this.InitNavStr('DOWN');
}
/////////////////////////////
function GridSyncScrollBar(dir)
{
	var add=dir?this.vbar.boxH:0;
	var new_pos=this.tbl_index*1/(this.grid_arr.length-2-this.len)*this.toolbar_height-add;
	
	new_pos=(new_pos<0)?0:new_pos; // lower rim
	
	if(new_pos > this.toolbar_height-this.vbar.boxH) // outer rim
		new_pos=this.toolbar_height-this.vbar.boxH;
	
	this.vbar.boxlyr.moveTo(0,new_pos);
}
/////////////////////////////
function GridAddRecord(pos)
{
	var table = this.GetTable();
	var row = document.createElement("TR");
	var td = new Array();
	var element;
	var i=0;
	var index=(pos == 'last')?this.len+this.tbl_index+1:this.tbl_index+1;
	var tmp;
	
	td[i]=document.createElement("TD");
	row.appendChild(td[i++]);
	
	for(element in this.grid_arr[0])
	{	
		td[i]=document.createElement("TD");
		td[i].height=this.td_size;
		td[i].grid_element=element;
		td[i].grid_index=index;
			
		row.appendChild(td[i]);
		
		if(this.str_obj[element]*1)
			tmp=this.grid_arr[index][element].substr(0,this.str_obj[element]);
		else
			tmp=this.grid_arr[index][element];
		
		if (i < 2 && i >0)
		{
			td[i++].innerHTML=tmp;
		}
		else
		{
			td[i++].appendChild(document.createTextNode(tmp+' '));
		}
	}

	if(pos == 'last')
	{
		table.appendChild(row);
		table.rows[this.len+2].cells[0].width=this.toolbar_width-3;
		this.DoGridEvents(table.rows[this.len+2]);
	}
	else
	{
		table.insertBefore(row,table.rows[2]);
		table.rows[2].cells[0].width=this.toolbar_width-3;
		this.DoGridEvents(table.rows[2]);
	}
	
	// if the line is zoomed
	if(this.GetZoomRowid()==index-1)
		row.bgColor=this.clr_cursor_zoom;
	// if the line was marked add the coloring
	else if(this.marked[index-1])
		this.DoMark(row,index-1);
}
/////////////////////////////
function GridRemoveRecord(pos)
{
	var table=document.getElementById('oTbl_'+this.name).getElementsByTagName("TBODY")[0];
	var row_num=0;
	var i=0;
	
	if(pos == 'last')
	{
		row_num=this.len+2;
	}
	else
	{
		row_num=2;
	}
	table.removeChild(table.rows[row_num]);
}
/////////////////////////////
function GridDoGridEvents(obj)
{
	obj.onmousemove=this.DoMouseMove;
	obj.onmouseout=this.DoMouseOut;
	obj.ondblclick=this.DoDblClick;
	obj.oncontextmenu=this.DoOnContextMenu;
}
/////////////////////////////
function GridDoMouseMove() 
{ 
	var obj=event.srcElement.parentNode;
	var instance=(event.srcElement.name) ? eval('c'+obj.parentNode.parentNode.parentNode.name.substring(4)) : eval('c'+obj.parentNode.parentNode.name.substring(4));
		
	if(obj.nodeName != 'TR')
		obj=obj.parentNode;
		
	if(!obj.childNodes[1].childNodes[0])
		return;
	
	if(obj.bgColor == instance.clr_cursor_base)
	{
		obj.bgColor = instance.clr_cursor;
	}
}
/////////////////////////////
function GridDoMouseOut() 
{ 
	var obj=event.srcElement.parentNode;
	var instance=(event.srcElement.name) ? eval('c'+obj.parentNode.parentNode.parentNode.name.substring(4)) : eval('c'+obj.parentNode.parentNode.name.substring(4));
	
	if(obj.nodeName != 'TR')
		obj=obj.parentNode;
	
	if(obj.bgColor == instance.clr_cursor)
				obj.bgColor = instance.clr_cursor_base;
}
/////////////////////////////
function GridDoDblClick() 
{ 
	var obj=event.srcElement.parentNode;
	var child;
	var index;
	var param = new Object(); 	// all param to be send to user func
	var instance=(event.srcElement.name) ? eval('c'+obj.parentNode.parentNode.parentNode.name.substring(4)) : eval('c'+obj.parentNode.parentNode.name.substring(4));
	
	// if checkbox
	if(event.srcElement.name)
		return; 		
	
	// no checkbox line is invalid
	if(!obj.childNodes[1].childNodes[0])
		return;
			
	child=obj.childNodes[1].childNodes[0].name;
		
	index=child.substring(10)*1;
	
	if(instance.marked_obj == obj)
	{	
		obj.bgColor=instance.clr_cursor_base;
		instance.marked_obj="";
	}
	else
	{
		// clear all checkboxes
		instance.DoLineChk(false);
		
		obj.bgColor=instance.clr_cursor_zoom;
		
		if(instance.marked_obj)
			instance.marked_obj.bgColor=instance.clr_cursor_base;
			
		instance.marked_obj=obj;
	}
	
	// handle the user event
	if(instance.dbl_click_func)
	{
		// create the param line for the func obj
		param.uid=instance.grid_arr[index+1][instance.uid];
		param.rowid=index;
		param.flag=(instance.marked_obj)?true:false;
	
		eval(instance.dbl_click_func+'(param)');
	}
}
/////////////////////////////
function GridDoOnContextMenu()
{
	var obj=event.srcElement.parentNode;
	var instance=(event.srcElement.name) ? eval('c'+obj.parentNode.parentNode.parentNode.name.substring(4)) : eval('c'+obj.parentNode.parentNode.name.substring(4));
	var grid_element=event.srcElement.grid_element;
	var row;

	if(!obj.childNodes[1].childNodes[0])
		return false;
	
	row=obj.childNodes[1].childNodes[0].name.substring(10);

	alert(instance.grid_arr[row*1+1][grid_element]);
	
	return false;
}
/////////////////////////////
function mouseDown(e) 
{
	var tmp=event.srcElement.id;
	var instance='c_'+tmp.substring(10,tmp.length-1);
	
	if(!window[instance])
		return;
	
	if (is.ns && e.target!=document) routeEvent(e)
	
	// other mouseDown code
	
	return true
}
/////////////////////////////
function mouseMove(e) 
{
	var tmp=event.srcElement.id;
	var instance='c_'+tmp.substring(10,tmp.length-1);
	
	if(!window[instance])
		return;
	
	if (is.ns && e.target!=document) routeEvent(e)

	// other mouseMove code
	window[instance].RunGrid();

	return true
}
/////////////////////////////
function mouseUp(e) 
{
	var tmp=event.srcElement.id;
	var instance='c_'+tmp.substring(10,tmp.length-1);
	//alert(event.srcElement.id+'|'+instance);
	
	if(!window[instance])
		return;
	
	if (is.ns && e.target!=document) routeEvent(e);
	
	// other mouseUp code
	window[instance].RunGrid();
	
	return true
}
/////////////////////////////
function GridRunGrid()
{
	var current_index=this.vbar.getYfactor()*(this.grid_arr.length-2-this.len);
	var delta=current_index-this.tbl_index;
	
	if(delta<0)
	{
		for(i=0;i<Math.floor(Math.abs(delta));i++)
		{
			this.DoUp();
		}
	}
	else if(delta>0)
	{
		for(i=0;i<Math.floor(Math.abs(delta));i++)
		{
			this.DoDown();
		}
	}
}
/////////////////////////////
// run over the line checkboxes and change their values
function GridDoLineChk(flag)
{
	var i=2;
	var table=document.getElementById('oTbl_'+this.name).getElementsByTagName("TBODY")[0];
	
	if(!table)
		return;
		
	// init all marked objects
	this.marked = new Array();
	
	if(flag)
	{
		// mark all elements 
		for(i=2;i<this.grid_arr.length;i++)
		{
			this.marked[i-1]=this.grid_arr[i][this.uid];
		}
		
		// reset the i element
		i=2;
		
		// run the length of the grid
		while(table.rows[i])
		{	
			if(!table.rows[i].childNodes[1].childNodes[0])
				break;

			this.DoMark(table.rows[i],i-1+this.tbl_index);
			i++;
		}
	}
	else
	{
		while(table.rows[i])
		{	
			if(!table.rows[i].childNodes[1].childNodes[0])
				break;
				
			this.DoDelMark(table.rows[i]);
			i++;
		}
	}
}
/////////////////////////////
function GridDoChk(obj,query_index)
{
	var row;
	var param = new Object;
			
	// if in update mod return 
	if(this.marked_obj)
	{
		obj.checked = false;
		return;
	}
	
	row=obj.parentNode.parentNode;
	
	// mark the checked chekboxes
	if(!obj.checked)
	{
		this.DoDelMark(row,query_index);
	}
	else
	{
		this.DoMark(row,query_index);
	}
	
	// handle the user event
	if(this.on_change_func)
	{
		// create the param line for the func obj
		param.uid=obj.value;
		param.rowid=query_index;
		param.flag=(obj.checked)?true:false;
	
		eval(this.on_change_func+'(param)');
	}
}
/////////////////////////////
function GridMarkChkRow(obj)
{
	var param = new Object();
			
	// if in update mod return 
	if(this.marked_obj)
	{
		obj.checked = false;
		return false;
	}
	
	if(obj.checked == true)
		this.DoLineChk(true);
	else
		this.DoLineChk(false);
	
	// handle the user event
	if(this.on_change_func)
	{
		// create the param line for the func obj
		param.uid=this.GetMarkedUidAsStr(this.quote_data);
		param.rowid=this.GetMarkedRowidAsStr(this.quote_data);
		param.flag=(obj.checked)?true:false;
	
		eval(this.on_change_func+'(param)');
	}
}
/////////////////////////////
function GridOrderTable(element)
{
	var src = document.images[element].src;
	var path = src.substring(0,src.lastIndexOf('/'));
	
	if(this.marked_obj)
		return;
	
	src=src.substring(src.lastIndexOf('/')+1);
	
	// change the image source
	switch (src) {			
		case 'space.gif':
			src = 'up.gif';
			this.order_by_dir='ASC';
			break;
			
		case 'up.gif':
			src = 'down.gif';
			this.order_by_dir='DESC';
			break;
			
		case 'down.gif':
			this.order_by_dir='';
			src = 'space.gif';
			break;
	}

	if(this.order_by_dir)	
		this.order_by=element.substring(('c_'+this.name).length+1);
		
	this.dir_gif=path+'/'+src;
	
	// init the start vars 
	this.start=1;
	this.current_step = this.step;
	
	// init the scrollbar
	this.vbar.boxlyr.moveTo(0,0);
	
	this.Rebuild('','',true);
}
/////////////////////////////
function GridDoSortArrow(image,element)
{
	var grid_img=document.images[element];
	
	this.ClearImg();
	
	grid_img.src=image;
	
	if(grid_img.src.indexOf('space.gif') >= 0)
	{
		grid_img.width=0;
		grid_img.height=0;
	}
	else
	{
		grid_img.width=12;
		grid_img.height=12;
	}
	
	// mark the sort itemes
	this.sort_item.element=element;
	this.sort_item.image=image;
}
/////////////////////////////
function GridClearImg()
{
	var i=0;
	
	while(document.images[i])
	{
		document.images[i].src=this.image_path+'/space.gif';
		document.images[i].width=1;
		document.images[i].height=1;
		i++;
	}
}
/////////////////////////////
function GridDraw()
{
	var i;
	var element;
	var vbar;
	var bar_obj;
	var x,y;
	var table,tbl_size,row_size;
	var first=1;
	var buf;
	var span_width=eval(this.span+".style.width");
	var counter=0;
	var table;
	var str_maxlength;
	var tmp;
	
	eval(this.span+".style.dir='"+this.dir+"'");
	
	// clean the px and make numberix
	span_width=span_width.substr(0,span_width.indexOf('px'))*1;
	
	// do the align
	document.writeln("<div dir='"+this.dir+"'>");
	document.writeln(this.tbl_header);
	document.writeln(this.tbl_header_row);
	
	table=this.GetTable();
	
	// do the title line
	for(element in this.grid_arr[0])
	{
		if(first)
		{
			buf="colspan=2";
			first=false;
		}
		
		document.writeln("<td id='" + element + "' height='"+this.td_size+"' align='baseline' "+buf+" nowrap>"+this.grid_arr[0][element]+"&nbsp;</td>");
		
		// build the str_obj element
		str_maxlength=table.rows[0].cells[element].childNodes[0].col_maxlength;
		
		if(str_maxlength)
				this.str_obj[element]=str_maxlength;
			
		// advance the counter
		counter++;
		
		// init the buf
		buf='';
	}
	//<img src="' + this.image_path +'/space.gif" alt="" width="1" height="1" border="0">
	document.writeln('</tr>\n<tr><td></td><td colspan=' + counter + '></td></tr>');

	// do the default grid body
	for(i=2;i<=this.len+1;i++)
	{  
		document.writeln(this.tbl_row);
		
		document.writeln("<td height='"+this.td_size+"' width="+(this.toolbar_width-3)+"></td>");
		
		for(element in this.grid_arr[0])
		{
			if(i < this.grid_arr.length)
			{
				if(this.str_obj[element]*1)
					tmp=this.grid_arr[i][element].substr(0,this.str_obj[element]);
				else
					tmp=this.grid_arr[i][element];
				
				document.writeln("<td id='" + element + "' height='"+this.td_size+"' grid_element='"+element+"' nowrap>"+tmp+"&nbsp;</td>");
			}
			else
			{
				document.writeln("<td id='" + element + "' height='"+this.td_size+"'></td>");
			}
		}
		
		document.writeln("</tr>\n");
		this.DoGridEvents(document.getElementById('oTbl_'+this.name).getElementsByTagName("TBODY")[0].rows[i]);
	}
	
	document.writeln("</table>\n");
	if(this.dir == 'RTL')
	{
		document.writeln('<input type="button" name="'+this.name+'_up" class="gridCntrlText__" value=">" onClick="c_'+this.name+'.DoUp()" dir=ltr>');
		document.writeln('<input type="button" name="'+this.name+'_down" class="gridCntrlText__" value="<" onClick="c_'+this.name+'.DoDown()" dir=ltr>');
	}
	else
	{
		document.writeln('<input type="button" name="'+this.name+'_up" class="gridCntrlText__" value="<" style="height:20;width:15;FONT:16 Fixedsys;cursor: hand" onClick="c_'+this.name+'.DoUp()" dir=ltr>');
		document.writeln('<input type="button" name="'+this.name+'_down" class="gridCntrlText__" value=">" style="height:20;width:15;FONT:16 Fixedsys;cursor: hand" onClick="c_'+this.name+'.DoDown()" dir=ltr>');
	}
	
	document.writeln('<span class="gridCntrlText__" id="nav_str_'+this.name+'"></span>');
	
	// Init the nav string
	this.InitNavStr();
	
	// ScrollBar section	
	table=document.getElementById('oTbl_'+this.name).getElementsByTagName("TBODY")[0];
	
	if(this.dir == 'RTL')
	{
		x=span_width-(this.toolbar_width+0);
	}
	else
	{
		x=0;
	}

	tbl_size=table.offsetHeight-2;
	row_size=table.rows[0].offsetHeight;
	delimeter_row_size=table.rows[1].offsetHeight;
	this.toolbar_height=tbl_size-row_size;
	
	y=row_size+2;
	this.vbar = new ScrollBar(x,y,this.toolbar_width,this.toolbar_height,15,15,this.name)

	//vbar.bgColor = "#c0c0c0"
	this.vbar.bgColor = "#d3d3d3"
	this.vbar.boxColor = "#808080"
	this.vbar.build();
	writeCSS(this.vbar.css);
	
	// init the vbar
	document.writeln(this.vbar.div);
	this.vbar.activate()
	
	// initialize mouse events
	bar_obj=window['scrollbar_'+this.name];
	
	bar_obj.onmousedown = mouseDown;
	bar_obj.onmousemove = mouseMove;
	bar_obj.onmouseup = mouseUp;
	//bar_obj.onmouseout = mouseUp;
	
	if (is.ns) document.captureEvents(Event.MOUSEDOWN | Event.MOUSEMOVE | Event.MOUSEUP);
	// end vbar initing
}
/////////////////////////////
function GridGetTable()
{
	return document.getElementById('oTbl_'+this.name).getElementsByTagName("TBODY")[0];
}
/////////////////////////////
function GridDoMark(obj,query_index)
{
	this.marked[query_index]=obj.childNodes[1].childNodes[0].value;
	obj.childNodes[1].childNodes[0].checked = true;
	obj.bgColor=this.clr_cursor_mark;
}
/////////////////////////////
function GridDoDelMark(obj,query_index)
{
	this.marked[query_index]='';
	obj.childNodes[1].childNodes[0].checked = false;
	obj.bgColor=this.clr_cursor_base;
}
//////////////////////////// 
// refresh the grid data content 
function GridRefresh(line_offset)
{
	var table = eval('oTbl_' + this.name);
	var i=0;
	var j=0;
	var tmp=0;
	var buf;
	
	// give default value
	line_offset = line_offset?line_offset:0;
	
	// init all check boxes and marked objects
	this.DoLineChk(false);
	this.marked_obj.bgColor=this.clr_cursor_base;
	
	while(table.rows[i])
	{
		if(i==1)
		{
			i++;
			continue;
		}

		tmp=(i>1)?tmp=i+line_offset:i;

		for(element in this.grid_arr[0])
		{	
			if(this.grid_arr[tmp])
			{
				// do the substr logic
				if(this.str_obj[element]*1 && i >= 2)
					buf=this.grid_arr[tmp][element].substr(0,this.str_obj[element]);
				else
					buf=this.grid_arr[tmp][element];
					
				table.rows[i].cells[j++].innerHTML=buf+'&nbsp;';
			}
			else
				table.rows[i].cells[j++].innerHTML='';
		}
		j=1;
		
		i++;
	}	

	// create the sort arrow
	if(this.sort_item.element)
		this.DoSortArrow(this.sort_item.image,this.sort_item.element);
	
	// init the grid gui vars:
	this.tbl_index=line_offset;
	this.marked_obj = "";
	this.marked = new Array();
	this.grayed = new Array();
}
//////////////////////////// 
// rebuild the grid from the db
function GridRebuild(extra,obj,suppress_header_rebuild,line_offset)
{
	var width=200;
	var height=100;
	var tmp='';
	var buf='';

	// save the header 
	if(suppress_header_rebuild)
		tmp=this.grid_arr[0];
		
	// init the grid array
	this.grid_arr = new Array();
	
	// save only the header 
	this.grid_arr[0]=tmp;
	
	if(!obj)
		var obj = new Object();
	
	obj.bnd_src = this.bnd_src;
	obj.uid = this.uid;
	obj.name = this.name;
	obj.langug_code = this.langug_code;
	obj.step = obj.step?obj.step:this.step;
	obj.extra = extra?extra:'';
	obj.suppress_header_rebuild = suppress_header_rebuild?1:0;
	obj.line_offset = line_offset?line_offset:0;
	obj.order_by_dir=this.order_by_dir;
	obj.order_by=this.order_by;
	obj.dir_gif=this.dir_gif;
	obj.charset=this.charset;

	// create the var buffer 
	for(element in obj)
	{
		buf+='&'+element+'='+obj[element];
	}
	
	var pt=GetCenterXY(width,height);
	
	// clear the sort_item indicator
	this.sort_item = new Object();
	
	// init the nav vars
	//this.InitNavVars();
	
	// rebuild the grid_arr from the database
	tmp = open(this.merge+"?template=Repository/Grid/grid_refresh.html"+buf,this.name+"_GRID_MESSAGE","width="+width+",height="+height+",left="+pt.x+",scrrenX="+pt.x+",top="+pt.y+",screenY="+pt.y+",status=no,toolbar=no,menubar=no");	
	tmp.focus();
}
////////////////////////////
function GridSetData(obj,rownum)
{
	DeepCopy(obj,this.obj);
	
	this.grid_arr[rownum]=this.obj;
	this.obj=new Object;
}
////////////////////////////
function DeepCopy(src,dest)
{
	for(element in src)
	{
		dest[element]=src[element];
	}
}
////////////////////////////
function GridGetMarkedUid(){ return this.marked; }
////////////////////////////
function GridGetMarkedUidAsStr(quoted)
{
	var i = 0;

	var buf = '';
	var sep = (quoted)?"','":",";
		
	for(i in this.marked)
	{
		if(this.marked[i])
		{
			buf += this.marked[i]+sep;
		}
	}

	// cut the last seperator 
	buf = buf.substr(0,(buf.length-sep.length));
	
	if(!buf)
		return;

	return (quoted)?"'"+buf+"'":buf;
}
////////////////////////////
function GridGetMarkedRowid()
{
	var i=0
	var arr = new Array();
	
	for(i in this.marked)
	{
		if(this.marked[i])
			arr[arr.length]=i;
	}

	return arr; 
}
////////////////////////////
function GridGetMarkedRowidAsStr(quoted)
{
	var arr=this.GetMarkedRowid();
	var buf='';
	var sep = (quoted)?"','":",";
	
	for(i in arr)
	{
		if(arr[i])
		{
			buf+=arr[i]+sep;
		}
	}
	
	// cut the last seperator 
	buf = buf.substr(0,(buf.length-sep.length));
	
	if(!buf)
		return;

	return (quoted)?"'"+buf+"'":buf;
}
////////////////////////////
function GridGetZoomUid() { return this.marked_obj ? this.grid_arr[this.GetZoomRowid()*1+1][this.uid] : '' ; }
////////////////////////////
function GridGetZoomRowid() { return this.marked_obj ? this.marked_obj.childNodes[1].childNodes[0].name.substring(10) : '' }
////////////////////////////
function GridSetHeaderCaptionByID(id,str) 
{ 
	var table = this.GetTable(); 
	var obj = table.rows[0].cells[id];
	var buf = obj.innerHTML;

	// if number
	if((id+1)/1)
		id=table.rows[0].cells[id].id;
		
	// change the buffer
	buf = buf.substr(0,buf.lastIndexOf('>',buf.lastIndexOf('<'))+1) + str;
	
	// update the string
	this.grid_arr[0][id] = buf;
	obj.innerHTML = buf;
}
////////////////////////////
function GridGetHeaderCaptionByID(id){var table = this.GetTable(); return table.rows[0].cells[id].innerText;}
////////////////////////////
function GridGetFieldByRowAndCol(row,col){return (!this.grid_arr[row*1+1])?'':this.grid_arr[row*1+1][col];}
////////////////////////////
function GridInitNavStr(dir) 
{ 
	switch (dir) {			
		case 'DOWN' :
			this.db_from++;
			this.db_to++;			
			break;
		case 'UP' :
			this.db_from--;
			this.db_to--;			
			break;
	}
	
	window['nav_str_'+this.name].innerText=this.cap_record+' ['+this.db_from+' - '+this.db_to+']';
}
////////////////////////////
function GridInitNavVars() 
{
	this.db_from=1;
	this.db_to=this.len;
	
	this.InitNavStr();
}
////////////////////////////
function GridUnMarkRow(row)
{
	var table = this.GetTable();
	var obj = table.rows[row*1+1].cells[1].childNodes[0];
	
	obj.checked = false;
	this.DoChk(obj,row*1+1);
}
////////////////////////////
function GridDelCoulmnByID(id)
{
	var row;
	var table = this.GetTable();
	var i;

	// let's delete the specific col from the grid_arr
	for(row in this.grid_arr)
	{
		delete(this.grid_arr[row][id]);
	}
	
	// now let's physicaly delete the column
	for(i=0;i<table.rows.length;i++)
	{
		if(table.rows[i].cells[id])
		{
			table.rows[i].removeChild(table.rows[i].cells[id]);
		}
		else
		{
			table.rows[i].cells[1].colSpan--;
		}
		
	}
	
}
////////////////////////////
function GridDelCoulmnOnEmptyHeader()
{
	var element;
	var table = this.GetTable();
	var i=1;

	while(table.rows[0].cells[i])
	{
		if(table.rows[0].cells[i].innerText == ' ')
		{
			// now let's delete the column
			this.DelCoulmnByFieldName(table.rows[0].cells[i].id);
			continue;
		}

		i++;
	}
}
////////////////////////////
function GridGetZoomColor(){return this.clr_cursor_zoom;}
////////////////////////////
function GridSetZoomColor(val){this.clr_cursor_zoom = val;}
////////////////////////////
function GridGetCursorColor(){return this.clr_cursor;}
////////////////////////////
function GridSetCursorColor(val){this.clr_cursor = val;}
////////////////////////////
