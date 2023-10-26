

var nasal_dir = getprop("/sim/fg-root") ~ "/Aircraft/Instruments-3d/ISFD/";
io.load_nasal(nasal_dir ~ 'ISFD_gui.nas', "isfd");
io.load_nasal(nasal_dir ~ 'ISFDGenericController.nas', "isfd");
io.load_nasal(nasal_dir ~ 'PhysicalController.nas', "isfd");

# main wrapper object
var ISFD = {

baseSize: 512,
halfSize: 256,
hsiHeight: 358,
hsiWidth: 306,
speedTapeWidth: 92,
altTapeWidth: 114,
pitchLadderDegreeSpacing: 8,
rollBaseRadius: 160,
roseRadius: 512,
boxHeight: 48,

needleBoxSize: 220,
needleBoxHeight: 20,

new : func(controller = nil) {
    var obj = {
        parents : [ISFD],
        _mode : ''
    };

    ISFD.hsiLeft = ISFD.speedTapeWidth - ISFD.halfSize;
    ISFD.hsiXCenter = ISFD.hsiLeft + ISFD.hsiWidth/2;
    ISFD.hsiRight = ISFD.halfSize - ISFD.altTapeWidth;
    ISFD.hsiBottom = ISFD.hsiHeight/2;
    ISFD.modeBoxHeight = (ISFD.baseSize - ISFD.hsiHeight)/2;

    obj.canvas = canvas.new({
            "name" : "ISFD Canvas",
            "size" : [ISFD.baseSize, ISFD.baseSize],
            "view" : [ISFD.baseSize, ISFD.baseSize],
            "mipmapping": 0,
            });

    obj.root = obj.canvas.createGroup();
    # centering transform
    obj.root.setTranslation(ISFD.halfSize, ISFD.halfSize);

    var controllerClass = (controller == nil) ? isfd.GenericController : controller; 
    obj._controller = controllerClass.new(obj);
    obj.createContents();
    obj._updateTimer = maketimer(0.05, func obj.update(); );
    obj._updateTimer.start();
    obj._appMode = nil; # set to nil to force update on first update() trigger

    return obj;
},

del: func()
{
    print('Deleting ISFD');
    me._updateTimer.stop();
},

# display the ISFD canvas on the specified object
display : func(target_object) {
  me.canvas.addPlacement({"node": target_object});
},

displayGUI : func(my_isfd, scale=1.0) {
    var gui = isfd.GUI.new(my_isfd, my_isfd.canvas, scale);
},

createContents : func() 
{
    me.createPitchLadder();
    me.createRollTicks();
    me.createCompassRose();
    me.createAltitudeTape();
    me.createSpeedTape();

    me.createSpeedBox();
    me.createAltitudeBox();

    me.createAltimeterSetting();
    # mach readout - not on the B737 model?
    me.createModeText();

    me.createLocalizer();
    me.createGlideslope();

    me.createAirplaneMarker();
   
},

createAirplaneMarker : func()
{
    var markerGroup = me.root.createChild("group", "airplane-indicator-group");
    markerGroup.setTranslation(ISFD.hsiXCenter, 0);

	var m = markerGroup.createChild("path", "airplane-indicator");
    m.setColorFill(0, 0, 0);
    m.setStrokeLineWidth(2);
    m.setColor(1, 1, 1);

    var markerWidth = 8;
    var hw = markerWidth / 2;
    var horWidth = 80;
    var vertExtension = markerWidth * 1.5;

    m.moveTo(-hw, -hw);
    m.line(markerWidth, 0);
    m.line(0, markerWidth);
    m.line(-markerWidth, 0);
    m.close();

    # left L
    m.moveTo(-hw - markerWidth, -hw);
    m.line(-horWidth, 0);
    m.line(0, markerWidth);
    m.line(horWidth - markerWidth, 0);
    m.line(0, vertExtension);
    m.line(markerWidth, 0);
    m.close();


    # right L
    m.moveTo(hw + markerWidth, -hw);
    m.line(horWidth, 0);
    m.line(0, markerWidth);
    m.line(markerWidth - horWidth, 0);
    m.line(0, vertExtension);
    m.line(-markerWidth, 0);
    m.close();
},

# add a single radially aligned tick mark between radiui one and two
addPolarTick : func(path, angle, r1, r2)
{
    var horAngle = angle + 90; # angle from +ve X axis
    var sa = math.sin(horAngle * D2R);
    var ca = math.cos(horAngle * D2R);

    path.moveTo(ca * r1, sa * r1);
    path.lineTo(ca * r2, sa * r2);
    return path;
},

addHorizontalSymmetricPolarTick : func(path, angle, r1, r2)
{
    var horAngle = angle + 90; # angle from +ve X axis
    var sa = -math.sin(horAngle * D2R);
    var ca = math.cos(horAngle * D2R);

    path.moveTo(ca * r1, sa * r1);
    path.lineTo(ca * r2, sa * r2);
    path.moveTo(-ca * r1, sa * r1);
    path.lineTo(-ca * r2, sa * r2);
    return path;
},

addHorizontalSymmetricLine : func(path, positiveLength, y)
{
    path.moveTo(-positiveLength, y);
    path.lineTo(positiveLength, y);
    return path;
},

addDiamond : func(path, radius)
{
    path.move(-radius, 0);
    path.line(radius, -radius); # top
    path.line(radius, radius); # right
    path.line(-radius, radius); # bottom
    path.close();
},

createDigitTape : func(parent, name, suffix = nil)
{
    var t = parent.createChild('text', name);
    # 'top' zero (above 9)
    var s = '0' ~ chr(10);
    if (suffix != nil) {
        s = '0' ~ suffix ~ chr(10);
    }

    for (var i=9; i>=0; i-=1) {
        if (suffix != nil) {
            s = s ~ i ~ suffix ~ chr(10);
        } else {
            s = s ~ i ~ chr(10);
        }
    }
    t.setText(s);
    t.setFont("LiberationFonts/LiberationMono-Regular.ttf");
    t.setFontSize(44);
   # t.set('line-height', 0.9);
    t.setAlignment("left-bottom");
    return t;
},

createRollTicks : func()
{
    # these don't move!
    # center filled white arrow pointing down
    # large tick at 30 deg
    # minor tick at 10, 20 deg
    # minor tick at 45?
    # and major tick at 60 by the looks of it

    me._rollGroup = me.root.createChild("group", "roll-group");
    me._rollGroup.setTranslation(ISFD.hsiXCenter, 0);
    me._rollGroup.set("clip-frame", canvas.Element.GLOBAL);
    me._rollGroup.set("clip", "rect(77px, 398px, 435px, 92px)");

	var rollScale = me.root.createChild("path", "roll-scale");
    rollScale.setTranslation(ISFD.hsiXCenter, 0);

    rollScale.setStrokeLineWidth(2);
    rollScale.setColor(1, 1, 1);
    var baseR = ISFD.rollBaseRadius;
    var minorTick = 16;
    var majorTick = 30;

    me.addHorizontalSymmetricPolarTick(rollScale, 10, baseR, baseR + minorTick);
    me.addHorizontalSymmetricPolarTick(rollScale, 20, baseR, baseR + minorTick);
    me.addHorizontalSymmetricPolarTick(rollScale, 30, baseR, baseR + majorTick);
    me.addHorizontalSymmetricPolarTick(rollScale, 45, baseR, baseR + minorTick);

    # we cap the length of these to avoid sticking into the speed/alt tapes
    me.addHorizontalSymmetricPolarTick(rollScale, 60, baseR, baseR + minorTick);
    rollScale.close();

    # add filled path for the zero arrow
    rollZeroArrow = me.root.createChild("path", "roll-zero-mark");
    rollZeroArrow.setColorFill(1, 1, 1);
    rollZeroArrow.setTranslation(ISFD.hsiXCenter, 0);

    # arrow extends from the roll radius to the top of HSI
    var arrowHeight = (ISFD.hsiHeight / 2) - ISFD.rollBaseRadius;
    var arrowHWidth = arrowHeight * (2/3);

    rollZeroArrow.moveTo(0, -baseR);
    rollZeroArrow.line(arrowHWidth, -arrowHeight);
    rollZeroArrow.line(-arrowHWidth * 2, 0);
    rollZeroArrow.close();

    # and the moving arrow
	var rollMarker = me._rollGroup.createChild("path", "roll-indicator");
    rollMarker.setColorFill(0, 0, 0);
    rollMarker.setStrokeLineWidth(2);
    rollMarker.setColor(1, 1, 1);
    rollMarker.moveTo(0, -baseR);
    rollMarker.line(arrowHWidth, arrowHeight);
    rollMarker.line(-arrowHWidth * 2, 0);
    rollMarker.close();
},

createPitchLadder : func()
{
     # sky rect
    var box = me.root.rect(ISFD.hsiLeft, -ISFD.hsiHeight/2, 
                           ISFD.hsiWidth, ISFD.hsiHeight);
    box.setColorFill('#69B3F4'); 

    me._pitchRotation = me.root.createChild("group", "pitch-rotation");
    me.pitchGroup = me._pitchRotation.createChild("group", "pitch-group");

    var bkGroup = me.root.createChild("group", "hsi-clip-group");
    

    # ground rect
    var box = me.pitchGroup.rect(-1000, 0, 2000, 2000);
    box.setColorFill('#8F9552'); 
    box.set("clip-frame", canvas.Element.GLOBAL);
    box.set("clip", "rect(77px, 398px, 435px, 92px)");
    
    var ladderGroup = me.pitchGroup.createChild("group", "pitch-ladder");
    ladderGroup.set("clip-frame", canvas.Element.GLOBAL);
    ladderGroup.set("clip", "rect(140px, 368px, 435px, 122px)");

	var pitchLadder = ladderGroup.createChild("path", "pitch-ladder-ticks");
    pitchLadder.setStrokeLineWidth(2);
    pitchLadder.setColor(1, 1, 1);

    var sp = ISFD.pitchLadderDegreeSpacing; # shorthand
    var tenDegreeWidth = 64;
    var fiveDegreeWidth = 32;
    var twoFiveDegreeWidth = 24;

    # add line at zero
    me.addHorizontalSymmetricLine(pitchLadder, ISFD.halfSize, 0);

    for (var i=1; i<=9; i+=1) 
    {
        var d = i * 10;
        me.addHorizontalSymmetricLine(pitchLadder, tenDegreeWidth, d * sp);
        me.addHorizontalSymmetricLine(pitchLadder, tenDegreeWidth, -d * sp);

        me.addHorizontalSymmetricLine(pitchLadder, fiveDegreeWidth, (d - 5) * sp);
        me.addHorizontalSymmetricLine(pitchLadder, fiveDegreeWidth, (5 - d) * sp);

        # 2.5 and 7.5 degree lines
        me.addHorizontalSymmetricLine(pitchLadder, twoFiveDegreeWidth, (d - 2.5) * sp);
        me.addHorizontalSymmetricLine(pitchLadder, twoFiveDegreeWidth, (2.5 - d) * sp);
        me.addHorizontalSymmetricLine(pitchLadder, twoFiveDegreeWidth, (d - 7.5) * sp);
        me.addHorizontalSymmetricLine(pitchLadder, twoFiveDegreeWidth, (7.5 - d) * sp);

        # add text as well
        var textUp = ladderGroup.createChild("text", "pitch-ladder-legend-" ~ d);
        textUp.setText(d);
        textUp.setAlignment("right-center");
        textUp.setTranslation(-tenDegreeWidth, d * sp);
        textUp.setFontSize(36);
        textUp.setFont("LiberationFonts/LiberationMono-Bold.ttf");

        var textDown = ladderGroup.createChild("text", "pitch-ladder-legend-" ~ d);
        textDown.setText(d);
        textDown.setAlignment("right-center");
        textDown.setTranslation(-tenDegreeWidth, -d * sp);
        textDown.setFontSize(36);
        textDown.setFont("LiberationFonts/LiberationMono-Bold.ttf");
    }
},

createSpeedTape : func()
{
    # background box
    var box = me.root.rect(0, -ISFD.halfSize, ISFD.speedTapeWidth - 1, ISFD.baseSize);
    box.setColorFill('#738A7E'); 
    box.setTranslation(-256, 0);
    box.set('z-index', -1);

    # short lines for text
    # long lines for 'odd' tens
    # 3 digit monospace text fits exactly between left side and short tick
    # maximum 5 (6?) visible text pieces

    me._speedTapeGroup = me.root.createChild("group", "speed-tape-group");
    me._speedTapeGroup.setTranslation(ISFD.hsiLeft, 0);
    me._speedTapeGroup.set('z-index', 2);

	var tapePath = me._speedTapeGroup.createChild("path", "speed-tape");
    tapePath.setStrokeLineWidth(2);
    tapePath.setColor(1, 1, 1);

    var knotSpacing = 4;
    var tenKnotWidth = 16;
    var twentyKnotWidth = 8;

    for (var i=0; i<=25; i+=1)
    {
        var tenKnotY = ((i * 20) + 10) * knotSpacing;
        var twentyKnot = ((i+1) * 20);

        tapePath.moveTo(0, -tenKnotY).line(-tenKnotWidth, 0);
        tapePath.moveTo(0, -twentyKnot * knotSpacing).line(-twentyKnotWidth, 0);

        var text = me._speedTapeGroup.createChild("text", "speed-tape-legend-" ~ twentyKnot);
        text.setText(twentyKnot);
        text.setAlignment("right-center");
        text.setFont("LiberationFonts/LiberationMono-Bold.ttf");
        text.setFontSize(36);
        text.setTranslation(-twentyKnotWidth-2, -twentyKnot * knotSpacing);
    }
},

updateSpeedTape : func()
{
    # special case when speed is close to zero (show 'bottom' only)
    # translate based on start value
    # update digits in text

    # given it's a 100kt range, maybe fixed graphic for the tape reduces updates?

    var yOffset = 4 * me._controller.getIndicatedAirspeedKnots();
    me._speedTapeGroup.setTranslation(ISFD.hsiLeft, yOffset);
},

createAltitudeTape : func()
{
    # tick every 50' interval
    # text, monospace, 5 digits, ever 100'

    # background box
    var box = me.root.rect(ISFD.hsiRight + 1, -ISFD.halfSize, 
                           ISFD.altTapeWidth, ISFD.baseSize);
    box.setColorFill('#738A7E'); 
    box.set('z-index', -1);

    me._altTapeGroup = me.root.createChild("group", "altitude-tape-group");
    me._altTapeGroup.setTranslation(ISFD.hsiRight, 0);

	var tapePath = me._altTapeGroup.createChild("path", "altitude-tape");
    tapePath.setStrokeLineWidth(2);
    tapePath.setColor(1, 1, 1);

    var hundredFtSpacing = 64;
    var twoHundredFtSpacing = hundredFtSpacing * 2;
    var twoHundredFtWidth = 20;

    # empty array to hold altitude tape texts for easy updating
    me._altitudeTapeTexts = [];

    for (var i=0; i<=12; i+=1)
    {
        var y = (i - 6) * twoHundredFtSpacing;
        var tickY = y + hundredFtSpacing;

        tapePath.moveTo(0, -tickY).line(twoHundredFtWidth, 0);

        var text = me._altTapeGroup.createChild("text", "altitude-tape-legend-" ~ i);
        text.setText(text);
        text.setFontSize(36);
        text.setAlignment("left-center");
        text.setFont("LiberationFonts/LiberationMono-Regular.ttf");
        text.setTranslation(2, -y);
        
        # we will update the text very often, ensure we only do
        # real work if it actually changes
        text.enableUpdate();

    # save for later updating
        append(me._altitudeTapeTexts, text);
    } 
},

updateAltitudeTape : func()
{
    var altFt = me._controller.getAltitudeFt();
    var alt200 = int(altFt/200);
    var altMod200 = altFt - (alt200 * 200);

    var offset = 128 * (altMod200 / 200.0);
    me._altTapeGroup.setTranslation(ISFD.hsiRight, offset);

    # compute this as current alt - half altitude range
    var lowestAlt = (alt200 - 6) * 200;

    for (var i=0; i<=12; i+=1)
    {
        var alt = lowestAlt + (i * 200);
        # printf with 5 digits
        var s = sprintf("%05i", alt);
        me._altitudeTapeTexts[i].updateText(s);
    }

    # compute transform on group to put the actual altitude on centre
},

createCompassRose : func()
{
    
    

    # clip group for numerals
    var clipGroup = me.root.createChild("group", "rose-clip-group");
    clipGroup.set("clip-frame", canvas.Element.LOCAL);
    clipGroup.set("clip", "rect(176px, 142px, 256px, -164px)");
    clipGroup.set('z-index', 2);

    var roseBoxHeight = ISFD.modeBoxHeight;
    var hh = roseBoxHeight / 2;

    # background of the compass
    var p = clipGroup.createChild('path', 'rose-background');
    p.moveTo(ISFD.hsiXCenter - ISFD.roseRadius, ISFD.hsiBottom + 12 + ISFD.roseRadius);
    p.arcSmallCW(ISFD.roseRadius, ISFD.roseRadius, 0, 
                 ISFD.roseRadius * 2, 0);
    p.close();
    p.setColorFill('#738A7E'); 

    # add path for the heading arrow
    var arrow = me.root.createChild("path", "rose-arrow");
    arrow.setTranslation(ISFD.hsiXCenter, ISFD.hsiBottom);
    arrow.setStrokeLineWidth(2);
    arrow.setColor(1, 1, 1);

    # same size as the roll arrow
    var arrowHeight = (ISFD.hsiHeight / 2) - ISFD.rollBaseRadius;
    var arrowHWidth = arrowHeight * (2/3);

    arrow.moveTo(0, arrowHeight);
    arrow.line(arrowHWidth, -arrowHeight);
    arrow.line(-arrowHWidth * 2, 0);
    arrow.close();
    arrow.set('z-index', 4);

    me._roseGroup = clipGroup.createChild('group', 'rose-group');
    me._roseGroup.setTranslation(ISFD.hsiXCenter, ISFD.hsiBottom + 12 + ISFD.roseRadius);

    var roseTicks = me._roseGroup.createChild('path', 'rose-ticks');
    roseTicks.setStrokeLineWidth(2);
    roseTicks.setColor(1, 1, 1);
    roseTicks.set('z-index', 2);

    var textR = (ISFD.roseRadius) - 16;
    for (var i=0; i<36; i+=1) {
        # create ten degree text
        # TODO: 30 degree sizes should be bigger

        var text = me._roseGroup.createChild("text", "compass-rose-" ~ i);
        text.setText(i);
        text.setFontSize(36);
        text.setAlignment("center-top");
        text.setFont("LiberationFonts/LiberationMono-Bold.ttf");

        var horAngle = 90 - (i * 10); # angle from +ve X axis
        var sa = math.sin(horAngle * D2R);
        var ca = math.cos(horAngle * D2R);
        text.setTranslation(ca * textR, -sa * textR);
        text.setRotation(i * 10 * D2R);

        me.addPolarTick(roseTicks, i * 10, ISFD.roseRadius, ISFD.roseRadius - 8);
        me.addPolarTick(roseTicks, (i * 10) + 5, ISFD.roseRadius, ISFD.roseRadius - 16);
    }

    roseTicks.close();

},

createAltitudeBox : func()
{
    var halfBoxHeight = ISFD.boxHeight / 2;
    var box = me.root.rect(ISFD.hsiRight - 10, -halfBoxHeight, 
                           ISFD.altTapeWidth + 10, ISFD.boxHeight);
    box.setColorFill('#000000'); 
    box.setColor('#ffffff');
    box.setStrokeLineWidth(2);
    box.set('z-index', 2);

    var clipGroup = me.root.createChild('group', 'altitude-box-clip');
    clipGroup.set("clip-frame", canvas.Element.LOCAL);
    clipGroup.set("clip", "rect(-24px," ~ (ISFD.altTapeWidth + 10) ~ "px, 24px, 0px)");
    clipGroup.setTranslation(ISFD.hsiRight - 10, 0);
    clipGroup.set('z-index', 3);

    var text = clipGroup.createChild('text', 'altitude-box-text');
    me._altitudeBoxText = text;

    text.setText('88 ');
    text.setFontSize(44);
    text.setAlignment("left-center");
    text.setFont("LiberationFonts/LiberationMono-Regular.ttf");

    me._altitudeDigits00 = me.createDigitTape(clipGroup, 'altitude-digits00', '0');
    me._altitudeDigits00.setFontSize(32);
    me._altitudeDigits00.set('z-index', 4);
},

createSpeedBox : func()
{
    var halfBoxHeight = ISFD.boxHeight / 2;
    var box = me.root.rect(-ISFD.halfSize - 2, -halfBoxHeight, 
                           ISFD.speedTapeWidth + 4, ISFD.boxHeight);
    box.setColorFill('#000000'); 
    box.setColor('#ffffff');
    box.setStrokeLineWidth(2);
    box.set('z-index', 2);

    var clipGroup = me.root.createChild('group', 'speed-box-clip');
    clipGroup.set("clip-frame", canvas.Element.LOCAL);
    clipGroup.set("clip", "rect(-24px," ~ (ISFD.speedTapeWidth + 4) ~ "px, 24px, 0px)");
    clipGroup.setTranslation(-ISFD.halfSize, 0);
    clipGroup.set('z-index', 3);

    var text = clipGroup.createChild('text', 'speed-box-text');
    me._speedBoxText = text;

    text.setText('88 ');
    text.setFontSize(44);
    text.setAlignment("left-center");
    text.setFont("LiberationFonts/LiberationMono-Regular.ttf");

    me._speedDigit0 = me.createDigitTape(clipGroup, 'speed-digit0');
    me._speedDigit0.set('z-index', 4);
},

createAltimeterSetting: func()
{
    me._altimeterText = me.root.createChild('text', 'altimeter-setting-text');
    me._altimeterText.setText('1013');
    me._altimeterText.setAlignment("right-center");
    me._altimeterText.setFont("LiberationFonts/LiberationMono-Regular.ttf");
    me._altimeterText.setColor('#00ff00');

    var midTextY = -ISFD.halfSize + (ISFD.modeBoxHeight * 0.5);
    me._altimeterText.setTranslation(ISFD.hsiRight - 2, midTextY);
},

createModeText : func()
{
    me._modeText = me.root.createChild('text', 'mode-text');
    me._modeText.setFontSize(44);
    me._modeText.setText('APP');
    me._modeText.setAlignment("left-center");
    me._modeText.setFont("LiberationFonts/LiberationMono-Regular.ttf");
    me._modeText.setColor('#00ff00');

    var midTextY = -ISFD.halfSize + (ISFD.modeBoxHeight * 0.5);
    me._modeText.setTranslation(ISFD.hsiLeft + 2, midTextY);
},

updateApproachMode: func
{
    if (me._appMode != 0) {
        me._modeText.setText('APP');  
    }

    me._modeText.setVisible(me._appMode);
    me._localizerGroup.setVisible(me._appMode);
    me._glideslopeGroup.setVisible(me._appMode);
},

createLocalizer: func
{
    var hw = ISFD.needleBoxSize * 0.5;
    var g = me.root.createChild('group', 'localizer-group');
    g.setTranslation(ISFD.hsiXCenter, 156);
    me._localizerGroup = g;
    
    var bkg = g.rect(-hw, 0, ISFD.needleBoxSize, ISFD.needleBoxHeight);
    bkg.setColorFill('#000000'); 

    # markers: white line and hollow dots
    var m = g.createChild("path", "localizer-marker");
    m.setStrokeLineWidth(2);
    m.setColor(1, 1, 1);
    m.moveTo(0, 0);
    m.line(0, ISFD.needleBoxHeight);
    m.close();

    var r =( ISFD.needleBoxHeight - 8) * 0.5;
    var hh = ISFD.needleBoxHeight * 0.5;

    # four dots
    for (var i = -2; i <= 2; i +=1) {
        if (i == 0) continue;
        var x = i * 50;
        m.moveTo(x - r, hh);
        m.arcSmallCW(r, r, 0, r * 2, 0);
        m.arcSmallCW(r, r, 0, -r * 2, 0);
        m.close();
    }

    me._localizerPointer = g.createChild("path", "localizer-pointer");
    me._localizerPointer.moveTo(0, hh);
    me.addDiamond(me._localizerPointer , hh);
    me._localizerPointer.setColorFill('#ff00ff'); # magenta!
},

createGlideslope: func
{
    var g = me.root.createChild('group', 'glideslope-bar');
    me._glideslopeGroup = g;

    var hh = ISFD.needleBoxSize * 0.5;
    var hw = ISFD.needleBoxHeight * 0.5;

    g.setTranslation(ISFD.hsiRight - 36, 0);
    me._localizerGroup = g;
    
    var bkg = g.rect(0, -hh, ISFD.needleBoxHeight, ISFD.needleBoxSize);
    bkg.setColorFill('#000000'); 

    # markers: white line and hollow dots
    var m = g.createChild("path", "gs-marker");
    m.setStrokeLineWidth(2);
    m.setColor(1, 1, 1);
    m.moveTo(0, 0);
    m.line(ISFD.needleBoxHeight, 0);
    m.close();

    var r =( ISFD.needleBoxHeight - 8) * 0.5;

    # four dots
    for (var i = -2; i <= 2; i +=1) {
        if (i == 0) continue;
        var y = i * 50;
        m.moveTo(hw, y - r);
        m.arcSmallCW(r, r, 0, 0, r * 2);
        m.arcSmallCW(r, r, 0, 0, -r * 2);
        m.close();
    }

    me._gsPointer = g.createChild("path", "gs-pointer");
    me._gsPointer.moveTo(hw, 0);
    me.addDiamond(me._gsPointer , hw);
    me._gsPointer.setColorFill('#ff00ff'); # magenta!
},

updateILS: func
{
    var hsz = ISFD.needleBoxSize * 0.5;

    me._localizerPointer.setVisible(me._controller.isLocalizerValid());
    var locDev = me._controller.getLocalizerDeviationNorm() * hsz;
    me._localizerPointer.setTranslation(locDev, 0);

    me._gsPointer.setVisible(me._controller.isGSValid());
    var gsDev = me._controller.getGSDeviationNorm() * hsz;
    me._gsPointer.setTranslation(0, gsDev);
},

pressButtonAPP : func
{
    me._controller.toggleApproachMode();
},

update : func()
{
    # read LOC/GS deviation
    # read Mach for some options  
    me._controller.update();

# pitch and roll 
    var roll = me._controller.getBankAngleDeg() * D2R;
    var pitch = me._controller.getPitchDeg();
    me.pitchGroup.setTranslation(ISFD.hsiXCenter, pitch * me.pitchLadderDegreeSpacing);
    me._pitchRotation.setRotation(-roll);
    me._rollGroup.setRotation(-roll);

# heading
    me._roseGroup.setRotation(-me._controller.getHeadingDeg() * D2R);

    me.updateAltitudeTape();
    me.updateSpeedTape();

# speed box
    var spd = me._controller.getIndicatedAirspeedKnots();
    var spdDigit0 = math.mod(spd, 10);
    me._speedDigit0.setTranslation(53, 16 + spdDigit0 * 44);
    var s = sprintf("%02i ", math.floor(spd / 10));
    me._speedBoxText.setText(s);

# altitude box
    var alt = me._controller.getAltitudeFt();
    var altDigits00 = math.mod(alt / 10, 10);
    me._altitudeDigits00.setTranslation(80, 16 + altDigits00 * 32);
    var s = sprintf("%03i ", math.floor(alt / 100));
    me._altitudeBoxText.setText(s);

# barometric
    if (me._controller.isSTDBarometricPressure()) {
        me._altimeterText.setFontSize(44);
        me._altimeterText.setText('STD');
    } else {
        var s = '';
        if (me._controller.isHPaBarometer()) {
            s = sprintf('%4d HPA', me._controller.getBarometricPressureSettingHPa());
        } else {
            s = sprintf('%4.2f IN', me._controller.getBarometricPressureSettingInHg());            
        }

        # smaller text to fit
        me._altimeterText.setFontSize(32);
        me._altimeterText.setText(s);
    }

# APProach mode
    if (me._appMode != me._controller.isApproachMode()) {
        me._appMode = me._controller.isApproachMode;
        me.updateApproachMode();
    }

    if (me._appMode != 0) {
        me.updateILS();
    }
}  

};
