define([
        'knockout', 'text!./Environment.html', './SubtopicViewmodel'
], function(ko, htmlString, SubtopicViewmodel) {
    ko.components.register('Environment/Date & Time', {
        require : 'topics/Environment/DateTime'
    });

    ko.components.register('Environment/Weather', {
        require : 'topics/Environment/Weather2'
    });

    ko.components.register('Environment/Position', {
        require : 'topics/Environment/Position'
    });

    // Return component definition
    return {
        viewModel : {
            createViewModel : function(params, componentInfo) {
                return new SubtopicViewmodel([
                        'Date & Time', 'Weather', 'Position',
                ], "Environment", params);
            },
        },
        template : htmlString
    };
});
