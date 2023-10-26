define([
        'jquery', 'knockout', 'text!./Select.html', 'fgcommand', 'kojqui/button'
], function(jquery, ko, htmlString,fgcommand) {
    
    function ViewModel(params) {
        var self = this;
        
        self.catalogs = ko.observableArray([]);
        
        self.install = function(pack) {
            console.log("install", pack);
//            jquery.get('/pkg/install/'+pack.id);
            fgcommand.switchAircraft(pack.id);
        }
        
        self.uninstall = function(pack) {
            console.log("uninstall", pack);
        }
        
        self.select = function(pack) {
            console.log("select", pack );
        }
        
        jquery.get('/pkg/catalogs', null, function(data) {
            if( data.catalogs )
                self.catalogs(data.catalogs);

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
