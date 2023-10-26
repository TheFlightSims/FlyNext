/*
 * SPDX-FileCopyrightText: (C) 2019-2022 swift Project Community / Contributors (https://swift-project.org/)
 * SPDX-FileCopyrightText: (C) 2019-2022 Lars Toenning <dev@ltoenning.de>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */
#pragma once

#include <memory>
#include <thread>

#include <Main/fg_props.hxx>
#include <simgear/compiler.h>
#include <simgear/io/raw_socket.hxx>
#include <simgear/props/props.hxx>
#include <simgear/structure/subsystem_mgr.hxx>

#include "dbusconnection.h"
#include "dbusdispatcher.h"
#include "dbusserver.h"
#include "plugin.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif

class SwiftConnection : public SGSubsystem
{
public:
    SwiftConnection();
    ~SwiftConnection();

    // Subsystem API.
    void init() override;
    void reinit() override;
    void shutdown() override;
    void update(double delta_time_sec) override;

    // Subsystem identification.
    static const char* staticSubsystemClassId() { return "swift"; }

    bool startServer(const SGPropertyNode* arg, SGPropertyNode* root);
    bool stopServer(const SGPropertyNode* arg, SGPropertyNode* root);

    std::unique_ptr<FGSwiftBus::CPlugin> plug{};

private:
    bool serverRunning = false;
    bool initialized = false;
};
