(function(factory) {
    if (typeof define === "function" && define.amd) {
        // AMD. Register as an anonymous module.
        define([
                'knockout', 'leaflet', 'props'
        ], factory);
    } else {
        // Browser globals
        factory();
    }
}(function(ko, leaflet, SGPropertyNode ) {

    var AITypeToCssClassMap = {
            aircraft: "ai-aircraft-marker-icon",
            multiplayer: "mp-aircraft-marker-icon"
    }

    function formatFL(num) {
      return "F" + ("000" + (num/100).toFixed(0)).substr(-3,3);
    }

    function ViewModel(h,l) {
        var self = this;

        self.heading = h;
        self.labelLines = l;
    }

    leaflet.AILayer = leaflet.GeoJSON.extend({
        options : {
            pointToLayer : function(feature, latlng) {
                var options = {
                    title : feature.properties.callsign,
                    alt : feature.properties.callsign,
                    riseOnHover : true,
                    draggable : true,
                };

                var aiMarker = null;
                if (feature.properties.type == "aircraft" || feature.properties.type == "multiplayer") {
                      var l1 = feature.properties.callsign,
                          l2 = feature.properties.heading + 'T ' + feature.properties.speed + 'KTAS ' + 
                               formatFL(feature.geometry.coordinates[2]),
                          l3 = feature.properties.departureAirportId + ' -> ' + feature.properties.arrivalAirportId;
                          
                      
                      aiMarker = L.aiAircraftMarker(latlng, { className: AITypeToCssClassMap[feature.properties.type] } );
                      aiMarker.on('add', function(e) {
                          if(feature.properties.type == "aircraft")
                            ko.applyBindings( new ViewModel(feature.properties.heading,[ l1,l2, l3 ]), e.target._icon);
                          else
                            ko.applyBindings( new ViewModel(feature.properties.heading,[ l1,l2 ]), e.target._icon);
                        });
                      aiMarker.options.draggable = true;
                      //We can't drag multiplayer 
                      if(feature.properties.type == "aircraft") {
	                    	  aiMarker.on('dragstart', function(evt) {
	                          evt.target.isDragging = true;
	                      });
	
	                      aiMarker.on('dragend', function(evt) {
	                          if( evt.target !== this)
	                          	return;
	                          var pos = evt.target.getLatLng();
	
	                          var props = {
	                              name : "position",
	                              children : [
	                                      {
	                                          name : "latitude-deg",
	                                          value : pos.lat,
	                                      }, {
	                                          name : "longitude-deg",
	                                          value : pos.lng,
	                                      },
	                              ],
	                          };
	                          $.post("json" + feature.properties.path, JSON.stringify(props));
	                          evt.target.isDragging = false;
	                      });
                      }
                      return aiMarker;
                }
                else if(feature.properties.type == "carrier"){
                  aiMarker = new leaflet.Marker(latlng, options);
                  return aiMarker;
                }
            },

//            onEachFeature : function(feature, layer) {
//            },
        },

        onAdd : function(map) {
            leaflet.GeoJSON.prototype.onAdd.call(this, map);
            this.update(++this.updateId);
        },

        onRemove : function(map) {
            this.updateId++;
            leaflet.GeoJSON.prototype.onRemove.call(this, map);
        },

        stop : function() {
            this.updateId++;
        },

        // Refresh method called every 10s to reload other aircraft
        updateId : 0,
        update : function(id) {
            var self = this;

            if (self.updateId != id)
                return;

            var url = "/json/ai/models?d=99";
            var jqxhr = $.get(url).done(function(data) {
                self.clearLayers();
                self.addData(self.aiPropsToGeoJson(data, [
                        "aircraft", "multiplayer", "carrier"
                ], self._map.getBounds()));
            }).fail(function(a, b) {
                self.updateId++;
                alert('failed to load AI data');
            }).always(function() {
            });

            if (self.updateId == id) {
                setTimeout(function() {
                   self.update(id)
                }, 10000);
            }
        },

        // Builds the GeoJSON representation of AI, Multiplayer and Carriers
        aiPropsToGeoJson : function(props, types, bounds ) {
            var geoJSON = {
                type : "FeatureCollection",
                features : [],
            };

            var root = new SGPropertyNode(props);
            types.forEach(function(type) {
                root.getChildren(type).forEach(function(child) {

                    if (!child.getNode("valid") || !child.getNode("valid").getValue())
                        return;

                	var path = child.getPath();
                    var position = child.getNode("position");
                    var orientation = child.getNode("orientation");
                    var velocities = child.getNode("velocities");
                    var lon = position.getNode("longitude-deg").getValue();
                    var lat = position.getNode("latitude-deg").getValue();
                    if( false == bounds.contains(L.latLng(lat,lon)) ) {
                        return;
                    }
                    var alt = position.getNode("altitude-ft").getValue();
                    var heading = orientation.getNode("true-heading-deg").getValue();
                    var id = child.getNode("id").getValue();
                    var callsign = "";
                    var name = "";
                    var speed = 0;
                    var departureAirportId = "";
                    var arrivalAirportId = "";
                    if (type == "carrier") {
                        callsign = child.getNode("sign").getValue();
                        name = child.getNode("name").getValue();
                        speed = velocities.getNode("speed-kts").getValue();
                    } else {
                        callsign = child.getNode("callsign").getValue();
                        speed = velocities.getNode("true-airspeed-kt").getValue();

                        if (type == "multiplayer") {
                            name = child.getNode("sim").getNode("model").getNode("path").getValue();
                        } else {
                            departureAirportId = child.getNode("departure-airport-id").getValue();
                            arrivalAirportId = child.getNode("arrival-airport-id").getValue();
                        }
                    }

                    geoJSON.features.push({
                        "type" : "Feature",
                        "geometry" : {
                            "type" : "Point",
                            "coordinates" : [
                                    lon, lat, alt.toFixed(0)
                            ],
                        },
                        "id" : id,
                        "properties" : {
                        	"path" : path,
                            "type" : type,
                            "heading" : heading.toFixed(0),
                            "speed" : speed.toFixed(0),
                            "callsign" : callsign,
                            "name" : name,
                            "departureAirportId" : departureAirportId,
                            "arrivalAirportId" : arrivalAirportId,
                        },
                    });

                });
            });

            return geoJSON;
        },

    });

    leaflet.aiLayer = function(options) {
        return new leaflet.AILayer(null, options);
    }

}));
