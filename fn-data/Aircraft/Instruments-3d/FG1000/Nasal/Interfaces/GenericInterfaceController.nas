# Copyright 2018 Stuart Buchanan
# This file is part of FlightGear.
#
# FlightGear is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# FlightGear is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with FlightGear.  If not, see <http://www.gnu.org/licenses/>.
#
# Generic Interface controller.

var nasal_dir = getprop("/sim/fg-root") ~ "/Aircraft/Instruments-3d/FG1000/Nasal/";
io.load_nasal(nasal_dir ~ 'Interfaces/PropertyPublisher.nas', "fg1000");
io.load_nasal(nasal_dir ~ 'Interfaces/PropertyUpdater.nas', "fg1000");

var GenericInterfaceController = {

  _instance : nil,

  INTERFACE_LIST : [
    { id:"NavDataInterface", path: nasal_dir ~ 'Interfaces/NavDataInterface.nas' },
    { id:"GenericEISPublisher", path: nasal_dir ~ 'Interfaces/GenericEISPublisher.nas' },
    { id:"GenericNavComPublisher", path: nasal_dir ~ 'Interfaces/GenericNavComPublisher.nas' },
    { id:"GenericNavComUpdater", path: nasal_dir ~ 'Interfaces/GenericNavComUpdater.nas' },
    { id:"GenericFMSPublisher", path: nasal_dir ~ 'Interfaces/GenericFMSPublisher.nas' },
    { id:"GenericFMSUpdater", path: nasal_dir ~ 'Interfaces/GenericFMSUpdater.nas' },
    { id:"GenericADCPublisher", path: nasal_dir ~ 'Interfaces/GenericADCPublisher.nas' },
    { id:"GenericFuelInterface", path: nasal_dir ~ 'Interfaces/GenericFuelInterface.nas' },
    { id:"GenericFuelPublisher", path: nasal_dir ~ 'Interfaces/GenericFuelPublisher.nas' },
    { id:"GFC700Interface", path: nasal_dir ~ 'Interfaces/GFC700Interface.nas' },
    { id:"GFC700Publisher", path: nasal_dir ~ 'Interfaces/GFC700Publisher.nas' },
    { id:"GMA1347Interface", path: nasal_dir ~ 'Interfaces/GMA1347Interface.nas' },

  ],

  # Factory method
  getOrCreateInstance : func() {
    if (GenericInterfaceController._instance == nil) {
      GenericInterfaceController._instance = GenericInterfaceController.new();
    }

    return GenericInterfaceController._instance;
  },

  new : func() {
    var obj = {
      parents : [GenericInterfaceController],
      running : 0,
    };

    return obj;
  },

  start : func() {
    if (me.running) return;

    foreach (var interface; GenericInterfaceController.INTERFACE_LIST) {
      io.load_nasal(interface.path, "fg1000");
      var code = sprintf("me.%sInstance = fg1000.%s.new();", interface.id, interface.id);
      var instantiate = compile(code);
      instantiate();
    }

    foreach (var interface; GenericInterfaceController.INTERFACE_LIST) {
      var code = 'me.' ~ interface.id ~ 'Instance.start();';
      var start_interface = compile(code);
      start_interface();
    }

    me.running = 1;
  },

  stop : func() {
    if (me.running == 0) return;

    foreach (var interface; GenericInterfaceController.INTERFACE_LIST) {
      io.load_nasal(interface.path, "fg1000");
      var code = 'me.' ~ interface.id ~ 'Instance.stop();';
      var stop_interface = compile(code);
      stop_interface();
    }

    me.running = 0;
  },

  restart : func() {
    me.stop();
    me.start();
  }
};
