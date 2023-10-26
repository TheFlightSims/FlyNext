#
# canvas.draw library - compass rose module
# created 12/2018 by jsb
# WARNING: this is still under development, interfaces may change
#

var CompassRose = {
    VERSION: 1.0,
    Style: {
        new: func() {
            var obj = {
                parents: [CompassRose.Style, canvas.draw.marksStyle.new()],
                mark_count: 36,       # number of marks, count = 360 / interval
                label_count: 12,      # number of text labels (degrees)
                label_div: 10,        # >0 div. degr. by this for text labels
                circle_color: [255,255,255,1],
                mark_color:   [255,255,255,1],
                label_color:  [255,255,255,1],
                center_mark: 0,       # draw a mark in the center of the rose
                font: "sans",         # fontsize for labels
                font_weight: "bold",  # fontsize for labels
                fontsize: 0,          # fontsize for labels
                nesw: 1,              # replace labels 0,90,180,270 by N,E,S,W
            };
            obj.setMarkLength(0.1);
            obj.setSubdivisionLength(0.5);
            return obj;
        },

        setMarkCount: func(value) {
            me.mark_count = num(value) or 0;
            return me;
        },

        setLabelCount: func(value) {
            me.label_count = num(value) or 0;
            return me;
        },

        # divide course by this value before creating text label. (try 10, 1 or 0)
        setLabelDivisor: func(value) {
            me.label_div = num(value) or 10;
            return me;
        },

        setFontSize: func(value) {
            me.fontsize = num(value) or 26;
            return me;
        },
    },
};

# draw a compass rose
# cgroup    canvas group, marks and lables will be created as children
CompassRose.draw = func(cgroup, radius, style=nil) {
    if (style == nil) {
        style = me.Style.new();
    }
    cgroup = cgroup.createChild("group", "compass-rose");
    if (style.center_mark) {
        var center = cgroup.createChild("path","center");
        var l = radius * 0.1;
        center.setStrokeLineWidth(1).setColor(style.circle_color)
            .moveTo(-l,0).line(2*l,0).moveTo(0,-l).line(0,2*l);
    }
    if (style.baseline_width > 0) {
        var c = cgroup.createChild("path", "circle");
        c.circle(radius)
         .setStrokeLineWidth(style.baseline_width)
         .setColor(style.circle_color);
    }
    if (style.mark_count > 0) {
        var marks = canvas.draw.marksCircular(cgroup, radius, 360 / style.mark_count, 0, 360, style);
        marks.setStrokeLineWidth(style.mark_width);
    }
    var fontsize = style.fontsize;
    if (style.fontsize == 0) {
        fontsize = math.round(math.sqrt(radius) * 1.4);
    }
    if (style.label_count > 0) {
        var labels = cgroup.createChild("group", "labels")
            .createChildren("text", style.label_count);
        var offset = (style.mark_offset < 0 ? -1 : 1) * style.mark_length * radius;
        var rot = 2*math.pi/style.label_count;
        var font = canvas.font_mapper(style.font, style.font_weight);
        forindex (i; labels) {
            var t = n = int(i*360 / style.label_count);
            if (style.label_div > 0) t = int(n / style.label_div);
            var txt = sprintf("%d", t);
            if (style.nesw) {
                if (n == 0) txt = "N";
                elsif (n == 90) txt = "E";
                elsif (n == 180) txt = "S";
                elsif (n == 270) txt = "W";
            }
            labels[i]
                .setText(txt)
                .setFontSize(fontsize)
                .setFont(font)
                .setColor(style.label_color)
                .setAlignment("center-"~(style.mark_offset < 0 ? "top" : "bottom"))
                .setTranslation(0,-radius-offset)
                .setCenter(0,radius+offset)
                .setRotation(i*rot);
        }
    }
    return cgroup;
};
