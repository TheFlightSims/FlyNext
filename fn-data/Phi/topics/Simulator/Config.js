define([
        'jquery', 'knockout', 'text!./Config.html', 'fgcommand', 'props', 'kojqui/button', 'kojqui/buttonset', 'kojqui/selectmenu',
], function(jquery, ko, htmlString, fgCommand, SGPropertyNode) {
    function ViewModel(params) {
        var self = this;
        
        self.asa = ko.observable('');

        self.aiEnabled = ko.observable().extend({
            fgPropertyGetSet : "/sim/traffic-manager/enabled"
        });
        self.multiplayerHideReplay = ko.observable().extend({
            fgPropertyGetSet : "/sim/traffic-manager/enabled"
        });

        self.callsign = ko.observable().extend({
            fgPropertyGetSet : "/sim/multiplay/callsign"
        });
       
        self.online = ko.observable().extend({
            fgprop : "/sim/multiplay/online"
        });

        self.offline = ko.pureComputed(function() {
           return !self.online(); 
        });
 
        self.selectedServer = ko.observable().extend({
            fgPropertyGetSet : "/sim/multiplay/selected-server"
        });
        
        self.gotServers = ko.observable().extend({
            fgprop: "/sim/multiplay/got-servers"
        }).subscribe(function(newValue) {
            if( newValue ) {
                self.serverList.removeAll();
                jquery.get('/json/sim/multiplay/server-list?d=3', null, function(data) {
                    var root = new SGPropertyNode(data);
                    root.getChildren('server').forEach(function(server){
                        if( !server.getNode('online').getValue() )
                            return;
                        self.serverList.push( {
                            name: server.getNode('name').getValue(),
                            host: server.getNode('hostname').getValue(),
                            location: server.getNode('location').getValue(),
                            port: server.getNode('port').getValue(),
                            longname: server.getNode('hostname').getValue() + ' - ' + server.getNode('location').getValue(),
                        })
                    });
                  
                });
            }
        });
        
                
        self.serverList = ko.observableArray([]);
        
        self.toggleConnect = function() {
            if( self.online() ) {
              fgCommand.multiplayerDisconnect();
            } else {
              fgCommand.multiplayerConnect({ 
                  'servername': self.selectedServer(),
                  'rxport': 5000,
                  'txport': 5000
              });
            }
        }
        
        self.serverListVisible = ko.observable(true);
        
        fgCommand.multiplayerRefreshserverlist();
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
