define([
    'jquery', 'knockout', 'text!./Failures.html'
], function(jquery, ko, htmlString) {

    function ViewModel(params) {
        var self = this;
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
