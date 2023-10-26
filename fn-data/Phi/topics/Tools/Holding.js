define([
        'jquery', 'knockout', 'text!./Holding.html', 'sprintf', 'kojqui/button', 'kojqui/spinner'
], function(jquery, ko, htmlString, sprintf) {

    function ViewModel(params) {
        var self = this;

        function normDeg(val, min, max) {
            var d = max - min;
            while (val >= max)
                val -= d;
            while (val < min)
                val += d;
            return val;
        }

        self.standard = ko.observable(true);
        self.nonStandard = ko.pureComputed(function() {
            return false == self.standard();
        });

        self.inboundTrack = ko.observable(0);
        self.heading = ko.observable(270);
        self.entry = ko.observable("");

        self.entryClass = function(p) {
            console.log(p, self.entry());
            if (p == self.entry())
                return 'holding-pattern-' + p;
            else
                return 'active-holding-pattern-' + p;

        }

        self.holdingTransform = ko.pureComputed(function() {
            return sprintf.sprintf("rotate(%f 50 50)", self.inboundTrack());
        });

        self.trackTransform = ko.pureComputed(function() {
            return sprintf.sprintf("rotate(%f 50 50)", self.heading());
        });
        
        function test() {
            var v = [ -1, 0 ];
            var phi = 0 * Math.PI/180;
            
            var cosPhi = Math.cos(phi);
            var sinPhi = Math.sin(phi);
            var m = [ [ cosPhi, sinPhi ], [ -sinPhi, cosPhi ] ];
            
            var r = [ m[0][0] * v[0] + m[1][0]*v[1], m[0][1] * v[0] + m[1][1]*v[1]];
            
            console.log(v,m,r);
        }
        
        function moveOnArc( targetHeading, r, dir ) {
            dir = dir || 1;
            var phi = targetHeading * Math.PI/180;
            var cosPhi = Math.cos(phi);
            var sinPhi = Math.sin(phi);
            var x = dir*r*(1- cosPhi);
            var y = r * sinPhi;
            return [ Number(x.toFixed(1)), Number(-y.toFixed(1)) ];
        }

        function moveStraight( heading, dist ) {
            var phi = heading * Math.PI/180;
            var cosPhi = Math.cos(phi);
            var sinPhi = Math.sin(phi);
            var x = dist * sinPhi;
            var y = dist * cosPhi;
            return [ Number(x.toFixed(1)), Number(-y.toFixed(1)) ];
        }

        self.trackDraw = ko.pureComputed(function() {
            function entryProcedure(s, t, h) {
                var d = normDeg(t - h, -180, 180);
                var reply = "";
                
                var dir = s ? 1 : -1;

                if ((s && d >= -110 && d < 70) || (!s && d >= -70 && d < 110)) {
                    self.entry("direct");
                    // turn to outbound track
                    var turn = normDeg(dir*d+180,0,360);
                    var p = moveOnArc(turn, 7.5, dir );
                    reply += sprintf.sprintf(" a 7.5 7.5, 0, %d, %d, %f %f ", turn>180?1:0, s?1:0, p[0], p[1] );

                    // fly outbound 
                    p = moveStraight(d+180, 25);
                    reply += sprintf.sprintf(" l %f,%f", p[0], p[1] );

                    // turn back to the holding pattern, intercept inbound
                    p = moveStraight(d-dir*90, 15 );
                    reply += sprintf.sprintf(" a 7.5 7.5, 0, %d, %d, %f %f ", 0, s?1:0, p[0], p[1] );

                    // and to the fix
                    reply += " L50,50";
                } else if ((s && d >= -180 && d < -110) || (!s && d >= 110 && d < 180)) {
                    self.entry("teardrop");

                    // fly outbount for 1minute
                    var p = moveStraight(d+180-dir*30, 30 );
                    reply += sprintf.sprintf(" l %f,%f", p[0], p[1] );

                    // turn back to station
                    p = moveOnArc(d-dir*30, 7.5, dir );
                    reply += sprintf.sprintf(" a 7.5 7.5, 0, %d, %d, %f %f ", 0, s?1:0, p[0], p[1] );

                    reply += " L50,50";
                } else if ((s && d >= 70 && d < 180) || (!s && d >= -180 && d < -70)) {
                    self.entry("parallel");
                    // turn to outbound track
                    var turn = normDeg(dir*d+180,0,360);
                    var p = moveOnArc(180-dir*d, 7.5, -dir );
                    reply += sprintf.sprintf(" a 7.5 7.5, 0, %d, %d, %f %f ", 0, s?0:1, p[0], p[1] );

                    // fly outbound 
                    p = moveStraight(d+180, 25);
                    reply += sprintf.sprintf(" l %f,%f", p[0], p[1] );

                    // turn back to the holding pattern, intercept inbound
                    p = moveStraight(d+dir*90, 15 );
                    reply += sprintf.sprintf(" a 7.5 7.5, 0, %d, %d, %f %f ", 0, s?0:1, p[0], p[1] );

                    reply += " L50,50";
                } else {
                    self.entry("unknown");
                }
                return reply;
            }
            return "M50,100 v-50 " + entryProcedure(self.standard(), self.inboundTrack(), self.heading());
        });

        self.setStandard = function(a, b) {
            self.standard(true);
        }

        self.setNonStandard = function(a, b) {
            self.standard(false);
        }

        self.inboundTrackSpin = function(event, ui) {
            $(event.target).spinner("value", normDeg(ui.value, 0, 360));
            return false;
        }

        self.headingSpin = function(event, ui) {
            $(event.target).spinner("value", normDeg(ui.value, 0, 360));
            return false;
        }

    }

    // ViewModel.prototype.dispose = function() {
    // }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
