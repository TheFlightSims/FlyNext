define([
        'jquery', 'knockout', 'text!./sidebarwidget.html', 'jquery-ui/draggable', 'jquery-ui/dialog'
], function(jquery, ko, htmlString) {

    function ViewModel(params, componentInfo) {
        var self = this;

        self.element = componentInfo.element;

        self.widget = ko.observable(params.widget);

        self.pinned = ko.observable(true);
        self.pin = function() {
            self.pinned(!self.pinned());
        }

        self.close = function() {
            jquery(self.element).remove();
        }

        self.detach = function() {
            jquery(self.element).find('.phi-widget').dialog();
            jquery(self.element).remove();
        }

        self.expanded = ko.observable(true);

        self.onMouseover = function() {
            self.expanded(true);
        }

        self.onMouseout = function() {
            if (!self.pinned())
                self.expanded(false);
        }
    }

    // Return component definition
    return {
        viewModel : {
            createViewModel : function(params, componentInfo) {
                return new ViewModel(params, componentInfo);
            },
        },
        template : htmlString
    };
});
