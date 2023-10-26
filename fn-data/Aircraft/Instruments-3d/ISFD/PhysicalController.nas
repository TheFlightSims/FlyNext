
# ISFD controller drive by physical properties rather
# than instruments. Useful for testing with the UFO
var PhysicalController =
{

  new : func (isfd)
  {
    var obj = {
        parents : [PhysicalController],
        _isfd: isfd,
        _navRadio: "/instrumentation/nav[0]/",
        _isSTDBaro : 0,
        _isHPa : 1,
        _approachMode : 0
    };

    print("ISFD is using physical properties, not indicated");
    return obj;
  },

  update : func
  {
  },

  getAltitudeFt : func
  {
    return getprop("/position/altitude-ft");
  },

  getIndicatedAirspeedKnots : func
  {
    return getprop("/velocities/airspeed-kt");
  },

  getHeadingDeg : func
  {
    return getprop("/orientation/heading-deg");
  },

  getPitchDeg : func
  {
    return getprop("/orientation/pitch-deg");
  },

  getBankAngleDeg : func
  {
    return getprop("/orientation/roll-deg");
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
    return 29.92;
  },

  getBarometricPressureSettingHPa : func
  {
    return 1013;
  },

  setBarometricPressureSettingInHg : func (inHg)
  {
      print('ISFD: no-op with PhysicalController, no altimeter')
  },

  setBarometricPressureSettingHPa : func (hpa)
  {
      print('ISFD: no-op with PhysicalController, no altimeter')
  },

  isApproachMode: func { 

    return me._approachMode; 
  },

  toggleApproachMode : func { me._approachMode = (me._approachMode == 0); },

  isLocalizerValid: func { return getprop(me._navRadio ~ "in-range"); },
  isGSValid: func { return getprop(me._navRadio ~ "gs-in-range");},

  getLocalizerDeviationNorm: func {
    return getprop(me._navRadio ~ "heading-needle-deflection-norm");
  },

  getGSDeviationNorm: func {
    return getprop(me._navRadio ~ "gs-needle-deflection-norm");
  },
}