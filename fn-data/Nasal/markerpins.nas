var pin_update_timer = nil;

var navPins = {};
var poiPins = {};
var trafficPins = {};
var trafficAddListener = nil;
var trafficRemoveListener = nil;

var enabled = {
        master: 0,
        airports: 0,
        navaids: 0,
        fixes: 0,
        pois: 0,
        traffic: 0,
    };

var update_pins = func () {
    var navs = [];
    if (enabled.master) {
        if (enabled.airports) {
            airports = findAirportsWithinRange(50);
            navs = navs ~ airports;
        }
        if (enabled.navaids) {
            navaids = findNavaidsWithinRange(50, "vor") ~
                      findNavaidsWithinRange(50, "ndb") ~
                      findNavaidsWithinRange(20, "ils") ~
                      findNavaidsWithinRange(20, "loc");
            navs = navs ~ navaids;
        }
        if (enabled.fixes) {
            # navaids = findNavaidsWithinRange(50, "fix");
            # navs = navs ~ navaids;
        }
        if (enabled.pois) {
            navaids = findNavaidsWithinRange(50, "city") ~
                      findNavaidsWithinRange(15, "town") ~
                      findNavaidsWithinRange(5, "village");
            navs = navs ~ navaids;
        }
    }

    foreach (var k; keys(navPins)) {
        navPins[k].alive = 0;
    }
    foreach (var nav; navs) {
        var pin = navPins[nav.id];
        if (pin == nil) {
            var color = [1, 1, 1];
            var height = 600;
            var fsize = 128;
            var elevation = nav.elevation;
            if (elevation == nil or elevation == 0) {
                elevation = geo.elevation(nav.lat, nav.lon);
            }
            if (elevation == nil) {
                continue;
            }
            elevation = elevation * M2FT;
            if (ghosttype(nav) == "airport") {
                color = [1, 0, 0];
                fsize = 256;
                height = 1200;
            }
            else {
                if (nav.type == "VOR") {
                    color = [0, 0.5, 1];
                    fsize = 160;
                    height = 900;
                }
                elsif (nav.type == "NDB") {
                    color = [0.5, 0.25, 0];
                    fsize = 128;
                    height = 700;
                }
                elsif (nav.type == "LOC" or nav.type == "ILS") {
                    color = [0, 1, 1];
                    fsize = 32;
                    height = 50;
                }
                elsif (nav.type == "FIX") {
                    color = [1, 1, 0];
                    fsize = 64;
                    height = 900;
                }
                elsif (nav.type == "city") {
                    color = [1, 1, 1];
                    fsize = 256;
                    height = 600;
                }
                elsif (nav.type == "town") {
                    color = [1, 1, 1];
                    fsize = 128;
                    height = 300;
                }
                elsif (nav.type == "village") {
                    color = [1, 1, 1];
                    fsize = 64;
                    height = 150;
                }
            }
            pin = {
                marker: geo.put_marker(nav.id, nav.lat, nav.lon, elevation, color, fsize, height),
            };
            navPins[nav.id] = pin;
        }
        navPins[nav.id].alive = 1;
    }
    foreach (var k; keys(navPins)) {
        if (!navPins[k].alive) {
            navPins[k].marker.remove();
            delete(navPins, k);
        }
    }
};

var toggleTrafficPins = func (node) {
    if (node.getBoolValue()) {
        # turn on
        print("Traffic pins on");
        var modelsNode = props.getNode('/ai/models');
        var nodes = modelsNode.getChildren('multiplayer') ~
                    modelsNode.getChildren('swift') ~
                    modelsNode.getChildren('aircraft');
        foreach (var k; keys(trafficPins)) {
            trafficPins[k].alive = 0;
        }
        var addTraffic = func (node, retry=3) {
            var nodeID = node.getName() ~ ':' ~ node.getIndex();
            var callsign = node.getValue('callsign');
            printf("Adding traffic: %s [%s]", nodeID, node.getValue('callsign'));
            if (callsign == nil) {
                if (retry > 0) {
                    # try again in 1 second
                    settimer(func { addTraffic(node, retry-1); }, 1);
                }
                else {
                    printf("Giving up on %s", nodeID);
                }
            }
            else {
                var pin = trafficPins[nodeID];
                if (pin == nil) {
                    var elev_prop = node.getPath() ~ '/position/altitude-ft';
                    var lat_prop = node.getPath() ~ '/position/latitude-deg';
                    var lon_prop = node.getPath() ~ '/position/longitude-deg';
                    pin = {
                        marker: geo.put_marker(callsign, lat_prop, lon_prop, elev_prop, [1,1,0], 10, 15, 5),
                    };
                    trafficPins[nodeID] = pin;
                }
                trafficPins[nodeID].alive = 1;
            }
        };
        foreach (var node; nodes) {
            if (node.getValue('valid')) {
                addTraffic(node);
            }
        }
        trafficRemoveListener = setlistener('/ai/models/model-removed', func(n) {
            var path = n.getValue();
            var node = props.getNode(path);
            var nodeID = node.getName() ~ ':' ~ node.getIndex();
            if (trafficPins[nodeID] != nil) {
                trafficPins[nodeID].marker.remove();
                delete(trafficPins, nodeID);
            }
        });
        trafficAddListener = setlistener('/ai/models/model-added', func (n) {
            var path = n.getValue();
            var node = props.getNode(path);
            addTraffic(node);
        });
        foreach (var k; keys(trafficPins)) {
            if (!trafficPins[k].alive) {
                trafficPins[l].marker.remove();
                delete(trafficPins, k);
            }
        }
    }
    else {
        # turn off
        print("Traffic pins off");
        if (trafficAddListener != nil) removelistener(trafficAddListener);
        if (trafficRemoveListener != nil) removelistener(trafficRemoveListener);
        foreach (var k; keys(trafficPins)) {
            trafficPins[k].marker.remove();
        }
        trafficPins = {};
    }
};

var fdm_init_listener = setlistener("/sim/signals/fdm-initialized", func {
	removelistener(fdm_init_listener); # uninstall, so we are only called once

    foreach (var k; ['master', 'airports', 'navaids', 'fixes', 'pois', 'traffic']) {
        var path = '/sim/marker-pins/' ~ k;
        var node = props.getNode(path);
        if (node == nil) {
            node = props.getNode(path, 1);
            node.setBoolValue(0);
            node.setAttribute('userarchive', 'y');
        }
        if (k == 'traffic') {
            setlistener(path, toggleTrafficPins, 1, 0);
        }
        else {
            setlistener(path, (func (key) { return func (p) { enabled[key] = p.getBoolValue(); }; })(k), 1, 0);
        }
    }
    var timer = maketimer(1, update_pins);

    timer.start();
});
