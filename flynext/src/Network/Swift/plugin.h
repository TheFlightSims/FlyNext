/*
 * SPDX-FileCopyrightText: (C) 2019-2022 swift Project Community / Contributors (https://swift-project.org/)
 * SPDX-FileCopyrightText: (C) 2019-2022 Lars Toenning <dev@ltoenning.de>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef BLACKSIM_FGSWIFTBUS_PLUGIN_H
#define BLACKSIM_FGSWIFTBUS_PLUGIN_H

//! \file

/*!
 * \namespace FGSwiftBus
 * Plugin loaded by Flightgear which publishes a DBus service
 */

#ifndef NOMINMAX
#define NOMINMAX
#endif

#include "config.h"
#include "dbusconnection.h"
#include "dbusdispatcher.h"
#include "dbusserver.h"
#include <memory>
#include <thread>

namespace FGSwiftBus {
class CService;
class CTraffic;

/*!
     * Main plugin class
     */
class CPlugin
{
public:
    //! Constructor
    CPlugin();
    void startServer();
    //! Destructor
    ~CPlugin();
    void fastLoop();

private:
    CDBusDispatcher m_dbusDispatcher;
    std::unique_ptr<CDBusServer> m_dbusP2PServer;
    std::shared_ptr<CDBusConnection> m_dbusConnection;
    std::unique_ptr<CService> m_service;
    std::unique_ptr<CTraffic> m_traffic;

    std::thread m_dbusThread;
    bool m_shouldStop = false;
};
} // namespace FGSwiftBus

#endif // BLACKSIM_FGSWIFTBUS_PLUGIN_H
