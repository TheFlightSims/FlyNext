define([
        'jquery', 'knockout', 'text!./Aloft.html', './LayerData', 'kojqui/selectmenu'
], function(jquery, ko, htmlString, layerData ) {
    
     function ViewModel(params) {
        var self = this;
        
        self.layerData = ko.observableArray([]);
        
        jquery.get('/json/environment/config/aloft?d=2', null, function(data) {

            var assemble = function(data) {
                var l = [];
                data.children.forEach(function(prop) {
                    if (prop.name === 'entry') {
                        var layer = new layerData();
                        l.push(ko.utils.knockprops.propsToObject(prop, layer.PropertyMap, layer ));
                    }
                });
                return l.reverse();
            }

            self.layerData(assemble(data));
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
