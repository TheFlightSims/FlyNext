define([
        'knockout', 'text!./Weather.html', 'kojqui/buttonset'
], function(ko, htmlString) {
 
    ko.components.register('Environment/Weather/METAR', {
        require : 'topics/Environment/Weather/METAR'
    });

    ko.components.register('Environment/Weather/Clouds', {
        require : 'topics/Environment/Weather/CloudLayers'
    });

    ko.components.register('Environment/Weather/Boundary', {
        require : 'topics/Environment/Weather/Boundary'
    });

    ko.components.register('Environment/Weather/Aloft', {
        require : 'topics/Environment/Weather/Aloft'
    });

    function ViewModel(params) {
        var self = this;
   
        self.topics = [
                'METAR',
                'Clouds', 
                'Boundary', 
                'Aloft',
        ];

        self.selectedTopic = ko.observable();

        self.selectedComponent = ko.pureComputed(function() {
            return "Environment/Weather/" + self.selectedTopic();
        });

        self.selectTopic = function(topic) {
           self.selectedTopic(topic);
        }

        self.selectTopic(self.topics[0]);
    }

    ViewModel.prototype.dispose = function() {
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
