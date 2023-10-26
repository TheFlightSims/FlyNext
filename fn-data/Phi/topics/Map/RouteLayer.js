(function(factory) {
    if (typeof define === "function" && define.amd) {
        // AMD. Register as an anonymous module.
        define([
                'leaflet', 'props', './MapIcons', 'knockout', 'geodesic'
        ], factory);
    } else {
        // Browser globals
        factory();
    }
}(function(leaflet, SGPropertyNode, MAP_ICON, ko) {

    leaflet.RouteLayer = leaflet.GeoJSON.extend({
        options : {

            style : function(feature) {
                if (feature.geometry.type == "LineString")
                    return {
                        'color' : '#4d56db',
                        'lineCap' : 'round',
                        'dashArray' : '20,10,5,5,5,10',
                        'weight' : '2',
                    }
            },
        },
        onAdd : function(map) {
            var self = this;
            leaflet.GeoJSON.prototype.onAdd.call(self, map);
            self.waypointCount = ko.observable(0).extend({
                observedProperty : '/autopilot/route-manager/route/num'
            });
            self.waypointCountSubscription = self.waypointCount.subscribe(function() {
                self.update();
            });

            self.geodesic = L.geodesic([], {
                weight: 5,
                opacity: 0.5,
                color: 'blue',
                steps: 20,
            }).addTo(map);
        },

        onRemove : function(map) {
            var self = this;
            self.waypointCountSubscription.dispose();
            self.waypointCount.dispose();
            map.removeLayer(self.geodesic);
            leaflet.GeoJSON.prototype.onRemove.call(this, map);
        },

        stop : function() {
            if (this.waypointCountSubscription) {
                this.waypointCountSubscription.dispose();
                this.waypointCount.dispose();
            }
        },

        update : function(id) {
            var self = this;

            var url = "/json/autopilot/route-manager/route?d=3";
            var jqxhr = $.get(url).done(function(data) {
                self.clearLayers();
                var geoJSON = self.routePropsToGeoJson(data);
                if (geoJSON) {
                    self.addData(geoJSON);
                    var latlngs = [];
                    geoJSON.features.forEach( function(f) {
                        if( f.geometry && f.geometry.coordinates )
                            latlngs.push( new L.LatLng(f.geometry.coordinates[1], f.geometry.coordinates[0] ) );
                    });
                    self.geodesic.setLatLngs([latlngs]);
                }
            }).fail(function(a, b) {
                // self.stop(); // TODO: Should we?
                alert('failed to load RouteManager data');
            }).always(function() {
            });
        },

        routePropsToGeoJson : function(props) {
            var geoJSON = {
                type : "FeatureCollection",
                features : [],
            };

            var root = new SGPropertyNode(props);
            root.getChildren("wp").forEach(function(wp) {
                var id = wp.getNode("id");
                var lon = wp.getNode("longitude-deg").getValue();
                var lat = wp.getNode("latitude-deg").getValue();

                var position = [
                        lon, lat
                ];

                geoJSON.features.push({
                    "type" : "Feature",
                    "geometry" : {
                        "type" : "Point",
                        "coordinates" : position,
                    },
                    "id" : id,
                    "properties" : {},
                });
            });

            if (geoJSON.features.length >= 2)
                return geoJSON;
        },

    });

    leaflet.routeLayer = function(options) {
        return new leaflet.RouteLayer(null, options);
    }

}));
