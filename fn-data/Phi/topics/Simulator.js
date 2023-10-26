define([
        'knockout', 'text!./Simulator.html', './SubtopicViewmodel'
], function(ko, htmlString, SubtopicViewmodel) {
    ko.components.register('Simulator/Screenshot', {
        require : 'topics/Simulator/Screenshot'
    });

    ko.components.register('Simulator/Properties', {
        require : 'topics/Simulator/Properties'
    });

    ko.components.register('Simulator/Config', {
        require : 'topics/Simulator/Config'
    });

    ko.components.register('Simulator/Reset', {
        require : 'topics/Simulator/Reset'
    });

    ko.components.register('Simulator/Exit', {
        require : 'topics/Simulator/Exit'
    });

    // Return component definition
    return {
        viewModel : {
            createViewModel : function(params, componentInfo) {
                return new SubtopicViewmodel([
                        'Screenshot', 'Properties', 'Config', 'Reset', 'Exit'
                ], "Simulator", params);
            },
        },
        template : htmlString
    };
});
