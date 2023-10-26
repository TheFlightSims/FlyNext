# Multiplayer
# ===========
#
# 1) Display chat messages from other aircraft to
#    the screen using screen.nas
#
# 2) Display a complete history of chat via dialog.
#
# 3) Allow chat messages to be written by the user.

var lastmsg = {};
var ignore = {};
var msg_loop_id = 0;
var msg_timeout = 0;
var log_file = nil;
var log_listeners = [];

var check_messages = func(loop_id) {
    if (loop_id != msg_loop_id) return;
    foreach (var mp; values(model.callsign)) {
        var msg = mp.node.getNode("sim/multiplay/chat", 1).getValue();
        if (msg and msg != lastmsg[mp.callsign]) {
            if (!contains(ignore, mp.callsign))
                echo_message(mp.callsign, msg);
            lastmsg[mp.callsign] = msg;
        }
    }
    settimer(func check_messages(loop_id), 1);
}

var echo_message = func(callsign, msg) {
    msg = string.trim(string.replace(msg, "\n", " "));

    # Only prefix with the callsign if the message doesn't already include it.
    if (find(callsign, msg) < 0)
        msg = callsign ~ ": " ~ msg;

    setprop("/sim/messages/mp-plane", msg);

    # Add the chat to the chat history.
    if (var history = getprop("/sim/multiplay/chat-history"))
        msg = history ~ "\n" ~ msg;

    setprop("/sim/multiplay/chat-history", msg);
}

var timeout_handler = func()
{
    var t = props.globals.getNode("/sim/time/elapsed-sec").getValue();
    if (t >= msg_timeout)
    {
        msg_timeout = 0;
        setprop("/sim/multiplay/chat", "");
    }
    else
        settimer(timeout_handler, msg_timeout - t);
}

var chat_listener = func(n)
{
    var msg = n.getValue();
    if (msg)
    {
        # ensure we see our own messages.
        echo_message(getprop("/sim/multiplay/callsign"), msg);

        # set expiry time
        if (msg_timeout == 0)
            settimer(timeout_handler, 10); # need new timer
        msg_timeout = 10 + props.globals.getNode("/sim/time/elapsed-sec").getValue();
    }
}



# Message composition function, activated using the - key.
var prefix = "Chat Message:";
var input = "";
var kbdlistener = nil;

var my_kbd_listener = func(event)
{
  var key = event.getNode("key");

  # Only check the key when pressed.
  if (!event.getNode("pressed").getValue())
    return;

  if (handle_key(key.getValue()))
    key.setValue(-1);           # drop key event
}

var capture_kbd = func()
{
  if (kbdlistener == nil) {
    kbdlistener = setlistener("/devices/status/keyboard/event", my_kbd_listener);
  }
}

var release_kbd = func()
{
  if (kbdlistener != nil) {
    removelistener(kbdlistener);
    kbdlistener = nil;
  }
}
var compose_message = func(msg = "")
{
  input = prefix ~ msg;
  gui.popupTip(input, 1000000);
  capture_kbd();
}

var end_compose_message = func()
{
  gui.popdown();
  release_kbd();
}

var view_select = func(callsign)
{
    view.model_view_handler.select(callsign, 1);
}

var handle_key = func(key)
{
  if (key == `\n` or key == `\r` or key == `~`)
  {
    # CR/LF -> send the message

    # Trim off the prefix
    input = substr(input, size(prefix));
    # Send the message and switch off the listener.
    setprop("/sim/multiplay/chat", input);
    end_compose_message();
    return 1;
  }
  elsif (key == 8)
  {
    # backspace -> remove a character

    if (size(input) > size(prefix))
    {
      input = substr(input, 0, size(input) - 1);
      gui.popupTip(input, 1000000);
    }

    # Always handle key so excessive backspacing doesn't toggle the heading autopilot
    return 1;
  }
  elsif (key == 27)
  {
    # escape -> cancel
    end_compose_message();
    return 1;
  }
  elsif ((key > 31) and (key < 128))
  {
    # Normal character - add it to the input
    input ~= chr(key);
    gui.popupTip(input, 1000000);
    return 1;
  }
  else
  {
    # Unknown character - pass through
    return 0;
  }
}



# multiplayer.dialog.show() -- displays pilot list dialog
#
var PILOTSDLG_RUNNING = 0;
var dialog = {
    init: func(x = nil, y = nil) {
        me.x = x;
        me.y = y;
        me.bg = [0.1, 0.1, 0.1, 0.8];    # background color
        me.fg = [[0.9, 0.9, 0.2, 1], [1, 1, 1, 1], [1, 0.7, 0, 1], [0.557,0.847,0.463, 1]]; # active, active alternate, disabled color, fallback available
        me.unit = 0;
        me.toggle_unit();          # set to imperial
        #
        # "private"
         me.font = { name: getprop("/sim/gui/selected-style/fonts/mp-list/name"),
                       size: getprop("/sim/gui/selected-style/fonts/mp-list/size"),
                       slant: getprop("/sim/gui/selected-style/fonts/mp-list/slant"),
                     };
        #printf('me.font is: %s', view.str(me.font));
        if (me.font.name == nil) {
            # We try to cope if no font is specified, so that we inherit
            # whatever default there is.
            printf("Failed to find font for Pilot List dialog");
            me.font = nil;
        }
        
        me.header = ["view", " callsign", " model", func dialog.dist_hdr, " ", func dialog.alt_hdr ~ " ", "", " brg", "chat", "ignore" ~ " ", " code", "ver", "airport", " set"];
        me.columns = [
            { type: "checkbox", legend: "", property: "view", halign: "right", "pref-height": 14, "pref-width": 14, callback: "multiplayer.view_select", argprop: "callsign", },
            { type: "text", property: "callsign",    format: " %s",    label: "-----------",    halign: "fill" },
            { type: "text", property: "model-short", format: " %s",     label: "--------------", halign: "fill" },
            { type: "text", property: func dialog.dist_node, format:" %8.2f", label: "---------", halign: "right" },
            { type: "text", property: "distance_delta", format: "%s", label: "--", halign: "right" },
            { type: "text", property: func dialog.alt_node,  format:" %7.0f", label: "---------", halign: "right" },
            { type: "text", property: "ascent_descent",          format: "%s", label: "-", halign: "right" },
            { type: "text", property: "bearing-to",  format: " %3.0f", label: "----",           halign: "right" },
            { type: "button", legend: "", halign: "right", callback: "multiplayer.compose_message", "pref-height": 14, "pref-width": 14 },
            { type: "checkbox", property: "controls/invisible", callback: "multiplayer.dialog.toggle_ignore",
              argprop: "callsign", label: "---------", halign: "right" },
            { type: "text", property: "id-code",    format: " %s",    label: "-",    halign: "fill"  },
            { type: "text", property: "sim/multiplay/protocol-version", format: " %s",     label: "--", halign: "fill"  },
            { type: "text", property: "airport-id", format: "%s",     label: "----", halign: "fill"  },
            { type: "text", property: "set-loaded", format: "%s",     label: "----", halign: "fill"  },
        ];
        me.cs_warnings = {};
        me.name = "who-is-online";
        me.dialog = nil;
        me.loopid = 0;

        me.listeners=[];
        append(me.listeners, setlistener("/sim/startup/xsize", func me._redraw_()));
        append(me.listeners, setlistener("/sim/startup/ysize", func me._redraw_()));
        append(me.listeners, setlistener("/sim/signals/reinit-gui", func me._redraw_()));
        append(me.listeners, setlistener("/sim/signals/multiplayer-updated", func me._redraw_()));
        append(me.listeners, setlistener("/sim/current-view/model-view", func me.update_view()));
    },
    create: func {
        if (me.dialog != nil)
            me.close();

        me.dialog = gui.dialog[me.name] = gui.Widget.new();
        me.dialog.set("name", me.name);
        me.dialog.set("dialog-name", me.name);
        if (typeof(me.font) == 'hash' and contains(me.font, "name") and me.font.name != nil) {
            me.dialog.set("font", me.font.name);
        }
        if (me.x != nil)
            me.dialog.set("x", me.x);
        if (me.y != nil)
            me.dialog.set("y", me.y);

        me.dialog.set("layout", "vbox");
        me.dialog.set("default-padding", 0);

        me.dialog.setColor(me.bg[0], me.bg[1], me.bg[2], me.bg[3]);
        
        # Sets out default foreground colour and also me.font if it is not nil.
        #
        set_default = func(w) {
            w.setColor(me.fg[1][0], me.fg[1][1], me.fg[1][2], me.fg[1][3],);
            if (me.font != nil) {
                w.node.setValues({ "font": me.font});
            }
        }

        var titlebar = me.dialog.addChild("group");
        titlebar.set("layout", "hbox");

        var view_self = titlebar.addChild("button");
        view_self.node.setValues({ "pref-height": 16, legend: "view self", default: 0 });
        view_self.setBinding("nasal", "view.model_view_handler.select(getprop('/sim/multiplayer/callsign'), 1);");

        titlebar.addChild("empty").set("stretch", 1);
        
        var w = titlebar.addChild("button");
        w.node.setValues({ "pref-width": 24, "pref-height": 16, legend: me.unit_button, default: 0 });
        w.setBinding("nasal", "multiplayer.dialog.toggle_unit(); multiplayer.dialog._redraw_()");

        titlebar.addChild("empty").set("stretch", 1);
        var w = titlebar.addChild("text");
        w.set("label", "Pilots: ");
        set_default(w);

        var w = titlebar.addChild("text");
        set_default(w);
        w.node.setValues({ label: "---", live: 1, format: "%d", property: "ai/models/num-players" });
        titlebar.addChild("empty").set("stretch", 1);

        var w = titlebar.addChild("button");
        w.node.setValues({ "pref-width": 16, "pref-height": 16, legend: "", default: 0 });
        # "Esc" causes dialog-close
        w.set("key", "Esc");
        w.setBinding("nasal", "multiplayer.dialog.del()");

        me.dialog.addChild("hrule");

        var content = me.dialog.addChild("group");
        content.set("layout", "table");
        content.set("default-padding", 0);

        var row = 0;
        var col = 0;
        # First row is column headers.
        foreach (var h; me.header) {
            var w = content.addChild("text");
            var l = typeof(h) == "func" ? h() : h;
            w.node.setValues({ "label": l, "row": row, "col": col, halign: me.columns[col].halign });
            set_default(w);
            w = content.addChild("hrule");
            w.node.setValues({ "row": row + 1, "col": col });
            col += 1;
        }
        row += 2;
        var odd = 1;
        # Add a row for each multiplayer aircraft.
        foreach (var mp; model.list) {
            var col = 0;
            var color = me.fg[2];
            if (mp.node.getNode("model-installed").getValue()) {
                color = me.fg[odd = !odd];
                color = me.fg[1];
            }
            else{
                #print("no model installed; check fallback");
                var fbn = mp.node.getNode("sim/model/fallback-model-index");
                if (fbn != nil){
                    #print(" ->> got fallback node =",fbn.getValue());
                    if (fbn.getValue() > 0) {
                        color = me.fg[3];
                    }
                } else
                    #print(" ->> no fallback node");
            }
            foreach (var column; me.columns) {
                var w = nil;
                if (column.type == "button") {
                    w = content.addChild("button");
                    w.node.setValues(column);
                    set_default(w);
                    w.setBinding("nasal", column.callback ~ "(\"" ~ mp.callsign ~ "\",);");
                            w.node.setValues({ row: row, col: col});
                } else {
                    var p = typeof(column.property) == "func" ? column.property() : column.property;
                    if (column.type == "text") {
                        w = content.addChild("text");
                        w.node.setValues(column);
                        set_default(w);
                    } elsif (column.type == "checkbox") {
                        w = content.addChild("checkbox");
                        w.setBinding("nasal", column.callback ~ "(getprop(\"" ~ mp.root ~ "/" ~ column.argprop ~ "\"))");
                        set_default(w);
                    }
                    w.node.setValues({ row: row, col: col, live: 1, property: mp.root ~ "/" ~ p });
                }
                w.setColor(color[0], color[1], color[2], color[3]);
                col += 1;
            }
            row += 1;
        }
        if (me.x != nil)
            me.dialog.set("x", me.x);
        if (me.y != nil)
            me.dialog.set("y", me.y);
        me.update(me.loopid += 1);
        fgcommand("dialog-new", me.dialog.prop());
        fgcommand("dialog-show", me.dialog.prop());
        me.update_view();
    },
    update_view: func() {
        # We are called when the aircraft being viewed has changed. We update
        # the boxes in the 'view' column so that only the one for the aircraft
        # being viewed is checked. If the user's aircraft is being viewed, none
        # of these boxes will be checked.
        var callsign = getprop("/sim/current-view/model-view");
        
        # Update Pilot View checkboxes.
        foreach (var mp; model.list) {
            mp.node.setValues({'view': mp.callsign == callsign});
        }
        
        # Update actual view.
        view.model_view_handler.select(callsign, 1);
    },
    update: func(id) {
        id == me.loopid or return;
        var self = geo.aircraft_position();
        foreach (var mp; model.list) {
            var n = mp.node;
            var x = n.getNode("position/global-x").getValue();
            var y = n.getNode("position/global-y").getValue();
            var z = n.getNode("position/global-z").getValue();
            var ac = geo.Coord.new().set_xyz(x, y, z);
            var distance = nil;
            var idcode = "----";
            idcode = me.IDCode(n.getNode("instrumentation/transponder/transmitted-id").getValue());

            call(func distance = self.distance_to(ac), nil, var err = []);

            if ((size(err))or(distance==nil)) {
                # Oops, have errors. Bogus position data (and distance==nil).
                if (me.cs_warnings[mp.callsign]!=1) {
                    # report each callsign once only (avoid cluttering)
                    me.cs_warnings[mp.callsign] = 1;
                    print("Received invalid position data: " ~ debug._error(mp.callsign));
                }
                #    debug.printerror(err);
                #    debug.dump(self, ac, mp);
                #    debug.tree(mp.node);
            }
            else
            {
                # Node with valid position data (and "distance!=nil").
                
                # For 'set-loaded' column, we find whether the 'set' has more
                # than just the 'sim' child (which we always create even if
                # we couldn't load the -set.xml, in order to provide default
                # values for views' config/z-offset-m values).
                var set = n.getNode("set");
                var set_numchildren = 0;
                if (set != nil) set_numchildren = size(set.getChildren());
                var set_loaded = (set_numchildren >= 2);
                
                var airport_id = n.getNode("sim/tower/airport-id");
                if (airport_id != nil) {
                    airport_id = airport_id.getValue();
                }
                
                var ascent_descent = n.getNode("velocities/vertical-speed-fps");
                if (ascent_descent == nil) {
                    ascent_descent = '';
                }
                else {
                    ascent_descent = ascent_descent.getValue();
                    if (ascent_descent > 1)         ascent_descent = '+';
                    else if (ascent_descent < -1)   ascent_descent = '-';
                    else ascent_descent = '';
                }
                
                distance_delta_text = ' ';
                var distance_km_old = n.getValue('distance-to-km');
                if (distance_km_old != nil) {
                    var distance_delta = distance - distance_km_old * 1000;
                    if (distance_delta >  10)   distance_delta_text = ' +';
                    if (distance_delta < -10)   distance_delta_text = ' -';
                }
                n.setValues({
                    "model-short": mp.modelInstallNode.getValue() ? mp.model : "[" ~ mp.model ~ "]",
                    "set-loaded": set_loaded ? "   *" : "    ",
                    "bearing-to": self.course_to(ac),
                    "distance-to-km": distance / 1000.0,
                    "distance-to-nm": distance * M2NM,
                    "distance_delta": distance_delta_text,
                    "position/altitude-m": mp.altitudeNode.getValue() * FT2M,
                    "ascent_descent": ascent_descent,
                    "controls/invisible": contains(ignore, mp.callsign),
                    "id-code": idcode,
                    "airport-id": airport_id,
                    "lag/lag-mod-averaged-ms": (mp.lagModAveragedNode.getDoubleValue() or 0) * 1000,
                });
            }
        }
        if (PILOTSDLG_RUNNING)
            settimer(func me.update(id), 1, 1);
    },
    _redraw_: func {
        if (me.dialog != nil) {
            me.close();
            me.create();
        }
    },
    toggle_unit: func {
        me.unit += 1;
        if (me.unit > 2) me.unit = 0;
        if (me.unit == 0) {
            me.alt_node = "position/altitude-m";
            me.alt_hdr = "alt-m";
            me.dist_hdr = "dist-km";
            me.dist_node = "distance-to-km";
            me.unit_button = "SI";
        } elsif (me.unit == 1) {
            me.alt_node = "position/altitude-ft";
            me.dist_node = "distance-to-nm";
            me.alt_hdr = "alt-ft";
            me.dist_hdr = "dist-nm";
            me.unit_button = "IM";
        } else {
            me.alt_node = "lag/lag-mod-averaged-ms";
            me.dist_node = "lag/pps-averaged";
            me.alt_hdr = "lag-ms";
            me.dist_hdr = "lag-pps";
            me.unit_button = "Lag";
        }
    },
    toggle_ignore: func (callsign) {
        if (contains(ignore, callsign)) {
            delete(ignore, callsign);
        } else {
            ignore[callsign] = 1;
        }
    },
    close: func {
        if (me.dialog != nil) {
            me.x = me.dialog.prop().getNode("x").getValue();
            me.y = me.dialog.prop().getNode("y").getValue();
        }
        fgcommand("dialog-close", me.dialog.prop());
    },
    del: func {
        PILOTSDLG_RUNNING = 0;
        me.close();
        delete(gui.dialog, me.name);
        foreach (var l; me.listeners)
            removelistener(l);
    },
    show: func {
        if (!PILOTSDLG_RUNNING) {
            PILOTSDLG_RUNNING = 1;
            me.init(-2, -2);
            me.create();
            me.update(me.loopid += 1);
        }
    },
    toggle: func {
        if (!PILOTSDLG_RUNNING)
            me.show();
        else
            me.del();
    },
    IDCode: func(code){

        var idcode= "----";

        if (code != nil )
            {
            if (code < 0)
                {
                idcode = "----";
                }
            else
                {
                idcode = sprintf("%04d", code);
                }
            }

        return idcode;
        },
};



# Autonomous singleton class that monitors multiplayer aircraft,
# maintains data in various structures, and raises signal
# "/sim/signals/multiplayer-updated" whenever an aircraft
# joined or left. Available data containers are:
#
#   multiplayer.model.data:        hash, key := /ai/models/~ path
#   multiplayer.model.callsign     hash, key := callsign
#   multiplayer.model.list         vector, sorted alphabetically (ASCII, case insensitive)
#
# All of them contain hash entries of this form:
#
# {
#    callsign: "BiMaus",
#    path: "Aircraft/bo105/Models/bo105.xml",      # relative file path
#    root: "/ai/models/multiplayer[4]",            # root property
#    node: {...},        # root property as props.Node hash
#    model: "bo105",     # model name (extracted from path)
#    sort: "bimaus",     # callsign in lower case (for sorting)
# }
#
var model = {
    init: func {
        me.L = [];
        append(me.L, setlistener("ai/models/model-added", func(n) {
            # Defer update() to the next convenient time to allow the
            # new MP entry to become fully initialized.
            settimer(func me.update(n.getValue()), 0);
        }));
        append(me.L, setlistener("ai/models/model-removed", func(n) {
            # Defer update() to the next convenient time to allow the
            # old MP entry to become fully deactivated.
            settimer(func me.update(n.getValue()), 0);
        }));
        me.update();
    },
    update: func(n = nil) {
        var changedNode = props.globals.getNode( n, 1 );
        if (n != nil and changedNode.getName() != "multiplayer")
            return;

        me.data = {};
        me.callsign = {};

        foreach (var n; props.globals.getNode("ai/models", 1).getChildren("multiplayer")) {
            if ((var valid = n.getNode("valid")) == nil or (!valid.getValue()))
                continue;
            if ((var callsign = n.getNode("callsign")) == nil or !(callsign = callsign.getValue()))
                continue;
            if (!(callsign = string.trim(callsign)))
                continue;

            var path = n.getNode("sim/model/path").getValue();
            var model = split(".", split("/", path)[-1])[0];
            model = me.remove_suffix(model, "-model");
            model = me.remove_suffix(model, "-anim");

            var root = n.getPath();
            var data = {
                        node: n,
                        callsign: callsign,
                        model: model,
                        root: root,
                        sort: string.lc(callsign),
                        modelInstallNode : n.getNode("model-installed",1),
                        altitudeNode : n.getNode("position/altitude-ft",1),
                        lagModAveragedNode: n.getNode("lag/lag-mod-averaged",1),
                        };

            me.data[root] = data;
            me.callsign[callsign] = data;
        }

        me.list = sort(values(me.data), func(a, b) cmp(a.sort, b.sort));

        setprop("ai/models/num-players", size(me.list));
        setprop("sim/signals/multiplayer-updated", 1);
    },
    remove_suffix: func(s, x) {
        var len = size(x);
        if (substr(s, -len) == x)
            return substr(s, 0, size(s) - len);
        return s;
    },
};

var mp_mode_changed = func(n) {
    var is_online = getprop("/sim/multiplay/online");
    var is_replaying = getprop("/sim/replay/replay-state");
    
    # Always activate multiplayer items if we are replaying, in case the
    # recording contains MP info.
    #
    foreach (var menuitem; ["mp-chat","mp-chat-menu","mp-list","mp-carrier"])
    {
        gui.menuEnable(menuitem, is_online or is_replaying);
    }

    if (is_online or is_replaying) {
        if (getprop("/sim/multiplay/write-message-log") and (log_file == nil)) {
            var t = props.globals.getNode("/sim/time/real");
            if (t == nil)
            {
                # not ready yet, delay...
                settimer(func mp_mode_changed(n), 0.1);
            }
            else
            {
                t = t.getValues();
                var ac = getprop("/sim/aircraft");
                var cs = getprop("/sim/multiplay/callsign");
                var apt = airportinfo().id;
                var file = string.normpath(getprop("/sim/fg-home") ~ "/mp-message.log");

                log_file = io.open(file, "a");
                io.write(log_file, sprintf("\n=====  %s %04d/%02d/%02d\t%s\t%s\t%s\n",
                    ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][t.weekday],
                    t.year, t.month, t.day, apt, ac, cs));
                io.flush(log_file);

                append(log_listeners, setlistener("/sim/signals/exit", func io.write(log_file, "=====  EXIT\n") and io.close(log_file)));
                append(log_listeners, setlistener("/sim/messages/mp-plane", func(n) {
                    io.write(log_file, sprintf("%02d:%02d  %s\n",
                        getprop("/sim/time/real/hour"),
                        getprop("/sim/time/real/minute"),
                        n.getValue()));
                    io.flush(log_file);
                }));
            }
        }
        check_messages(msg_loop_id += 1);
    }
    else
    {
        # stop message loop
        msg_loop_id += 1;
        if (log_file != nil)
        {
            io.write(log_file, "=====  DISCONNECT\n");
            io.flush(log_file);
            io.close(log_file);
            log_listeners = [];
            log_file = nil;
            foreach (var l; log_listeners)
                removelistener(l);
        }
    }
}

model.init();
setlistener("/sim/multiplay/online", mp_mode_changed, 1, 1);
setlistener("/sim/replay/replay-state", mp_mode_changed, 1, 1);

# Call-back to ensure we see our own messages.
setlistener("/sim/multiplay/chat", chat_listener);

if (getprop("/sim/presets/avoided-mp-runway")) {
    setlistener("/sim/sceneryloaded", func {
      gui.popupTip("Multi-player enabled, start moved to runway hold short position.");
    });
}
