define([
        'jquery', 'knockout', 'text!./Screenshot.html', 'kojqui/spinner'
], function(jquery, ko, htmlString ) {
    
    function ViewModel(params) {
        var self = this;
        
        self.imageUrl = ko.observable("");
        self.updateInterval = ko.observable(5);
        self.spinUpdateInterval = function(evt, ui) {
            $(evt.target).spinner("value",ui.value);
            return true;
        }
        
        self.updateId = 0;
        
        self.update = function( id ) {
            if( id != self.updateId )
                return;
            self.imageUrl("/screenshot?type=jpg&t=" + Date.now());
            setTimeout( function() { self.update(id); }, self.updateInterval()*1000);
        };

        self.update(++self.updateId);
    }

    ViewModel.prototype.dispose = function() {
        ++self.updateId;
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
