// Configure require.js and tell it where to find our modules
require.config({
    baseUrl : '.', // use this base if we don't give absolute paths
    paths : {
        knockout : '/3rdparty/knockout/knockout-3.2.0',
        knockprops : '/lib/knockprops',
    },
});

require([
         // we depend on those modules
        'knockout', // lookup 'knockout' in the 'paths' attribute above, 
                    // load the script and pass the resulting object as the
                    // first parameter below
        'knockprops' // load 'knockprops' in the 'paths' attribute above etc.
], function(ko) {
    // ko is now the locally available knockout extension
    // the second arg would be knockprops but that is not needed as it registers itself with knockout.utils

    
    // this creates the websocket to FG and registers listeners for the named properites
    ko.utils.knockprops.setAliases({
        pitch: "/orientation/pitch-deg",
        roll: "/orientation/roll-deg"
    });
    

    // knockout stuff - create a ViewModel representing the data of the page
    function ViewModel() {
        var self = this;
        
        // magic function,
        // create observables for all defined properties
        ko.utils.knockprops.makeObservablesForAllProperties( self );
        // we now have observables as if we typed
        // self.pitch = ko.observable();
        // self.roll = ko.observable();
        // but our knockprops observables always reflect the value of the FG property
        // updated at frame rate through the websocket

        // build the transform-string for the css transform property
        // we want something "rotate(45deg) translate(30%)"
        // see http://knockoutjs.com/documentation/computed-pure.html
        self.groundTransform = ko.pureComputed(function() {
            return "translateY(-50%) rotate(" + (-self.roll()) + "deg) translateY(50%)" + self.groundTranslateTransform();
        });

        // this little helper just scales and clamps the y-translation
        self.groundTranslateTransform = ko.pureComputed(function() {
            var t = 20 * (self.pitch() / 30);
            if( t > 20 ) t = 20;
            if( t < -20 ) t = -20;
            return "translateY(" + (t) + "%)";
        });
        
    }

    // Create the ViewModel instance and tell knockout to process the data-bind 
    // attributes of all elements within our wrapper-div.
    ko.applyBindings(new ViewModel(), document.getElementById('wrapper'));
    
    // now, every update of a registered property in flightgear gets to our browser
    // through the websocket. Knockprops delivers each change to the associated ko.observable
    // and fires the listeners of the observable. Those listeners trigger the change of the HTML DOM
    // which results in a redraw of the browser window.
});
