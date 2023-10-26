# SPDX-License-Identifier: GPL-2.0-or-later
#
# NOTE! This copyright does *not* cover user models that use these Nasal
# services by normal function calls - this is merely considered normal use
# of the code, and does *not* fall under the heading of "derived work."
#-------------------------------------------------------------------------------
# hash.nas - simple hash class for development, allows to add callback on write
# author:       Henning Stahlke
# created:      07/2020
#-------------------------------------------------------------------------------

#load only once (via /Nasal/std.nas) not via C++ module loader
if (ishash(globals["std"]) and ishash(std["Hash"])) 
    return;

Hash = {
    new: func(hash=nil, name="") {
        var obj = {
            parents: [me],
            name: name,
            _h: {},
            _callback: func,
        };
        if (ishash(hash)) 
            obj._h = hash;
        return obj;
    },
   
    set: func (key, value) {
        me._h[key] = value;
        me._callback(key, value);
        return me;
    },
    
    get: func (key) {
        return me._h[key];
    },

    clear: func() {
        me._h = {};
        return me;
    },
    
    contains: func(key) {
        return contains(me._h, key);
    },
    
    getName: func () {
        return me.name;
    },
    
    getKeys: func () {
        return keys(me._h);
    },
    
    # export keys to props p/<keys>
    # p:    root property path or props.Node object
    keys2props: func (p) {
        if (!isa(p, props.Node)) {
            p = props.getNode(p, 1);
        }
        foreach (var key; keys(me._h)) {
            p.getNode(key, 1);
        }
        return me;
    },
    
    # export hash to props p/<key>=<value>
    # p:    root property path or props.Node object
    hash2props: func (p) {
        if (!isa(p, props.Node)) {
            p = props.getNode(p, 1);
        }
        p.setValues(me._h);
        return me;
    },
    
    # callback for set()
    addCallback: func (f) {
        if (isfunc(f)) {
            me._callback = f;
            return me;
        }
        return nil;
    },
};
