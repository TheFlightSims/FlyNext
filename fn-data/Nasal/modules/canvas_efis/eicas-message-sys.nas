#
# EICAS message system
# initial version by jsb 05/2018
#

# simple pager to get a sub vector of messages
var Pager = {
    new: func(page_length, prop_path) {
        var obj = {
            parents: [me],
            page_length: 1,
            lengthN: props.getNode(prop_path~"/page_length",1),
            current_page: 1,
            pageN: props.getNode(prop_path~"/page",1),
            pagesN: props.getNode(prop_path~"/pages",1),
            last_result: 0,
            prop_path: prop_path,
            line_count: 0,
            pg_changed: 0,
        };
        obj.setPageLength(page_length);
        obj.setPage(1);
        setlistener(obj.pageN.getPath(), func(n) {
            obj.current_page = n.getValue();
            obj.pg_changed = 1;
        }, 0, 0);
        setlistener(obj.lengthN.getPath(), func(n) {
            obj.page_length = n.getValue();
            obj.pg_changed = 1;
        }, 0, 0);
        return obj;
    },

    pageChanged: func() {
        var c = me.pg_changed;
        me.pg_changed = 0;
        return c;
    },

    setPageLength: func(n) {
        me.page_length = int(n) or 1;
        me.lengthN.setIntValue(me.page_length);
        return me;
    },

    setPage: func(p) {
        me.current_page = int(p) or 1;
        me.pageN.setIntValue(me.current_page);
        return me;
    },

    getPageCount: func() {
        return me.page_count;
    },

    getCurrentPage: func() {
        return me.current_page;
    },

    # lines: vector of all messages
    # returns lines of current page; sticky lines will not be paged
    page: func(lines) {
        me.line_count = size(lines);
        #count sticky lines, assume sorted list
        for (var sticky = 0; sticky < me.line_count; sticky += 1) {
            if (lines[sticky].paging) break;
        }
        if (sticky >= me.page_length) {
            sticky = me.page_length;
            me.page_count = 1;
        }
        else {
            var page_lines = me.line_count - sticky;
            var len = me.page_length - sticky;
            me.page_count = int((page_lines - 1) / len) + 1;
        }
        me.pagesN.setValue(me.page_count);
        me.current_page = me.pageN.getValue() or 1;
        var start = len * (me.current_page-1) + sticky;
        # default to first page if page is invalid
        if (me.current_page > me.page_count) {
            me.setPage(1);
            start = sticky;
        }
        var end = start + len - 1;
        if (end >= me.line_count)
            end = me.line_count-1;
        #print("page l:"~me.line_count~" start "~start~" end "~end);
        var result = sticky ? lines[0:(sticky-1)] : [];
        if (start <= end) {
            return result~lines[start:end];
        }
        else return result;
    },
};

var MessageClass = {
    #static, increased by new()
    prio: 0,

    new: func(name, paging, prio=0) {
        var obj = {
            parents: [me],
            name: name,
            paging: paging,
            disabled: 0,
            color: [1,1,1],
        };
        if (prio)
            obj.prio = prio;
        else {
            obj.prio = me.prio;
            me.prio += 1;
        }
        return obj;
    },

    setColor: func(color) {
        if (color != nil)
            me.color = color;
        return me;
    },

    setPrio: func(prio) {
        me.prio = int(prio);
        return me;
    },

    enable: func { me.disabled = 0; },
    disable: func(bool = 1) { me.disabled = bool; },
    isDisabled: func { return me.disabled; },
};

var Message = {
    msg: "",
    prop: "",
    aural: "",
    condition: {
        eq: "equals",
        ne: "not equals",
        lt: "less than",
        gt: "greater than",
    },
};

var MessageSystem = {
    PAGING: 1,
    NO_PAGING: 0,

    new: func(page_length, prop_path) {
        if (!isint(page_length) or page_length < 1 or page_length > 100) {
            logprint(LOG_ALERT, "MessageSystem.new(): page_length must be an integer value between 1 and 100");
            return;
        }

        var obj = {
            parents: [me],
            rootN : props.getNode(prop_path,1),
            page_length: page_length,
            pager: Pager.new(page_length, prop_path),
            classes: [],
            messages: [],       # vector of vector of messages
            sounds: {},
            sound_path: "",
            sound_queue: "efis",
            active_messages: [],    # lists of active message IDs per class
            active_aurals: {},      # list of active aural warnings ((un-)set if corresponding message is (in-)active)
            msg_list: [],           # active message list (flat, sorted by class)
            first_changed_line: 0,  # for later optimisation: first changed line in msg_list
            changed: 1,
            powerN: nil,
            canvas_group: nil,
            page_indicator: nil,
            page_indicator_format: "Page %2d/%2d",
            lines: [],
        };
        return obj;
    },

    # setRootNode: func(n) {
        # me.rootN = n;
    # },

    # set power prop and add listener to start/stop all registered update functions
    setPowerProp: func(p) {
        me.powerN = props.getNode(p,1);
        setlistener(me.powerN, func(n) {
            if (n.getValue()) {
                me.init();
            }
        }, 1, 0);
    },

    # class_name:  identifier for msg class
    # paging:     true = normal paging, false = msg class is sticky at top of list
    # returns class id (int)
    addMessageClass: func(class_name, paging, color = nil) {
        var class = size(me.classes);
        me["new-msg"~class] = me.rootN.getNode("new-msg-"~class_name,1);
        me["new-msg"~class].setIntValue(0);
        append(me.classes, MessageClass.new(class_name, paging).setColor(color));
        append(me.active_messages, []);
        return class;
    },

    # addMessages creates a new msg class and add messages to it
    # class:     class id returned by addMessageClass();
    # messages:  vector of message objects (hashes)
    addMessages: func(class, messages) {
        forindex (var i; messages) {
            messages[i]["_class"] = class;
        }
        append(me.messages, messages);

        var simpleL = func(i){
            return func(n) {
                var val = n.getValue() or 0;
                me.setMessage(class, i, val);
            }
        };
        var eqL = func(i) {
            return func(n) {
                var val = n.getValue() or 0;
                if (val == messages[i].condition["eq"])
                    me.setMessage(class, i, 1);
                else me.setMessage(class, i, 0);
            }
        };
        var neL = func(i) {
            return func(n) {
                var val = n.getValue() or 0;
                if (val != messages[i].condition["ne"])
                    me.setMessage(class, i, 1);
                else me.setMessage(class, i, 0);
            }
        };
        var ltL = func(i) {
            return func(n) {
                var val = num(n.getValue()) or 0;
                if (val  < messages[i].condition["lt"])
                    me.setMessage(class, i, 1);
                else me.setMessage(class, i, 0);
            }
        };
        var gtL = func(i) {
            return func(n) {
                var val = num(n.getValue()) or 0;
                if (val > messages[i].condition["gt"])
                    me.setMessage(class, i, 1);
                else me.setMessage(class, i, 0);
            }
        };
        forindex (var i; messages) {
            if (messages[i].prop) {
                #print("addMessage "~i~" t:"~messages[i].msg~" p:"~messages[i].prop);
                var prop = props.getNode(messages[i].prop,1);
                # listeners won't work on aliases so find real node
                while (prop.getAttribute("alias")) {
                    prop = prop.getAliasTarget();
                }
                if (messages[i]["condition"] != nil) {
                    var c = messages[i]["condition"];
                    if (c["eq"] != nil) setlistener(prop, eqL(i), 1, 0);
                    if (c["ne"] != nil) setlistener(prop, eqL(i), 1, 0);
                    if (c["lt"] != nil) setlistener(prop, ltL(i), 1, 0);
                    if (c["gt"] != nil) setlistener(prop, gtL(i), 1, 0);
                }
                else setlistener(prop, simpleL(i), 1, 0);
            }
        }
    },

    setSoundPath: func(path) {
        me.sound_path = path;
    },

    addAuralAlert: func(id, filename, volume=1.0, path=nil) {
        if (typeof(id) == "hash") {
            logprint(DEV_ALERT, "First argument to addAuralAlert() must be a string but is a hash. Use addAuralAlerts() to pass all alerts in one hash.");
        }
        me.sounds[id] = {
            path: (path == nil) ? me.sound_path : path,
            file: filename,
            volume: volume,
            queue: me.sound_queue,
        };
        me.active_aurals[id] = 0;
    },

    addAuralAlerts: func(alert_hash) {
        if (typeof(alert_hash) != "hash") {
            logprint(DEV_ALERT, "MessageSystem.addAuralAlerts: parameter must be a hash!");
            return;
        }
        me.sounds = alert_hash;
        foreach (var k; keys(alert_hash)){
            me.active_aurals[k] = 0;
            if (typeof(me.sounds[k]) == "scalar") {
                me.sounds[k] = {file: me.sounds[k]};
            }
            me.sounds[k]["queue"] = me.sound_queue;
            if (me.sounds[k]["path"] == nil) {
                me.sounds[k]["path"] = me.sound_path;
            }
            if (me.sounds[k]["volume"] == nil) {
                me.sounds[k]["volume"] = 1.0;
            }
        }
    },

    # check per class queues and create list of all active messages not inhibited
    _updateList: func() {
        me.msg_list = [];
        forindex (var class; me.active_messages) {
            foreach (var id; me.active_messages[class]) {
                if (!me.classes[class].disabled and !me.messages[class][id]["disabled"])
                    append(me.msg_list, {
                        text: me.messages[class][id].msg,
                        color: me.classes[class].color,
                        paging: me.classes[class].paging });
            }
        }
    },

    _remove: func(class, msg) {
        var tmp = [];
        for (var i = 0; i < size(me.active_messages[class]); i += 1) {
            if (me.active_messages[class][i] != msg) {
                append(tmp, me.active_messages[class][i]);
            }
        }
        return tmp;
    },

    _isActive: func(class, msg) {
        foreach (var m; me.active_messages[class]) {
            if (m == msg) {
                return 1;
            }
        }
        return 0;
    },

    # (de-)activate message
    setMessage: func(class, msg_id, visible=1) {
        if (class >= size(me.classes))
            return;
        var isActive = me._isActive(class, msg_id);
        if ((isActive and visible) or (!isActive and !visible)) {
            # no change
            return;
        }
        if (!me.changed) {
            me.first_changed_line = me.pager.page_length;
        }
        #add message at head of list, 2DO: priority handling?!
        var aural = me.messages[class][msg_id]["aural"];
        if (visible) {
            me.active_messages[class] = [msg_id]~me.active_messages[class];
            # set new-msg flag in prop tree, e.g. to trigger sounds;
            # may be reset from outside this class so we can trigger again here
            me["new-msg"~class].setIntValue(1);
            if (aural != nil) {
                me.active_aurals[aural] = 1;
                me.auralAlert(aural);
            }
        }
        else {
            me.active_messages[class] = me._remove(class, msg_id);
            if (aural != nil) me.active_aurals[aural] = 0;
            # clear new-msg flag if last message is gone
            if (size(me.active_messages[class]) == 0)
                me["new-msg"~class].setIntValue(-1);
        }

        # count lines of classes with higher priority (= lower class id)
        # we do not need to update them as they did not change
        var unchanged = 0;
        for (var c = 0; c < class; c += 1) {
            unchanged += size(me.active_messages[c]);
        }
        if (me.first_changed_line > unchanged) {
            me.first_changed_line = unchanged;
        }
        #print("set c:"~class~" m:"~msg_id~" v:"~visible~ " 1upd:"~me.first_changed_line);
        # me._updateList();
        me.changed = 1;
    },

    auralAlert: func(aural) {
        if (me.sounds != nil and aural != nil) {
            if (me.active_aurals[aural])
                fgcommand("play-audio-sample", props.Node.new(me.sounds[aural]));
        }
    },

    #-- check for active messages and set new-msg flags.
    #   can be used on power up to trigger new-msg events.
    init: func {
        forindex (var class; me.active_messages) {
            if (size(me.active_messages[class])) {
                me["new-msg"~class].setIntValue(1);
            }
        }
        me.changed = 1;
        #hack for aural alerts
        #print("Enabling EICAS Message System sounds: /sim/sound/"~me.sound_queue~"/enabled = 1");
        setprop("/sim/sound/"~me.sound_queue~"/enabled", 1);
    },

    hasUpdate: func {
        return me.changed;
    },

    setPageLength: func(p) {
        if (p > size(me.lines))
            return;
        for (var i = math.min(p, me.page_length); i < size(me.lines); i += 1) {
            me.lines[i].setText("");
        }
        me.page_length = p;
        me.pager.setPageLength(p);
        me.updateCanvas();
        return me;
    },

    getPageLength: func {
        return me.page_length;
    },

    getFirstUpdateIndex: func {
        return me.first_changed_line;
    },

    # returns message queue and clears the hasUpdate flag
    getActiveMessages: func {
        if (me.changed) {
            me._updateList();
        }
        me.changed = 0;
        return me.msg_list;
    },

    #find message text, return id
    getMessageID: func(class, msgtext) {
        forindex (var id; me.messages[class]) {
            if (me.messages[class][id].msg == msgtext)
                return id;
        }
        return -1;
    },

    # inhibit message id (or all messages in class if no id is given)
    disableMessage: func(class, id = nil) {
        if (id != nil)
            me.messages[class][id]["disabled"] = 1;
        else forindex (var i; me.messages[class])
            me.messages[class][i]["disabled"] = 1;
    },

    # re-enable message id (or all messages in class if no id is given)
    enableMessage: func(class, id = nil) {
        if (id != nil)
            me.messages[class][id]["disabled"] = 0;
        else forindex (var i; me.messages[class])
            me.messages[class][i]["disabled"] = 0;
    },

    #
    #-- following methods are for message output on a canvas --
    #

    # pass an existing canvas group to create text elements on
    setCanvasGroup: func(group) {
        if (isa(group, canvas.Group)) {
            me.canvas_group = group;
        }
        else {
            me.canvas_group = nil;
            logprint(DEV_ALERT, "setCanvasGroup: argument is not a canvas group");
        }
        return me;
    },

    # create text elements for message lines in canvas group; call setCanvasGroup() first!
    createCanvasTextLines: func(left, top, line_spacing, font_size) {
        if (me.canvas_group == nil) return;
        me.lines = me.canvas_group.createChildren("text", me.page_length);
        forindex (var i; me.lines) {
            var l = me.lines[i];
            l.setAlignment("left-top").setTranslation(left, top + i*line_spacing);
            l.setFont("LiberationFonts/LiberationSans-Regular.ttf");
            l.setFontSize(font_size);
        }
        return me.lines;
    },

    # create text element for "page i of N"; call setCanvasGroup() first!
    # returns the text element
    createPageIndicator: func(left, top, font_size, format_string = nil) {
        if (me.canvas_group == nil) return;
        me.page_indicator = me.canvas_group.createChild("text");
        me.page_indicator.setAlignment("left-top").setTranslation(left, top);
        me.page_indicator.setFont("LiberationFonts/LiberationSans-Regular.ttf");
        me.page_indicator.setFontSize(font_size);
        if (format_string != nil)
            me.page_indicator_format = format_string;
        return me.page_indicator;
    },

    # call this regularly to update text lines on canvas
    updateCanvas: func() {
        # check if page change was selected
        var pg_changed = me.pager.pageChanged();
        if (!(pg_changed or me.changed))
            return 0;
        if (pg_changed) {
            # update all lines on screen
            me.first_changed_line = 0;
        }
        me._updateList();
        me.changed = 0;
        var messages = me.pager.page(me.msg_list);
        for (var i = me.first_changed_line; i < size(messages); i += 1) {
            me.lines[i].setText(messages[i].text);
            if (messages[i].color != nil)
                me.lines[i].setColor(messages[i].color);
        }
        # clear text from unused lines
        for (i; i < me.page_length; i += 1) {
            me.lines[i].setText("");
        }
        if (me.page_indicator != nil) {
            if (me.pager.getPageCount() > 1) {
                me.page_indicator.show();
                me.updatePageIndicator(me.pager.getCurrentPage(), me.pager.getPageCount());
            }
            else me.page_indicator.hide();
        }
    },

    updatePageIndicator: func(current, total) {
        me.page_indicator.setText(sprintf(me.page_indicator_format, current, total));
        return me;
    },
};
