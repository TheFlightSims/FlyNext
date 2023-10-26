define([
      'knockout', 'text!./efis.svg', 'sprintf'
], function(ko, htmlString, sprintf) {

    function ViewModel(params) {
        var self = this;
        params = params||{}
        
        self.rateLimit = params.rateLimit || 100;

        self.propertyMap = {
            pitch : 'pitch',
            roll : 'roll',
            airspeed : 'airspeed',
            altitude : 'altitude',
            heading : 'heading',
            slip : 'slip'
        }

        this.pitch = ko.observable(0).extend({
            fgprop : self.propertyMap.pitch
        }).extend({rateLimit: self.rateLimit });
        this.roll = ko.observable(0).extend({
            fgprop : self.propertyMap.roll
        }).extend({rateLimit: self.rateLimit });
        this.airspeed = ko.observable(0).extend({
            fgprop : self.propertyMap.airspeed
        }).extend({rateLimit: self.rateLimit });
        this.altitude = ko.observable(0).extend({
            fgprop : self.propertyMap.altitude
        }).extend({rateLimit: self.rateLimit });
        this.heading = ko.observable(0).extend({
            fgprop : self.propertyMap.heading
        }).extend({rateLimit: self.rateLimit });
        
        this.slip = ko.observable(0).extend({
            fgprop : self.propertyMap.slip
        }).extend({rateLimit: self.rateLimit });

        this.horizonAnimation = ko.pureComputed(function() {
            return "rotate(" + (-self.roll()) + " 512 384) translate(0 " + (self.pitch() * 20) + ")";
        });

        this.compassAnimation = ko.pureComputed(function() {
            return "rotate(" + (-self.heading()) + " 512 1108.175)";
        });

        this.headingTextAnimation = ko.pureComputed(function() {
            return sprintf.sprintf("%03d", Math.round(self.heading()));
        });

        this.asiTextAnimation = ko.pureComputed(function() {
            return sprintf.sprintf("%3d", Math.round(self.airspeed()));
        });

        this.altimeterThousandsTextAnimation = ko.pureComputed(function() {
            return sprintf.sprintf("%2d", self.altitude() / 1000);
        });

        this.altimeterHundretsTextAnimation = ko.pureComputed(function() {
            return sprintf.sprintf("%03d", Math.abs(self.altitude() % 1000));
        });

        this.asiLadderLabelAnimation0 = ko.pureComputed(function() {
            return self._getAsiLadderLabel(0);
        });

        this.asiLadderLabelAnimation1 = ko.pureComputed(function() {
            return self._getAsiLadderLabel(1);
        });

        this.asiLadderLabelAnimation2 = ko.pureComputed(function() {
            return self._getAsiLadderLabel(2);
        });

        this.asiLadderLabelAnimation3 = ko.pureComputed(function() {
            return self._getAsiLadderLabel(3);
        });

        this.asiLadderLabelAnimation4 = ko.pureComputed(function() {
            return self._getAsiLadderLabel(4);
        });

        this.altitudeLadderLabelAnimation0 = ko.pureComputed(function() {
            return self._getAltitudeLadderLabel(0);
        });

        this.altitudeLadderLabelAnimation1 = ko.pureComputed(function() {
            return self._getAltitudeLadderLabel(1);
        });

        this.altitudeLadderLabelAnimation2 = ko.pureComputed(function() {
            return self._getAltitudeLadderLabel(2);
        });

        this.altitudeLadderLabelAnimation3 = ko.pureComputed(function() {
            return self._getAltitudeLadderLabel(3);
        });

        this.altitudeLadderLabelAnimation4 = ko.pureComputed(function() {
            return self._getAltitudeLadderLabel(4);
        });

        this.asiLadderLabelTransform = ko.pureComputed(function() {
            var v = self.airspeed();
            var y = v > 40 ? 38 * 8 + 152 * (v % 20) / 20 : 38 * v / 5;
            return "translate(0 " + y + ")";
        });

        this.asiLadderTransform = ko.pureComputed(function() {
            var v = self.airspeed();
            var y = v > 40 ? 38 * 8 + 76 * (v % 10) / 10 : 38 * v / 5;
            return "translate(0 " + y + ")";
        });

        this.altimeterLadderLabelTransform = ko.pureComputed(function() {
            var v = self.altitude();
            var y = 152 * (v % 200) / 200;
            return "translate(0 " + y + ")";
        });

        this.altimeterLadderTransform = ko.pureComputed(function() {
            var v = self.altitude();
            var y = 76 * (v % 100) / 100;
            return "translate(0 " + y + ")";
        });

        this.slipSkidTransform = ko.pureComputed(function() {
            var v = self.slip() * -71.6125;
            var x = v < -125 ? -125 : v > 125 ? 125 : v;
            return "translate(" + x + " 0)";
        });
    }

    ViewModel.prototype._getAsiLadderLabel = function(n) {
        // draw labels every 20kt
        var v = ((this.airspeed() / 20) | 0) * 20 - 40;
        v = v < 0 ? 0 : v;
        return sprintf.sprintf("%3d", v + n * 20)
    }

    ViewModel.prototype._getAltitudeLadderLabel = function(n) {
        // draw labels every 200ft
        var v = ((this.altitude() / 200) | 0) * 2 - 4;
        return sprintf.sprintf("%2.1f", (v + n * 2) / 10);
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
