# helpers for working with GoFlight input devices

# map decimal digits 0..9 to standard 7-segment LCD pattern
var translateDigitToSevenSegment = [0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x67];

var formatFrequencyMHz = func(freqMhz, fieldWidth)
{
    return bytesForString(sprintf("%.3f", freqMhz), fieldWidth);
}

var formatFrequencyKHz = func(freqKhz, fieldWidth)
{
    return bytesForString(sprintf("%6.2f", freqKhz), fieldWidth);
}

var bytesForString = func(s, fieldWidth)
{
    var padCount = fieldWidth - size(s);
    var r = "";

    while (padCount > 0) {
        r ~= chr(0);
        padCount -=1;
    }

    for (var i=0; i < size(s); i += 1) {
        if (s[i] == `.`) {
            # set the high bit to correspond to the decimal
            var lastIndex = size(r) - 1;
            r[lastIndex] = r[lastIndex] + 0x80;
        } else if (s[i] == ` `) { # spaces
            r ~= chr(0);
        } else if (s[i] == `-`) { # negative
            r ~= chr(0x40);
        } else {
            var digitCode = s[i] - `0`;
            r ~= chr(translateDigitToSevenSegment[digitCode]);
        }
    }

    return r;
}

# TEST
# STBY
# OFF 
# XPDR
# TA
# TA/RA


var translateTo14Segment = {
    32: [0x0, 0x0],        # space
    65: [0x22, 0x37],     # A
    66: [0x0A, 0x8f],
    67: [0x00, 0x39],
    68: [0x08, 0x8f],     # uppercase D
    69: [0x22, 0x39],
    70: [0x20, 0x31], # F
    77: [0x00, 0x00],       # upper M
    78: [0x00, 0x00],       # upper N
    79: [0x00, 0x3f],       # upper O
    80: [0x22, 0x33],       # upper P
    82: [0x26, 0x33],       # upper R
    83: [0x22, 0x2d],       # upper S
    84: [0x08, 0x81],   # T
    88: [0x15, 0x40],   # X
    89: [0x09, 0x40]   # Y
};

var formatFourteenSegment = func(s, fieldWidth)
{
    var r = [];
    for (var i=0; i < size(s); i += 1) {
        var ch = s[i];
        if (!contains(translateTo14Segment, ch)) {
            debug.dump('No 14 segment mapping for:', ch);
        } else {
            var t = translateTo14Segment[s[i]];
            append(r, t[0]);
            append(r, t[1]);
        }
    }
    return r;
}

var reverseBytes = func(bytes)
{
    var r=[];
    for (var i = size(bytes) - 1; i >=0; i -=1) {
        append(r, bytes[i]);
    }
    return r;
}

var MFRController = {

  new: func(prefix)
  {
    var m = {
      parents: [MFRController]
    };

  #  m._hideTimer = maketimer(m.DELAY, m, Tooltip._hideTimeout);
  #  m._hideTimer.singleShot = 1;

    return m;
  }
};

var mcp = {
    init: func()
    {
        me._speedKnotsProp = props.globals.getNode("/autopilot/settings/target-speed-kt", 1);
        me._speedMachProp = props.globals.getNode("/autopilot/settings/target-speed-mach", 1);
        me._altitudeFtProp = props.globals.getNode("/autopilot/settings/target-altitude-ft", 1);
        me._vsFPMProp = props.globals.getNode("/autopilot/settings/vertical-speed-fpm", 1);
        me._headingProp = props.globals.getNode("/autopilot/settings/heading-bug-deg", 1);
        me._course1Prop = props.globals.getNode("/instrumentation/nav[0]/radials/selected-deg", 1);
        me._course2Prop = props.globals.getNode("/instrumentation/nav[1]/radials/selected-deg", 1);

        me._useMach = 0;
        me._refreshProp = props.globals.getNode("/input/goflight/mcp/refresh", 1);
        me._refreshHeadingProp = props.globals.getNode("/input/goflight/mcp/refresh-headings", 1);

        me._blankVSWindow = props.globals.getNode("/input/goflight/mcp/blank-vs-window", 1);

        me._ledProps = [];
        for (var l=0; l<4; l+=1) {
            var node = props.globals.getNode("/input/goflight/mcp/led[" ~ l ~ "]", 1);
            node.setIntValue(0);
            append(me._ledProps, node);
        }

        setlistener(me._speedKnotsProp, func { me.doRefresh(); } );
        setlistener(me._speedMachProp, func { me.doRefresh(); });
        setlistener(me._altitudeFtProp, func { me.doRefresh(); });
        setlistener(me._vsFPMProp, func { me.doRefresh(); });
        setlistener(me._blankVSWindow, func { me.doRefresh(); });

        setlistener(me._headingProp, func { me.doRefreshHeading(); });
        setlistener(me._course1Prop, func { me.doRefreshHeading(); });
        setlistener(me._course2Prop, func { me.doRefreshHeading(); });

        me.doRefresh();
        me.doRefreshHeading();

        print("GoFlight MCP init done");
    },

    setAltitudeFtProp: func(path)
    {
        me._altitudeFtProp = props.globals.getNode(path, 1);
        setlistener(me._altitudeFtProp, func { me.doRefresh(); });
        me.doRefresh();
    },

    doRefresh: func()
    {
        me._refreshProp.setIntValue(0);
    },

    doRefreshHeading: func()
    {
        me._refreshHeadingProp.setIntValue(0);
    },

    setMachMode: func(useMach)
    {
        me._useMach = useMach;
        me.doRefresh();
    },

    altitudeData: func()
    {
        # if window is blanked, return empty data
        var alt = me._altitudeFtProp.getValue();
        return bytesForString(sprintf("%d", alt), 5);
    },

    vsData: func()
    {
        # if window is blanked, return empty data
        if (me._blankVSWindow.getValue()) {
            return bytesForString("     ", 5);
        }

        var vs = me._vsFPMProp.getValue();
        return bytesForString(sprintf("%d", vs), 5);
    },

    speedData: func()
    {
        if (me._useMach) {
            var mach = me._speedMachProp.getValue();
            return bytesForString(sprintf("%0.3f ", mach), 5);
        }

        var spd = me._speedKnotsProp.getValue();
        return bytesForString(sprintf("%d", spd), 5);
    },

    adjustSpeed: func(val)
    {
        if (me._useMach) {
            var mach = me._speedMachProp.getValue();
            me._speedMachProp.setDoubleValue(mach + (val * 0.01));
            return;
        }

        var spd = me._speedKnotsProp.getValue();
        me._speedKnotsProp.setIntValue(spd + val);
    },

    adjustAltitude: func(val)
    {
        var alt = me._altitudeFtProp.getValue();
        me._altitudeFtProp.setIntValue(alt + val);
    },

    headingData: func()
    {
        var h = me._headingProp.getValue();
        return bytesForString(sprintf("%0d", h), 3);
    },

    course1Data: func()
    {
        var h = me._course1Prop.getValue();
        return bytesForString(sprintf("%0d", h), 3);
    },

    course2Data: func()
    {
        var h = me._course2Prop.getValue();
        return bytesForString(sprintf("%0d", h), 3);
    },

    _ledNames: { 
        'SPEED': [1, 0],
        'LVL-CHG': [1, 1],
        'HDG-SEL': [1, 2],
        'APP': [1,3],
        'ALT-HLD': [1,4],
        'V/S': [1,5],
        'F/O F/D': [1,7],
    # bank 2    
        'CWS A': [2,1],
        'CWS B': [2,2],
        'CAP F/D': [2,6],
        'N1': [2, 7],
    # bank 3
        'VNAV': [3,0],
        'LNAV': [3,1],
        'CMD A': [3,2],
        'CMD B': [3,3],
        'A/T ARM': [3,4],
        'VOR-LOC': [3,7],
    },

    watchPropertyForLED: func(prop, ledName)
    {
        if (!contains(me._ledNames, ledName)) {
            logprint(LOG_WARN, 'Unknown GoFlight MCP LED:' ~ ledName);
            return;
        }

        var ledData = me._ledNames[ledName];
        setlistener(prop, func(n) { me.setLED(ledData, n.getValue()); });
    },

    setLED: func(data, b)
    {
        # data is a pair of ints; the LED node and the bit within
        var node =  me._ledProps[data[0]];
        var ledBits = node.getValue();
        node.setIntValue(bits.switch(ledBits, data[1], b));
    }
};
