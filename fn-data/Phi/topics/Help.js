define([
        'knockout', 'text!./Help.html'
], function(ko, htmlString) {

    function ViewModel(params) {
        var self = this;
        
    }

    ViewModel.prototype.dispose = function() {
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
