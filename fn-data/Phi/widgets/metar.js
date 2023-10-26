define([
        'knockout', 'text!./metar.html', 'fgcommand', 'kojqui/tooltip'
], function(ko, htmlString, fgCommand ) {

    function ViewModel(params) {
      var NO_METAR = "*** no METAR ";
      self.scrolledMetar = ko.observable("");
      self.textStart = 0;
      self.metar = ko.observable(NO_METAR);
      self.valid = ko.observable(false).extend({ fgprop: 'metar-valid' });
      self.valid.subscribe(function(newValue) {
        self.textStart = 0;
        if( false == newValue ) {
          self.metar(NO_METAR);
          return;
        }
        self.metar("Wait.. ");
        fgCommand.getPropertyValue('/environment/metar/data', function(value) {
          self.textStart = 0;
          // start with station id (4 upcase chars), skip leading garbage
          var idx = value.search("[A-Z]{4}");
          if( idx >= 0 ) value = value.substring(idx);
          self.metar(value);
        });
      });

      self.textLength = 20;
      self.timerId = 0;
      self.longTimeout = 1500;
      self.shortTimeout = 50;

      function scrollText ( id ){
          if( id != self.timerId )
              return;

          var t = self.metar() + " " + self.metar();
          var a = self.textStart;
          var b = a+self.textLength;
          self.scrolledMetar( t.substring(a,b) );
          var timeout = t.charAt(a) == ' ' ? self.longTimeout : self.shortTimeout;
          if( ++a  >= self.metar().length )
            a = 0;
          self.textStart = a;
          setTimeout(function() { scrollText(id); }, timeout );
      }

      scrollText( ++self.timerId );
    }

    ViewModel.prototype.dispose = function() {
      self.timerId++;
    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : htmlString
    };
});
