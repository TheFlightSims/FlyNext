/**
 * 
 */
(function(factory) {
    if (typeof define === "function" && define.amd)// AMD. Register as an
                                                    // anonymous module.
        define([
            'jquery'
        ], factory);
    else
        // Browser globals
        factory(jQuery);
}(function(jquery) {

    fgCommand = {
        oneArg : function(t1, p1) {
            return {
                name : '',
                children : [
                    {
                        name : t1,
                        index : 0,
                        value : p1
                    }
                ]
            };
        },
        twoArgs : function(t1, p1, t2, p2) {
            return {
                name : '',
                children : [
                        {
                            name : t1,
                            index : 0,
                            value : p1
                        }, {
                            name : t2,
                            index : (t1 == t2 ? 1 : 0),
                            value : p2
                        }
                ]
            };
        },

        twoPropsArgs : function(p1, p2) {
            return this.twoArgs("property", p1, "property", p2);
        },

        propValueArgs : function(p, v) {
            return this.twoArgs("property", p, "value", v);
        },

        sendCommand : function(name, args) {
            if (typeof (args) == 'undefined ')
                jquery.post("/run.cgi?value=" + name);
            else
                jquery.post("/run.cgi?value=" + name, JSON.stringify(args));
        },

        propertySwap : function(p1, p2) {
            this.sendCommand("property-swap", this.twoPropsArgs(p1, p2));
        },

        propertyAssign : function(p1, value) {
            this.sendCommand("property-assign", this.propValueArgs(p1, value));
        },

        pause : function() {
            jquery.post("/run.cgi?value=pause");
        },

        reset : function() {
            jquery.post("/run.cgi?value=reset");
        },

        exit : function() {
            jquery.post("/run.cgi?value=exit");
        },

        reinit : function(subsys) {
            var arg = {
                name : '',
                children : []
            };
            if (typeof (subsys) === 'string')
                arg.children.push({
                    name : 'subsystem',
                    index : 0,
                    value : subsys
                });
            else
                subsys.forEach(function(s, i) {
                    arg.children.push({
                        name : 'subsystem',
                        index : i,
                        value : s
                    });
                });
            this.sendCommand("reinit", arg);
        },

        dialogShow : function(dlg) {
            this.sendCommand("dialog-show", this.oneArg("dialog-name", dlg));
        },
        dialogClose : function(dlg) {
            this.sendCommand("dialog-close", this.oneArg("dialog-name", dlg));
        },
        reposition : function() {
            jquery.post("/run.cgi?value=reposition");
        },
        timeofday : function(type, offset) {
            this.sendCommand("timeofday", this.twoArgs("timeofday", type, "offset", null != offset ? offset : 0));
        },
        switchAircraft : function(id) {
            this.sendCommand("switch-aircraft", this.oneArg("aircraft", id));
        },

        requestMetar : function(id, path) {
            this.sendCommand("request-metar", this.twoArgs("station", id, "path", path));
        },

        togglepause : function() {
            this.sendCommand("pause");
        },

        unpause : function() {
            this.sendCommand("pause", this.oneArg("force-play", true));
        },

        pause : function() {
            this.sendCommand("pause", this.oneArg("force-pause", true));
        },

        multiplayerConnect : function(cmd) {
            cmd = cmd || {};
            var arg = {
                'name' : '',
                'children' : [],
            };
            arg.children.push({
                'name' : 'servername',
                'value' : cmd.servername
            });
            if (cmd.rxport)
                arg.children.push({
                    'name' : 'rxport',
                    'value' : Number(cmd.rxport)
                });
            if (cmd.txport)
                arg.children.push({
                    'name' : 'txport',
                    'value' : Number(cmd.txport)
                });
            this.sendCommand("multiplayer-connect", arg);
        },

        multiplayerDisconnect : function() {
            var arg = {
                'name' : '',
                'children' : [],
            };
            this.sendCommand("multiplayer-disconnect");
        },

        multiplayerRefreshserverlist : function() {
            this.sendCommand('multiplayer-refreshserverlist');
        },

        clearMetar : function(path) {
            this.sendCommand("clear-metar", this.oneArg("path", path));
        },

        profilerStart : function(filename) {
            this.sendCommand("profiler-start", filename ? this.oneArg("filename", filename) : null );
        },

        profilerStop : function() {
            this.sendCommand("profiler-stop");
        },

        // not really commands, but very useful to get/set a single properties
        // value
        getPropertyValue : function(path, callback, context) {
            var url = "/json/" + path;

            jquery.get(url).done(function(data) {
                if (context)
                    callback.call(context, data.value);
                else
                    callback(data.value);
            }).fail(function(a, b) {
                console.log("failed to getPropertyValue(): ", a, b);
            }).always(function() {
            });
        },

        setPropertyValue : function(path, value, callback, context) {
            if( value == null )
              return;

            var url = "/json/" + path;
            switch( typeof(value) ) {
              case 'number':
              case 'string':
              case 'boolean':
                jquery.post(url, JSON.stringify({
                    'value' : value
                })).done(function(data){
                  if( !callback ) return;
                  if (context) callback.call(context, data.value);
                  else callback(data.value);
                });
                return;

              case 'object':
                jquery.post(url, JSON.stringify(value)).done(function(data){
                  if( !callback ) return;
                  if (context) callback.call(context, data.value);
                  else callback(data.value);
                });
                return;

              default:
                return;
            }
        },
    };

    return fgCommand;
}));
