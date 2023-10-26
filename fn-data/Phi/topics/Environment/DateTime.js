define([
        'jquery', 'knockout', 'text!./DateTime.html', 'fgcommand', 'kojqui/datepicker', 'kojqui/spinner', 'clockpicker'
], function(jquery, ko, htmlString, fgcommand) {
    function ViewModel(params) {
        var self = this;

        self.timesOfToday = [
                'Clock Time', 'Dawn', 'Morning', 'Noon', 'Afternoon', 'Dusk', 'Evening', 'Night',
        ];

        self.setTimeOfToday = function(type) {
            var offsetTypes = {
                "Clock Time" : "real",
                "Dawn" : "dawn",
                "Morning" : "morning",
                "Noon" : "noon",
                "Afternoon" : "afternoon",
                "Dusk" : "dusk",
                "Evening" : "evening",
                "Night" : "night",
            }
            offsetType = offsetTypes[type] || null;
            if (!offsetType) {
                console.log("unknown time offset type ", type);
                return;
            }
            fgcommand.timeofday(offsetType);
        }

        self.gmtProp = ko.observable().extend({
            fgprop : 'gmt'
        });
        //TODO: bind this to gmtProp?
//      self.clockpickerInput.val(d.getUTCHours() + ':' + d.getUTCMinutes());

        self.warp = ko.observable().extend({
            fgprop : 'timeWarp'
        });

        self.simTimeUTC = ko.pureComputed(function() {
            // make a Date object holding the UTC time
            var d = new Date(self.gmtProp() + "Z");
            return d.getTime();
        });
        
        self.timeAsString = ko.pureComputed(function() {
            var d = new Date();
            d.setTime( self.simTimeUTC() );
           return d.toUTCString() 
        });
        
        self.simTimeAsLocalTime = ko.pureComputed(function() {
            // jqui datepicker displays local (browser) time, so fake it by adding timezoneOffset
            var d = new Date();
            d.setTime( self.simTimeUTC() + 60000 * d.getTimezoneOffset() );
            return d;
        });

        self.onDateSelect = function(dateText, inst) {
            var utc = new Date(self.simTimeUTC());
            utc.setFullYear(inst.selectedYear, inst.selectedMonth, inst.selectedDay);
            self.setWarpFor( utc.getTime() );
        }
        
        self.setWarpFor = function( newDateTime ) {
            var warp = (newDateTime - self.simTimeUTC())/1000;
            console.log("warp=", warp, self.warp());
            ko.utils.knockprops.write( "timeWarp", self.warp() + warp );
        }

        // clockpicker: see http://weareoutman.github.io/clockpicker/
        self.clockpicker = jquery('.clockpicker').clockpicker({
            placement : 'top',
            align : 'left',
            autoclose : true,
            afterDone : function() {
                var utc = new Date();
                utc.setTime( self.simTimeUTC() );
                var hm = self.clockpickerInput.val().toString().split(":");
                utc.setUTCHours(hm[0]);
                utc.setUTCMinutes(hm[1]);
                self.setWarpFor( utc.getTime() );
            },
        });

        self.clockpickerInput = jquery('.clockpicker input');
    }

    ViewModel.prototype.dispose = function() {
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
