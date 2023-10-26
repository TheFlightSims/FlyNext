require.config({
    baseUrl : '.',
    paths : {
        jquery : '3rdparty/jquery/jquery-1.11.2.min',
        'jquery-ui' : '3rdparty/jquery/ui',
        knockout : '3rdparty/knockout/knockout-3.4.0',
        kojqui : '3rdparty/knockout-jqueryui',
        sprintf : '3rdparty/sprintf/sprintf.min',
        leaflet : '3rdparty/leaflet-0.7.7/leaflet',
        geodesic : '3rdparty/leaflet-0.7.7/Leaflet.Geodesic.min',
        text : '3rdparty/require/text',
        flot : '3rdparty/flot/jquery.flot',
        flotresize : '3rdparty/flot/jquery.flot.resize',
        flottime : '3rdparty/flot/jquery.flot.time',
        fgcommand : 'lib/fgcommand',
        props : 'lib/props2',
        knockprops : 'lib/knockprops',
        sammy : '3rdparty/sammy-latest.min',
        aircraft : '../aircraft-dir',
        pagedown : '3rdparty/pagedown',
        clockpicker : '3rdparty/clockpicker/jquery-clockpicker.min',
        stamen : 'http://maps.stamen.com/js/tile.stamen',
    },
    waitSeconds : 30,
});

require([
        'knockout', 'jquery', 'sammy', 'fgcommand', 'themeswitch', 'kojqui/button', 'kojqui/buttonset', 'kojqui/selectmenu',
        'jquery-ui/sortable', 'flot', 'leaflet', 'knockprops'
], function(ko, jquery, Sammy, fgcommand) {

    ko.options.deferUpdates = true;


    ko.utils.knockprops.setAliases({

        // time
        gmt : "/sim/time/gmt",
        timeWarp : "/sim/time/warp",
        // flight
        pitch : "/orientation/pitch-deg",
        roll : "/orientation/roll-deg",
        heading : "/orientation/heading-magnetic-deg",
        "true-heading" : "/orientation/heading-deg",
        altitude : "/position/altitude-ft",
        latitude : "/position/latitude-deg",
        longitude : "/position/longitude-deg",
        airspeed : "/velocities/airspeed-kt",
        groundspeed : "/velocities/groundspeed-kt",
        slip : "/instrumentation/slip-skid-ball/indicated-slip-skid",
        cg : "/fdm/jsbsim/inertia/cg-x-in",
        weight : "/fdm/jsbsim/inertia/weight-lbs",

        // radio settings
        com1stn : "/instrumentation/comm/station-name",
        com1use : "/instrumentation/comm/frequencies/selected-mhz",
        com1sby : "/instrumentation/comm/frequencies/standby-mhz",
        com1stn : "/instrumentation/comm/station-name",
        com2stn : "/instrumentation/comm[1]/station-name",
        com2use : "/instrumentation/comm[1]/frequencies/selected-mhz",
        com2sby : "/instrumentation/comm[1]/frequencies/standby-mhz",
        com2stn : "/instrumentation/comm[1]/station-name",
        nav1use : "/instrumentation/nav/frequencies/selected-mhz",
        nav1sby : "/instrumentation/nav/frequencies/standby-mhz",
        nav1stn : "/instrumentation/nav/nav-id",
        nav2use : "/instrumentation/nav[1]/frequencies/selected-mhz",
        nav2sby : "/instrumentation/nav[1]/frequencies/standby-mhz",
        nav2stn : "/instrumentation/nav[1]/nav-id",
        adf1use : "/instrumentation/adf/frequencies/selected-khz",
        adf1sby : "/instrumentation/adf/frequencies/standby-khz",
        adf1stn : "/instrumentation/adf/ident",
        dme1use : "/instrumentation/dme/frequencies/selected-mhz",
        dme1dst : "/instrumentation/dme/indicated-distance-nm",
        xpdrcod : "/instrumentation/transponder/id-code",
        // weather
        "ac-wdir" : "/environment/wind-from-heading-deg",
        "ac-wspd" : "/environment/wind-speed-kt",
        "ac-visi" : "/environment/visibility-m",
        "ac-temp" : "/environment/temperature-degc",
        "ac-dewp" : "/environment/dewpoint-degc",
        "gnd-wdir" : "/environment/config/boundary/entry/wind-from-heading-deg",
        "gnd-wspd" : "/environment/config/boundary/entry/wind-speed-kt",
        "gnd-visi" : "/environment/config/boundary/entry/visibility-m",
        "gnd-temp" : "/environment/config/boundary/entry/temperature-degc",
        "gnd-dewp" : "/environment/config/boundary/entry/dewpoint-degc",
        "metar-valid" : "/environment/metar/valid",
    });

    function PhiViewModel(topics) {
        var self = this;
        self.widgets = ko.observableArray([
                "METAR", "PFD", "Radiostack", "Small Map", "Stopwatch"
        ]);

        self.topics = topics;

        self.selectedTopic = ko.observable();
        self.selectedSubtopic = ko.observable();

        self.selectTopic = function(topic) {
            location.hash = topic;
        }

        self.refresh = function() {
            location.reload();
        }

        self.doPause = function() {
            fgcommand.pause();
        }

        self.doUnpause = function() {
            fgcommand.unpause();
        }

        jquery("#widgetarea").sortable({
            handle : ".widget-handle",
            axis : "y",
            cursor : "move",
        });
        // jquery("#widgetarea").disableSelection();

        // Client-side routes
        Sammy(function() {
            this.get('#:topic', function() {
                self.selectedTopic(this.params.topic);
                self.selectedSubtopic('');
            });

            this.get('#:topic/:subtopic', function() {
                self.selectedTopic(this.params.topic);
                self.selectedSubtopic(this.params.subtopic);
            });
            // empty route
            this.get('', function() {
                this.app.runRoute('get', '#' + self.topics[0]);
            });
        }).run();

    }
    ko.components.register('sidebarwidget', {
        require : 'widgets/sidebarwidget'
    });

    ko.components.register('Small Map', {
        require : 'widgets/map'
    });

    ko.components.register('Radiostack', {
        require : 'widgets/radiostack'
    });

    ko.components.register('AircraftMarker', {
        require : 'widgets/AircraftMarker'
    });

    ko.components.register('METAR', {
        require : 'widgets/metar'
    });

    ko.components.register('PFD', {
        require : 'widgets/efis'
    });

    ko.components.register('Stopwatch', {
        require : 'widgets/Stopwatch'
    });

    ko.components.register('dualarcgauge', {
        require : 'instruments/DualArcGauge'
    })

    ko.bindingHandlers.flotchart = {
        init : function(element, valueAccessor, allBindings) {
            // This will be called when the binding is first applied to an
            // element
            // Set up any initial state, event handlers, etc. here
            var value = valueAccessor() || {};

            if (value.hover && typeof (value.hover) === 'function') {
                jquery(element).bind("plothover", function(event, pos, item) {
                    value.hover.call(jquery(this).data("flotplot"), pos, item);
                });
            }
            if (value.click && typeof (value.click) === 'function') {
                jquery(element).bind("plotclick", function(event, pos, item) {
                    value.click.call(jquery(this).data("flotplot"), pos, item);
                });
            }
        },

        update : function(element, valueAccessor, allBindings) {
            var value = valueAccessor() || {};
            var data = ko.unwrap(value.data);
            var options = ko.unwrap(value.options);
            var plot = jquery.plot(element, data, options);
            jquery(element).data("flotplot", plot);
            var postUpdate = ko.unwrap(value.postUpdate);
            if (postUpdate) {
                postUpdate.call(value, element);
            }

        },

    };

    jquery.get('/config.json', null, function(config) {

        var userConfig = {}
        // merge user config into global config
        var jqxhr = jquery.get('/fg-home/Phi/config.json', null, function(data) {
          userConfig = data;
        }).always(function(){
            for ( var p in userConfig.plugins ) {
              config.plugins[p] = userConfig.plugins[p];
            }

            var topics = [];
            if (config && config.plugins ) {
                for ( var p in config.plugins ) {
                    var plugin = config.plugins[p];
                    if (plugin.component) {
                        if (false == ko.components.isRegistered(p)) {
                            ko.components.register(p, { require: plugin.component });
                        }
                    }

                    topics.push(p);
                }
            }

            topics.sort(function(a,b) {
              indexa = config.plugins[a].index || 0;
              indexb = config.plugins[b].index || 0;
              return indexa - indexb;
            });
            ko.applyBindings(new PhiViewModel(topics), document.getElementById('wrapper'));
        });
    });


    jquery("#toolbar").click(function() {
        jquery("#content").animate({
            top : 0
        }, 1000, null, function() {
            jquery(".htabs").css('background', '#427EBF url("images/FI_logo.svg") no-repeat scroll left center');
        });
        jquery("#widgetarea").animate({
            top : 29
        }, 1000);
    });

});
