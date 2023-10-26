# SPDX-License-Identifier: GPL-2.0-or-later
#
# NOTE! This copyright does *not* cover user models that use these Nasal
# services by normal function calls - this is merely considered normal use
# of the code, and does *not* fall under the heading of "derived work."
#
# Copyright (C) 2003-2007 by andy
# Copyright (C) 2005-2008 by mfranz
# Copyright (C) 2012-2014 by Thomas Geymayer
# Copyright (C) 2017-2019 by Stuart Buchanan
# Copyright (C) 2019-2020 by Henning Stahlke

# debug.nas -- debugging helpers
#------------------------------------------------------------------------------
#
# debug.dump(<variable>)               ... dumps contents of variable to terminal;
#                                          abbreviation for print(debug.string(v))
#
# debug.local([<frame:int>])           ... dump local variables of current
#                                          or given frame
#
# debug.backtrace([<comment:string>], [<dump:bool=1>], [<skip_level:int=0>]}
#                                      ... writes backtrace (similar to gdb's "bt full)
#                                          dump=0: only call stack 
#                                          dump=1 (default): with local variables 
#                                          skip_level: remove this many levels from 
#                                           call stack
#
# debug.proptrace([<property [, <frames>]]) ... trace property write/add/remove
#                                          events under the <property> subtree for
#                                          a number of frames. Defaults are "/" and
#                                          2 frames (of which the first one is incomplete).
#
# debug.tree([<property> [, <mode>])   ... dump property tree under property path
#                                          or props.Node hash (default: root). If
#                                          <mode> is unset or 0, use flat mode
#                                          (similar to props.dump()), otherwise
#                                          use space indentation
#
# debug.bt()                           ... abbreviation for debug.backtrace()
#
# debug.string(<variable>)             ... returns contents of variable as string
#
# debug.attributes(<property> [, <verb>]) ... returns attribute string for a given property.
#                                          <verb>ose is by default 1, and suppressed the
#                                          node's refcounter if 0.
#
# debug.isnan()                            returns 1 if argument is an invalid number (NaN),
#                                          0 if it's a valid number, and nil in all other cases
#
# debug.benchmark(<label:string>, <func> [, <repeat:int> [, <output:vector>]])
#                                      ... runs function <repeat> times (default: nil)
#                                          and prints total execution time in seconds,
#                                          prefixed with <label>, while adding results
#                                          to <output>, or returning the only result
#                                          if <repeat> is nil.
#
# debug.benchmark_time(<func> [, <repeat:int> [, <output:vector>]])
#                                      ... like debug.benchmark, but returns total
#                                          execution time and does not print anything.
#
# debug.rank(<list:vector> [, <repeat:int>])
#                                      ... sorts the list of functions based on execution
#                                          time over <repeat> samples (default: 1).
#
# debug.print_rank(<result:vector>, <names:int>)
#                                      ... prints the <result> of debug.rank with <names>
#                                          (which can be a vector of [name, func] or
#                                          [func, name], or a hash of name:func).
#
# debug.printerror(<err-vector>)       ... prints error vector as set by call()
#
# debug.warn(<message>, <level>)       ... generate debug message followed by caller stack trace
#                                          skipping <level> caller levels (default: 0).
#
# debug.propify(<variable>)            ... turn about everything into a props.Node
#
# debug.Probe       class              ... base class to collect stats; details below
# debug.Breakpoint  class              ... conditional backtrace; details below
#
# debug.addProbeToFunc(label, func)    ... wraps a function with a probe 
# debug.findFunctions(ns, recursive=0) ... find all functions in a hash (namespace)
#
# debug.addProbesToNamespace(ns, label="", recursive=0) 
#                                      ... combines findFunctions and addProbeToFunc
#
# CAVE: this file makes extensive use of ANSI color codes. These are
#       interpreted by UNIX shells and MS Windows with ANSI.SYS extension
#       installed. If the color codes aren't interpreted correctly, then
#       set property /sim/startup/terminal-ansi-colors=0
#

# ANSI color code wrappers  (see  $ man console_codes)
#
var _title       = func(s, color=nil) globals.string.color("33;42;1", s, color); # backtrace header
var _section     = func(s, color=nil) globals.string.color("37;41;1", s, color); # backtrace frame
var _error       = func(s, color=nil) globals.string.color("31;1",    s, color); # internal errors
var _bench       = func(s, color=nil) globals.string.color("37;45;1", s); # benchmark info

var _nil         = func(s, color=nil) globals.string.color("32", s, color);      # nil
var _string      = func(s, color=nil) globals.string.color("31", s, color);      # "foo"
var _num         = func(s, color=nil) globals.string.color("31", s, color);      # 0.0
var _bracket     = func(s, color=nil) globals.string.color("", s, color);        # [ ]
var _brace       = func(s, color=nil) globals.string.color("", s, color);        # { }
var _angle       = func(s, color=nil) globals.string.color("", s, color);        # < >
var _vartype     = func(s, color=nil) globals.string.color("33", s, color);      # func ghost
var _proptype    = func(s, color=nil) globals.string.color("34", s, color);      # BOOL INT LONG DOUBLE ...
var _path        = func(s, color=nil) globals.string.color("36", s, color);      # /some/property/path
var _internal    = func(s, color=nil) globals.string.color("35", s, color);      # me parents
var _varname     = func(s, color=nil) s;                                         # variable_name


##
# Turn p into props.Node (if it isn't yet), or return nil.
#
var propify = func(p, create = 0) {
	if (isghost(p) and ghosttype(p) == "prop")
		return props.wrapNode(p);
	if (isscalar(p) and num(p) == nil)
		return props.globals.getNode(p, create);
	if (isa(p, props.Node))
		return p;
	return nil;
}


var tree = func(n = "", graph = 1) {
	n = propify(n);
	if (n == nil)
		return dump(n);
	_tree(n, graph);
}


var _tree = func(n, graph = 1, prefix = "", level = 0) {
	var path = n.getPath();
	var children = n.getChildren();
	var s = "";

	if (graph) {
		s = prefix ~ n.getName();
		var index = n.getIndex();
		if (index)
			s ~= "[" ~ index ~ "]";
	} else {
		s = n.getPath();
	}

	if (size(children)) {
		s ~= "/";
		if (n.getType() != "NONE")
			s ~= " = " ~ debug.string(n.getValue()) ~ " " ~ attributes(n)
					~ "    " ~ _section(" PARENT-VALUE ");
	} else {
		s ~= " = " ~ debug.string(n.getValue()) ~ " " ~ attributes(n);
	}

	if ((var a = n.getAliasTarget()) != nil)
		s ~= "  " ~ _title(" alias to ") ~ "  " ~ a.getPath();

	print(s);

	if (n.getType() != "ALIAS")
		forindex (var i; children)
			_tree(children[i], graph, prefix ~ ".   ", level + 1);
}


var attributes = func(p, verbose = 1, color=nil) {
	var r = p.getAttribute("readable")    ? "" : "r";
	var w = p.getAttribute("writable")    ? "" : "w";
	var R = p.getAttribute("trace-read")  ? "R" : "";
	var W = p.getAttribute("trace-write") ? "W" : "";
	var A = p.getAttribute("archive")     ? "A" : "";
	var U = p.getAttribute("userarchive") ? "U" : "";
	var P = p.getAttribute("preserve")    ? "P" : "";
	var T = p.getAttribute("tied")        ? "T" : "";
	var attr = r ~ w ~ R ~ W ~ A ~ U ~ P ~ T;
	var type = "(" ~ p.getType();
	if (size(attr))
		type ~= ", " ~ attr;
	if (var l = p.getAttribute("listeners"))
		type ~= ", L" ~ l;
	if (verbose and (var c = p.getAttribute("references")) > 2)
		type ~= ", #" ~ (c - 2);
	return _proptype(type ~ ")", color);
}


var _dump_prop = func(p, color=nil) {
	_path(p.getPath(), color) ~ " = " ~ debug.string(p.getValue(), color)
                            ~  " "  ~ attributes(p, 1, color);
}


var _dump_var = func(v, color=nil) {
	if (v == "me" or v == "parents")
		return _internal(v, color);
	else
		return _varname(v, color);
}


var _dump_string = func(str, color=nil) {
	var s = "'";
	for (var i = 0; i < size(str); i += 1) {
		var c = str[i];
		if (c == `\``)
			s ~= "\\`";
		elsif (c == `\n`)
			s ~= "\\n";
		elsif (c == `\r`)
			s ~= "\\r";
		elsif (c == `\t`)
			s ~= "\\t";
		elsif (globals.string.isprint(c))
			s ~= chr(c);
		else
			s ~= sprintf("\\x%02x", c);
	}
	return _string(s ~ "'", color);
}


# dump hash keys as variables if they are valid variable names, or as string otherwise
var _dump_key = func(s, color=nil) {
	if (num(s) != nil)
		return _num(s, color);
	if (!size(s))
		return _dump_string(s, color);
	if (!globals.string.isalpha(s[0]) and s[0] != `_`)
		return _dump_string(s, color);
	for (var i = 1; i < size(s); i += 1)
		if (!globals.string.isalnum(s[i]) and s[i] != `_`)
			return _dump_string(s, color);
	_dump_var(s, color);
}


var string = func(o, color=nil, ttl=5) {
    if (o == globals and ttl < 5) return "<globals>"; # do not loop int globals
    if (!ttl) return "<...>";
    var t = typeof(o);
	if (t == "nil") {
		return _nil("null", color);

	} elsif (isscalar(o)) {
		return num(o) == nil ? _dump_string(o, color) : _num(o~"", color);

	} elsif (isvec(o)) {
		var s = "";
		forindex (var i; o)
			s ~= (i == 0 ? "" : ", ") ~ debug.string(o[i], color, ttl - 1);
		return _bracket("[", color) ~ s ~ _bracket("]", color);

	} elsif (ishash(o)) {
		if (contains(o, "parents") and isvec(o.parents)
				and size(o.parents) == 1 and o.parents[0] == props.Node)
			return _angle("'<", color) ~ _dump_prop(o, color) ~ _angle(">'", color);

		var k = keys(o);
		var s = "";
		forindex (var i; k)
			s ~= (i == 0 ? "" : ", ") ~ _dump_key(k[i], color) ~ ": " ~ debug.string(o[k[i]], color, ttl - 1);
		return _brace("{", color) ~ " " ~ s ~ " " ~ _brace("}", color);

	} elsif (isghost(o)) {
		return _angle("'<", color) ~ _nil(ghosttype(o), color) ~ _angle(">'", color);

	} else {
		return _angle("'<", color) ~ _vartype(t, color) ~ _angle(">'", color);
	}
}


var dump = func(vars...) {
	if (!size(vars))
		return local(1);
	if (size(vars) == 1)
		return print(debug.string(vars[0]));
	forindex (var i; vars)
		print(globals.string.color("33;40;1", "#" ~ i) ~ " ", debug.string(vars[i]));
}


var local = func(frame = 0) {
	var v = caller(frame + 1);
	print(v == nil ? _error("<no such frame>") : debug.string(v[0]));
	return v;
}

# According to the Nasal design doc funtions do not have unique internal names.
# Nevertheless you can sometimes find a matching symbol, so funcname may help to
# make debug output more helpful, but unfortunately you cannot rely on it.
var funcname = func(f) {
    if (!isfunc(f)) return "";
    var namespace = closure(f);
    
    foreach (var k; keys(namespace)) {
        if (isfunc(namespace[k])) {
            if (namespace[k] == f)
                return k;
        }
    }
    return "-unknown-";
}

# Write backtrace information.
#
# desc:
#   Text to write in first line.
# dump_vars:
#   If true, show info about variables.
# skip_level:
#   How many top-level stack frames to skip.
# shorten:
#   If greater than 10, max filename length before being trimmed.
#
var backtrace = func(desc = nil, dump_vars = 1, skip_level = 0, shorten = 50) {
    var d = (desc == nil) ? "" : " '" ~ desc ~ "'";
    print("");
    print(_title("### backtrace" ~ d ~ " ###"));
    skip_level += 1;
    for (var i = skip_level; 1; i += 1) {
        if ((var v = caller(i)) == nil) return caller(i - 1);
        var filename = v[2];
        var line = v[3];
        if (shorten >= 10 and size(filename) > shorten)
            filename = substr(filename, 0, 5)~"[...]"~substr(filename, -(shorten-10));
        print(_section(sprintf("#%-2d called from %s:%d (%s) (locals %s):", 
            i - skip_level, filename, line, funcname(v[1]), id(v[0]))));
        if (dump_vars) dump(v[0]);
    }
}
var bt = backtrace;


var proptrace = func(root = "/", frames = 2) {
	var events = 0;
	var trace = setlistener(propify(root), func(this, base, type) {
		events += 1;
		if (type > 0)
			print(_nil("ADD "), this.getPath());
		elsif (type < 0)
			print(_num("DEL "), this.getPath());
		else
			print("SET ", this.getPath(), " = ", debug.string(this.getValue()), " ", attributes(this));
	}, 0, 2);
	var mark = setlistener("/sim/signals/frame", func {
		print("-------------------- FRAME --------------------");
		if (!frames) {
			removelistener(trace);
			removelistener(mark);
			print("proptrace: stop (", events, " calls)");
		}
		frames -= 1;
	});
}


##
# Executes function fn "repeat" times and prints execution time in seconds. If repeat
# is an integer and an optional "output" argument is specified, each test's result
# is appended to that vector, then the vector is returned. If repeat is nil, then
# the function is run once and the result returned. Otherwise, the result is discarded.
# Examples:
#
#     var test = func { getprop("/sim/aircraft"); }
#     debug.benchmark("test()/1", test, 1000);
#     debug.benchmark("test()/2", func setprop("/sim/aircraft", ""), 1000);
#
#     var results = debug.benchmark("test()", test, 1000, []);
#     print("  Results were:");
#     print("    ", debug.string(results));
#
var benchmark = func(label, fn, repeat = nil, output=nil) {
	var start = var end = nil;
	if (repeat == nil) {
		start = systime();
		output = fn();
	} elsif (isvec(output)) {
		start = systime();
		for (var i = 0; i < repeat; i += 1)
			append(output, fn());
	} else {
		start = systime();
		for (var i = 0; i < repeat; i += 1)
			fn();
	}
	end = systime();
	print(_bench(sprintf(" %s --> %.6f s ", label, end - start)));
	return output;
}

var benchmark_time = func(fn, repeat = 1, output = nil) {
	var start = var end = nil;
	if (repeat == nil) {
		start = systime();
		output = fn();
	} elsif (isvec(output)) {
		start = systime();
		for (var i = 0; i < repeat; i += 1)
			append(output, fn());
	} else {
		start = systime();
		for (var i = 0; i < repeat; i += 1)
			fn();
	}
	end = systime();
	return end - start;
}

##
# Executes each function in the list and returns a sorted vector with the fastest
# on top (i.e. first). Each position in the result is a vector of [func, time].
#
var rank = func(list, repeat = nil) {
	var result = [];
	foreach (var fn; list) {
		var time = benchmark_time(fn, repeat);
		append(result, [fn, time]);
	}
	return sort(result, func(a,b) a[1] < b[1] ? -1 : a[1] > b[1] ? 1 : 0);
}

var print_rank = func(label, list, names) {
	print("Test results for "~label);
	var first = 1;
	var longest = list[-1][1];
	foreach (var item; list) {
		var (fn, time) = item;
		var name = nil;
		if (isvec(names)) {
			foreach (var l; names) {
				if (l[1] == fn) {
					name = l[0]; break;
				} elsif (l[0] == fn) {
					name = l[1]; break;
				}
			}
		} else {
			foreach (var name; keys(names)) {
				if (names[name] == fn) break;
				else name = nil;
			}
		}
		if (name == nil) die("function not found");
		print("  "~name~(first?" (fastest)":"")~" took "~(time*1000)~" ms ("~(time/longest*100)~"%) time");
		first = 0;
	}
	return list;
}


##
# print error vector as set by call(). By using call() one can execute
# code that catches "exceptions" (by a die() call or errors). The Nasal
# code doesn't abort in this case. Example:
#
#     var possibly_buggy = func { ... }
#     call(possibly_buggy, nil, var err = []);
#     debug.printerror(err);
#
var printerror = func(err) {
	if (!size(err))
		return;
	printf("%s:\n at %s, line %d", err[0], err[1], err[2]);
	for (var i = 3; i < size(err); i += 2)
		printf("  called from: %s, line %d", err[i], err[i + 1]);
}


# like die(), but code execution continues. The level argument defines
# how many caller() levels to omit. One is automatically omitted, as
# this would only point to debug.warn(), where the event in question
# didn't happen.
#
var warn = func(msg, level = 0) {
	var c = caller(level += 1);
	if (c == nil)
		die("debug.warn with invalid level argument");
	printf("%s:\n  at %s, line %d", msg, c[2], c[3]);
	while ((c = caller(level += 1)) != nil)
		printf("  called from: %s, line %d", c[2], c[3]);
}


var isnan = func {
	call(math.sin, arg, var err = []);
	return !!size(err);
}

# Probe class - collect statistics; controlled via property tree
# Data can be viewed / modified in the prop tree /_debug/nas/probe/<myLabel>/*
# ./enable    bool, 
# ./reset     bool, reset hit counters to 0 and _start_time to now
# ./hits[i]   number of hits, by default i=0 -> hits
#             secondary counters can be added under the same path 
#             with addCounter()
# ./time      after generateStats() show how long the probe was enabled
# ./hps       after generateStats() show avg. hits/second
# ./hitratio  after generateStats() if two counters: hits[1]/hits[0]
#
# == Example == 
# var myProbe = debug.Probe.new("myLabel").enable();
# var cnt2 = myProbe.addCounter(); # create a 2nd counter
#
# #at the place of interest (e.g. in some loop or class method) insert:
# myProbe.hit();        # count how often this place in the code is hit
# if (condition) 
#    myProbe.hit(cnt2); # count how often condition is true
#
# print(myProbe.getHits()); 
# print(myProbe.getHits(cnt2)/myProbe.getHits()); # print hit ratio
#
var Probe = {
    _instances: {},
    
    _uid: func(label, class) {
        class = globals.string.replace(class, " ", "_");
        label = globals.string.replace(label, " ", "_");
        label = globals.string.replace(label, "/", "_");
        label = globals.string.replace(label, "\\", "_");
        return class~"-"~label;
    },
    
    # label:       Used in property path 
    # prefix:      Optional 
    new: func(label, class = "probe") {
        if (!isscalar(label) or !isscalar(class)) {
            die("Invalid argument type to Probe.new");
        }
        var uid = me._uid(label,class);
        if (Probe._instances[uid] != nil) return Probe._instances[uid];
        
        var obj = {
            parents: [Probe],
            uid: uid,
            label: label,
            hits: [0],
            node: nil,
            _enableN: nil,
            _resetN: nil,
            _hitsN: [],
            _start_time: 0,
            _stop_time: 0,
            _timeoutN: nil,   # > 0, disable probe after _timeout seconds
            _L: [],
        };

        obj.node = props.globals.getNode("/_debug/nas/"~class~"/"~label, 1);
        obj.node.removeChildren();
        obj._enableN = obj.node.addChild("enable");
        obj._enableN.setBoolValue(0);
        append(obj._L, 
            setlistener(obj._enableN, func(n) {
                if (n.getValue()) obj.enable();
                else obj.disable();
            }, 0, 0)
        );
       
        obj._resetN = obj.node.addChild("reset");
        obj._resetN.setBoolValue(0);
        append(obj._L, 
            setlistener(obj._resetN, func(n) {
                if (n.getValue()) {
                    obj.reset();
                    n.setValue(0);
                }
            }, 0, 0)
        );
        
        append(obj._hitsN, obj.node.addChild("hits"));
        obj._hitsN[0].setIntValue(0);
        # for live monitoring via prop browser, alias all hit counters in one place
        props.globals.getNode("/_debug/nas/_stats/"~obj.uid, 1)
            .alias(obj._hitsN[0]);
        Probe._instances[obj.uid] = obj;
        return obj;
    },
    
    del: func () {
        foreach (var l; me._L) {
            removelistener(l);
        }
        me.node.remove();
        Probe._instances[me.uid] = nil;
    },
    
    reset: func {
        forindex (var i; me.hits) {
            me.hits[i] = 0;
            me._hitsN[i].setValue(0);
        }
        me._start_time = systime();
    },
    
    # set timeout, next hit() after timeout will disable()
    setTimeout: func(seconds) {
        if (!isa(me._timeoutN, props.Node))
            me._timeoutN = me.node.getNode("timeout", 1);
        me._timeoutN.setValue(num(seconds) or 0);
        return me;
    },
    
    #enable counting 
    enable: func {
        me._enableN.setValue(1);
        me._start_time = systime();
        return me;
    },
    
    #disable counting, write time and hit/s to property tree
    disable: func {
        me._enableN.setValue(0);
        me._stop_time = systime();
        me.generateStats();
        return me;
    },

    generateStats: func {
        if (me._start_time) {
            if (me._enableN.getValue())
                me._stop_time = systime();
            var dt = me._stop_time - me._start_time;
            me.node.getNode("time", 1).setValue(dt);
            me.node.getNode("hps", 1).setValue(me.hits[0] / dt );
            if (size(me.hits) == 2)
                me.node.getNode("hitratio",1).setValue(me.hits[1] / me.hits[0] or 1);
        }
    },
    
    getHits: func(counter_id = 0) {
        return me.hits[counter_id];
    },
    
    # add secondary counter(s)
    # returns counter id
    addCounter: func {
        append(me._hitsN, me.node.addChild("hits"));
        append(me.hits, 0);
        return size(me._hitsN) - 1;
    },
    
    # increment counter (if enabled)
    # use addCounter() before using counter_id > 0
    hit: func(counter_id = 0, callback = nil) {
        if (me._enableN.getValue()) {
            if (counter_id >= size(me._hitsN)) {
                print("debug.Probe.hit(): Invalid counter_id");
                me.disable();
                return nil;
            }
            if (isa(me._timeoutN, props.Node)) {
                var timeout = me._timeoutN.getValue();
                if (timeout and systime() - me._start_time > timeout) {
                    return me.disable();
                }
            }
            me.hits[counter_id] += 1;
            me._hitsN[counter_id].increment();
            if (isfunc(callback)) {
                callback(me.hits);
            }
        }
        return me;
    },
};

# Breakpoint (BP) - do conditional backtrace (BT) controlled via property tree
# * count how often the BP was hit
# * do only a limited number of BT, avoid flooding the log / console
# 
# Data can be viewed / modified in the prop tree /_debug/nas/bp/<myLabel>/*
# * tokens: number of backtraces to do; each hit will decrement this by 1
# * hits:   total number of hits
#
# == Example == 
# var myBP = debug.Breakpoint.new("myLabel", 0);
# myBP.enable(4);       # allow 4 hits, then be quiet 
# 
# #at the place of interest (e.g. in some loop or class method) insert:
# myBP.hit();           # do backtrace here if tokens > 0, reduce tokens by 1
# myBP.hit(myFunction); # same but call myFunction instead of backtrace
#
# print(myBP.getHits()); # print total number of hits
#
var Breakpoint = {
    
    # label:       Used in property path and as text for backtrace.
    # dump_locals: bool passed to backtrace. Dump variables in BT.
    # skip_level:  int passed to backtrace. 
    new: func(label, dump_locals = 0, skip_level=0) {
        var obj = {
            parents: [Breakpoint, Probe.new(label, "bp")],
            tokens: 0,
            skip_level: num(skip_level+1), # +1 for Breakpoint.hit()
            dump_locals: num(dump_locals),
        };
        obj._enableN.remove();
        obj._enableN = obj.node.getNode("tokens", 1);
        obj._enableN.setIntValue(0);

        return obj;
    },

    # enable BP and set hit limit; 
    # tokens: int > 0; default: 1 (single shot); 0 allowed (=disable); 
    enable: func(tokens = 1) {
        if (num(tokens) == nil) tokens = 1;
        if (tokens < 0) tokens = 0;
        me.tokens = tokens;
        me._enableN.setIntValue(tokens);
        return me;
    },
    
    # hit the breakpoint, e.g. do backtrace if we have tokens available
    hit: func(callback = nil) {
        me.hits[0] += 1;
        me._hitsN[0].increment();
        me.tokens = me._enableN.getValue() or 0;
        if (me.tokens > 0) {
            me.tokens -= 1;
            if (isfunc(callback)) {
                callback(me.hits[0], me.tokens);
            }
            else {
                debug.backtrace(me.label, me.dump_locals, me.skip_level);
            } 
            me._enableN.setValue(me.tokens);
        }
        return me;
    },

};

# Tracer - perform conditional backtraces / statistics controlled via property tree
# * backtraces are written to property tree
# * do only a limited number of BT, avoid flooding the log / console
# * trace statistics can be dumped to XML file
# 
# Data can be viewed / modified in the prop tree /_debug/nas/trc/<myLabel>/*
# * tokens: number of backtraces to do; each hit will decrement this by 1
# * hits:   total number of hits
#
# == Example == 
# var myBP = debug.Tracer.new("myLabel", 0);
# myBP.enable(4);       # allow 4 hits, then be quiet 
# 
# #at the place of interest (e.g. in some loop or class method) insert:
# myBP.hit();           # do backtrace here if tokens > 0, reduce tokens by 1
# myBP.hit(myFunction); # same but call myFunction instead of backtrace
#
# print(myBP.getHits()); # print total number of hits
#
var Tracer = {
    
    # label:       Used in property path and as text for backtrace.
    # dump_locals: bool passed to backtrace. Dump variables in BT.
    # skip_level:  int passed to backtrace. 
    new: func(label, dump_locals = 0, skip_level=0) {
        var obj = {
            parents: [Tracer, Probe.new(label, "trc")],
            tokens: 0,
            skip_level: num(skip_level+1), # +1 for Tracer.hit()
            dump_locals: num(dump_locals),
        };
        obj._enableN.remove();
        obj._enableN = obj.node.getNode("tokens", 1);
        obj._enableN.setIntValue(0);

        obj._dumpN = obj.node.addChild("dump-trace");
        obj._dumpN.setBoolValue(0);
        append(obj._L, 
            setlistener(obj._dumpN, func(n) {
                if (n.getValue() == 1) obj.dumpTrace();
                n.setBoolValue(0);
            }, 0, 0)
        );
        
        obj._resetTraceN = obj.node.addChild("reset-trace");
        obj._resetTraceN.setBoolValue(0);
        append(obj._L, 
            setlistener(obj._resetTraceN, func(n) {
                if (n.getValue() == 1) obj.resetTrace();
                n.setBoolValue(0);
            }, 0, 0)
        );
        return obj;
    },

    # enable BP and set hit limit; 
    # tokens: int > 0; default: 1 (single shot); 0 allowed (=disable); 
    enable: func(tokens = 1) {
        if (num(tokens) == nil) tokens = 1;
        if (tokens < 0) tokens = 0;
        me.tokens = tokens;
        me._enableN.setIntValue(tokens);
        return me;
    },

    disableTracing: func() {
        me._enableN.setIntValue(0);
        return me;
    },
    
    resetTrace: func () {
        me.node.getNode("trace",1).remove();
    },

   
    hit: func(callback = nil) {
        me.hits[0] += 1;
        me._hitsN[0].increment();
        me.tokens = me._enableN.getValue() or 0;
        if (me.tokens > 0) {
            me.tokens -= 1;
            if (isfunc(callback)) {
                callback(me.hits[0], me.tokens);
            }
            me._enableN.setValue(me.tokens);
            me._trace(1);
        }
        return me;
    },

    #write backtrace to prop tree with counters
    _trace: func(skip=0) {
        var flat_mode = 0;
        if (!me._enableN.getValue()) return;
        me._enableN.decrement();
        var tn = me.node.getNode("trace",1);
        for (var i = skip + 1; 1; i += 1) {
            var c  = caller(i);
            if (c == nil) break;
            var fn = io.basename(c[2]);
            #invalid chars are : [ ] < > =
            fn = globals.string.replace(fn,":","_");
            fn = globals.string.replace(fn,"#","_");
            fn = globals.string.replace(fn,"<","_");
            fn = globals.string.replace(fn,">","_");
            if (!fn) fn = "_unknown_";
            var line = num(c[3]);
            var sid = fn~":"~line;
            if (flat_mode) {
                if (tn.getChild(fn,line) == nil) {
                    tn.getChild(fn,line,1).setIntValue(1);
                }
                else {
                    tn.getChild(fn,line).increment();
                }
            }
            else {
                tn = tn.getChild(fn,line,1);
                if (tn.getNode("hits") == nil) {
                    tn.getNode("hits",1).setIntValue(1);
                }
                else { 
                    tn.getNode("hits").increment(); 
                }
            }
        }
    },
    
    dumpTrace: func (path = nil) {
        #props.dump(me.node.getNode("trace",1));
        if (path == nil) {
            path = getprop("/sim/fg-home")~"/Export/dumpTrace-"~me.uid~".xml";
        }
        me.node.getNode("dump-result", 1).setValue(
            io.write_properties(path, me.node.getNode("trace",1))
        );
    },
}; #Tracer


# addProbeToFunc - wrap a function with a debug probe
# f:        function to wrap with a debug probe (hit counter)
# label:    description, passed to probe
#
# WARNING: call() currently breaks the call stack which affects backtrace and 
# the use of caller(i>0). Do not use addProbeToFunc on functions which rely on
# caller (which is probably bad coding style, but allowed).
#
var addProbeToFunc = func (f, label) {
    if (!isfunc(f)) {
        logprint(DEV_ALERT, "wrapFunc() error: argument is not a function.");
        return nil;
    }
    if (!isstr(label)) {
        logprint(DEV_ALERT, "wrapFunc() error: argument is not a string.");
        return nil;
    }
    var __probe = Probe.new(label).enable();
    var wrapped = func() {
        __probe.hit();
        return call(f, arg, me, );
    }
    return wrapped;
}

# addTracerToFunc - wrap a function with a debug breakpoint for tracing
# f:        function to wrap with a tracer
# label:    description, passed to breakpoint
#
# WARNING: call() currently breaks the call stack which affects backtrace and 
# the use of caller(i>0). Do not use addTracerToFunc on functions which rely on
# caller (which is probably bad coding style, but allowed).
#
var addTracerToFunc = func (f, label) {
    if (!isfunc(f)) {
        logprint(DEV_ALERT, "wrapFunc() error: argument is not a function.");
        return nil;
    }
    if (!isstr(label)) {
        logprint(DEV_ALERT, "wrapFunc() error: argument is not a string.");
        return nil;
    }
    var __trc = Tracer.new(label).enable();
    var wrapped = func() {
        __trc.hit();
        return call(f, arg, me, );
    }
    return wrapped;
}

# scan a hash for function references
# ns:           the hash to be searched
# recursive:    if you want to search sub hashes (e.g. classes), set this to 1
var findFunctions = func (ns, recursive = 0) {
    var functions = {};
    foreach (var key; keys(ns)) {
        if (recursive and ishash(ns[key]) and id(ns) != id(ns[key])) {
            print(key);
            var f = findFunctions(ns[key]);
            foreach (var k; keys(f)) {
                functions[key~"."~k] = f[k];
            }
        }
        if (isfunc(ns[key])) {
            functions[key] = ns[key];
        }
    }    
    return functions;
}

# add probes to all functions in a namespace for finding hotspots
# use property browser at runtime to check /_debug/nas/_stats/
# ns:           hash 
# label:        description, passed to probe

var _probed_ns = {};
var addProbesToNamespace = func (ns, label = "") {
    var nsid = id(ns);
    if (_probed_ns[nsid] != nil) return;
    else _probed_ns[nsid] = {};
       
    var funcs = findFunctions(ns, 0);
    foreach (var key; keys(funcs)) {
        _probed_ns[nsid][key] = funcs[key];
        ns[key] = addProbeToFunc(funcs[key], label~"-"~key);
    }
}

var removeProbesFromNamespace = func (ns) {
    var nsid = id(ns);
    if (_probed_ns[nsid] == nil) {
        logprint(DEV_ALERT, "removeProbesFromNamespace: namespace not found");
        return;
    }
        
    foreach (var key; keys(_probed_ns[nsid])) {
        ns[key] = _probed_ns[nsid][key];
    }
    _probed_ns[nsid] = nil;
}

# dump a sorted list of hit counters to console
var dumpProbeStats = func () {
    var nodes = props.getNode("/_debug/nas/_stats/", 1).getChildren();
    var data = [];
    foreach (var n; nodes) {
        append(data, {name: n.getName(), value: n.getValue()});
    }
    var mysort = func(a,b) {
        if (a.value > b.value) return -1;
        elsif (a.value == b.value) return 0;
        else return 1;
    }
    
    foreach (var probe; sort(data, mysort)) {
        print(probe.name," ",probe.value);
    }    
    return;
}

#-- Init -----------------------------------------------------------------------
# General purpose breakpoint for the lazy ones.
var bp = Breakpoint.new("default", 0);

var dumpN = props.getNode("/_debug/nas/_dumpstats", 1);
dumpN.setBoolValue(0);
setlistener(dumpN, func(n) {
    n.setBoolValue(0);
    debug.dumpProbeStats();
}, 0, 0);

# --prop:debug=1 enables debug mode with additional warnings
#

if (getprop("debug")) {
    var writewarn = func(f, p, r) {
        if (!r) {
            var hint = "";
            if ((var n = props.globals.getNode(p)) != nil) {
                if (!n.getAttribute("writable"))
                    hint = " (write protected)";
                elsif (n.getAttribute("tied"))
                    hint = " (tied)";
            }
            warn("Warning: " ~ f ~ " -> writing to " ~ p ~ " failed" ~ hint, 2);
        }
        return r;
    }

    setprop = (func { var _ = setprop; func writewarn("setprop",
            globals.string.join("", arg[:-2]), call(_, arg)) })();
    props.Node.setDoubleValue = func writewarn("setDoubleValue", me.getPath(),
            props._setDoubleValue(me._g, arg));
    props.Node.setBoolValue = func writewarn("setBoolValue", me.getPath(),
            props._setBoolValue(me._g, arg));
    props.Node.setIntValue = func writewarn("setIntValue", me.getPath(),
            props._setIntValue(me._g, arg));
    props.Node.setValue = func writewarn("setValue", me.getPath(),
            props._setValue(me._g, arg));
}
