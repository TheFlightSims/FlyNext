define([
    'jquery', 'knockout', 'text!./VerticalNavigation.html'
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