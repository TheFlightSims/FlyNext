define([
        'knockout',
], function(ko) {

    function LayerData() {
        var self = this;
        self.index = 0;
        self.altitude = ko.observable(0);
        self.windDir = ko.observable(0);
        self.windSpeed = ko.observable(0);
        self.visibility = ko.observable(0);
        self.temperature = ko.observable(0);
        self.dewpoint = ko.observable(0);
        self.turbulence = [
                {
                    id : 0,
                    text : 'none'
                }, {
                    id : 1,
                    text : 'light'
                }, {
                    id : 2,
                    text : 'moderate'
                }, {
                    id : 3,
                    text : 'severe'
                }
        ];
        self.turbulenceValue = ko.observable(0);
    }
    
    LayerData.prototype.PropertyMap = {
            "index": "index",
            "elevation-ft": "altitude",
            "wind-from-heading-deg": "windDir",
            "wind-speed-kt": "windSpeed",
            "visibility-m": "visibility",
            "temperature-degc": "temperature",
            "dewpoint-degc": "dewpoint",
        };

    return LayerData;
});
