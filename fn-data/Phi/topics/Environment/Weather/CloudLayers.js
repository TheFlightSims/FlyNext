define([
        'jquery', 'knockout', 'text!./CloudLayers.html', 'kojqui/selectmenu'
], function(jquery, ko, htmlString) {

    function ViewModel(params) {
        var self = this;

        function CloudLayer() {
            var self = this;
            self.index = 0;
            self.base = ko.observable(0);
            self.coverage = [
                    {
                        id : 4,
                        text : 'clear'
                    }, {
                        id : 3,
                        text : 'few'
                    }, {
                        id : 2,
                        text : 'scattered'
                    }, {
                        id : 1,
                        text : 'broken'
                    }, {
                        id : 0,
                        text : 'overcast'
                    }
            ];
            self.thickness = ko.observable(0);
            self.coverageId = ko.observable(0);
            self.tops = ko.pureComputed(function() {
                return self.base() + self.thickness(); 
            });
        }

        self.cloudLayers = ko.observableArray([]);

        jquery.get('/json/environment/clouds?d=2', null, function(data) {

            var assemble = function(data) {

                var PropertyMap = {
                    "index" : "index",
                    "elevation-ft" : "base",
                    "coverage-type" : "coverageId",
                    "thickness-ft" : "thickness",
                };

                var cloudLayers = [];
                data.children.forEach(function(prop) {
                    if (prop.name === 'layer') {
                        var layer = new CloudLayer();
                        cloudLayers.push(ko.utils.knockprops.propsToObject(prop, PropertyMap, layer));
                    }
                });

                return cloudLayers.reverse();
            }

            self.cloudLayers(assemble(data));
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
