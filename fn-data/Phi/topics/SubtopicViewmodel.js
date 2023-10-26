(function(factory) {
    if (typeof define === "function" && define.amd) {
        // AMD. Register as an anonymous module.
        define(['knockout'], factory);
    } else {
        // Browser globals
        factory(ko);
    }
}(function(ko) {
    
    function SubtopicViewModel(topics, prefix, params) {
        var self = this;
        
        self.topics = ko.observableArray(topics);

        self.selectedTopic = ko.observable();

        self.selectedComponent = ko.pureComputed(function() {
            return prefix + "/" + self.selectedTopic();
        });

        self.selectTopic = function(topic) {
            location.hash = prefix + "/" + topic;
            self.selectedTopic(topic);
        }

        var topic = (params && params.topic) ? ko.unwrap(params.topic) : self.topics()[0];
        if( self.topics.indexOf(topic) == -1 )
            topic = self.topics()[0];
        self.selectTopic(topic);
    }
    
    return SubtopicViewModel;
}));
