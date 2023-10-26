# See: http://wiki.flightgear.org/MapStructure
# Class things:
var name = 'PARKING';
var parents = [DotSym];
var __self__ = caller(0)[0];
DotSym.makeinstance( name, __self__ );

var element_type = "group"; # we want a group, becomes "me.element"
var rwys = nil;

var init = func {
	var apt=airportinfo(me.model.id);
	var style = me.layer.style;
	var svg_path = style.svg_path;

	var group = me.element.createChild("group", "parking-"~apt.id);
	foreach(var park; apt.parking()) {
		var p = me.element.createChild("group", "parking-"~park.name);
		p.setGeoPosition(park.lat, park.lon);

		if (svg_path != nil) {
			canvas.parsesvg(p, svg_path);
		} else {
			p.createChild("path", name ~ " icon" )
			.moveTo(-10,-10)
			.lineTo(10,10)
			.moveTo(10,-10)
			.lineTo(-10,10)
			.close()
			.setColor(style.color_default)
			.setStrokeLineWidth(style.line_width)
			.setScale(style.scale_factor);
		}

		p.createChild("text", "parking-" ~ park.name)
			.setDrawMode( canvas.Text.ALIGNMENT
			            + canvas.Text.TEXT )
			.setTranslation([style.scale_factor * style.text_offset[0], style.scale_factor * style.text_offset[1]])
			.setText(park.name)
			.setFont("LiberationFonts/LiberationSans-Regular.ttf")
			.setColor(style.label_font_color)
			.setFontSize(style.label_font_size, 1.3)
			.setScale(style.scale_factor);
	}
};
var draw = func;
