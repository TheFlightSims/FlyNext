define([
        'jquery', 'knockout', 'text!./Reset.html', 'kojqui/button'
], function(jquery, ko, htmlString) {
    
    function ViewModel(params) {
        var self = this;

        self.doReset = function() {
console.log("reset");
        }
    }

    ViewModel.prototype.dispose = function() {
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
