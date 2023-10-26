define([
        'knockout', 'text!./Tools.html', './SubtopicViewmodel'
], function(ko, htmlString, SubtopicViewmodel) {

    ko.components.register('Tools/Holding Pattern', {
        require : 'topics/Tools/Holding'
    });

    ko.components.register('Tools/Wind Calculator', {
        require : 'topics/Tools/WindCalculator'
    });

    ko.components.register('Tools/Vertical Navigation', {
        require : 'topics/Tools/VerticalNavigation'
    });

    ko.components.register('Tools/Stopwatch', {
        require : 'topics/Tools/Stopwatch'
    });

    // Return component definition
    return {
        viewModel : {
            createViewModel : function(params, componentInfo) {
                return new SubtopicViewmodel([
                        'Holding Pattern', 'Wind Calculator', 'Vertical Navigation', 'Stopwatch'
                ], "Tools", params);
            },
        },
        template : htmlString
    };
});
