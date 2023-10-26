(function(factory) {
    if (typeof define === "function" && define.amd) {
        // AMD. Register as an anonymous module.
        define([
            'leaflet'
        ], factory);
    } else {
        // Browser globals
        factory(L);
    }
}(function(leaflet) {

    function SquareIcon(w, url) {
        return leaflet.icon({
            iconSize : [
                    w, w
            ],
            iconAnchor : [
                    w / 2, w / 2
            ],
            popupAnchor : [
                    0, w / 2 - 2
            ],
            iconUrl : url,
        })
    }

    var MAP_ICON = {};
    MAP_ICON["VOR"] = SquareIcon(30, 'images/vor.svg');
    MAP_ICON["NDB"] = SquareIcon(30, 'images/ndb.svg');
    MAP_ICON["dme"] = SquareIcon(30, 'images/dme.svg');
    MAP_ICON["fix"] = SquareIcon(20, 'images/fix.svg');
    MAP_ICON["airport-paved"] = SquareIcon(30, 'images/airport-paved.svg');
    MAP_ICON["airport-unpaved"] = SquareIcon(30, 'images/airport-unpaved.svg');
    MAP_ICON["airport-unknown"] = SquareIcon(30, 'images/airport-unknown.svg');
    MAP_ICON["arp"] = SquareIcon(30, 'images/arp.svg');
    MAP_ICON["aircraft"] = SquareIcon(20, 'images/aircraft.svg');

    return MAP_ICON;
}));

