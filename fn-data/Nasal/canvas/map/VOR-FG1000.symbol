# See: http://wiki.flightgear.org/MapStructure
# Class things:
var name = 'VOR_FG1000';
var parents = [DotSym];
var __self__ = caller(0)[0];
DotSym.makeinstance( name, __self__ );

SymbolLayer.get(name).df_style = {
	line_width: 3,
	scale_factor: 1,
	font: "LiberationFonts/LiberationSans-Regular.ttf",
	font_color: [0,0,0],
	font_size: 28,
	icon_color: [0.5, 0, 0.5],
	circle_color: [0.2,0.2,1.0],
	circle_radius: 64,
	show_labels: 1,
};


var element_type = "group"; # we want a group, becomes "me.element"

##
# used during initialization to populate the symbol cache with a VOR symbol
#
var drawVOR = func(group) {

	# Circle around the edge
	var circle = group.createChild("path")
		.moveTo(0 -circle_radius,0)
		.arcSmallCW(circle_radius, circle_radius, 0, 2 * circle_radius,0)
		.arcSmallCW(circle_radius, circle_radius, 0,-2 * circle_radius,0)
		.close()
		.setStrokeLineWidth(line_width)
		.setColor(circle_color)
		.set("z-index",-2);

	# Magnetic North marking.  Will be rotated later
	circle.moveTo(0, 0);
	circle.lineTo(0, -circle_radius);

	# 10-degree markings
	for (var i = 0; i < 36; i = i + 1) {
		theta = D2R * (i * 10.0);
		# Start at 90% of the circle radius
		var start_x = 0.9 * circle_radius * math.sin(theta);
		var start_y = -0.9 * circle_radius * math.cos(theta);
		var end_x = circle_radius * math.sin(theta);
		var end_y = -circle_radius * math.cos(theta);

		circle.moveTo(start_x, start_y);
		circle.lineTo(end_x, end_y);
	}

	# 5 - degree markings - 5% of radius
	for (var i = 0; i < 36; i = i + 1) {
		theta = D2R * (i * 10.0 + 5.0);
		# Start at 95% of the circle radius
		var start_x = 0.95 * circle_radius * math.sin(theta);
		var start_y = -0.95 * circle_radius * math.cos(theta);
		var end_x = circle_radius * math.sin(theta);
		var end_y = -circle_radius * math.cos(theta);

		circle.moveTo(start_x, start_y);
		circle.lineTo(end_x, end_y);
	}

}
var _name = name;

var init = func {
	# initialize the cached fix symbol
	var draw_fn = me.getOption('draw_function');
	if(typeof(draw_fn) != 'func')
		draw_fn = drawVOR;

	var cache = StyleableCacheable.new(
		name:_name,
		draw_func: draw_fn,
		cache: SymbolCache256x256,
		draw_mode: SymbolCache.DRAW_CENTERED,
		relevant_keys: ["line_width", "icon_color", "circle_color", "circle_radius"],
	);
	cache.render(me.element, me.style).setScale(me.style.scale_factor);

	# Rotate the symbol to take into account the magnetic variation for the VOR.
	me.element.setRotation(me.model.magvar * D2R);

	# Center icon
	me.element.createChild("path")
		.setRotation(- me.model.magvar * D2R)
		.moveTo(-15,0)
		.lineTo(-7.5,12.5)
		.lineTo(7.5,12.5)
		.lineTo(15,0)
		.lineTo(7.5,-12.5)
		.lineTo(-7.5,-12.5)
		.close()
		.setStrokeLineWidth(me.getStyle('line_width', 1))
		.setColor(me.getStyle('icon_color', [0,0.6,0.85]))
		.set("z-index",-2);


	# non-cached stuff: Symbol in use and labels.
	if (me.style.show_labels){
		var txt_offset = me.getStyle('text_offset', [3, 0]);
		var txt_alignment = me.getStyle('text_alignment', 'center-bottom');
		var txt_color = me.getStyle('text_color', [0,0.6,0.85]);
		var txt_bgcolor = me.getStyle('text_bgcolor', [0,0,0,0]);
		var txt_mode = me.getStyle('text_mode', canvas.Text.TEXT);
		var txt_padding = me.getStyle('text_padding', 0);
		var txt_size = me.getStyle('font_size', 14);

		me.text_fix = me.newText(me.model.id).
		setScale(me.style.scale_factor).
		setTranslation(txt_offset).
		setRotation(- me.model.magvar * D2R).
		setFontSize(txt_size).
		setAlignment(txt_alignment).
		setPadding(txt_padding).
		setDrawMode(txt_mode).
		setColor(txt_color).
		setColorFill(txt_bgcolor);
	}
}
var draw = func {me.callback('draw');};
