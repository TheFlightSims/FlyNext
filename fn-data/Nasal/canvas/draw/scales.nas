#
# canvas.draw library - scale module for speed tape etc.
# created 12/2018 by jsb
#
# The Scale class combines draw.marks* with text labels to create scales/gauges
# to build speed tape, compass etc.

var Scale = {

    # see also canvas.draw.marksStyle
    Style: {
        new: func() {
            var obj = {
                parents: [Scale.Style, canvas.draw.marksStyle.new()],
                orientation: "u",
                spacing: 20,            # spacing in pixel
                label_interval: 1,      # one txt every n marks
                label_distance_abs: 0,  # distance between ticks and text labels in px
                label_distance_rel: 1.1,  # distance in %mark_length
                mark_color: [255,255,255,1],
                label_color: [255,255,255,1],
                fontsize: 16,           # fontsize for labels
            };
            return obj;
        },

        # the 'draw direction' for a linear scale (up, down, left, right)
        setOrientation: func(value) {
            me.orientation = chr(string.tolower(value[0]));
            if (me.orientation == "v") me.orientation = "d";
            if (me.orientation == "h") me.orientation = "r";
            return me;
        },

        setFontSize: func(value) {
            me.fontsize = num(value) or 16;
            return me;
        },

        setSpacing: func(value) {
            me.spacing = num(value) or 10;
            return me;
        },

        # draw one text label every <value> marks
        setLabelInterval: func(value) {
            me.label_interval = num(value) or 1;
            return me;
        },

        # Distance of text label to mark in pixel (be careful when resizing).
        # See also setLabelDistanceRel()
        setLabelDistanceAbs: func(value) {
            me.label_distance_abs = num(value) or 0;
            return me;
        },

        # Distance of text label to mark in %mark_length (easy scaling).
        setLabelDistanceRel: func(value) {
            me.label_distance_rel = num(value) or 1.1;
            return me;
        },

        # get alignment of text label for linear scales based on style params
        getAlignmentString: func() {
            if (me.orientation == "d") {
                return (me.mark_offset < 0 ? "right" : "left")~"-center";
            }
            elsif (me.orientation == "u") {
                return (me.mark_offset < 0 ? "right" : "left")~"-center";
            }
            elsif (me.orientation == "r") {
                return "center-"~(me.mark_offset > 0 ? "top" : "bottom");
            }
            elsif (me.orientation == "l") {
                return "center-"~(me.mark_offset > 0 ? "top" : "bottom");
            }
            else {
                return "center-center";
            }
        },
    },
};


# draw a scale on canvas group
# start     first value of scale
# count     number of values to draw
# increment value to add (can be negative)
Scale.draw = func(cgroup, start, count, increment, style=nil) {
    if (style == nil) {
        style = me.Style.new();
    }
    var label_count = count; #math.floor(math.abs(stop - start) / increment);
    if (label_count < 2) {
        return false;
    }
    var marks = canvas.draw.marksLinear(cgroup, style.orientation, label_count * style.label_interval, style.spacing, style);
    marks.setStrokeLineWidth(style.mark_width);
    var labels = cgroup.createChild("group", "labels")
        .createChildren("text", label_count);

    var length = style.spacing * style.mark_length;
    var offset = style.mark_offset * length * style.label_distance_rel;
    offset += (offset > 0) ? style.label_distance_abs : -style.label_distance_abs;
    var alignment = style.getAlignmentString();
    forindex (i; labels) {
        var txt = sprintf("%d", start + i * increment);
        var translation = i * style.spacing * style.label_interval;
        labels[i]
            .setText(txt)
            .setAlignment(alignment)
            .setFontSize(style.fontsize)
            .setColor(style.label_color);
        if (style.orientation == "d") {
            labels[i].setTranslation(offset, translation);
        }
        elsif (style.orientation == "u") {
            labels[i].setTranslation(offset, -translation);
        }
        elsif (style.orientation == "r") {
            labels[i].setTranslation(translation, offset);
        }
        elsif (style.orientation == "l") {
            labels[i].setTranslation(-translation, offset);
        }
    }
    return cgroup;
};
