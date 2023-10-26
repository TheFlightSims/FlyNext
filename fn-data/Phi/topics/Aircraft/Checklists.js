define([
        'jquery', 'knockout', 'props', 'text!./Checklists.html', 'jquery-ui/accordion',
], function(jquery, ko, SGPropertyNode, htmlString) {
    function ViewModel(params) {
        var self = this;

        self.checklists = ko.observableArray([]);
        self.selectedChecklist = ko.observable('').extend({
            observedProperty : '/sim/gui/dialogs/checklist/selected-checklist'
        });

        self.selectedChecklistSubscription = self.selectedChecklist.subscribe(function(newValue) {
            self.openChecklist(newValue);
        });

        self.openChecklist = function(title) {
            jquery("#checklists h4").each(function(idx) {
                if ($(this).text() == title) {
                    jquery("#checklists").accordion("option", "active", idx);
                }
            });
        }

        jquery.get('/json/sim/checklists?d=3', null, function(data) {

            var assembleChecklists = function(data) {

                var checklists = [];
                var root = new SGPropertyNode(data);
                root.getChildren("checklist").forEach(function(checklistNode) {
                    var checklist = {
                        title : checklistNode.getValue('title', 'unnamed'),
                        abnormal : checklistNode.getValue('type', '') == 'abnormal',
                        items : []
                    };
                    checklists.push(checklist);
                    checklistNode.getChildren("item").forEach(function(itemNode) {
                        checklist.items.push({
                            name : itemNode.getValue('name', 'unnamed'),
                            value : itemNode.getValue('value', ''),
                        });
                    });
                });
                return checklists;

            }

            self.checklists(assembleChecklists(data));
            jquery("#checklists").accordion({
                collapsible : true,
                heightStyle : "content",
                active : false,
            });
            jquery("#checklists li").hover(function() {
                $(this).addClass("ui-state-highlight").addClass("ui-corner-all");

            }, function() {
                $(this).removeClass("ui-state-highlight").removeClass("ui-corner-all");

            });
            self.openChecklist( self.selectedChecklist() );
        });
    }

    ViewModel.prototype.dispose = function() {
        var self = this;
        self.selectedChecklistSubscription.dispose();
        self.selectedChecklist.dispose();
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
