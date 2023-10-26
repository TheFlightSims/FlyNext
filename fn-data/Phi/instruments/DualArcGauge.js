define([
        'jquery', 'knockout', 'text!./DualArcGauge.svg', 'sprintf'
], function(jquery, ko, svgString, sprintf) {

    function getXY(positionNorm, r) {
        var a = (120*positionNorm-60)/180*Math.PI;
        return {
            'x':  50+r*Math.sin(a),
            'y':  52-r*Math.cos(a)
        }
    }
    
    function Tick( width, positionNorm, color ) {
        var self = this;

        self.width = width;
        self.color = color;

        var xy = getXY( positionNorm, 45 );
        self.getStartXY = xy.x.toString()+","+ xy.y.toString();

        xy = getXY( positionNorm, 50 );
        self.getEndXY = xy.x.toString()+","+ xy.y.toString();
    }

    function Marker( label, positionNorm, color ) {
        var self = this;

        self.label = label;
        self.color = color;
        
        var xy = getXY( positionNorm, 52 );
        self.getX = xy.x;
        self.getY = xy.y;
        
        self.anchor = 'middle';
        if( positionNorm < 0.4 ) self.anchor = 'end';
        if( positionNorm > 0.6 ) self.anchor = 'start';
    }
    
    function Arc( color, start, end ) {
        var self = this;
        self.color = color;

        if( start == end ) {
            start -= 0.005;
            end += 0.005;
        }
        
        var xy = getXY( start, 47.5 );
        self.getStartXY = xy.x.toString()+","+ xy.y.toString();
        
        xy = getXY( end, 47.5 );
        self.getEndXY = xy.x.toString()+","+ xy.y.toString();
    }
    
    function ViewModel(params) {
        var self = this;

        self.config = {
            label : params.label || '',
            min : params.min || 0,
            max : params.max || 1,
            left : {
                value : params.left.value || 0,
                format : params.left.format || '%d',
            },
            right : {
                value : params.right.value || 0,
                format : params.right.format || '%d',
            },
        }

        function getRotationNorm(value) {
            if (value < self.config.min)
                return 0;
            if (value > self.config.max)
                return 1;
            return (value - self.config.min) / (self.config.max - self.config.min);
        }

        self.leftRotationNorm = ko.pureComputed(function() {
            return getRotationNorm(ko.utils.unwrapObservable(self.config.left.value));
        });

        self.rightRotationNorm = ko.pureComputed(function() {
            return getRotationNorm(ko.utils.unwrapObservable(self.config.right.value));
        });

        self.leftText = ko.pureComputed(function() {
            return sprintf.sprintf(self.config.left.format, ko.utils.unwrapObservable(self.config.left.value));
        });

        self.rightText = ko.pureComputed(function() {
            return sprintf.sprintf(self.config.right.format, ko.utils.unwrapObservable(self.config.right.value));
        });

        self.label = self.config.label;

        self.markers = [];
        self.ticks = [];
        self.arcs = [];
        
        for ( var pos in params.marker) {
            var m = params.marker[pos];
            self.markers.push( new Marker( pos, getRotationNorm(Number(pos)), m) );
        }
        
        for ( var pos in params.ticks) {
            var t = params.ticks[pos];
            self.ticks.push( new Tick( t.width || 1, getRotationNorm(Number(pos)), t.color || 'white' ) );
        }
        
        if( params.arcs ) params.arcs.forEach(function(arc) {
            var end = arc.end || arc.start;
            self.arcs.push( new Arc(arc.color,getRotationNorm(Number(arc.start)),getRotationNorm(Number(end))));
        });

    }

    // Return component definition
    return {
        viewModel : ViewModel,
        template : svgString
    };
});
