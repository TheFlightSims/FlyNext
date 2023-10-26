/*
 * Traffic module for swift<->FG connection
 * SPDX-FileCopyrightText: (C) 2019-2022 swift Project Community / Contributors (https://swift-project.org/)
 * SPDX-FileCopyrightText: (C) 2019-2022 Lars Toenning <dev@ltoenning.de>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef BLACKSIM_FGSWIFTBUS_TRAFFIC_H
#define BLACKSIM_FGSWIFTBUS_TRAFFIC_H

//! \file

#include "SwiftAircraftManager.h"
#include "dbusobject.h"

#include <functional>
#include <utility>

//! \cond PRIVATE
#define FGSWIFTBUS_TRAFFIC_INTERFACENAME "org.swift_project.fgswiftbus.traffic"
#define FGSWIFTBUS_TRAFFIC_OBJECTPATH "/fgswiftbus/traffic"
//! \endcond

namespace FGSwiftBus {
/*!
     * FGSwiftBus service object for traffic aircraft which is accessible through DBus
     */
class CTraffic : public CDBusObject
{
public:
    //! Constructor
    CTraffic();

    //! Destructor
    ~CTraffic() override;

    //! DBus interface name
    static const std::string& InterfaceName();

    //! DBus object path
    static const std::string& ObjectPath();

    //! Initialize the multiplayer planes rendering and return true if successful
    bool initialize();

    //! Perform generic processing
    int process();

    void emitSimFrame();

protected:
    virtual void dbusDisconnectedHandler() override;

    DBusHandlerResult dbusMessageHandler(const CDBusMessage& message) override;

private:
    void emitPlaneAdded(const std::string& callsign);
    void cleanup();

    struct Plane {
        void* id = nullptr;
        std::string callsign;
        char label[32]{};
    };

    bool m_emitSimFrame = true;
    std::unique_ptr<FGSwiftAircraftManager> acm;
};
} // namespace FGSwiftBus

#endif // guard
