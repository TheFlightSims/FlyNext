/*
 * SPDX-FileName: propsProtocol.hxx
 * SPDX-FileComment: Property server class. Used for telnet server.
 * SPDX-FileCopyrightText: Copyright (C) 2000  Curtis L. Olson - http://www.flightgear.org/~curt
 * SPDX-FileContributor: Modified by Bernie Bright, May 2002
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <simgear/compiler.h>
#include <string>
#include <vector>

#include <simgear/io/sg_netChannel.hxx>

#include "protocol.hxx"

/**
 * Property server class.
 * This class provides a telnet-like server for remote access to
 * FlightGear properties.
 */
class FGProps : public FGProtocol,
                public simgear::NetChannel,
                public SGPropertyChangeListener // for subscriptions
{
private:
    class PropsChannel;

    /**
     * Server port to listen on.
     */
    int port = 5501;
    simgear::NetChannelPoller poller;

    std::vector<PropsChannel*> _activeChannels;

public:
    /**
     * Create a new TCP server.
     * 
     * @param tokens Tokenized configuration parameters
     */
    FGProps(const std::vector<std::string>& tokens);

    /**
     * Destructor.
     */
    ~FGProps();

    /**
     * Start the telnet server.
     */
    bool open() override;

    /**
     * Process network activity.
     */
    bool process() override;

    /**
     * 
     */
    bool close() override;

    /**
     * Accept a new client connection.
     */
    void handleAccept() override;

    void removeChannel(PropsChannel* channel);
};
