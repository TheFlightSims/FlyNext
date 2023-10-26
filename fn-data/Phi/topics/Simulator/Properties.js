define([
        'jquery', 'knockout', 'text!./Properties.html', 'flot', 'flotresize', 'flottime'
], function(jquery, ko, htmlString) {

    function SampleSource(prop, source, params) {
        params = params || {};

        this.source = source;
        this.path = prop.path;
        this.maxSamples = params.maxSamples || 100;

        this.samples = [];
        this.sample = function(timeStamp) {
            while (this.samples.length >= this.maxSamples) {
                this.samples.shift();
            }
            this.samples.push([
                    timeStamp, this.source()
            ]);
        }
    }

    function PropertySampler(params) {

        params = params || {};

        this.sources = {};
        this.sampleInterval = params.sampleInterval || 1000;

        this.start = function() {
            this.update(++this.updateId);
            return this;
        }

        this.stop = function() {
            ++this.updateId;
            return this;
        }

        this.addSource = function(source) {
            this.sources[source.path] = source;
            return this;
        }

        this.removeSource = function(source) {
            var s = this.sources[source].source;
            delete this.sources[source];
            return s;
        }

        this.containsSource = function(source) {
            return source in this.sources;
        }

        this.updateId = 0;
        this.update = function(id) {
            if (id != this.updateId)
                return;

            var now = Date.now();
            for ( var key in this.sources) {
                this.sources[key].sample(now);
            }

            var self = this;
            setTimeout(function() {
                self.update(id);
            }, self.sampleInterval);
        }

    }

    function PropertyViewModel(propertyPlotter) {
        var self = this;

        function load() {
            jquery.get('/json' + self.path, null, function(data) {
                self.hasChildren = data.nChildren > 0;
                self.index = data.index;
                self.type = data.type;
                if (typeof (data.value) != 'undefined') {
                    self.value(data.value);
                    self.hasValue = true;
                } else {
                    self.value('');
                    self.hasValue = false;
                }

                var a = [];
                if (data.children) {
                    data.children.forEach(function(prop) {
                        var p = new PropertyViewModel(propertyPlotter);
                        p.name = prop.name;
                        p.path = prop.path;
                        p.index = prop.index;
                        p.type = prop.type;
                        p.hasChildren = prop.nChildren > 0;
                        if (typeof (prop.value) != 'undefined') {
                            p.value(prop.value);
                            p.hasValue = true;
                        } else {
                            p.hasValue = false;
                        }
                        a.push(p);
                    });
                    self.children(a.sort(function(a, b) {
                        if (a.name == b.name) {
                            return a.index - b.index;
                        }
                        return a.name.localeCompare(b.name);
                    }));
                }

            });
        }
        self.name = '';
        self.value = ko.observable('');
        self.children = ko.observableArray([]);
        self.index = 0;
        self.path = '';
        self.hasChildren = false;
        self.hasValue = false;
        self.type = '';

        self.indexedName = ko.pureComputed(function() {
            if (0 == self.index)
                return self.name;
            return self.name + "[" + self.index + "]";
        });

        self.isExpanded = ko.observable(false);
        self.isExpanded.subscribe(function(newValue) {
            if (newValue) {
                load();
            } else {
                self.children.removeAll();
            }
        });

        self.isPlottable = ko.pureComputed(function() {
            return [
                    "double", "float", "int"
            ].indexOf(self.type) != -1;
        });

        self.toggle = function() {
            if (self.hasChildren) {
                self.isExpanded(!self.isExpanded());
            } else {
                load();
            }
        }

        self.togglePlot = function(prop, evt) {
            propertyPlotter.toggleProp(prop);
        }

        self.valueEdit = function(prop, evt) {
            var inplaceEditor = jquery(jquery('#inplace-editor-template').html());

            var elem = jquery(evt.target);
            elem.hide();
            elem.after(inplaceEditor);
            inplaceEditor.val(elem.text());
            inplaceEditor.focus();

            function endEdit(val) {
                inplaceEditor.remove();
                elem.show();

                if (typeof (val) === 'undefined')
                    return;
                var val = val.trim();
                elem.text(val);

                jquery.post('/json' + self.path, JSON.stringify({
                    value : val
                }));
            }

            inplaceEditor.on('keyup', function(evt) {
                switch (evt.keyCode) {
                case 27:
                    endEdit();
                    break;
                case 13:
                    endEdit(inplaceEditor.val());
                    break;
                }
            });

            inplaceEditor.blur(function() {
                endEdit(inplaceEditor.val());
            });
        }
    }

    function ViewModel(params) {
        var self = this;

        self.root = new PropertyViewModel(self);
        self.root.name = "root";
        self.root.path = "/";
        self.root.isExpanded(true);
        self.properties = self.root.children;

       self.startLabel = ko.pureComputed(function() {
            return self.running() ? "Pause" : "Start";
        });
    
        self.startIcons = ko.pureComputed(function() {
            return self.running() ? {
                primary : 'ui-icon-pause'
            } : {
                primary : 'ui-icon-play'
            };
        });

        self.settings = function() {
        }

        self.running = ko.observable(false);
        self.startPause = function() {
          if( self.running() ) {
            self.stop();
          } else {
            self.start();
          }
        }

        self.flotOptions = ko.observable({
            xaxes : [
                {
                    mode : "time"
                }
            ],
            yaxes : [
                    {
                        position : "right"
                    }, {
                        position : "left"
                    }

            ],
            legend : {
                show : true,
                labelFormatter: null,
                backgroundOpacity: 0.5,
                sorted: "ascending",
            },
            grid : {
                hoverable : false,
                backgroundColor: { colors: ["#eee", "#888"] }
            }
        });

        self.flotData = ko.observableArray([]);

        self.graphHover = function() {
        }

        self.hasGraphItems = ko.pureComputed(function() {
            return self.flotData().length > 0;
        });

        self.propertySampler = new PropertySampler({
            sampleInterval : 100,
        });

        self.propertySampler.start();
        self.running(true);

        self.toggleProp = function(prop) {

            if (self.propertySampler.containsSource(prop.path)) {
                var obs = self.propertySampler.removeSource(prop.path);
                ko.utils.knockprops.removeListener(prop.path, obs);
                return;
            }

            var obs = ko.observable(0);
            ko.utils.knockprops.addListener(prop.path, obs);
            self.propertySampler.addSource(new SampleSource(prop, obs, {
                maxSamples : 300,
            }));
        }

        self.updateId = 0;
        self.update = function(id) {

            if (self.updateId != id)
                return;

            var sources = self.propertySampler.sources;
            var data = [];

            var i = 1;
            for ( var key in sources) {
                var source = sources[key];
                data.push({
                    // color : 'rgb(192, 128, 0)',
                    data : source.samples,
                    label : key,
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
                    yaxis : i++,
                });
            }

            self.flotData(data);

            setTimeout(function() {
                self.update(id);
            }, 100);
        }

        self.start = function() {
          self.update(++self.updateId);
          self.propertySampler.start();
          self.running(true);
        }

        self.stop = function() {
          self.updateId++;
          self.propertySampler.stop();
          self.running(false);
        }

        self.start();

    }

    ViewModel.prototype.dispose = function() {
        console.log("disposing pal");
        this.propertySampler.stop();
        this.updateId++;
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
