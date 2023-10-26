define([
        'jquery', 'knockout', 'text!./Stopwatch.html', 'jquery-ui/dialog', 'kojqui/button'
], function(jquery, ko, htmlString) {

    function ViewModel(params) {
        var self = this;
        
        self.watches = ko.observableArray([]);
        
        self.addWatch = function() {
            self.watches.push(self.watches().length);
        }
        
        self.toDialog = function(a,evt) {
            var p = jquery(evt.target).parent();
            p.next().dialog({ 
                title: p.text(),
                closeOnEscape: false,
                });
            p.remove();
        }
        
        self.addWatch();
    }

     ViewModel.prototype.dispose = function() {
     }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
