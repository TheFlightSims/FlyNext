define([
        'jquery', 'knockout', 'text!./AircraftMarker.html', 'text!../images/aircraft.svg'
], function(jquery, ko, htmlString, aircraftSvgFileContent ) {

    // extract root element which should be <svg> from image xml (strip pi) and convert to string
    // what an easy way to make Safari happy :-P
    var iconSvgString = jquery('<div>') // wrap into detached <div> to get it's innerHTML
                       .append(
                           jquery( aircraftSvgFileContent ) // parse the file content
                          .filter(":first")[0]) // get root element
                       .html();

    function ViewModel(params) {
        var self = this;

        self.iconSvg = iconSvgString;
        self.rotate = 0;
        self.label = [];

        if( params && params.rotate ) {
          self.rotate = params.rotate;
        } 

        if( params && params.label ) {
          self.label = params.label;
        }

        self.transformCss = function() {
          return 'rotate(' + ko.unwrap(self.rotate) + 'deg)';
        }
    }

//    ViewModel.prototype.dispose = function() {
//    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
