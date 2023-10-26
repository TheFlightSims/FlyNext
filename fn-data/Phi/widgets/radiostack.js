define([
        'knockout', 'text!./radiostack.html', 'kojqui/tooltip', 'kojqui/spinner'
], function(ko, htmlString) {

    function DualFrequencyViewModel(label, pfx) {
        var self = this;
        self.useKey = pfx + "use";
        self.sbyKey = pfx + "sby";
        self.stnKey = pfx + "stn";

        self.label = ko.observable(label);
        self.use = ko.observable(188.888).extend({
            fgprop : self.useKey
        });
        
        self.stby = ko.observable(188.888).extend({
            fgprop : self.sbyKey
        });

        self.stn = ko.observable("").extend({
            fgprop : self.stnKey
        });

        self.swap = function() {
            ko.utils.knockprops.write(self.useKey, self.stby());
            ko.utils.knockprops.write(self.sbyKey, self.use());
        };

        self.onUseBlur = function() {
            ko.utils.knockprops.write(self.useKey, self.use());
        }

        self.onUseKey = function(ui,evt) {
            if( evt.keyCode == 13 )
                ko.utils.knockprops.write(self.useKey, self.use());
        }

        self.onStbyKey = function(ui,evt) {
            if( evt.keyCode == 13 )
                ko.utils.knockprops.write(self.sbyKey, self.stby());
        }

        self.onStbyBlur = function() {
            ko.utils.knockprops.write(self.sbyKey, self.stby());
        }
    }

    function ViewModel(params) {
        this.radios = ko.observableArray([
                new DualFrequencyViewModel("COM1", "com1"), new DualFrequencyViewModel("COM2", "com2"),
                new DualFrequencyViewModel("NAV1", "nav1"), new DualFrequencyViewModel("NAV2", "nav2"),
                new DualFrequencyViewModel("ADF", "adf1"), 
        ]);

    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
