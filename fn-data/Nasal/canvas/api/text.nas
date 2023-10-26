#-------------------------------------------------------------------------------
# canvas.Text
#-------------------------------------------------------------------------------
# Class for a text element on a canvas
#
var font_mapper = func(family = nil, weight = nil, style = nil, options = nil)
{
    var defaults = {
        "default-font-family": "LiberationSans",
        "default-font-weight": "",
        "default-font-style": "",
    };

    # setup defaults if no options are given
    if (options == nil) {
        options = defaults;
    }
    if (!ishash(options)) {
        logprint(LOG_ALERT, "font_mapper: options must be a hash!")
    }

    # use defaults for missing arguments
    if (family == nil) {
        family = options["default-font-family"] or defaults["default-font-family"];
    }
    if (weight == nil) {
        weight = options["default-font-weight"] or defaults["default-font-weight"];
    }
    if (style == nil) {
        style = options["default-font-style"] or defaults["default-font-style"];
    }

    if (isfunc(options["font-mapper"])) {
        var font = options["font-mapper"](family, weight, style);
        if (font != nil) {
            return font;
        }
    }

    # Remove '' that Inkscape puts around font names containing spaces
    if (left(family, 1) == "'") family = substr(family, 1);
    if (right(family, 1) == "'") family = substr(family, 0, size(family) - 1);

    # map generic Inkscape sans serif to our default font
    if (string.lc(family) == "sans" or string.lc(family) == "sans-serif") {
        family = "LiberationSans";
    }
    if (left(family, 10) == "Liberation") {
        style = style == "italic" ? "Italic" : "";
        weight = weight == "bold" ? "Bold" : "";

        var s = weight~style;
        if (s == "") s = "Regular";

        return "LiberationFonts/"~string.replace(family, " ", "")~"-"~s~".ttf";
    }

    return "LiberationFonts/LiberationMono-Bold.ttf";
};

var Text = {
    new: func(ghost) {
        var obj = {
            parents: [Text, Element.new(ghost)],
        };
        return obj;
    },

    # Set the text
    setText: func(text) {
        me.set("text", typeof(text) == "scalar" ? text : "");
    },

    getText: func() {
        return me.get("text");
    },

    # enable reduced property I/O update function
    enableUpdate: func () {
        me._lasttext = "INIT_BLANK";
        me.updateText = func (text)
        {
            if (text == me._lasttext) {return;}
            me._lasttext = text;
            me.set("text", typeof(text) == "scalar" ? text : "");
        };
    },

    # reduced property I/O text update template
    updateText: func (text) {
        die("updateText() requires enableUpdate() to be called first");
    },


    # enable fast setprop-based text writing
    enableFast: func () {
        me._node_path = me._node.getPath()~"/text";
        me.setTextFast = func(text) {
            setprop(me._node_path, text);
        };
    },

    # fast, setprop-based text writing template
    setTextFast: func (text) {
        die("setTextFast() requires enableFast() to be called first");
    },

    # append text to an existing string
    appendText: func(text) {
        me.set("text", (me.get("text") or "")~(typeof(text) == "scalar" ? text : ""));
    },

    # Set alignment
    #
    #    @param align String, one of:
    #     left-top
    #     left-center
    #     left-bottom
    #     center-top
    #     center-center
    #     center-bottom
    #     right-top
    #     right-center
    #     right-bottom
    #     left-baseline
    #     center-baseline
    #     right-baseline
    #     left-bottom-baseline
    #     center-bottom-baseline
    #     right-bottom-baseline
    #
    setAlignment: func(align) {
        me.set("alignment", align);
    },

    # Set the font size
    setFontSize: func(size, aspect = 1) {
        me.setDouble("character-size", size);
        me.setDouble("character-aspect-ratio", aspect);
    },

    # Set font (by name of font file)
    setFont: func(name) {
        me.set("font", name);
    },

    # Enumeration of values for drawing mode:
    TEXT:               0x01, # The text itself
    BOUNDINGBOX:        0x02, # A bounding box (only lines)
    FILLEDBOUNDINGBOX:  0x04, # A filled bounding box
    ALIGNMENT:          0x08, # Draw a marker (cross) at the position of the text
    # Set draw mode. Binary combination of the values above. Since I have not
    # found a bitwise "or" we have to use a "+" instead.
    # e.g. my_text.setDrawMode(Text.TEXT + Text.BOUNDINGBOX);
    setDrawMode: func(mode) {
        me.setInt("draw-mode", mode);
    },

    # Set bounding box padding
    setPadding: func(pad) {
        me.setDouble("padding", pad);
    },

    setMaxWidth: func(w) {
        me.setDouble("max-width", w);
    },

    setColor: func {
        me.set("fill", _getColor(arg));
    },

    getColor: func {
        me.get("fill");
    },

    setColorFill: func {
        me.set("background", _getColor(arg));
    },

    getColorFill: func {
        me.get("background");
    },
};
