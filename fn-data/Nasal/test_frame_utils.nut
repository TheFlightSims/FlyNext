 #---------------------------------------------------------------------------
 #
 #	Title                : FRAME UTILS tests
 #
 #	File Type            : Unit test
 #
 #	Author               : Richard Harrison (richard@zaretto.com)
 #
 #	Creation Date        : 24 October 2020
 #
 #  Copyright (C) 2020 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

# fgcommand("nasal-test", props.Node.new({"path":"test_frame_utils.nut"}));

var setUp = func {
    logprint(LOG_INFO, "frame_utils test started");
};

# same, cab be ommitted
var tearDown = func {
    logprint(LOG_INFO, "frame_utils test finished");
};

test_partitionProcessorTest = func {
      var tt = maketimestamp();
      tt.stamp();
      var xx= PartitionProcessor.new("TEST", 54, tt);
      xx.set_max_time_usec(100);
      var obj = xx;

      for (ii=0;ii<5;ii+=1) {
          xx.process(obj, awg_9.tgts_list, 
                     func(pp, obj, data){
                         print("init");
                         obj.designated = 0;
                         obj.active_found = 0;
                         obj.searchCallsign = nil;
                         if (awg_9.active_u != nil and awg_9.active_u.Callsign != nil)
                           obj.searchCallsign =  awg_9.active_u.Callsign.getValue();
                     },
                     func(pp, obj, u){
                         printf("%-5d : %s",obj.data_index, u.Callsign.getValue());
                         var v = 0;
                         for (var idx=0;idx < 20; idx  += 1) {
                             #                       getprop("orientation/heading-deg");
                         }
                         return 1;
                     },
                     func(pp, obj, data)
                     {
                         print("Completed\n");
                     }
                    );
      }
}

#partitionProcessorTest();
