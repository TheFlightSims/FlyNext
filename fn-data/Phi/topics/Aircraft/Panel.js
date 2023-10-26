define([
        'jquery', 'knockout', 'text!./Panel.html'
], function(jquery, ko, htmlString) {
    function ViewModel(params) {
        var self = this;
    }

//    ViewModel.prototype.dispose = function() {
//    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
