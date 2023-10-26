/**
###########################################################################
# knockprops - knockout.js <-> flightgear properties bridge 
# (c) 2015 Torsten Dreyer
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
############################################################################
 */
define(['knockout'], function(ko) {
    
    function KnockProps() {

        var self = this;

        self.initWebsocket = function() {
            self.ws = new WebSocket('ws://' + location.host + '/PropertyListener');

            self.ws.onclose = function(ev) {
                var msg = 'Lost connection to FlightGear. Should I try to reconnect?';
                if (confirm(msg)) {
                    // try reconnect
                    self.initWebsocket();
                } else {
                    throw new Error(msg);
                }
            }

            self.ws.onerror = function(ev) {
                var msg = 'Error communicating with FlightGear. Please reload this page and/or restart FlightGear.';
                alert(msg);
                throw new Error(msg);
            }

            self.ws.onmessage = function(ev) {
                try {
                    self.fire(JSON.parse(ev.data));
                } catch (e) {
                }
            };

            self.openCache = [];
            self.ws.onopen = function(ev) {
                // send subscriptions when the socket is open
                var c = self.openCache;
                delete self.openCache;
                c.forEach(function(e) {
                    self.addListener(e.prop, e.koObservable);
                });
                for ( var p in self.listeners) {
                    self.addListener(p, self.listeners[p]);
                }
            };
        }

        self.initWebsocket();

        self.fire = function(json) {
            var value = json.value;
            var listeners = self.listeners[json.path] || [];
            listeners.forEach(function(koObservable) {
                koObservable(value)
            });
            koObservable(json.value);
        }

        function resolvePropertyPath(self, pathOrAlias) {
            if (pathOrAlias in self.aliases)
                return self.aliases[pathOrAlias];
            if (pathOrAlias.charAt(0) == '/')
                return pathOrAlias;
            return null;
        }

        self.listeners = {}

        self.removeListener = function(pathOrAlias, koObservable) {
            var path = resolvePropertyPath(self, pathOrAlias);
            if (path == null) {
                console.log("can't remove listener for " + pathOrAlias + ": unknown alias or invalid path.");
                return self;
            }

            var listeners = self.listeners[path] || [];
            var idx = listeners.indexOf(koObservable);
            if (idx == -1) {
                console.log("can't remove listener for " + path + ": not a listener.");
                return self;
            }

            listeners.splice(idx, 1);

            if (0 == listeners.length) {
                self.ws.send(JSON.stringify({
                    command : 'removeListener',
                    node : path
                }));
            }

            return self;
        }

        self.addListener = function(alias, koObservable) {
            if (self.openCache) {
                // socket not yet open, just cache the request
                self.openCache.push({
                    "prop" : alias,
                    "koObservable" : koObservable
                });
                return self;
            }

            var path = resolvePropertyPath(self, alias);
            if (path == null) {
                console.log("can't listen to " + alias + ": unknown alias or invalid path.");
                return self;
            }

            var listeners = self.listeners[path] = (self.listeners[path] || []);
            if (listeners.indexOf(koObservable) != -1) {
                console.log("won't listen to " + path + ": duplicate.");
                return self;
            }

            koObservable.fgPropertyPath = path;
            koObservable.fgBaseDispose = koObservable.dispose;
            koObservable.dispose = function() {
                if (this.fgPropertyPath) {
                    self.removeListener(this.fgPropertyPath, this);
                }
                this.fgBaseDispose.call(this);
            }
            listeners.push(koObservable);
            koObservable.fgSetPropertyValue = function(value) {
                self.setPropertyValue(this.fgPropertyPath, value);
            }

            if (1 == listeners.length) {
                self.ws.send(JSON.stringify({
                    command : 'addListener',
                    node : path
                }));
            }
            self.ws.send(JSON.stringify({
                command : 'get',
                node : path
            }));

            return self;
        }

        self.aliases = {};
        self.setAliases = function(arg) {
            if( Object.prototype.toString.call( arg ) === '[object Array]' ) {
                // [
                //  [ shortcut, propertypath ],
                //  [ othercut, otherproperty ],
                // ]
                arg.forEach(function(a) {
                    self.aliases[a[0]] = a[1];
                });
            } else {
                self.aliases = arg;
            }
        }

        self.addAliases = function(arg) {
            self.aliases = self.aliases || {};

            for( var p in arg ) {
                if( self.aliases.hasOwnProperty(p) ) {
                    console.log(p + " is already a property alias. Skipping.");
                    continue;
                }
                self.aliases[p] = arg[p];
            }
        }

        self.makeObservablesForAllProperties = function(target, aliases ) {
            aliases = aliases || self.aliases;

            for( var p in aliases ) {
                if( aliases.hasOwnProperty(p) ) {
                    target[p] = ko.observable().extend({
                        fgprop : p
                    }).extend({
                        rateLimit: 40
                    });
                }
            }
        }

        self.props = {};

        self.get = function(target, prop) {
            if (self.props[prop]) {
                return self.props[prop];
            }

            return (self.props[prop] = self.observedProperty(target, prop));
        }

        self.observedProperty = function(target, prop) {
            var reply = ko.pureComputed({
                read : target,
                write : function(newValue) {
                    if (newValue == target())
                        return;
                    target(newValue);
                    target.notifySubscribers(newValue);
                }
            });
            self.addListener(prop, reply);
            return reply;
        }

        self.write = function(prop, value) {
            var path = this.aliases[prop] || "";
            if (path.length == 0) {
                console.log("can't write " + prop + ": unknown alias.");
                return;
            }

            self.setPropertyValue(path, value);
        }

        self.setPropertyValue = function(path, value) {
            this.ws.send(JSON.stringify({
                command : 'set',
                node : path,
                value : value
            }));
        }

        self.propsToObject = function(prop, map, result) {
            result = result || {}
            prop.children.forEach(function(prop) {
                var target = map[prop.name] || null;
                if (target) {
                    if (typeof (result[target]) === 'function') {
                        result[target](prop.value);
                    } else {
                        result[target] = prop.value;
                    }
                }
            });
            return result;
        }
    }

    ko.utils.knockprops = new KnockProps();
    
    ko.extenders.fgprop = function(target, prop) {
        return ko.utils.knockprops.get(target, prop);
    };

    ko.extenders.observedProperty = function(target, prop) {
        return ko.utils.knockprops.observedProperty(target, prop);
    };

    /*
    ko.extenders.fgPropertyGetSet = function(target, option) {

        fgCommand.getPropertyValue(option, function(value) {
            target(value);
        }, self);

        var p = ko.pureComputed({
            read : target,
            write : function(newValue) {
                if (newValue == target())
                    return;
                target(newValue);
                target.notifySubscribers(newValue);
                fgCommand.setPropertyValue(option, newValue);
            }
        });
        return p;
    }
    */

    // don't return anything, use ko.extenders or ku.utils.knockprops

});