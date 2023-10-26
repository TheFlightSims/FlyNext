
# generic widgets for canvas dialogs
# Thorsten Renk 2018

# widget definitions ##############################################################

var cdlg_widget_box = {
	new: func (root, width, height, color, fill_color ) {
 	var wb = { parents: [cdlg_widget_box] };
		
	wb.width = width;
	wb.height = height;
	wb.color = color;
	wb.fill_color = fill_color;

	wb.graph = root.createChild("group", "box_widget");

	#var data = [[0.0, 0.0], [0.0, height], [width, height], [width, 0.0], [0.0, 0.0]];
	
	var data = [[0.0, 0.0], [-0.5 * width, 0.0], [-0.5*width, -height], [0.5*width, -height], [0.5*width, 0.0], [0.0, 0.0]];

	wb.frame = wb.graph.createChild("path", "")
        .setStrokeLineWidth(2)
        .setColor(color)
	.moveTo(data[0][0], data[0][1]);
	for (var i = 0; (i< size(data)-1); i=i+1) 
		{wb.frame.lineTo(data[i+1][0], data[i+1][1]);}

	wb.fill = wb.graph.createChild("path", "")
        .setStrokeLineWidth(2)
        .setColor(color)
	.setColorFill(fill_color)
	.moveTo(data[0][0], data[0][1]);
	for (var i = 0; (i< size(data)-1); i=i+1) 
		{wb.fill.lineTo(data[i+1][0], data[i+1][1]);}

	return wb;
	},


	setTranslation: func (x,y) {
		me.graph.setTranslation(x,y);

	},

	setPercentageHt: func (x) {

		if (x > 1.0)
			{x = 1.0;}
		else if (x < 0.0) {x = 0.0;}

		var red_ht = me.height * x;

		var cmd = [canvas.Path.VG_MOVE_TO, canvas.Path.VG_LINE_TO,
	  		canvas.Path.VG_LINE_TO,canvas.Path.VG_LINE_TO,canvas.Path.VG_LINE_TO];

		var draw = [0.0, 0.0, -0.5 * me.width, 0.0, -0.5*me.width, -red_ht, 0.5*me.width, -red_ht, 0.5*me.width, 0.0, 0.0, 0.0];


		me.fill.setData(cmd, draw);

	},

	setContextHelp: func (f) {

			me.frame.addEventListener("mouseover", func(e) {
			fgcommand("set-cursor", props.Node.new({'cursor':'left-right'}));
			f("mouseover");
		  	});

			me.frame.addEventListener("mouseout", func(e) {
			fgcommand("set-cursor", props.Node.new({'cursor':'inherit'}));
			f("mouseout");
		  	});

			me.fill.addEventListener("mouseover", func(e) {
			fgcommand("set-cursor", props.Node.new({'cursor':'left-right'}));
			f("mouseover");
		  	});

			me.fill.addEventListener("mouseout", func(e) {
			fgcommand("set-cursor", props.Node.new({'cursor':'inherit'}));
			f("mouseout");
		  	});



	},


};



# tank gauge ##############################################################

var cdlg_widget_tank = {
	new: func (root, radius, color, fill_color) {
	 	var wtk = { parents: [cdlg_widget_tank] };
		
		wtk.radius = radius;
		wtk.color = color;
		wtk.fill_color = fill_color;

		wtk.graph = root.createChild("group", "tank_widget");

		var data = [];


		for (var i = 0; i< 33; i=i+1)
			{
			var phi = i * 2.0 * math.pi/32.0;

			var x = radius * math.cos(phi);
			var y = radius * math.sin(phi);

			append(data, [x,y]);
			}


		wtk.frame = wtk.graph.createChild("path", "")
		.setStrokeLineWidth(2)
		.setColor(color)
		.moveTo(data[0][0], data[0][1]);
		for (var i = 0; (i< size(data)-1); i=i+1) 
			{wtk.frame.lineTo(data[i+1][0], data[i+1][1]);}

		wtk.fill = wtk.graph.createChild("path", "")
		.setStrokeLineWidth(2)
		.setColor(color)
		.setColorFill(fill_color)
		.moveTo(data[0][0], data[0][1]);
		for (var i = 0; (i< size(data)-1); i=i+1) 
			{wtk.fill.lineTo(data[i+1][0], data[i+1][1]);}



		return wtk;
	},

	setTranslation: func (x,y) {
		me.graph.setTranslation(x,y);

	},

	setPercentage: func (x) {

		if (x > 1.0)
			{x = 1.0;}
		else if (x < 0.0) {x = 0.0;}

		var red_ht = me.radius -2.0 * me.radius * x;
		var arg = me.radius * me.radius - red_ht * red_ht;
		if (arg < 0.0) {arg = 0.0;}

		var xlimit = math.sqrt(arg);
		
		var draw = [];
		var cmd = [];

		for (var i = 0; i< 33; i=i+1)
			{
			var phi = i * 2.0 * math.pi/32.0;

			var x = me.radius * math.cos(phi);
			var y = me.radius * math.sin(phi);

			
			if (y < red_ht) { y = red_ht; if (x>0.0) {x = xlimit;} else {x=-xlimit;} }

			append(draw,x);
			append(draw,y);
			append(cmd, canvas.Path.VG_LINE_TO);
			}

		cmd[0] = canvas.Path.VG_MOVE_TO; 

		me.fill.setData(cmd, draw);		

	},


	setContextHelp: func (f) {

			me.frame.addEventListener("mouseover", func(e) {
			fgcommand("set-cursor", props.Node.new({'cursor':'left-right'}));
			f("mouseover");
		  	});

			me.frame.addEventListener("mouseout", func(e) {
			fgcommand("set-cursor", props.Node.new({'cursor':'inherit'}));
			f("mouseout");
		  	});

			me.fill.addEventListener("mouseover", func(e) {
			fgcommand("set-cursor", props.Node.new({'cursor':'left-right'}));
			f("mouseover");
		  	});

			me.fill.addEventListener("mouseout", func(e) {
			fgcommand("set-cursor", props.Node.new({'cursor':'inherit'}));
			f("mouseout");
		  	});



	},


};


# property display labels ##############################################################

var cdlg_widget_property_label = {
	new: func (root, text, text_color = nil, color = nil, fill_color = nil ) {
 	var pl = { parents: [cdlg_widget_property_label] };
		
	pl.text_string = text;
	pl.unit_string = "";
	pl.unit_set = 0;
	pl.size = utf8.size(text);
	pl.limits = 0;
	pl.limit_upper = 1e6;
	pl.limit_lower = -1e6;
	pl.limit_violation = 0;

	if (text_color == nil) {text_color = [0.0, 0.0, 0.0];}
	pl.text_color = text_color;

	pl.font_scale_factor = 1.0;

	if (color == nil) 
		{pl.box_mode = 0;}
	else
		{
		pl.color = color;
		pl.box_mode = 1;
		}

	if (fill_color == nil)
		{
		pl.box_fill = 0;
		}
	else
		{
		pl.box_fill = 1;
		pl.fill_color = fill_color;
		}



	pl.graph = root.createChild("group", "property_label");



	if (pl.box_mode == 1)
		{
		var height = 25.0;
		var width = 10.0 * pl.size;
		var data = [[0.0, -0.8 * height], [-0.5 * width, -0.8 * height], [-0.5 * width, 0.2 * height], [0.5 * width, 0.2 * height], [0.5 * width, -0.8 * height],[0.0, -0.8 * height]];
		pl.box = pl.graph.createChild("path", "")
		.setStrokeLineWidth(2)
		.setColor(color)
		.moveTo(data[0][0], data[0][1]);
		for (var i = 0; (i< size(data)-1); i=i+1) 
			{pl.box.lineTo(data[i+1][0], data[i+1][1]);}

		if (pl.box_fill == 1)
			{
			pl.box.setColorFill(fill_color);
			}
		}

	
	pl.text = pl.graph.createChild("text")
      		.setText(text)
		.setColor(text_color)
		.setFontSize(15)
		#.setFont("LiberationFonts/LiberationMono-Bold.ttf")
		.setFont("LiberationFonts/LiberationSans-Bold.ttf")
		.setAlignment("center-bottom")
		.setRotation(0.0);

	pl.text.enableUpdate();

	pl.text.setTranslation(0.0, pl.getOffset(text));
	if (pl.box_mode == 1)
		{
		pl.box.setTranslation(0.0, -pl.getOffset(text));
		}
	
	return pl;
	},

	setTranslation: func (x,y) {
		me.graph.setTranslation(x,y);

	},

	updateText: func (text) {

		me.text.updateText(text);
	},

	setText: func (text) {

		me.text.setText(text);
	},
	
	
	setValue: func (value) {
	
		if (me.limits == 1)
			{
			me.check_limits(value);
			}
		me.text.updateText(me.formatValue(value));
	},
	
	formatValue: func (value) {
	
		var textString = me.formatFunction(value);
		return textString~me.unit_text;
	},
	
	
	formatFunction: func (value) {
	
		return sprintf("%0.0f", value);	
	},
	
	
	setUnit: func (unit) {
		
		me.unit_text = unit;
		me.unit_set = 1;
	
	},
	
	setLimits: func (lLower, lUpper) {
		me.limits = 1;
		me.limit_upper = lUpper;
		me.limit_lower = lLower;
	
	},
	
	check_limits: func (value) {
	
		if ((value < me.limit_lower) or (value > me.limit_upper))
			{
			if (me.limit_violation == 0)
				{
				me.text.setColor(1.0, 0.0, 0.0);
				me.limit_violation = 1;
				}
			}
		else	
			{
			if (me.limit_violation == 1)
				{
				me.text.setColor(me.text_color);
				me.limit_violation = 0;
				}
			}
	
	},

	setFont: func (font) {

		me.text.setFont(font);
	},

	setFontSize: func (size) {

		me.font_scale_factor = size/15.0;
		me.text.setFontSize(size);
	},

	setScale: func (x,y = nil) {

		me.graph.setScale(x,y);
	},

	setBoxScale: func (x,y = nil) {

		if (me.box_mode == 0) {return;}
		me.box.setScale(x,y);
	},

 

	getOffset: func (string) {
		return 0.0;
		var flag = 0;
		for (var i = 0; i < utf8.size(string); i=i+1)
			{
			var char = utf8.strc(string, i);

			if ((char == "y") or (char == "g") or (char == "j") or (char == "p") or (char == "q"))
				{
				flag == 1; break;
				}
			}
		if (flag == 0) {return -2.0;}
		else {return 0.0;}
	},

};

# infobox  ##############################################################

var cdlg_widget_infobox = {
	new: func (root, width, title, texts, corner_radius = 0.0, frame_color = nil, title_color = nil, title_fill = nil, text_color = nil, text_fill = nil) {

		var ib = { parents: [cdlg_widget_infobox] };
		
		ib.width = width;
		ib.title = title;
		ib.texts = texts;

		ib.unit = "";

		if (title_color == nil) {title_color = [0.0, 0.0, 0.0];}
		if (text_color == nil) {text_color = [0.0, 0.0, 0.0];}
		if (frame_color == nil) {frame_color = [0.0, 0.0, 0.0];}

		ib.title_color = title_color;
		ib.title_fill =  title_fill;
		ib.text_color = text_color;
		ib.text_fill = text_fill;
		ib.frame_color = frame_color;

		ib.font_size = 15;
		ib.num_lines = size(texts);
		ib.num_columns = size(texts[0]);
		ib.font_height = 25.0;

		ib.height = (ib.num_lines + 1) * ib.font_height;
		ib.corner_radius = corner_radius;


		ib.graph = root.createChild("group", "infobox");



		var data = [];
		var point = [0.0, -0.7* ib.font_height]; append(data, point);

		point = [ib.width * 0.5 - ib.corner_radius, - 0.7* ib.font_height]; append(data, point);
		point = [ib.width * 0.5 - ib.corner_radius * 0.617, - 0.7* ib.font_height + ib.corner_radius * 0.076]; append(data, point);
		point = [ib.width * 0.5 - ib.corner_radius * 0.293, - 0.7* ib.font_height + ib.corner_radius * 0.293]; append(data, point);
		point = [ib.width * 0.5 - ib.corner_radius * 0.076, - 0.7* ib.font_height + ib.corner_radius * 0.617]; append(data, point);
		point = [ib.width * 0.5, - 0.7* ib.font_height + ib.corner_radius]; append(data, point);

		point = [ib.width * 0.5, 0.3 * ib.font_height]; append(data, point);
		point = [-ib.width * 0.5, 0.3 * ib.font_height]; append(data, point);

		point = [-ib.width * 0.5, -0.7* ib.font_height + ib.corner_radius]; append(data, point);
		point = [-ib.width * 0.5 + ib.corner_radius * 0.076, -0.7* ib.font_height + ib.corner_radius * 0.617]; append(data, point);
		point = [-ib.width * 0.5 + ib.corner_radius * 0.293, -0.7* ib.font_height + ib.corner_radius * 0.293]; append(data, point);
		point = [-ib.width * 0.5 + ib.corner_radius * 0.617, -0.7* ib.font_height + ib.corner_radius * 0.076]; append(data, point);
		point = [-ib.width * 0.5 + ib.corner_radius, -0.7* ib.font_height]; append(data, point);
		point = [0.0, - 0.7 * ib.font_height]; append(data, point);

		ib.title_frame = ib.graph.createChild("path", "")
		.setStrokeLineWidth(2)
		.setColor(ib.frame_color)
		.moveTo(data[0][0], data[0][1]);
		for (var i = 0; (i< size(data)-1); i=i+1) 
			{ib.title_frame.lineTo(data[i+1][0], data[i+1][1]);}

		if (ib.title_fill != nil)
			{
			ib.title_frame.setColorFill(ib.title_fill);
			}


		data = [];


		point = [0.0, 0.3* ib.font_height]; append(data, point);
		point = [ib.width * 0.5, 0.3 * ib.font_height]; append(data, point);

		point = [ib.width * 0.5, 10.0 + ib.num_lines *  ib.font_height - ib.corner_radius]; append(data, point);
		point = [ib.width * 0.5 - ib.corner_radius * 0.293, 10.0 + ib.num_lines *  ib.font_height - ib.corner_radius * 0.293]; append(data, point);
		point = [ib.width * 0.5 - ib.corner_radius, 10.0 + ib.num_lines *  ib.font_height]; append(data, point);


		point = [-ib.width * 0.5 + ib.corner_radius, 10.0 + ib.num_lines *  ib.font_height]; append(data, point);
		point = [-ib.width * 0.5 + ib.corner_radius * 0.293, 10.0 + ib.num_lines *  ib.font_height - ib.corner_radius * 0.293]; append(data, point);
		point = [-ib.width * 0.5, 10.0 + ib.num_lines *  ib.font_height - ib.corner_radius]; append(data, point);

		point = [-ib.width * 0.5, 0.3 * ib.font_height]; append(data, point);
		point = [0.0, 0.3 * ib.font_height]; append(data, point);

		ib.text_frame = ib.graph.createChild("path", "")
		.setStrokeLineWidth(2)
		.setColor(ib.frame_color)
		.moveTo(data[0][0], data[0][1]);
		for (var i = 0; (i< size(data)-1); i=i+1) 
			{ib.text_frame.lineTo(data[i+1][0], data[i+1][1]);}

		if (ib.text_fill != nil)
			{
			ib.text_frame.setColorFill(ib.text_fill);
			}

		var offset = me.getOffset(title);

		ib.title_text = ib.graph.createChild("text")
	      		.setText(title)
			.setColor(text_color)
			.setFontSize(15)
			.setFont("LiberationFonts/LiberationSans-Bold.ttf")
			.setAlignment("center-bottom")
			.setTranslation(0, offset)
			.setRotation(0.0);

		ib.texts = [];
		ib.values = [];

		for (var i = 0; i< ib.num_lines; i=i+1)
			{

			var translation = 0.0;
			var alignment = "center-bottom";

			if (ib.num_columns == 2)
				{
				translation = -0.45 * ib.width;
				alignment = "left-bottom";
				}



			var tmp_text = ib.graph.createChild("text")
	      		.setText(texts[i][0])
			.setColor(text_color)
			.setFontSize(15)
			.setFont("LiberationFonts/LiberationSans-Bold.ttf")
			.setAlignment(alignment)
			.setTranslation(translation, 5.0 + (i+1) * ib.font_height)
			.setRotation(0.0);

			tmp_text.enableUpdate();

			if (ib.num_columns == 2)
				{
				append (ib.texts, tmp_text);
				}
			else
				{
				append (ib.values, tmp_text);
				}

			if (ib.num_columns == 2)
				{
				var tmp_value = ib.graph.createChild("text")
		      		.setText(texts[i][1])
				.setColor(text_color)
				.setFontSize(15)
				.setFont("LiberationFonts/LiberationSans-Bold.ttf")
				.setAlignment("left-bottom")
				.setTranslation(0.05 * ib.width, 5.0 + (i+1) * ib.font_height)
				.setRotation(0.0);

				tmp_value.enableUpdate();

				append (ib.values, tmp_value);

				}
			


			}


		return ib;

	}, 

	setTranslation: func (x,y) {

		me.graph.setTranslation(x,y);

	},


	setText: func (i, text) {
		
		me.texts[i].updateText(text);

	},

	setValueText: func (i, text) {
		
		me.values[i].updateText(text);

	},

	setUnit: func (unit) {

		me.unit = unit;

	},

	setValue: func (i, value) {
		
		var text = me.formatFunction(value)~me.unit;

		me.values[i].updateText(text);
	

	},

	formatFunction: func (value) {

		return sprintf("%d", value);

	},

	getOffset: func (string) {
		var flag = 0;
		for (var i = 0; i < utf8.size(string); i=i+1)
			{
			var char = utf8.strc(string, i);
			#print (char);

			if ((char == 112) or (char == 121) or (char == 106) or (char == 103) or (char == 113))
				{
				flag = 1; break;
				}
			}
		if (flag == 1) {return 4.0;}
		else {return 0.0;}
	},


};

# image stack ##############################################################

var cdlg_widget_img_stack = {

	new: func (root, stack, width, height, button_flag = 0) {
	 	var is = { parents: [cdlg_widget_img_stack] };
		
		is.root = root;
		is.width = width;
		is.height = height;
		is.index = 0;	
		is.button_flag = button_flag;

		is.n_elements = size(stack);
		
		is.stack = [];
		is.graph = root.createChild("group", "stack");

		for (var i = 0; i< is.n_elements; i = i+1)
			{

			
			var tmp_image = is.graph.createChild("image")
					.setFile(stack[i]);

			tmp_image.setVisible(0);

			append(is.stack, tmp_image);
			}

		is.stack[0].setVisible(1);


		is.graph.addEventListener("click", func() {

			if (is.button_flag == 0)
				{is.increment();}
			else if (is.button_flag == 1)
			   	{is.depress();}

			is.f();
		  	});

		return is;

	},

	setTranslation: func (x,y) {


		me.graph.setTranslation(x,y);

	},

	
	increment: func {

		me.index += 1;

		if (me.index == me.n_elements) {me.index = 0;}

		for (var i=0; i< me.n_elements; i=i+1)
			{
			if (me.index == i)
				{
				me.stack[i].setVisible(1);
				}
			else
				{
				me.stack[i].setVisible(0);
				}
			
			}

	},

	set_index: func (index) {

		me.index = index;

		if ((me.index > me.n_elements) or (me.index < 0)) {return;}

		for (var i=0; i< me.n_elements; i=i+1)
			{
			if (me.index == i)
				{
				me.stack[i].setVisible(1);
				}
			else
				{
				me.stack[i].setVisible(0);
				}
			
			}

	},

	depress: func {

		me.index = 1;
		me.stack[1].setVisible(1);
		me.stack[0].setVisible(0);

		settimer ( func {
			me.index = 0;
			me.stack[1].setVisible(0);
			me.stack[0].setVisible(1);

			}, 0.2);

	},

	setContextHelp: func (f) {

			me.graph.addEventListener("mouseover", func(e) {
			fgcommand("set-cursor", props.Node.new({'cursor':'left-right'}));
			f("mouseover");
		  	});

			me.graph.addEventListener("mouseout", func(e) {
			fgcommand("set-cursor", props.Node.new({'cursor':'inherit'}));
			f("mouseout");
		  	});



	},

	f: func {


		return;

	},



};

# analog gauge ##############################################################

var cdlg_widget_analog_gauge = {
	new: func (root, gauge_bg, gauge_needle , width, height) {
 	var ag = { parents: [cdlg_widget_analog_gauge] };

	ag.graph = root.createChild("group", "analog gauge");

	ag.gauge_background = ag.graph.createChild("image")
			.setFile(gauge_bg);

	ag.gauge_needle = ag.graph.createChild("image")
			.setFile(gauge_needle);

	ag.gauge_needle.setCenter(127,127);

	return ag;
	},

	setTranslation: func (x,y) {

		me.graph.setTranslation(x,y);

	},


	setAngle: func (angle) {

		me.gauge_needle.setRotation(angle);

	},

};


# clickspots ##############################################################

var cdlg_clickspot = {

	new: func (x,y,rw,rh,tab,type) {
	 	var cs = { parents: [cdlg_clickspot] };
		
		cs.x = x;
		cs.y = y;
		cs.rw = rw;
		cs.rh = rh;
		cs.fraction_up = 0.0;
		cs.fraction_right = 0.0;
		cs.tab = tab;
		cs.type = type;

		return cs;
	},

	check_event : func (click_x, click_y) {

		if (me.type = "rect") 
			{
			if ((math.abs(click_x - me.x) < me.rw) and (math.abs(click_y - me.y) < me.rh)) 					{
				me.update_fractions (click_x, click_y);
				me.f();
				return 1;
				}
			}
		else if (me.type = "circle") 
			{
			var click_r = math.sqrt((click_x - me.x) * (click_x - me.x) + (click_y - me.y) * (click_y - me.y));

			if (click_r < me.rw)
				{
				me.update_fractions (click_x, click_y);
				me.f();
				return 1;
				}
			}
		return 0;
	},

	update_fractions: func (click_x, click_y) {

		var y_rel = (click_y - me.y);
		var x_rel = (click_x - me.x);
		me.fraction_up = (-y_rel + me.rw)/(2.0 * me.rw);
		me.fraction_right = (x_rel + me.rw)/(2.0 * me.rw);

	},

	get_fraction_up: func {

		return me.fraction_up;

	},

	get_fraction_right: func {

		return me.fraction_right;

	},

	f: func {

		return;

	},

};

