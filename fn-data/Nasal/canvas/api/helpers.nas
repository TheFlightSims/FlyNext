#-------------------------------------------------------------------------------
# canvas API helper functions
#-------------------------------------------------------------------------------
# 
var _getColor = func(color) {
    if (size(color) == 1)
        var color = color[0];

    if (isscalar(color))
        return color;
    if (!isvec(color))
        return debug.warn("Wrong type for color");
    if (size(color) < 3 or size(color) > 4)
        return debug.warn("Color needs 3 or 4 values (RGB or RGBA)");

    var str = 'rgb';
    if (size(color) == 4)
        str ~= 'a';
    str ~= '(';

    # rgb = [0,255], a = [0,1]
    for (var i = 0; i < size(color); i += 1) {
        str ~= (i > 0 ? ',' : '') ~ (i < 3 ? int(color[i] * 255) : color[i]);
    }
    return str ~ ')';
};

var _arg2valarray = func {
    var ret = arg;
    while (isvec(ret) and size(ret) == 1 and isvec(ret[0])) {
        ret = ret[0];
    }
    return ret;
}
