define([
        'knockout', 'jquery', 'text!./Weather2.html', 'props', 'flot', 'flotresize'
], function(ko, jquery, htmlString, SGPropertyNode) {

    if (typeof Math.roundTo === "undefined") {
        Math.roundTo = function(num, step) {
            return Math.floor((num / step) + .5) * step;
        }
    }

    function ViewModel(params, componentInfo) {
        // componentInfo.element

        var self = this;

        function createIsotherms() {
            var reply = [];
            for (x = -50; x < 50; x += 10) {
                reply.push([
                        x, -0.02
                ]);
                reply.push([
                        x, 16
                ]);
                reply.push(null);
            }
            /*
             * for (x = -160; x < 50; x += 10) { reply.push([ x, -56 ]);
             * reply.push([ x + 116, 50 ]); reply.push(null); }
             */
            return reply;
        }

        function createDryAdiabates() {
            var reply = [];
            /*
             * for (x = -35; x <= 200; x += 20) { reply.push([ x, 1050 ]);
             * reply.push([ x-160, 100 ]); reply.push(null); }
             */
            return reply;
        }

        jquery.get('/json/environment/config?d=4', null, function(data) {
            var wx = new SGPropertyNode(data);

            function createProbes(k) {
                var probes = [];
                wx.getNode("boundary").getChildren("entry").forEach(function(entry) {
                    probes.push([
                            entry.getValue(k, 15), entry.getValue("elevation-ft", 0) * 0.3048 / 1000
                    // km
                    ]);
                });
                wx.getNode("aloft").getChildren("entry").forEach(function(entry) {
                    probes.push([
                            entry.getValue(k, 15), entry.getValue("elevation-ft", 0) * 0.3048 / 1000
                    // km
                    ]);
                });
                return probes;
            }

            function createWind() {
                var wind = [];
                wx.getNode("boundary").getChildren("entry").forEach(function(entry) {
                    wind.push([
                            entry.getValue("wind-speed-kt", 0), entry.getValue("elevation-ft", 0) * 0.3048 / 1000, // km
                            entry.getValue("wind-from-heading-deg", 0),
                    ]);
                });
                wx.getNode("aloft").getChildren("entry").forEach(function(entry) {
                    wind.push([
                            entry.getValue("wind-speed-kt", 0), entry.getValue("elevation-ft", 0) * 0.3048 / 1000, // km
                            entry.getValue("wind-from-heading-deg", 0),
                    ]);
                });
                return wind;
            }

            self.wxData()[3].data = createProbes("temperature-degc");
            self.wxData()[4].data = createProbes("dewpoint-degc");
            self.wxData()[5].data = createWind();
            self.wxData.notifySubscribers(self.wxData.peek());
        });

        jquery.get('/json/environment/clouds?d=4', null, function(data) {
            var clouds = new SGPropertyNode(data);
            function createClouds() {
                var reply = [];
                clouds.getChildren("layer").forEach(function(layer) {
                    var coverage = layer.getValue("coverage");
                    if( coverage == "clear" ) return;

                    var base = layer.getValue("elevation-ft", -9999 );
                    if( base < -9000 ) return;

                    var tops = base + layer.getValue("thickness-ft",0) + base;
                    if( tops == base ) return;

                    base *= 0.3048/1000;
                    tops *= 0.3048/1000;

                    reply.push( [reply.length, tops, base] );
                });

                return reply;
            }


            self.wxData()[2].data = createClouds();
            self.wxData.notifySubscribers(self.wxData.peek());
        });


        self.wxData = ko.observableArray([
                {// Series: Isotherms
                    color : 'rgb(0, 0, 255)',
                    data : createIsotherms(),
                    label : "Isotherm",
                    lines : {
                        lineWidth : 0.5,
                        show : true
                    },
                    points : {
                        show : false
                    },
                    bars : {
                        show : false
                    },
                    shadowSize : 0,
                    yaxis : 2, // on linear scale
                    xaxis : 1,
                }, {// Series: Dry Adiabat
                    color : 'rgb(0, 255, 0)',
                    data : createDryAdiabates(),
                    label : "dry adiabat",
                    lines : {
                        lineWidth : 0.5,
                        show : true
                    },
                    points : {
                        show : true
                    },
                    bars : {
                        show : false
                    },
                    shadowSize : 0,
                    yaxis : 1,
                    xaxis : 1,
                }, { // clouds
                    color : 'rgb(128,128,128)',
                    data : [],
                    label : 'clouds',
                    lines : {
                        show : false
                    },
                    bars : {
                        show : true,
                        lineWidth : 0,
                        barWidth : 1,
                        fillColor : {
                            colors : [
                                    {
                                        opacity : 0.2
                                    }, {
                                        opacity : 0.9
                                    }
                            ]
                        }
                    },
                    shadowSize : 2,
                    yaxis : 2,
                    xaxis : 2,
                }, { // Temperature
                    color : 'rgb(255, 0, 0)',
                    data : [],
                    label : "temperature",
                    lines : {
                        lineWidth : 2,
                        show : true
                    },
                    points : {
                        show : true
                    },
                    bars : {
                        show : false
                    },
                    shadowSize : 0,
                    yaxis : 2,
                    xaxis : 1,
                }, { // dewpoint
                    color : 'rgb(0, 255, 0)',
                    data : [],
                    label : "dewpoint",
                    lines : {
                        lineWidth : 2,
                        show : true
                    },
                    points : {
                        show : true
                    },
                    bars : {
                        show : false
                    },
                    shadowSize : 0,
                    yaxis : 2,
                    xaxis : 1,
                }, {
                    color : 'rgb(0, 255, 0)',
                    data : [],
                    label : "windarrows",
                    lines : {
                        show : false
                    },
                    points : {
                        show : false
                    },
                    bars : {
                        show : false
                    },
                    windarrows : {
                        show : true,
                    },
                    shadowSize : 0,
                    yaxis : 2,
                    xaxis : 1,
                }
        ]);

        self.wxOptions = {
            legend : {
                show : false,
            },
            xaxes : [
                    { // Axis 1: Temperature
                        show : true,
                        position : "bottom",
                        color : 'blue',
                        tickColor : 'green',
                        min : -56,
                        max : 50,
                        tickLength : 0,
                    }, { // Axis 2: Cloud Layer
                        show : false,
                        min : 0,
                        max : 5,
                    },
            ],
            yaxes : [
                    { // Axis 1: Pressure (hpa), Log-P
                        show : true,
                        position : "left",
                        color : 'blue',
                        tickColor : 'blue',
                        min : 100,
                        max : 1050,
                        // tickLength : 0,
                        transform : function(v) {
                            return -Math.log(v);
                        },
                        inverseTransform : function(v) {
                            return Math.exp(-v);
                        },

                    }, { // Axis 2: Altitude (km)
                        show : true,
                        position : "right",
                        color : 'black',
                        tickColor : 'green',
                        min : -.020,
                        max : 16,
                        tickLength : 0,

                    }
            ],

            grid : {
                hoverable : true,
                clickable : true
            },

            hooks : {
                processRawData : function(plot, series, data, datapoints) {
                    if (series.windarrows && series.windarrows.show) {
                        datapoints.format = [
                                {
                                    x : true,
                                    number : true,
                                    required : true

                                }, {
                                    y : true,
                                    number : true,
                                    required : true

                                }, {
                                    number : true,
                                    required : true
                                }
                        ]
                    }

                },

                drawSeries : function(plot, ctx, series) {
                    if (series.windarrows && series.windarrows.show) {
                        function drawSeriesWindarrows(datapoints) {
                            var points = datapoints.points, ps = datapoints.pointsize;
                            for (var i = 0; i < points.length; i += ps) {
                                var ws = Math.roundTo(points[i], 5), y = points[i + 1], wd = points[i + 2];

                                var x = series.xaxis.p2c(40);
                                y = series.yaxis.p2c(y);

                                ctx.save();
                                ctx.translate(x, y);
                                ctx.rotate((wd + 180) * Math.PI / 180);

                                ctx.beginPath();
                                ctx.arc(0, 0, 3, 0, Math.PI * 2, false);
                                ctx.closePath();

                                ctx.moveTo(0, 0);
                                ctx.lineTo(0, 9 * 5);
                                var pos = 0;
                                while (ws >= 5) {
                                    if (ws >= 50) {
                                        ws -= 50;
                                        ctx.moveTo(0, (9 - pos) * 5);
                                        ctx.lineTo(-10, (8.5 - pos) * 5);
                                        ctx.lineTo(0, (8 - pos) * 5);
                                        pos++;
                                    } else if (ws >= 10) {
                                        if (pos > 0)
                                            pos++;
                                        ws -= 10;
                                        ctx.moveTo(0, (9 - pos) * 5);
                                        ctx.lineTo(-10, (9.5 - pos) * 5);
                                    } else {
                                        pos++;
                                        ws -= 5;
                                        ctx.moveTo(0, (9 - pos) * 5);
                                        ctx.lineTo(-5, (9.25 - pos) * 5);
                                    }
                                }

                                ctx.stroke();
                                ctx.restore();

                            }

                        }
                        var plotOffset = plot.getPlotOffset();

                        ctx.save();
                        ctx.translate(plotOffset.left, plotOffset.top);
                        ctx.lineWidth = 1.5;
                        ctx.strokeStyle = 'black';

                        drawSeriesWindarrows(series.datapoints);

                        ctx.restore();

                    }
                }
            },
        };

        self.afterUpdate = function(element) {
            var yaxisLabel = jquery("<div class='axisLabel yaxisLabel'></div>").text("Pressure (hpa)").appendTo(element);

            // Since CSS transforms use the top-left corner of the label as the
            // transform origin,
            // we need to center the y-axis label by shifting it down by half
            // its
            // width.
            // Subtract 20 to factor the chart's bottom margin into the
            // centering.

            yaxisLabel.css("margin-top", yaxisLabel.width() / 2 - 20);
        }

        var highlighted = null;

        self.plotHover = function(pos, item) {

            if (highlighted) {
                self.wxData()[highlighted.seriesIndex].data[highlighted.dataIndex] = [
                        pos.x1, highlighted.datapoint[1]
                ];
                this.setData(self.wxData());
                this.draw();
            }
        }

        self.plotClick = function(pos, item) {
            if (highlighted) {
                this.unhighlight(highlighted.series, highlighted.datapoint);
                highlighted = null;
            } else {
                if (item && item.seriesIndex != 3 && item.seriesIndex != 4)
                    return;

                highlighted = item;
                if (highlighted)
                    this.highlight(highlighted.series, highlighted.datapoint);
            }
        }
    }

    ViewModel.prototype.dispose = function() {
    }

    // Return component definition
    return {
        viewModel : {
            createViewModel : function(params, componentInfo) {
                return new ViewModel(params, componentInfo);
            },
        },
        template : htmlString
    };
});
