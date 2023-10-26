# See: http://wiki.flightgear.org/MapStructure
# Class things:
var name = 'NDB';
var parents = [DotSym];
var __self__ = caller(0)[0];
DotSym.makeinstance( name, __self__ );

SymbolLayer.get(name).df_style = {
	line_width: 3,
	scale_factor: 1,
	font: "LiberationFonts/LiberationSans-Regular.ttf",
	font_color: [0,0,0],
	font_size: 28,
	color: [0.5, 0, 0.5],
	dash_array: [0,2,0,2],
	show_labels: 1,
};


var element_type = "group"; # we want a group, becomes "me.element"

##
# used during initialization to populate the symbol cache with a FIX symbol
#
var drawNDB = func(group) {
	group.createChild("path")
		.moveTo(-4, 0)
		.horizTo(4)
		.moveTo(0, -4)
		.vertTo(4)
		.moveTo(-8, 0)
		.arcSmallCW(8,8,0,16,0)
		.arcSmallCW(8,8,0,-16,0)
		.moveTo(-15,0)
		.arcSmallCW(15,15,0,30,0)
		.arcSmallCW(15,15,0,-30,0)
		.setStrokeLineWidth(line_width)
		.setStrokeDashArray(dash_array)
		.setColor(color);
}
var _name = name;

var init = func {
	# initialize the cached fix symbol
	var draw_fn = me.getOption('draw_function');
	if(typeof(draw_fn) != 'func')
		draw_fn = drawNDB;

	var cache = StyleableCacheable.new(
		name:_name,
		draw_func: draw_fn,
		cache: SymbolCache32x32,
		draw_mode: SymbolCache.DRAW_CENTERED,
		relevant_keys: ["line_width", "color", "dash_array"],
	);
	cache.render(me.element, me.style).setScale(me.style.scale_factor);

	var txt_offset = me.getStyle('text_offset', [3, 0]);
	var txt_alignment = me.getStyle('text_alignment', 'left-bottom');
	var txt_color = me.getStyle('text_color', [0,0.6,0.85]);
	var txt_bgcolor = me.getStyle('text_bgcolor', [0,0,0,0]);
	var txt_mode = me.getStyle('text_mode', canvas.Text.TEXT);
	var txt_padding = me.getStyle('text_padding', 0);
	# non-cached stuff:
	if (me.style.show_labels){
		me.text_fix = me.newText(me.model.id).
		setScale(me.style.scale_factor).
		setTranslation(txt_offset).
		setAlignment(txt_alignment).
		setPadding(txt_padding).
		setDrawMode(txt_mode).
		setColor(txt_color).
		setColorFill(txt_bgcolor);
	}
}
var draw = func {me.callback('draw');};
