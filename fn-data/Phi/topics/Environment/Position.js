define([
        'jquery', 'knockout', 'text!./Position.html', 'sprintf', 'leaflet', 'fgcommand', 'kojqui/autocomplete'
], function( jquery, ko, htmlString, sprintf, leaflet, fgcommand ) {
    
    var MetarPropertiesPath = "/aaa";

    function getAirportList(obs) {
        if(typeof(Storage) !== "undefined") {
            var storedList = sessionStorage.getItem("phiPositionAirportlist");
            if( storedList ) {
                obs(JSON.parse(storedList));
                return;
            }
        }
        
        // get airport list only once
        jquery.get("/navdb?q=airports").done(function(data) {
            sessionStorage.setItem("phiPositionAirportlist",JSON.stringify(data));
            obs(data);
        }).fail(function() {
        }).always(function() {
        });
    }

    function getAirportId( txt ) {
      var end = txt.lastIndexOf(')');
      if( end < 0 ) return "";
      var start = txt.lastIndexOf('(', end );
      if( start < 0 ) return "";
      return txt.substr(start+1,end-start-1);
    }

    function RunwayViewModel(rwy) {
      var self = this;
      self.id = ko.observable(rwy.id);
      self.heading = ko.observable(Number(rwy.heading_deg||0).toFixed(0));

      self.lengthM = ko.observable(Number(rwy.length_m||0).toFixed(0));
      self.lengthFt = ko.pureComputed(function(){
        return (self.lengthM()/0.3048).toFixed(0);
      });

      self.widthM = ko.observable(Number(rwy.width_m||0).toFixed(0));
      self.widthFt = ko.pureComputed(function(){
        return (self.widthM()/0.3048).toFixed(0);
      });

      self.displacedThresholdM = ko.observable(Number(rwy.dispacedThreshold_m||0).toFixed(0));
      self.displacedThresholdFt = ko.pureComputed(function(){
        return (self.displacedThresholdM()/0.3048).toFixed(0);
      });
      self.hasDisplacedThreshold = ko.pureComputed(function() {
        return self.displacedThresholdM() > 0;
      });

      self.stopwayM = ko.observable(Number(rwy.stopway_m||0).toFixed(0));
      self.stopwayFt = ko.pureComputed(function(){
        return (self.stopwayM()/0.3048).toFixed(0);
      });
      self.hasStopway = ko.pureComputed(function() {
        return self.stopwayM() > 0;
      });

      self.surface = ko.observable(rwy.surface);

    }

    function AirportViewModel(geoJson, id) {
      var self = this;

      jquery.get("/navdb?q=airport&id=" + id ).done(function(data) {
        // expect geoJSON FeatureCollection
        if( "FeatureCollection" !== data.type )
          return;

        // expect one feature
        if( !(data.features && data.features.length == 1) )
          return;

        var airport = data.features[0];

        var rwy = self.runway();
        airport.properties.runways.forEach(function(r){
          rwy.push( new RunwayViewModel(r));
        });
        self.runway(rwy);

        self.id(airport.properties.id);
        self.name(airport.properties.name);
        self.city(airport.properties.name);
        self.country(airport.properties.name);
        self.hasMetar(airport.properties.metar);
        if(self.hasMetar()) {
            fgcommand.requestMetar( self.id(), MetarPropertiesPath );
        }

        var comm = {};
        airport.properties.comm.forEach(function(c){
          var f = comm[c.id] || [];
          f.push( c.mhz );
          comm[c.id] = f;
        });
        var a = [];
        for( var id in comm ) {
          a.push({ name: id, frequencies: comm[id]} );
        }
        self.comm(a);

        var arp = airport.geometry.geometries[0].coordinates;
        self.elevation((Number(arp[2]||0)/0.3048).toFixed(0));
        self.longitude(Number(arp[0]||0));
        self.latitude(Number(arp[1]||0));

        geoJson.clearLayers();
        geoJson.addData(airport);
        geoJson._map.setView([ self.latitude(), self.longitude() ], 13);
      });

      self.id = ko.observable('');
      self.name = ko.observable('');
      self.city = ko.observable('');
      self.country = ko.observable('');
      self.elevation = ko.observable(0);
      self.longitude = ko.observable(0);
      self.latitude = ko.observable(0);
      self.hasMetar = ko.observable(false);
      self.arpFormatted = ko.pureComputed(function() {
        function dm(v) {
          var s = v < 0;
          if( s ) v = -v;
          var d = v|0;
          return {
            's': s,
            'd': d,
            'm': (v-d)*60,
          }
        }

        var lat = dm(self.latitude());
        var lon = dm(self.longitude());
        return sprintf.sprintf("%s%02d %3.1f %s%03d %3.1f",
          lat.s ? 'S' : 'N', lat.d, lat.m, lon.s ? 'W' : 'E', lon.d, lon.m );
      });

      self.comm = ko.observableArray([]);
      self.runway = ko.observableArray([]);

      self.gotoRwy = function(ui,evt) {
        var presets = {
          children: [
            {
              'name': 'airport-id',
              'value': self.id(),
            },
            {
              'name': 'longitude-deg',
              'value': -9999,
            },
            {
              'name': 'latitude-deg',
              'value': -9999,
            },
            {
              'name': 'altitude-ft',
              'value': -9999,
            },
            {
              'name': 'airspeed-kt',
              'value': 0,
            },
            {
              'name': 'offset-distance-nm',
              'value': 0,
            },
            {
              'name': 'offset-azimuth-deg',
              'value': 0,
            },
            {
              'name': 'glideslope-deg',
              'value': 0,
            },
            {
              'name': 'heading-deg',
              'value': 0,
            },
            {
              'name': 'runway',
              'value': ui.id(),
            },
          ],
        };

        fgcommand.setPropertyValue( '/sim/presets', presets, function() {
          fgcommand.reposition();
        }, self );

      }
    }

    function ViewModel(params) {
        var self = this;

        var map = leaflet.map("phi-environment-position-map", {
          dragging: false,
          touchZoom: false,
          scrollWheelZoom: false,
        });
        var geoJson = leaflet.geoJson(null,{
            style : function(feature) {
                    return {
                        color : 'black',
                        weight : 3,
                        fill : 'true',
                        fillColor : '#606060',
                        fillOpacity : 1.0,
                        lineJoin : 'bevel',
                    };
            }
        });
        geoJson._map = map;
        geoJson.addTo(map);

        self.airports = ko.observableArray([]);
        getAirportList(self.airports);
        self.hasAirports = ko.pureComputed(function() {
          return self.airports().length;
        });

        self.isLoading = ko.pureComputed(function() {
           return self.airports().length < 1;
        });

        self.selectedAirport = ko.observable();

        self.metarValidFlag = ko.observable(0).extend({
            observedProperty : MetarPropertiesPath + "/valid"
        });

        self.metarValid = ko.pureComputed(function(){
          return self.metarValidFlag() && self.selectedAirport() && self.selectedAirport().hasMetar();
        });

        self.metar = ko.observable('').extend({
            observedProperty : MetarPropertiesPath + "/data"
        });
        
        self.onSelect = function(ev,ui) {
            var id = getAirportId(ui.item.value);
            self.selectedAirport(new AirportViewModel(geoJson,id));
        }
    }

    ViewModel.prototype.dispose = function() {
        var self = this;
        fgcommand.clearMetar(MetarPropertiesPath);
        self.metar.dispose();
        self.metarValidFlag.dispose();
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
