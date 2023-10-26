define([
        'jquery', 'knockout', 'text!./Exit.html', 'fgcommand', 'kojqui/button'
], function(jquery, ko, htmlString, fgcommand ) {
    
    function ViewModel(params) {
        var self = this;

        self.doExit = function() {
            fgcommand.exit();
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
