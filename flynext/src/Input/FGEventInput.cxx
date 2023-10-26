// FGEventInput.cxx -- handle event driven input devices
//
// Written by Torsten Dreyer, started July 2009.
//
// Copyright (C) 2009 Torsten Dreyer, Torsten (at) t3r _dot_ de
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation; either version 2 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// $Id$

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <cstring>
#include "FGEventInput.hxx"
#include <Main/fg_props.hxx>
#include <simgear/io/sg_file.hxx>
#include <simgear/props/props_io.hxx>
#include <simgear/math/SGMath.hxx>
#include <simgear/math/interpolater.hxx>
#include <Scripting/NasalSys.hxx>

using simgear::PropertyList;
using std::cout;
using std::endl;
using std::map;
using std::string;

FGEventSetting::FGEventSetting( SGPropertyNode_ptr base ) :
  value(0.0)
{
  SGPropertyNode_ptr n;

  if( (n = base->getNode( "value" )) != NULL ) {  
    valueNode = NULL;
    value = n->getDoubleValue();
  } else {
    n = base->getNode( "property" );
    if( n == NULL ) {
      SG_LOG( SG_INPUT, SG_WARN, "Neither <value> nor <property> defined for event setting." );
    } else {
      valueNode = fgGetNode( n->getStringValue(), true );
    }
  }

  if( (n = base->getChild("condition")) != NULL )
    condition = sgReadCondition(base, n);
  else
    SG_LOG( SG_INPUT, SG_ALERT, "No condition for event setting." );
}

double FGEventSetting::GetValue()
{
  return valueNode == NULL ? value : valueNode->getDoubleValue();
}

bool FGEventSetting::Test()
{
  return condition == NULL ? true : condition->test();
}

static inline bool StartsWith( string & s, const char * cp )
{
  return s.find( cp ) == 0;
}

FGInputEvent * FGInputEvent::NewObject( FGInputDevice * device, SGPropertyNode_ptr node )
{
  string name = node->getStringValue( "name", "" );
  if( StartsWith( name, "button-" ) )
    return new FGButtonEvent( device, node );

  if( StartsWith( name, "rel-" ) )
    return new FGRelAxisEvent( device, node );

  if( StartsWith( name, "abs-" ) )
    return new FGAbsAxisEvent( device, node );

  return new FGInputEvent( device, node );
}

FGInputEvent::FGInputEvent( FGInputDevice * aDevice, SGPropertyNode_ptr node ) :
  device( aDevice ),
  lastDt(0.0), 
  lastSettingValue(std::numeric_limits<float>::quiet_NaN())
{
  name = node->getStringValue( "name", "" );
  desc = node->getStringValue( "desc", "" );
  intervalSec = node->getDoubleValue("interval-sec",0.0);
  
  read_bindings( node, bindings, KEYMOD_NONE, device->GetNasalModule() );
    
  for (auto child : node->getChildren("setting"))
    settings.push_back( new FGEventSetting(child) );
}

FGInputEvent::~FGInputEvent()
{
}

void FGInputEvent::update( double dt )
{
  for (auto setting : settings) {
    if( setting->Test() ) {
      const double value = setting->GetValue();
      if( value != lastSettingValue ) {
        device->Send( GetName(), value );
        lastSettingValue = value;
      }
    }
  }
}

void FGInputEvent::fire( FGEventData & eventData )
{
  lastDt += eventData.dt;
  if( lastDt >= intervalSec ) {

    for( binding_list_t::iterator it = bindings[eventData.modifiers].begin(); it != bindings[eventData.modifiers].end(); ++it )
      fire( *it, eventData );

    lastDt -= intervalSec;
  }
}

void FGInputEvent::fire(SGAbstractBinding* binding, FGEventData& eventData)
{
  binding->fire();
}



FGAxisEvent::FGAxisEvent( FGInputDevice * device, SGPropertyNode_ptr node ) :
  FGInputEvent( device, node )
{
  tolerance = node->getDoubleValue("tolerance", 0.002);
  minRange = node->getDoubleValue("min-range", 0.0 );
  maxRange = node->getDoubleValue("max-range", 0.0 );
  center = node->getDoubleValue("center", 0.0);
  deadband = node->getDoubleValue("dead-band", 0.0);
  lowThreshold = node->getDoubleValue("low-threshold", -0.9);
  highThreshold = node->getDoubleValue("high-threshold", 0.9);
  lastValue = 9999999;
    
// interpolation of values
  if (node->hasChild("interpolater")) {
    interpolater.reset(new SGInterpTable{node->getChild("interpolater")});
    mirrorInterpolater = node->getBoolValue("interpolater/mirrored", false);
  }
}

FGAxisEvent::~FGAxisEvent()
{
    
}

void FGAxisEvent::fire( FGEventData & eventData )
{
  if (fabs( eventData.value - lastValue) < tolerance)
    return;
  lastValue = eventData.value;

  // We need a copy of the  FGEventData struct to set the new value and to avoid side effects
  FGEventData ed = eventData;

  if( minRange != maxRange )
    ed.value = 2.0*(eventData.value-minRange)/(maxRange-minRange)-1.0;

  if( fabs(ed.value) < deadband )
    ed.value = 0.0;
    
  if (interpolater) {
    if ((ed.value < 0.0) && mirrorInterpolater) {
      // mirror the positive interpolation for negative values
      ed.value = -interpolater->interpolate(fabs(ed.value));
    } else {
      ed.value = interpolater->interpolate(ed.value);
    }
  }

  FGInputEvent::fire( ed );
}

void FGAbsAxisEvent::fire(SGAbstractBinding* binding, FGEventData& eventData)
{
  // sets the "setting" node
  binding->fire( eventData.value );
}

FGRelAxisEvent::FGRelAxisEvent( FGInputDevice * device, SGPropertyNode_ptr node ) : 
  FGAxisEvent( device, node ) 
{
  // relative axes can't use tolerance
  tolerance = 0.0;
}

void FGRelAxisEvent::fire(SGAbstractBinding* binding, FGEventData& eventData)
{
  // sets the "offset" node
  binding->fire( eventData.value, 1.0 );
}

FGButtonEvent::FGButtonEvent( FGInputDevice * device, SGPropertyNode_ptr node ) :
  FGInputEvent( device, node ),
  repeatable(false),
  lastState(false)
{
  repeatable = node->getBoolValue("repeatable", repeatable);
}

void FGButtonEvent::fire( FGEventData & eventData )
{
  bool pressed = eventData.value > 0.0;
  if (pressed) {
    // The press event may be repeated.
    if (!lastState || repeatable) {
      SG_LOG( SG_INPUT, SG_DEBUG, "Button has been pressed" );
      FGInputEvent::fire( eventData );
    }
  } else {
    // The release event is never repeated.
    if (lastState) {
      SG_LOG( SG_INPUT, SG_DEBUG, "Button has been released" );
      eventData.modifiers|=KEYMOD_RELEASED;
      FGInputEvent::fire( eventData );
    }
  }
          
  lastState = pressed;
}

void FGButtonEvent::update( double dt )
{
  if (repeatable && lastState) {
      // interval / dt handling is done by base ::fire method
      FGEventData ed{1.0, dt, 0 /* modifiers */};
      FGInputEvent::fire( ed );
  }
}

FGInputDevice::~FGInputDevice()
{
  auto nas = globals->get_subsystem<FGNasalSys>();
  if (nas && deviceNode ) {
    SGPropertyNode_ptr nasal = deviceNode->getNode("nasal");
    if( nasal ) {
      SGPropertyNode_ptr nasalClose = nasal->getNode("close");
      if (nasalClose) {
        const string s = nasalClose->getStringValue();
        nas->createModule(nasalModule.c_str(), nasalModule.c_str(), s.c_str(), s.length(), deviceNode );
      }
    }
    nas->deleteModule(nasalModule.c_str());
  }
} 

void FGInputDevice::Configure( SGPropertyNode_ptr aDeviceNode )
{
  deviceNode = aDeviceNode;

  // use _uniqueName here so each loaded device gets its own Nasal module
  nasalModule = string("__event:") + _uniqueName;

  for (auto ev : deviceNode->getChildren( "event" )) {
    AddHandledEvent( FGInputEvent::NewObject( this, ev) );
  }

  debugEvents = deviceNode->getBoolValue("debug-events", debugEvents );
  grab = deviceNode->getBoolValue("grab", grab );

    PropertyList reportNodes = deviceNode->getChildren("report");
    for( PropertyList::iterator it = reportNodes.begin(); it != reportNodes.end(); ++it ) {
        FGReportSetting_ptr r = new FGReportSetting(*it);
        reportSettings.push_back(r);
    }

  // TODO:
  // add nodes for the last event:
  // last-event/name [string]
  // last-event/value [double]

  SGPropertyNode_ptr nasal = deviceNode->getNode("nasal");
  if (nasal) {
    SGPropertyNode_ptr open = nasal->getNode("open");
    if (open) {
      const string s = open->getStringValue();
      auto nas = globals->get_subsystem<FGNasalSys>();
      if (nas)
        nas->createModule(nasalModule.c_str(), nasalModule.c_str(), s.c_str(), s.length(), deviceNode );
    }
  }

}

void FGInputDevice::AddHandledEvent( FGInputEvent_ptr event )
{
    auto it = handledEvents.find(event->GetName());
    if (it == handledEvents.end()) {
        handledEvents.insert(it, std::make_pair(event->GetName(), event));
    }
}

void FGInputDevice::update( double dt )
{
  for( map<string,FGInputEvent_ptr>::iterator it = handledEvents.begin(); it != handledEvents.end(); it++ )
    (*it).second->update( dt );

  report_setting_list_t::const_iterator it;
  for (it = reportSettings.begin(); it != reportSettings.end(); ++it) {
    if ((*it)->Test()) {
      std::string reportData = (*it)->reportBytes(nasalModule);
      SendFeatureReport((*it)->getReportId(), reportData);
    }
  }
}

void FGInputDevice::HandleEvent( FGEventData & eventData )
{
  string eventName = TranslateEventName( eventData );  
  if( debugEvents ) {
    SG_LOG(SG_INPUT, SG_INFO, GetUniqueName() << " has event " <<
           eventName << " modifiers=" << eventData.modifiers << " value=" << eventData.value);
  }
    
  if( handledEvents.count( eventName ) > 0 ) {
    handledEvents[ eventName ]->fire( eventData );
  }
}

void FGInputDevice::SetName( string name )
{
  this->name = name; 
}

void FGInputDevice::SetUniqueName(const std::string &name)
{
  _uniqueName = name;
}

void FGInputDevice::SetSerialNumber( std::string serial )
{
    serialNumber = serial;
}

void FGInputDevice::SendFeatureReport(unsigned int reportId, const std::string& data)
{
    SG_LOG(SG_INPUT, SG_WARN, "SendFeatureReport not implemented");
}


const char * FGEventInput::PROPERTY_ROOT = "/input/event";

FGEventInput::FGEventInput()
{
}

FGEventInput::~FGEventInput()
{

}

void FGEventInput::shutdown()
{
    for (auto it : input_devices) {
        it.second->Close();
        delete it.second;
    }
    input_devices.clear();
}

void FGEventInput::init( )
{
    configMap = FGDeviceConfigurationMap( "Input/Event",
                                          fgGetNode(PROPERTY_ROOT, true),
                                          "device-named");
}

void FGEventInput::postinit ()
{
}

void FGEventInput::update( double dt )
{
    for (auto it : input_devices) {
        it.second->update(dt);
    }
}

std::string FGEventInput::computeDeviceIndexName(FGInputDevice* dev) const
{
    int count = 0;
    const auto devName = dev->GetName();
    for (auto it : input_devices) {
        if (it.second->GetName() == devName) {
            ++count;
        }
    }

    std::ostringstream os;
    os << devName << "_" << count;
    return os.str();
}

unsigned FGEventInput::AddDevice( FGInputDevice * inputDevice )
{
  SGPropertyNode_ptr baseNode = fgGetNode( PROPERTY_ROOT, true );
  SGPropertyNode_ptr deviceNode;

  const string deviceName = inputDevice->GetName();
  SGPropertyNode_ptr configNode;
  
    // if we have a serial number set, try using that to select a specfic configuration
  if (!inputDevice->GetSerialNumber().empty()) {
    const string nameWithSerial = deviceName + "::" + inputDevice->GetSerialNumber();
    if (configMap.hasConfiguration(nameWithSerial)) {
      configNode = configMap.configurationForDeviceName(nameWithSerial);
        SG_LOG(SG_INPUT, SG_INFO, "using instance-specific configuration for device "
               << nameWithSerial << " : " << configNode->getStringValue("source"));
      inputDevice->SetUniqueName(nameWithSerial);
    }
  }

  // try instanced (counted) name
  const auto nameWithIndex = computeDeviceIndexName(inputDevice);
  if (configNode == nullptr) {
      if (configMap.hasConfiguration(nameWithIndex)) {
          configNode = configMap.configurationForDeviceName(nameWithIndex);
          SG_LOG(SG_INPUT, SG_INFO, "using instance-specific configuration for device "
                 << nameWithIndex << " : " << configNode->getStringValue("source"));
      }
  }
  
  // otherwise try the unmodifed name for the device
  if (configNode == nullptr) {
    if (!configMap.hasConfiguration(deviceName)) {
      SG_LOG(SG_INPUT, SG_DEBUG, "No configuration found for device " << deviceName);
      delete inputDevice;
      return INVALID_DEVICE_INDEX;
    }
    configNode = configMap.configurationForDeviceName(deviceName);
  }
    
  // if we didn't generate a name based on the serial number,
  // use the name with the index suffix _0, _1, etc
  if (inputDevice->GetUniqueName().empty()) {
    inputDevice->SetUniqueName(nameWithIndex);
  }

  // found - copy to /input/event/device[n]
  // find a free index
  unsigned int index;
  for ( index = 0; index < MAX_DEVICES; index++ ) {
    if ( (deviceNode = baseNode->getNode( "device", index, false ) ) == nullptr )
      break;
  }

  if (index == MAX_DEVICES) {
    SG_LOG(SG_INPUT, SG_WARN, "To many event devices - ignoring " << inputDevice->GetUniqueName() );
    delete inputDevice;
    return INVALID_DEVICE_INDEX;
  }

  // create this node
  deviceNode = baseNode->getNode( "device", index, true );

  // and copy the properties from the configuration tree
  copyProperties(configNode, deviceNode );

  inputDevice->Configure( deviceNode );

    bool ok = inputDevice->Open();
    if (!ok) {
        // TODO repot a better error here, to the user
        SG_LOG(SG_INPUT, SG_ALERT, "can't open InputDevice " << inputDevice->GetUniqueName());
        delete inputDevice;
        return INVALID_DEVICE_INDEX;
    }

    input_devices[deviceNode->getIndex()] = inputDevice;

    SG_LOG(SG_INPUT, SG_DEBUG, "using InputDevice " << inputDevice->GetUniqueName());
    return deviceNode->getIndex();
}

void FGEventInput::RemoveDevice( unsigned index )
{
  // not fully implemented yet
  SGPropertyNode_ptr baseNode = fgGetNode( PROPERTY_ROOT, true );
  SGPropertyNode_ptr deviceNode = NULL;

  FGInputDevice *inputDevice = input_devices[index];
  if (inputDevice) {
    inputDevice->Close();
    input_devices.erase(index);
    delete inputDevice;
    
  }
  deviceNode = baseNode->removeChild("device", index);
}

FGReportSetting::FGReportSetting( SGPropertyNode_ptr base )
{
    reportId = base->getIntValue("report-id");
    nasalFunction = base->getStringValue("nasal-function");

    PropertyList watchNodes = base->getChildren( "watch" );
    for (PropertyList::iterator it = watchNodes.begin(); it != watchNodes.end(); ++it ) {
        std::string path = (*it)->getStringValue();
        SGPropertyNode_ptr n = globals->get_props()->getNode(path, true);
        n->addChangeListener(this);
    }

    dirty = true;
}

bool FGReportSetting::Test()
{
    bool d = dirty;
    dirty = false;
    return d;
}

std::string FGReportSetting::reportBytes(const std::string& moduleName) const
{
    auto nas = globals->get_subsystem<FGNasalSys>();
    if (!nas) {
        return {};
    }

    naRef module = nas->getModule(moduleName.c_str());
    if (naIsNil(module)) {
        SG_LOG(SG_IO, SG_WARN, "No such Nasal module:" << moduleName);
        return {};
    }
    
    naRef func = naHash_cget(module, (char*) nasalFunction.c_str());
    if (!naIsFunc(func)) {
        return std::string();
    }

    naRef result = nas->call(func, 0, 0, naNil());
    if (naIsString(result)) {
        size_t len = naStr_len(result);
        char* bytes = naStr_data(result);
        return std::string(bytes, len);
    }

    if (naIsVector(result)) {
      int len = naVec_size(result);
      std::string s;
      for (int b=0; b < len; ++b) {
        int num = naNumValue(naVec_get(result, b)).num;
        s.push_back(static_cast<char>(num));
      }

      // can't access FGInputDevice here to check debugEvents flag
#if 0
      std::ostringstream byteString;
      static const char* hexTable = "0123456789ABCDEF";

        for (int i=0; i<s.size(); ++i) {
            uint8_t uc = static_cast<uint8_t>(s[i]);
            byteString << hexTable[uc >> 4];
            byteString << hexTable[uc & 0x0f];
            byteString << " ";
        }
        SG_LOG(SG_INPUT, SG_INFO, "report bytes: (" << s.size() << ") " << byteString.str());
#endif

      return s;
    }
    
    SG_LOG(SG_INPUT, SG_DEV_WARN, "bad return data from report setting");
    return {};
}

void FGReportSetting::valueChanged(SGPropertyNode * node)
{
    dirty = true;
}
