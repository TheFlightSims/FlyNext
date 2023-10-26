# XML Dialog - XML dialog object without using PUI
# SPDX-FileCopyrightText: (C) 2022 James Turner <james@flightgear.org>
# SPDX-License-Identifier: GPL-2.0-or-later

# alias this module to keep things somewhat readable
var cwidgets = canvas.gui.widgets;

# This is the Nasal peer of a dialog defined by XML
# it manages creating some top level Canvas (eg a Window) according
# to the XML data
var XMLDialog = {

init: func(dialogProps)
{
    var d = me.dialog();
    var sz = [d.width, d.height];
    me._window = canvas.Window.new(sz, "dialog", d.name);
    
    # FIXME: lookup translated dialog name, this is the 
    # key string here
    me._window.setTitle(d.name);

    var m = me;
    me._window.del = func { 
        m.onWindowClosed();
    }
},

didBuild: func()
{
    var ourCanvas = me._window.getCanvas(1); # create, probably
    ourCanvas.set("background", canvas.style.getColor("bg_color"));
    var rootCanvasGroup = ourCanvas.createGroup();

    # get the root XMLObject, almost certainly a container of 
    # some kind. (eg frame / group / scroll area)
    var rootObject = me.dialog().root;
    
    # show the root object inside our Canvas group. We could delay this
    # until we are made visible to make things more efficient/lazy
    rootObject.show(rootCanvasGroup);
    ourCanvas.setLayout(rootObject.layoutItem());
},

# this is the callback from the canvas.Window: we request a close of
# the dialog, which will end up with us in 'onClosed'
onWindowClosed: func
{
    logprint(LOG_WARN, "XMLDialog window was requested to closed");
    me.dialog().close();
},

onBringToFront: func()
{
    me._window.raise();
},

onGeometryChanged: func()
{
    var d = me.dialog();
    logprint(LOG_INFO, "Dialog geometry is now:" ~ d.x ~ ", " ~ d.y ~ " w:" ~ d.width ~ ", h:" ~ d.height);
    me._window.setPosition(d.x, d.y);
    me._window.setSize(d.width, d.height);
},

onClose: func
{
    logprint(LOG_WARN, "XMLDialog closed");

    # call the base canvas.Window delete method, not
    # our wrapper above.
    call(canvas.Window.del, [], me._window);
}

};

# this is the callback function which C++ invokes, to create a peer
# for an XML dialog (and its C++ class). In the future, different kinds
# of dialog could be created if necessary (eg, with different window frame
# styles or frameless / non-draggable)
var _createDialogPeer = func(type)
{
    logprint(LOG_INFO, "Creating dialog of type:" ~ type);
    var z = gui.xml.Dialog.new({
        parents: [XMLDialog]
    });

    return z;
};

var _getProp = func(objectProps, name, def)
{
    var node = objectProps.getNode(name);
    if (node == nil)
        return def;
    return node.getValue();
}

var _getBoolProp = func(objectProps, name, def)
{
    var node = objectProps.getNode(name);
    if (node == nil)
        return def;
    return node.getBoolValue();
}

var _getDoubleProp = func(objectProps, name, def)
{
    var node = objectProps.getNode(name);
    if (node == nil)
        return def;
    return node.getDoubleValue();
}


#################################################################################################

var XMLObjectBase = 
{
    _configValue: func(name, def = nil) 
    {
        var node = me.config.getNode(name);
        if (node == nil)
            return def;
        return node.getValue();
    },

    _configDouble: func(name, def = 0.0) 
    {
        var node = me.config.getNode(name);
        if (node == nil)
            return def;
        return node.getDoubleValue();
    },

    _configBool: func(name, def = 0) 
    {
        var node = me.config.getNode(name);
        if (node == nil)
            return def;
        return node.getBoolValue();
    },

    _applyLayoutConfig: func()
    {
        var halign = me._configValue("halign");
        var valign = me._configValue("valign");
        var l = me.layoutItem();
        if (!l)
            return;

        if (halign or valign) {
            var ha = 0;
            if (halign == "left") {
                ha = canvas.AlignLeft;
            } elsif (halign == "center") {
                ha = canvas.AlignHCenter;
            } elsif (halign == "right") {
                ha = canvas.AlignRight;
            }

            var va = 0;
            if (valign == "top") {
                va = canvas.AlignTop;
            } elsif (valign == "center") {
                va = canvas.AlignVCenter;
            } elsif (valign == "bottom") {
                va = canvas.AlignBottom;
            }

            l.setAlignment(ha + va);
        }

        if (ghosttype(l) == "canvas.Widget") {
            var fixedWidth = me._configValue("width");
            var fixedHeight = me._configValue("height");
            if (fixedWidth or fixedHeight) {
                # query existing values in case we only write to
                # one axis, instead of both
                var minSize = l.minimumSize();
                var maxSize = l.maximumSize();
                if (fixedWidth) {
                    minSize[0] = fixedWidth;
                    maxSize[0] = fixedWidth;
                }
                if (fixedHeight) {
                    minSize[1] = fixedHeight;
                    maxSize[1] = fixedHeight;
                }
                l.setMaximumSize(maxSize);
                l.setMinimumSize(minSize);
            }

            var prefWidth = me._configValue("pref-width");
            var prefHeight = me._configValue("pref-height");
            if (prefWidth or prefHeight) {
                var hint = l.sizeHint();
                if (prefWidth) {
                    hint[0] = prefWidth;
                }
                if (prefHeight) {
                    hint[1] = prefHeight;
                }

                l.setSizeHint(hint);
            }
        } else {
            # layout item is not a NasalWidget, so lacks public
            # setters for these. Could extend the API if we need to
            # cover these cases where XML dialogs specify sizes on
            # layouts
        }
        
    },

    view: func { return me._view; },
    layoutItem : func { return me._layout; }
};

#################################################################################################
# XML object peers
#
# For each object defined in XML, we create a C++ object (PUICompatObject) and invoke
# the callback below (_createCompatObject) to create a corresponding Nasal peer. There is
# no requirement for a 1:1 mapping from XML types to the classes below. 
#
# The Nasal peer class responds to callbacks from C++, especially showing and hiding, to
# create some visual representation of the object. It's important that this view of the
# object is only created on demand, so that invisible GUI elements do not create Canvas
# objects, which have a rendering cost. 

var XMLButton =
{ 
    init: func(objectProps)
    {
        me._isDefault = me._configBool("default");
        me._label = me.configValue("legend");
    },

    show: func(viewParent)
    {
        me._view = cwidgets.Button.new(viewParent, canvas.style, {});
        me._view.setText(me._label);
        me._layout = me._view;

        if (me._isDefault) {
            me._view.setDefault(1);
        }

        # hook up the button to our bindings
        me._view.listen("clicked", func  me.activateBindings(); );
        me._applyLayoutConfig();
    }

};

var XMLCheckbox =
{ 
    init: func(objectProps)
    {
        me._label = me.configValue("label");
        
    },

    show: func(viewParent)
    {
        me._view = cwidgets.CheckBox.new(viewParent, canvas.style, {});
        me._view.setText(me._label);
        me._layout = me._view;
        me._applyLayoutConfig();
        me.update();
        return me._view;
    },

    update: func()
    {
        if (me._view == nil) 
            return;
        
        var v = me.value;
        if (v) {
            me._view.setText(str(v));
        }
    }

};

var XMLLabel =
{ 
    init: func(objectProps)
    {
        me._label = me.configValue("label");
    },

    show: func(viewParent)
    {
        me._view = cwidgets.Label.new(viewParent, canvas.style, {});
        me._view.setText(me._label);
        me._layout = me._view;
        me._applyLayoutConfig();
        me.update();
        return me._view;
    },

    update: func()
    {
        if (me._view == nil) 
            return;
        
        var v = me.value;
        if (v) {
            me._view.setText(str(v));
        }
    }
};

var XMLGroup = 
{
    init: func(objectProps)
    {
        me._layoutType = me.configValue("layout");
        me._padding = me._configDouble("default-padding");
    },

    show: func(viewParent)
    {
        me._view = viewParent.createChild("group");

        # check for layout on us
        var layout = nil;
        if (me._layoutType == "hbox") {
            layout = canvas.HBoxLayout.new();
        } elsif (me._layoutType == "vbox") {
            layout =  canvas.VBoxLayout.new();
        } elsif (me._layoutType == "table") {
            layout = canvas.GridLayout.new();
        } else {
            logprint(LOG_WARN, "Unknown layout type:" ~ me._layoutType);
        }

        if (layout != nil) {
            me._layout = layout;
            layout.setSpacing(me._padding);
            me._applyLayoutConfig();
        }

        foreach (var c; me.children) {
            # create view for each child
            c.show(me._view);
            if (layout != nil) {
                var childItem = c.layoutItem();

                if (me._layoutType == "table") {
                    var gpos = c.gridLocation();
                    layout.addItem(childItem, gpos.column, gpos.row, gpos.columnSpan, gpos.rowSpan);
                } else {
                    layout.addItem(childItem);

                    # TODO: support 'equal' configBool here, set
                    # stretch factor as well?

                    # old layout.cxx code only implements stretch on
                    # hbox and vbox, so this is the correct equivalent place
                    # for compatability
                    if (c._configBool("stretch")) {
                        layout.setStretchFactor(childItem, 1.0);
                    }
                }
            } # of children show+layout iteration
            # record the childView elsewhere?
        }

        return me._view;
    },

    update: func()
    {
        # re-create children is we are visible?
    }
};

var XMLSlider =
{ 
    init: func(objectProps)
    {
        # TODO: support vertical sliders
    },

    show: func(viewParent)
    {
        me._view = cwidgets.Slider.new(viewParent, canvas.style, {});
        me._layout = me._view;
        me._applyLayoutConfig();
        me.update();
        return me._view;
    },

    update: func()
    {


    }
};

var XMLDial =
{ 
    init: func(objectProps)
    {
        logprint(LOG_INFO, "Init of XMLDial");
       
        
    },

    show: func(viewParent)
    {
        me._view = cwidgets.Dial.new(viewParent, canvas.style, {});
        me._layout = me._view;
        me._applyLayoutConfig();
        me.update();
        return me._view;
    },

    update: func()
    {

    }
};

var XMLTextEdit =
{ 
    init: func(objectProps)
    {
        # TODO: config to restrict to numerical / decimal input, etc
    },

    show: func(viewParent)
    {
        me._view = cwidgets.LineEdit.new(viewParent, canvas.style, {});
        me._layout = me._view;
        me._applyLayoutConfig();
        me.update();
        return me._view;
    },

    update: func()
    {
        # don't overwrite if it has focus
        if (me._view and !me._view.hasActiveFocus()) {
            me._view.setText(str(me.value));
        }
    }
};

var XMLEmpty =
{ 
    init: func(objectProps)
    {
    },

    show: func(viewParent)
    {
        # TODO: add Nasal-Canvas API to create spacer items
        # explicitly
        me._view = canvas.createChild("empty", "group");
        me._layout = canvas.Spacer.new();
        me._applyLayoutConfig();

        return me._view;
    },

    update: func()
    {
        me._view.setSize(me._size);
    }
};

var XMLHRule =
{ 
    show: func(viewParent)
    {
        var label = me.configValue("label");

        me._view = cwidgets.HorizontalRule.new(viewParent, canvas.style, {});
        if (label) {
            me._view.setText(label);
        }

        me._layout = me._view;
        me._applyLayoutConfig();
        return me._view;
    },

    update: func()
    {
        # allow label to be updated live
        var l = me.value();
        if (l) {
            me._view.setText(l);
        }

        me._view.setSize(me._size);
    }
};

var XMLVRule =
{ 
    show: func(viewParent)
    {
        me._view = cwidgets.VerticalRule.new(viewParent, canvas.style, {});
        me._layout = me._view;
        me._applyLayoutConfig();
        return me._view;
    }
};


var XMLComboBox =
{ 
    init: func(objectProps)
    {
    },

    show: func(viewParent)
    {
        # do we support a label or is that a seperate widget?

        me._view = cwidgets.ComboBox.new(viewParent, canvas.style, {});
        me._layout = me._view;
        me._applyLayoutConfig();
        me.update();
        return me._view;
    },

    update: func()
    {
        if (me._view and !me._view.hasActiveFocus()) {
            me._view.setCurrentByValue(me.value);
        }
    }
};

# this is the callback function invoked by C++ to build Nasal peers
# for the C++ objects defined by XML (PUICompatObject). It's primarly
# a factory method: once the peer object is created, all other behaviour
# is passed to it.
var _createCompatObject = func(type)
{
    # default to a label
    var widget = XMLLabel;

    # FIXME use a hash for these :)
    if (type == "button") {
        widget = XMLButton;
    }

    if (type == "checkbox") {
        widget = XMLCheckbox;
    }

    if (type == "slider") {
        widget = XMLSlider;
    }

    if (type == "dial") {
        widget = XMLDial;
    }

    if (type == "group") {
        widget = XMLGroup;
    }

    if (type == "input") {
        widget = XMLTextEdit;
    }

    if (type == "empty") {
        widget = XMLEmptyWidget;
    }

    if (type == "hrule") {
        widget = XMLHRule;
    }

    if (type == "vrule") {
        widget = XMLVRule;
    }

    if (type == "combo") {
        widget = XMLComboBox;
    }

    return gui.xml.Object.new({
        parents: [widget, XMLObjectBase]
    }, type);
};

logprint(LOG_INFO, "Loaded gui.XMLDialog");

