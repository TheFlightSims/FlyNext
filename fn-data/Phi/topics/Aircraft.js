define([
        'jquery', 'knockout', 'text!./Aircraft.html', './SubtopicViewmodel'
], function(jquery, ko, htmlString, SubtopicViewmodel) {
    ko.components.register('Aircraft/Select', {
        require : 'topics/Aircraft/Select'
    });

    ko.components.register('Aircraft/Mass & Balance', {
        require : 'topics/Aircraft/MassBalance'
    });

    ko.components.register('Aircraft/Checklists', {
        require : 'topics/Aircraft/Checklists'
    });

    ko.components.register('Aircraft/Failures', {
        require : 'topics/Aircraft/Failures'
    });

    ko.components.register('Aircraft/Help', {
        require : 'topics/Aircraft/Help'
    });

    ko.components.register('Aircraft/Panel', {
        require : 'topics/Aircraft/Panel'
    });

    function Viewmodel(topics, prefix, params) {
        var self = this;
        SubtopicViewmodel.call(self, topics, prefix, params);

        self.config = ko.observable({});

        self.thumbnailUrl = "/aircraft-dir/thumbnail.jpg?N=" + Date.now();

        jquery.get('/aircraft-dir/Phi/config.json', null, function(config) {
            self.config(config);
            
            if (config && config.plugins && config.plugins.Aircraft) {
                for ( var p in config.plugins.Aircraft) {
                    var plugin = config.plugins.Aircraft[p];
                    if (plugin.component && plugin.component.key && plugin.component.lib) {
                        if (false == ko.components.isRegistered(plugin.component.key)) {
                            ko.components.register(plugin.component.key, { require: plugin.component.lib });
                        }
                    }
                    self.topics.push(p);
                }
            }
        });
    }

    // Return component definition
    return {
        viewModel : {
            createViewModel : function(params, componentInfo) {
                return new Viewmodel([
                        'Help', 'Mass & Balance', 'Checklists', 'Failures', 'Panel', 'Select'
                ], "Aircraft", params);
            },
        },
        template : htmlString
    };
});
