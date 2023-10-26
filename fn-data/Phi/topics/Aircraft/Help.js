define([
        'jquery', 'knockout', 'text!./Help.html', 'pagedown/Markdown.Converter'
], function(jquery, ko, htmlString) {

    var converter = new Markdown.Converter();

    function ViewModel(params) {
        var self = this;

        self.helpTitle = ko.observable("");
        self.helpContent = ko.observableArray([]);
        self.description = ko.observable('');
        self.longDescription = ko.observable('');

        jquery.get('/json/sim/description', null, function(data) {
            self.description(data.value);
        });

        jquery.get('/json/sim/long-description', null, function(data) {
            self.longDescription(data.value);
        });

        jquery.get('/json/sim/help?d=2', null, function(data) {

            var helpContent = [];
            data.children.forEach(function(prop) {
                if (prop.name === 'title') {
                    self.helpTitle(prop.value);
                } else if (prop.name == 'line' ) {
                    helpContent.push({
                        type: 'line',
                        text: prop.value,
                    });
                } else if (prop.name == 'text') {
                    helpContent.push({
                        type: 'text',
                        text: converter.makeHtml(prop.value),
                    });
                } else if (prop.name == 'key') {
                    var content = {
                            type: 'key',
                            name: 'noname',
                            desc: 'nothing',
                    }
                    helpContent.push(content);
                    prop.children.forEach(function(prop) {
                        if (prop.name === 'name') {
                            content.name = prop.value;
                        } else if( prop.name == 'desc' ) {
                            content.desc = prop.value;
                        }
                    });
                }
            });
            self.helpContent(helpContent);

        });
    }

//    ViewModel.prototype.dispose = function() {
//    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
