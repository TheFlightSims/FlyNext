define([
        'jquery', 'knockout', 'text!./MassBalance.html', 'flot', 'kojqui/slider', 'flotresize'
], function(jquery, ko, htmlString) {

    function ViewModel(params) {
        var self = this;

        var Series = {
            ENVELOPE : 0,
            PAYLOAD : 1,
            FUEL : 2,
            CG : 3
        }

        self.envelopeData = ko.observableArray([
                // Series 0: Envelope
                {
                    color : 'rgb(192, 128, 0)',
                    data : [],
                    label : "Envelope",
                    lines : {
                        show : true
                    },
                    points : {
                        show : false
                    },
                    bars : {
                        show : false
                    },
                    shadowSize : 0,

                },
                // Series 1: Payload
                {
                    color : 'rgb(0, 0, 255)',
                    data : [],
                    label : "Payload",
                    lines : {
                        show : true
                    },
                    points : {
                        show : true
                    },
                    bars : {
                        show : false
                    },

                },
                // Series 2: Fuel
                {
                    color : 'rgb(0, 255, 0)',
                    data : [],
                    label : "Fuel",
                    lines : {
                        show : true
                    },
                    points : {
                        show : true
                    },
                    bars : {
                        show : false
                    },

                },
                // Series 3: CG
                {
                    color : 'rgb(255, 0, 0)',
                    data : [],
                    label : "CG",
                    lines : {
                        show : false
                    },
                    points : {
                        show : true
                    },
                    bars : {
                        show : false
                    },

                },
        ]);

        self.hover = function(pos, item) {
            if( ! item ) {
                self.hoverLabel("");
                self.hoverMass(0);
                self.hoverCG(0);
                return;
            }
            
            switch (item.seriesIndex) {
            case Series.CG:
                self.hoverLabel("CG");
                break;
            case Series.PAYLOAD:
                self.hoverLabel("Load"); //self.loads()[item.dataIndex].name;
                break;

            case Series.FUEL:
                self.hoverLabel("Fuel"); //self.tanks()[item.dataIndex].name;
                break;

            }
            self.hoverCG(item.datapoint[0]);
            self.hoverMass(item.datapoint[1]);
                    
        }
        
        self.hoverLabel = ko.observable();
        self.hoverMass = ko.observable(0);
        self.hoverCG = ko.observable(0);
        
        self.envelopeOptions = ko.observable({
            legend : {
                show : false,
            },
            grid : {
                hoverable : true,
            }
        });

        self.tanks = ko.observableArray([]);
        self.loads = ko.observableArray([]);
        self.cglimits = ko.observableArray([]);

        self.weight = ko.observable(0).extend({
            fgprop : 'weight'
        });
        self.cg = ko.observable(0).extend({
            fgprop : 'cg'
        });

        self.currentCG = ko.computed(function() {
            return [
                    self.cg(), self.weight()
            ];
        }).extend({
            rateLimit : 1000
        });

        self.currentCG.subscribe(function(newValue) {
            var data = self.envelopeData();

            var p = newValue;

            data[Series.CG].data = [
                p
            ];

            var fuelSeriesData = [
                p
            ];
            var moment = newValue[0] * newValue[1];
            var mass = newValue[1];
            self.tanks().forEach(function(tank) {
                moment -= tank.moment();
                mass -= tank.mass();
                p = [
                        moment / mass, mass
                ];
                fuelSeriesData.push(p);
            });
            data[Series.FUEL].data = fuelSeriesData;

            var payloadSeriesData = [
                p
            ];

            self.loads().forEach(function(load) {
                moment -= load.moment();
                mass -= load.mass();
                p = [
                        moment / mass, mass
                ];
                payloadSeriesData.push(p);
            });
            data[Series.PAYLOAD].data = payloadSeriesData;

            self.envelopeData(data);

        });

        self.cglimits.subscribe(function(newValue) {
            var bounds = {
                xMin : Number.MAX_VALUE,
                xMax : Number.MIN_VALUE,
                yMin : Number.MAX_VALUE,
                yMax : Number.MIN_VALUE,
            };
            var envelope = [];

            self.cglimits().forEach(function(entry) {
                envelope.push([
                        entry.position, entry.mass
                ]);
                if (entry.mass < this.yMin)
                    this.yMin = entry.mass;
                if (entry.mass > this.yMax)
                    this.yMax = entry.mass;
                if (entry.position < this.xMin)
                    this.xMin = entry.position;
                if (entry.position > this.xMax)
                    this.xMax = entry.position;
            }, bounds);
            if (envelope.length > 0)
                envelope.push(envelope[0]);

            var options = self.envelopeOptions() || {};
            options.xaxis = options.xaxis || {};
            options.yaxis = options.yaxis || {};
            options.xaxis.min = bounds.xMin;
            options.xaxis.max = bounds.xMax;
            options.yaxis.min = bounds.yMin;
            options.yaxis.max = bounds.yMax;
            self.envelopeOptions(options);
            var ed = self.envelopeData();
            ed[0].data = envelope;
            self.envelopeData(ed);
        });

        var WeightViewModel = function(number) {
            var self = this;

            self.number = number;
            self.name = 'Load' + number.toString();
            self.arm = ko.observable(1);
            self.mass = ko.observable(0);
            self.min = 0;
            self.max = 0;

            self.moment = ko.pureComputed(function() {
                return self.mass() * self.arm();
            });

            self.setLoad = function() {
                jquery.post('/json/payload/weight[' + this.number + ']', JSON.stringify({
                    name : 'weight-lb',
                    value : this.mass()
                }));
            }
        }

        jquery.get('/json/payload?d=2', null, function(data) {

            var assemble = function(data) {

                var loads = [];
                data.children.forEach(function(prop) {
                    if (prop.name === 'weight') {
                        var weight = new WeightViewModel(loads.length);
                        loads.push(weight);
                        prop.children.forEach(function(prop) {
                            if (prop.name === 'name') {
                                weight.name = prop.value;
                            } else if (prop.name === 'weight-lb') {
                                weight.mass(Number(prop.value));
                            } else if (prop.name == 'min-lb') {
                                weight.min = Number(prop.value);
                            } else if (prop.name == 'max-lb') {
                                weight.max = Number(prop.value);
                            } else if (prop.name == 'arm-in') {
                                weight.arm(Number(prop.value));
                            }
                        });
                    }
                });
                return loads;

            }

            self.loads(assemble(data));
        });

        jquery.get('/json/limits/mass-and-balance/cg/limit?d=2', null, function(data) {

            var assemble = function(data) {

                var cgLimits = [];
                data.children.forEach(function(prop) {
                    if (prop.name === 'entry') {
                        var entry = {
                            position : 0,
                            mass : 0
                        };
                        cgLimits.push(entry);
                        prop.children.forEach(function(prop) {
                            if (prop.name === 'position') {
                                entry.position = Number(prop.value);
                            } else if (prop.name == 'mass-lbs') {
                                entry.mass = Number(prop.value);
                            }
                        });
                    }
                });
                return cgLimits;

            }

            self.cglimits(assemble(data));
        });

        var TankViewModel = function(number) {
            var self = this;

            self.name = 'Tank' + number.toString();
            self.number = number;
            self.capacity = 0;
            self.content = ko.observable(0);
            self.arm = ko.observable(1);
            self.density = ko.observable(0);
            self.hidden = false;
            self.mass = ko.pureComputed(function() {
                return self.content() * self.density();
            });

            self.moment = ko.pureComputed(function() {
                return self.mass() * self.arm();
            });

            self.setTankLevel = function() {
                jquery.post('/json/consumables/fuel/tank[' + this.number + ']', JSON.stringify({
                    name : 'level-gal_us',
                    value : this.content()
                }));
            }
        }

        jquery.get('/json/consumables/fuel?d=2', null, function(data) {

            var assemble = function(data) {

                var tanks = [];
                data.children.forEach(function(prop) {
                    if (prop.name === 'tank') {
                        var tank = new TankViewModel(tanks.length);
                        tanks.push(tank);
                        prop.children.forEach(function(prop) {
                            if (prop.name === 'name') {
                                tank.name = prop.value;
                            } else if (prop.name == 'capacity-gal_us') {
                                tank.capacity = Number(prop.value);
                            } else if (prop.name == 'density-ppg') {
                                tank.density(Number(prop.value));
                            } else if (prop.name == 'level-gal_us') {
                                tank.content(Number(prop.value));
                            } else if (prop.name == 'arm-in') {
                                tank.arm(Number(prop.value));
                            } else if (prop.name == 'hidden') {
                                tank.hidden = prop.value !== 'false';
                            }
                        });
                    }
                });
                return tanks;

            }

            self.tanks(assemble(data));

        });
    }

    ViewModel.prototype.dispose = function() {
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
