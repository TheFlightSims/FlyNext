 #---------------------------------------------------------------------------
 #
 #	Title                : EMESARY tests
 #
 #	File Type            : Unit test
 #
 #	Author               : Richard Harrison (richard@zaretto.com)
 #
 #	Creation Date        : 14 June 2020
 #
 #  Copyright (C) 2020 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

# fgcommand("nasal-test", props.Node.new({"path":"test_emesary.nut"}));


# note you can omit this if not needed
var setUp = func {
    logprint(LOG_INFO, "Emesary tests begin");
};

# same, cab be ommitted
var tearDown = func {
    logprint(LOG_INFO, "Emesary tests finished");
};


var test_emesary_transmit_receive = func {
    logprint(LOG_INFO, "Emesary test transmit receive");

var baseRecipientCount = emesary.GlobalTransmitter.RecipientCount(); 
    logprint(LOG_INFO, " (notice) already have ",baseRecipientCount);

    var TestFailCount = 0;
    var TestSuccessCount = 0;

    var TestNotification =
    {
        new: func(_value)
        {
            var new_class = emesary.Notification.new("TestNotification", _value);
            return new_class;
        },
    };
    var TestNotProcessedNotification =
    {
        new: func(_value)
        {
            var new_class = emesary.Notification.new("TestNotProcessedNotification", _value);
            return new_class;
        },
    };
    var RadarReturnNotification =
    {
        new: func(_value, _x, _y, _z)
        {
            var new_class = emesary.Notification.new("RadarReturnNotification", _value);
            new_class.x = _x;
            new_class.y = _y;
            new_class.z = _z;
            return new_class;
        },
    };

    var TestRecipient =
    {
        new: func(_ident)
        {
            var new_class = emesary.Recipient.new(_ident);
            new_class.count = 0;
            new_class.Receive = func(notification)
            {
                if (notification.NotificationType == "TestNotification")
                    {
                        me.count = me.count + 1;
                        return emesary.Transmitter.ReceiptStatus_OK;
                    }
                return emesary.Transmitter.ReceiptStatus_NotProcessed;
            };
            return new_class;
        },
    };

    var TestRadarRecipient =
    {
        new: func(_ident)
        {
            var new_class = emesary.Recipient.new(_ident);
            new_class.Value = "";
            new_class.Receive = func(notification)
            {
                if (notification.NotificationType == "RadarReturnNotification"){
                        new_class.ReturnValue = sprintf("%s:%s.%s.%s",notification.NotificationType, notification.x, notification.y, notification.z);
                        notification.ReturnValue = new_class;
                        return emesary.Transmitter.ReceiptStatus_OK;
                    }
                return emesary.Transmitter.ReceiptStatus_NotProcessed;
            };
            return new_class;
        },
    };

    var PerformTest = func(tid, expected_value, method)
    {
        var testResult = method();
        if (testResult)
            {
                TestSuccessCount = TestSuccessCount + 1;
                logprint(LOG_INFO, sprintf("  %s [Pass] :%s == %s",tid,expected_value, testResult));
            }
        else
            {
                TestFailCount = TestFailCount + 1;
                logprint(LOG_ALERT, sprintf("  %s [Fail] : %s != %s",tid,expected_value, testResult));
            }
        unitTest.assert(expected_value, testResult, tid);

    }
    var tt = TestRecipient.new("tt recipient");
    var tt1 = TestRecipient.new("tt1 recipient1");
    var tt3 = TestRecipient.new("tt3 recipient3");
    var tt_radar_recipient = TestRadarRecipient.new("tt_radar_recipient: Radar Test recipient2");

    PerformTest("Create Notification", "TestNotification.Test notification",
                func 
                {
                    var tn = TestNotification.new("Test notification"); 
                    return tn.NotificationType~"."~tn.Ident;
                });

    PerformTest("Register tt", 1 + baseRecipientCount,
                func 
                {
                    emesary.GlobalTransmitter.Register(tt);
                    return emesary.GlobalTransmitter.RecipientCount(); 
                });
    PerformTest("Register tt1", 2 + baseRecipientCount,
                func 
                {
                    emesary.GlobalTransmitter.Register(tt1);
                    return emesary.GlobalTransmitter.RecipientCount(); 
                });
    PerformTest("Register tt_radar_recipient", 3 + baseRecipientCount,
                func 
                {
                    emesary.GlobalTransmitter.Register(tt_radar_recipient);
                    return emesary.GlobalTransmitter.RecipientCount(); 
                });
    PerformTest("Register tt3", 4 + baseRecipientCount,
                func 
                {
                    emesary.GlobalTransmitter.Register(tt3);
                    return emesary.GlobalTransmitter.RecipientCount(); 
                });

    PerformTest("Notify", 1,
                func
                {
                    var rv = emesary.GlobalTransmitter.NotifyAll(TestNotification.new("Test notification"));
                    return !emesary.Transmitter.IsFailed(rv) and rv != emesary.Transmitter.ReceiptStatus_NotProcessed and tt.count == 1; 
                });

    PerformTest("DeRegister tt1", 3 + baseRecipientCount,
                func
                {
                    emesary.GlobalTransmitter.DeRegister(tt1);
                    return emesary.GlobalTransmitter.RecipientCount(); 
                });

#    tt1_count = tt1.count;
    PerformTest("NotifyAfterDeregister", tt1.count,
                func
                {
                    emesary.GlobalTransmitter.NotifyAll(TestNotification.new("Test notification"));
#                    return tt1.count == tt1_count;
                    return tt1.count;
                });

    tt.count = 0;

    PerformTest("Recipient.Active", 1,
                func
                {
                    var rv = emesary.GlobalTransmitter.NotifyAll(TestNotification.new("Test notification"));
                    if (!emesary.Transmitter.IsFailed(rv) and rv != emesary.Transmitter.ReceiptStatus_NotProcessed)
                      return tt.count; 
                    else
                      return -1000;
                });


    PerformTest("Test Not Processed Notification", emesary.Transmitter.ReceiptStatus_NotProcessed,
                func
                {
                    var rv = emesary.GlobalTransmitter.NotifyAll(TestNotProcessedNotification.new("Not Processed"));
                    return rv; 
                });

    PerformTest("NotifyAll", "RadarReturnNotification.x0.y0.z0",
                func
                {
                    emesary.GlobalTransmitter.NotifyAll(RadarReturnNotification.new("Radar notification", "x0","y0","z0"));
                    return tt_radar_recipient.ReturnValue; 
                });

    PerformTest("Deregister", 0 + baseRecipientCount,
                func
                {
                    emesary.GlobalTransmitter.DeRegister(tt);
                    emesary.GlobalTransmitter.DeRegister(tt3);
                    emesary.GlobalTransmitter.DeRegister(tt_radar_recipient);
                    return emesary.GlobalTransmitter.RecipientCount(); 
                });


}
#---1


# all test macros take an option 'message' argument
test_transfer = func {
    logprint(LOG_INFO, "Emesary: Test_transfers");
    var decoded = 10;
    var coded = "1234";
    var init = 1;
    var counter = 11;
    var pos = 4;
    while (init or (size(coded) == 4 and pos == 4 and decoded == counter-1 and find(emesary_mp_bridge.OutgoingMPBridge.MessageEndChar,coded) == -1 and find(emesary_mp_bridge.OutgoingMPBridge.SeperatorChar,coded) == -1 and counter != 65600)) {
        coded = emesary.BinaryAsciiTransfer.encodeInt(counter,4);
        if (init) {
            init = 0;
        }
        decoded = emesary.BinaryAsciiTransfer.decodeInt(coded,4,0);
        pos = decoded.pos;
        decoded = decoded.value;
        counter += 1;
    }
    unitTest.assert_equal(counter, 65600, sprintf("Decoded=%d Coded=%s Integer=%d Pos=%d Size=%d", decoded, coded, counter-1, pos, size(coded)));

    for(i=-1;i<=1;i+=0.1){
        var dv = emesary.TransferNorm.encode(i,2);
        var v = emesary.TransferNorm.decode(dv, 2,0);
        var delta = math.abs(i - v.value);
        unitTest.assert(delta <= 0.01, sprintf("Norm: Fail: %f => %f : d=%f",i,v.value,delta));
    }

    for(i=-124;i<124;i+=1){
        var dv = emesary.TransferByte.encode(i);
        var v = emesary.TransferByte.decode(dv, 0);
        unitTest.assert(i == v.value, sprintf("Byte: fail: %d => %d ",i,v.value));
    }

    var pos = 0;
    var v = emesary.BinaryAsciiTransfer.encodeNumeric(123, 1, 1.0);
    var dv=emesary.BinaryAsciiTransfer.decodeNumeric(v,1,1.0  ,pos);
    unitTest.assert_equal(dv.value,123, "BinaryAsciiTransfer.encodeNumeric");

    for(i=-123; i <= 123; i+=1){
        var v = emesary.BinaryAsciiTransfer.encodeNumeric(i,1, 1.0);
        var pos = 0;
        var dv=emesary.BinaryAsciiTransfer.decodeNumeric(v,1,1.0  ,pos);
        unitTest.assert_equal(dv.value, i, "BinaryAsciiTransfer.encodeNumeric(1)");
    }

    teststring = func(s){
        dv = emesary.TransferString.encode(s);
        nv = emesary.TransferString.decode(dv,0);
        unitTest.assert_equal(s, nv.value, "emesary.TransferString");
    }
    teststring("");
    teststring("@");
    teststring("--");
    teststring("qqqqqqqqqq-");
}


test_mp_bridge = func {
     logprint(LOG_INFO,"Emesary MP bridge tests start");

     var testMpPropertyPath = "/ai[0]/models[0]/multiplayer[11]";
     var mp_listener = nil;
     var testRoutedNotifications = [notifications.GeoEventNotification.new(nil)];
     var testBridgedTransmitter = emesary.Transmitter.new("geoOutgoingBridge");
     var testOutgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("F-14mp.geo",testRoutedNotifications, 18, "", testBridgedTransmitter);
     testOutgoingBridge.MPStringMaxLen = 150;

     var msgList = [];
     var testRecipient = emesary.Recipient.new("Test");

     valuesWithinRange = func(value1, value2, range){
         return math.abs(value1 - value2) <= range;
     }
     testRecipient.FailCount = 0;
     testRecipient.Receive = func(notification) {
         if (notification.NotificationType == "GeoEventNotification") {
             #        print ("recv(0): type=",notification.NotificationType, " fromIncoming=",notification.FromIncomingBridge);
             if (notification.Name=="DONE") {
                 printf("Emesary MP Bridge tests completed; %d failure",me.FailCount);

                 # now clean up;
                 emesary.GlobalTransmitter.DeRegister(testRecipient);

                 setprop("/ai/models/model-removed",testMpPropertyPath);

                 if (mp_listener != nil)
                     removelistener(mp_listener);

                 return emesary.Transmitter.ReceiptStatus_NotProcessed; # we're not processing it, just looking
             }

             foreach (var msg; msgList) {
                 if (msg.SecondaryKind == notification.SecondaryKind) {
                     #print("Check msg ",msg.Kind);
                     var failed = 0;

                     if (math.abs(msg.Position.lat() - notification.Position.lat()) > 0.00001 or 
                         math.abs(msg.Position.lon() - notification.Position.lon()) > 0.00001 or 
                         math.abs(msg.Position.alt() - notification.Position.alt()) > 1) {
                         failed = 1;
                         printf("Fail Position:(%d) %s != %s",msg.Kind, msg.Position, notification.Position);
                     }

                     if (msg.Name != notification.Name) {
                         failed = 1;
                         printf("Fail Name:(%d) %s != %s",msg.Kind, msg.Name, notification.Name);
                     }

                     if (msg.Kind != notification.Kind) {
                         failed = 1;
                         printf("Fail Kind:(%d) %s != %s",msg.Kind, msg.Kind, notification.Kind);
                     }

                     if (msg.SecondaryKind != notification.SecondaryKind) {
                         failed = 1;
                         printf("Fail SecondaryKind:(%d) %s != %s",msg.Kind, msg.SecondaryKind, notification.SecondaryKind);
                     }

                     if (!valuesWithinRange(msg.u_fps, notification.u_fps,1)) {
                         failed = 1;
                         printf("Fail u_fps:(%d) %s != %s",msg.Kind, msg.u_fps, notification.u_fps);
                     }

                     if (!valuesWithinRange(msg.v_fps, notification.v_fps,1)) {
                         failed = 1;
                         printf("Fail v_fps:(%d) %s != %s",msg.Kind, msg.v_fps, notification.v_fps);
                     }

                     if (!valuesWithinRange(msg.w_fps, notification.w_fps,1)) {
                         failed = 1;
                         printf("Fail w_fps:(%d) %s != %s",msg.Kind, msg.w_fps, notification.w_fps);
                     }

                     if (msg.RemoteCallsign != notification.RemoteCallsign) {
                         failed = 1;
                         printf("Fail RemoteCallsign:(%d) %s != %s",msg.Kind, msg.RemoteCallsign, notification.RemoteCallsign);
                     }

                     if (msg.Flags != notification.Flags) {
                         failed = 1;
                         printf("Fail Flags:(%d) %s != %s",msg.Kind, msg.Flags, notification.Flags);
                     }
                     if (!failed)
                         printf("%s (%d) received correctly",notification.NotificationType, notification.Kind);
                     else
                         me.FailCount = me.FailCount + 1;
                     return emesary.Transmitter.ReceiptStatus_NotProcessed; # we're not processing it, just looking
                 }
             }
             print("Failed to locate notification Key=",msg.SecondaryKind);
             #    debug.dump(notification);
         }
         return emesary.Transmitter.ReceiptStatus_NotProcessed; # we're not processing it, just looking
     }

     # register the test recipient on the global transmitter as that is where messages will be bridged to
     emesary.GlobalTransmitter.Register(testRecipient);

     # start the incoming bridge - which will connect from the remote bridge (testBridgedTransmitter)
     # and route the notifications so that they come out of the global transmitter.
     emesary_mp_bridge.IncomingMPBridge.startMPBridge(testRoutedNotifications, 18, emesary.GlobalTransmitter);

     #
     # Create the incoming bridge by faking a model appearing
     #
     var node = props.getNode(testMpPropertyPath,1);
     node.getNode("callsign",1).setValue("test-mp");
     var mpNode = node.getNode("sim/multiplay",1);
     bridgeNode = mpNode.getNode("emesary/bridge[18]",1);

     #
     # lastly we need to manually copy the properties from where the outgoing bridge puts them
     # to where the incoming bridge expects them.
     # This is normally performed by the multiplayer code - but for test purposes this
     # allows testing on a single instance.
     mp_listener = setlistener("/sim/multiplay/emesary/bridge[18]", func(v){
             bridgeNode.setValue(v.getValue());
         },0,0);

     # This is what causes the incoming bridge to create a connection between the multiplayer node
     # and will result in an active incoming bridge 
     setprop("/ai/models/model-added", testMpPropertyPath);

     #
     # send out test messages
     for (var idx=0; idx < 20; idx += 1) {
         var msg = notifications.GeoEventNotification.new("mhit", "AIM"~idx, 19, idx);
         testBridgedTransmitter.NotifyAll(msg);
         append(msgList, msg);
     }
     msg = notifications.GeoEventNotification.new("mhit", "DONE", 19, 100);
     testBridgedTransmitter.NotifyAll(msg);
}

