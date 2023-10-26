define([
        'jquery', 'knockout', 'text!./METAR.html', 'jquery-ui/accordion', 'kojqui/button'
], function(jquery, ko, htmlString) {

    function WeatherScenarioVM() {
        var self = this;

        self.index = 0;
        self.name = "unnamed";
        self.metar = ko.observable("NIL");
        self.description = "NIL";

    }

    var WeatherScenarioMapping = {
        "index" : "index",
        "description" : "description",
        "name" : "name",
        "metar" : "metar"
    }

    function ViewModel(params) {
        var self = this;

        self.scenarios = ko.observableArray([]);
        self.selectScenario = function(foo) {
            console.log(foo);
        }

        jquery.get('/json/environment/weather-scenarios?d=2', null, function(data) {

            var assemble = function(data) {
                var scenarios = [];
                data.children.forEach(function(prop) {
                    if (prop.name === 'scenario') {
                        var scenario = new WeatherScenarioVM();
                        scenarios.push(ko.utils.knockprops.propsToObject(prop, WeatherScenarioMapping, scenario));
                        
                        // listen to the metar property for the live data scenario
                        if (scenario.name == "Live data") {
                            scenario.metar = ko.observable().extend({
                                fgprop : 'metar'
                            });
                        }
                    }
                });
                return scenarios;
            }

            self.scenarios(assemble(data));
            jquery("#weather-scenarios").accordion({
                collapsible : true,
                heightStyle : "content",
                active : false,
            });
        });

    }

    // ViewModel.prototype.dispose = function() {
    // }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
