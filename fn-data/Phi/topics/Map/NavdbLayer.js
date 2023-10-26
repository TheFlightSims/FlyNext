(function(factory) {
    if (typeof define === "function" && define.amd) {
        // AMD. Register as an anonymous module.
        define([
            'leaflet','./MapIcons'
        ], factory);
    } else {
        // Browser globals
        factory();
    }
}(function(leaflet,MAP_ICON) {

    leaflet.NavdbLayer = leaflet.GeoJSON.extend({
        options : {
            pointToLayer : function(feature, latlng) {
                var options = {
                    title : feature.properties.id + ' (' + feature.properties.name + ')',
                    alt : feature.properties.id,
                    riseOnHover : true,
                };

                if (feature.properties.type == "airport") {
                    if (this._map && this._map.getZoom() >= 13) {
                        options.icon = MAP_ICON['arp'];
                    } else {
                        options.angle = feature.properties.longestRwyHeading_deg;
                        switch (feature.properties.longestRwySurface) {
                        case 'asphalt':
                        case 'concrete':
                            options.icon = MAP_ICON['airport-paved'];
                            break;
                        case 'unknown':
                            options.icon = MAP_ICON['airport-unknown'];
                            break;
                        default:
                            options.icon = MAP_ICON['airport-unpaved'];
                            break;
                        }
                    }
                } else {
                    if (feature.properties.type in MAP_ICON) {
                        options.icon = MAP_ICON[feature.properties.type];
                    }
                }

                return new leaflet./*Rotated*/Marker(latlng, options);
            },

            onEachFeature : function(feature, layer) {
                if (feature.properties) {
                    var popupString = '<div class="popup">';
                    for (var k in feature.properties) {
                        var v = ""
                        switch (k) {
                            case "runways":
                                var runways = new Array();
                                feature.properties.runways.forEach(element => {
                                    runways.push(element.id);
                                });
                                v = runways.join(", ");
                                break;
                            case "comm":
                                var comm = new Array();
                                feature.properties.comm.forEach(element => {
                                    comm.push(element.id+" ("+element.mhz+")");
                                });
                                v = comm.join(", ");
                                break;
                            default:
                                v = feature.properties[k];
                                break;
                        }
                        popupString += k + ': ' + v + '<br />';
                    }
                    popupString += '</div>';
                    layer.bindPopup(popupString, {
                        maxHeight : 200
                    });
                    if( feature.properties.metar ) {
                    }
                }
            },

            filter : function(feature) {
                var zoom = (this._map && this._map.getZoom()) || 11;
                switch (feature.properties.type) {
                case 'airport':
                    if (zoom >= 10)
                        return true;
                    return feature.properties.longestRwyLength_m >= 2000;
                    break;

                case 'NDB':
                    if (zoom >= 10)
                        return true;
                    if (zoom >= 8)
                        return feature.properties.range_nm >= 30;
                    return feature.properties.range_nm > 50;
                }
                return true;
            },

            style : function(feature) {
                if (feature.properties.type == "ILS" || feature.properties.type == "localizer") {
                    return {
                        color : 'black',
                        weight : 2,
                    };
                }
                if (feature.properties.type == "airport") {
                    return {
                        color : 'black',
                        weight : 3,
                        fill : 'true',
                        fillColor : '#606060',
                        fillOpacity : 1.0,
                        lineJoin : 'bevel',
                    };
                }
            },
        },

        onAdd : function(map) {
            leaflet.GeoJSON.prototype.onAdd.call(this, map);
            this.dirty = true;
            this.update(++this.updateId);
        },

        onRemove : function(map) {
            this.updateId++;
            leaflet.GeoJSON.prototype.onRemove.call(this, map);
        },

        stop : function() {
            this.updateId++;
        },

        invalidate : function() {
            this.dirty = true;
        },

        dirty : true,
        updateId : 0,
        update : function(id) {
            var that = this;

            if (this.updateId != id)
                return;

            if (this.dirty) {
                this.dirty = false;
                var bounds = this._map.getBounds();
                // radius in NM
                var radius = bounds.getSouthWest().distanceTo(bounds.getNorthEast()) / 3704;

                if (radius > 250)
                    radius = 250;
                if (radius < 10)
                    radius = 10;

                var filter = "vor,ndb,airport";
                if (radius < 60)
                    filter += ",ils,dme,loc,om,fix";
                if (radius < 20)
                    filter += ",mm";

                var center = this._map.getCenter();
                var lat = center.lat;
                var lon = center.lng;

                var url = "/navdb?q=findWithinRange&type=" + filter + "&range=" + radius + "&lat=" + lat + "&lon=" + lon;

                var jqxhr = $.get(url).done(function(data) {
                    if (that.updateId == id) {
                        that.clearLayers();
                        that.addData.call(that, data);
                    }
                }).fail(function() {
                    that.updateId++;
                    alert('failed to load navdb data');
                }).always(function() {
                });
            }
            if (this.updateId == id) {
                setTimeout(function() {
                    that.update(id)
                }, 5000);
            }
        },

    });

    leaflet.navdbLayer = function(options) {
        return new leaflet.NavdbLayer(null, options);
    }
}));
