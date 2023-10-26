# See: http://wiki.flightgear.org/MapStructure

# Class things:
var name = 'GRID';
var parents = [LineSymbol];
var __self__ = caller(0)[0];
LineSymbol.makeinstance( name, __self__ );

SymbolLayer.get(name).df_style = { # style to use by default
	line_width: 1,
	color: [0.5,0.5,0.5],
	dash_array: [5,15,5,15],
};

var init = func {
	me.element.setColor(me.layer.style.color)
	.setStrokeLineWidth(me.layer.style.line_width)
	.setStrokeDashArray(me.layer.style.dash_array);
};
