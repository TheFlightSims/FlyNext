

var GenericController =
{

  new : func (isfd)
  {
    var obj = {
        parents : [GenericController],
        _isfd: isfd,
        _altimeterProp : "/instrumentation/altimeter/",
        _airspeedProp : "/instrumentation/airspeed-indicator/",
        _attitudeProp : "/instrumentation/attitude-indicator/",
        _navRadio: "/instrumentation/nav[0]/",
        _isSTDBaro : 0,
        _isHPa : 1,
        _approachMode : 0
    };

    return obj;
  },

  update : func
  {
  },

  getAltitudeFt : func
  {
    return getprop(me._altimeterProp ~ "indicated-altitude-ft");
  },

  getIndicatedAirspeedKnots : func
  {
    return getprop(me._airspeedProp ~ "indicated-speed-kt");
  },

  getHeadingDeg : func
  {
    # compass / gyro source for this?
    return getprop("/orientation/heading-deg");
  },

  getPitchDeg : func
  {
    return getprop(me._attitudeProp ~ "indicated-pitch-deg");
  },

  getBankAngleDeg : func
  {
    return getprop(me._attitudeProp ~ "indicated-roll-deg");
  },

  isSTDBarometricPressure : func
  {
    return me._isSTDBaro;
  },

  toggleSTDBarometricPressure : func 
  {
    me._isSTDBaro = (me._isSTDBaro == 0);
  },

  isHPaBarometer : func
  {
    return me._isHPa;
  },

  toggleHPaBarometer : func 
  {
    me._isHPa = (me._isHPa == 0);
  },
  
  getBarometricPressureSettingInHg : func
  {
    if (me._isSTDBaro) return 29.92;
    return getprop(me._altimeterProp ~ "setting-inhg");
  },

  getBarometricPressureSettingHPa : func
  {
    if (me._isSTDBaro) return 1013;
    return getprop(me._altimeterProp ~ "setting-hpa");
  },

  setBarometricPressureSettingInHg : func (inHg)
  {
    setprop(me._altimeterProp ~ "setting-inhg", inHg);
  },

  setBarometricPressureSettingHPa : func (hpa)
  {
    setprop(me._altimeterProp ~ "setting-hpa", hpa);
  },

  isApproachMode: func { return (me._approachMode != 0); },
  toggleApproachMode : func { me._approachMode = (me._approachMode == 0); },

  isLocalizerValid: func { return getprop(me._navRadio ~ "in-range"); },
  isGSValid: func { return getprop(me._navRadio ~ "gs-in-range");},

  getLocalizerDeviationNorm: func {
    return getprop(me._navRadio ~ "heading-needle-deflection-norm") or 0;
  },

  getGSDeviationNorm: func {
    return getprop(me._navRadio ~ "gs-needle-deflection-norm") or 0;
  },
}