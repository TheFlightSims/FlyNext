/*
 * SPDX-FileCopyrightText: (C) 2019-2022 swift Project Community / Contributors (https://swift-project.org/)
 * SPDX-FileCopyrightText: (C) 2019-2022 Lars Toenning <dev@ltoenning.de>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "plugin.h"
#include "swift_connection.hxx"
#include <Main/fg_props.hxx>
#include <simgear/props/props.hxx>
#include <simgear/structure/commands.hxx>
#include <simgear/structure/event_mgr.hxx>
#include <simgear/structure/subsystem_mgr.hxx>

namespace {
inline std::string fgswiftbusServiceName()
{
    return std::string("org.swift-project.fgswiftbus");
}
} // namespace

bool SwiftConnection::startServer(const SGPropertyNode* arg, SGPropertyNode* root)
{
    SwiftConnection::plug = std::make_unique<FGSwiftBus::CPlugin>();

    serverRunning = true;
    fgSetBool("/sim/swift/serverRunning", true);

    return true;
}

bool SwiftConnection::stopServer(const SGPropertyNode* arg, SGPropertyNode* root)
{
    fgSetBool("/sim/swift/serverRunning", false);
    serverRunning = false;

    SwiftConnection::plug.reset();

    return true;
}

SwiftConnection::SwiftConnection()
{
    init();
}

SwiftConnection::~SwiftConnection()
{
    shutdown();

    if (serverRunning) {
        SwiftConnection::plug.reset();
    }
}

void SwiftConnection::init()
{
    if (!initialized) {
        globals->get_commands()->addCommand("swiftStart", this, &SwiftConnection::startServer);
        globals->get_commands()->addCommand("swiftStop", this, &SwiftConnection::stopServer);

        fgSetBool("/sim/swift/available", true);
        initialized = true;
    }
}

void SwiftConnection::update(double delta_time_sec)
{
    if (serverRunning) {
        SwiftConnection::plug->fastLoop();
    }
}

void SwiftConnection::shutdown()
{
    if (initialized) {
        fgSetBool("/sim/swift/available", false);
        initialized = false;

        globals->get_commands()->removeCommand("swiftStart");
        globals->get_commands()->removeCommand("swiftStop");
    }
}

void SwiftConnection::reinit()
{
    shutdown();
    init();
}

// Register the subsystem.
SGSubsystemMgr::Registrant<SwiftConnection> registrantSwiftConnection(
    SGSubsystemMgr::POST_FDM);
