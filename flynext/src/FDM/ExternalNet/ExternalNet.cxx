/*
 * SPDX-FileName: ExternalNet.cxx
 * SPDX-FileComment: an net interface to an external flight dynamics model
 * SPDX-FileCopyrightText: Copyright (C) 2001  Curtis L. Olson  - http://www.flightgear.org/~curt
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <cstring>

#include <simgear/debug/logstream.hxx>
#include <simgear/io/lowlevel.hxx> // endian tests
#include <simgear/io/sg_netBuffer.hxx>

#include <Main/fg_props.hxx>
#include <Network/native_structs.hxx>
#include <Network/native_ctrls.hxx>
#include <Network/native_fdm.hxx>

#include "ExternalNet.hxx"


class HTTPClient : public simgear::NetBufferChannel
{
    bool done;
    SGTimeStamp start;
    simgear::NetChannelPoller poller;

public:
    HTTPClient(const char* host, int port, const char* path) : done(false)
    {
        open();
        connect(host, port);

        char buffer[300];
        ::snprintf(buffer, 299, "GET %s HTTP/1.0\r\n\r\n", path);
        buffer[299] = '\0';

        bufferSend(buffer, strlen(buffer));

        poller.addChannel(this);
        start.stamp();
    }

    virtual void handleBufferRead(simgear::NetBuffer& buffer)
    {
        const char* s = buffer.getData();
        while (*s)
            fputc(*s++, stdout);

        printf("done\n");

        buffer.remove();

        done = true;
    }

    bool isDone() const { return done; }
    bool isDone(long usec) const
    {
        if (start + SGTimeStamp::fromUSec(usec) < SGTimeStamp::now()) {
            return true;
        } else {
            return done;
        }
    }

    void poll(int timeout)
    {
        poller.poll(timeout);
    }
};

FGExternalNet::FGExternalNet(double dt, std::string host, int dop, int dip, int cp)
{
    //     set_delta_t( dt );

    valid = true;

    data_in_port = dip;
    data_out_port = dop;
    cmd_port = cp;
    fdm_host = host;

    /////////////////////////////////////////////////////////
    // Setup client udp connection (sends data to remote fdm)

    if (!data_client.open(false)) {
        SG_LOG(SG_FLIGHT, SG_ALERT, "Error opening client data channel");
        valid = false;
    }

    // fire and forget
    data_client.setBlocking(false);

    if (data_client.connect(fdm_host.c_str(), data_out_port) == -1) {
        printf("error connecting to %s:%d\n", fdm_host.c_str(), data_out_port);
        valid = false;
    }

    /////////////////////////////////////////////////////////
    // Setup server udp connection (for receiving data)

    if (!data_server.open(false)) {
        SG_LOG(SG_FLIGHT, SG_ALERT, "Error opening client server channel");
        valid = false;
    }

    // disable blocking
    data_server.setBlocking(false);

    // allowed to read from a broadcast addr
    // data_server.setBroadcast( true );

    // if we bind to fdm_host = "" then we accept messages from
    // anyone.
    if (data_server.bind("", data_in_port) == -1) {
        printf("error binding to port %d\n", data_in_port);
        valid = false;
    }
}


FGExternalNet::~FGExternalNet()
{
    data_client.close();
    data_server.close();
}


// Initialize the ExternalNet flight model, dt is the time increment
// for each subsequent iteration through the EOM
void FGExternalNet::init()
{
    // cout << "FGExternalNet::init()" << endl;

    // Explicitly call the superclass's
    // init method first.
    common_init();

    double lon = fgGetDouble("/sim/presets/longitude-deg");
    double lat = fgGetDouble("/sim/presets/latitude-deg");
    double alt = fgGetDouble("/sim/presets/altitude-ft");
    double ground = get_Runway_altitude_m();
    double heading = fgGetDouble("/sim/presets/heading-deg");
    double speed = fgGetDouble("/sim/presets/airspeed-kt");

    char cmd[256];

    HTTPClient* http;
    snprintf(cmd, 256, "/longitude-deg?value=%.8f", lon);
    http = new HTTPClient(fdm_host.c_str(), cmd_port, cmd);
    while (!http->isDone(1000000)) http->poll(0);
    delete http;

    snprintf(cmd, 256, "/latitude-deg?value=%.8f", lat);
    http = new HTTPClient(fdm_host.c_str(), cmd_port, cmd);
    while (!http->isDone(1000000)) http->poll(0);
    delete http;

    snprintf(cmd, 256, "/altitude-ft?value=%.8f", alt);
    http = new HTTPClient(fdm_host.c_str(), cmd_port, cmd);
    while (!http->isDone(1000000)) http->poll(0);
    delete http;

    snprintf(cmd, 256, "/ground-m?value=%.8f", ground);
    http = new HTTPClient(fdm_host.c_str(), cmd_port, cmd);
    while (!http->isDone(1000000)) http->poll(0);
    delete http;

    snprintf(cmd, 256, "/speed-kts?value=%.8f", speed);
    http = new HTTPClient(fdm_host.c_str(), cmd_port, cmd);
    while (!http->isDone(1000000)) http->poll(0);
    delete http;

    snprintf(cmd, 256, "/heading-deg?value=%.8f", heading);
    http = new HTTPClient(fdm_host.c_str(), cmd_port, cmd);
    while (!http->isDone(1000000)) http->poll(0);
    delete http;

    SG_LOG(SG_IO, SG_INFO, "before sending reset command.");

    if (fgGetBool("/sim/presets/onground")) {
        snprintf(cmd, 256, "/reset?value=ground");
    } else {
        snprintf(cmd, 256, "/reset?value=air");
    }
    http = new HTTPClient(fdm_host.c_str(), cmd_port, cmd);
    while (!http->isDone(1000000)) http->poll(0);
    delete http;

    SG_LOG(SG_IO, SG_INFO, "Remote FDM init() finished.");
}


// Run an iteration of the EOM.
void FGExternalNet::update(double dt)
{
    int length;
    int result;

    if (is_suspended())
        return;

    // Send control positions to remote fdm
    length = sizeof(ctrls);
    FGProps2Ctrls<FGNetCtrls>( globals->get_props(), &ctrls, true, true);
    if (data_client.send((char*)(&ctrls), length, 0) != length) {
        SG_LOG(SG_IO, SG_DEBUG, "Error writing data.");
    } else {
        SG_LOG(SG_IO, SG_DEBUG, "wrote control data.");
    }

    // Read next set of FDM data (blocking enabled to maintain 'sync')
    length = sizeof(fdm);
    while ((result = data_server.recv((char*)(&fdm), length, 0)) >= 0) {
        SG_LOG(SG_IO, SG_DEBUG, "Success reading data.");
        FGFDM2Props<FGNetFDM>( globals->get_props(), &fdm);
    }
}

// Register the subsystem.
#if 0
SGSubsystemMgr::Registrant<FGExternalNet> registrantFGExternalNet;
#endif
