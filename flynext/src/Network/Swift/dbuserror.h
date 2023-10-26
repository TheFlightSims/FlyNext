/*
 * SPDX-FileCopyrightText: (C) 2019-2022 swift Project Community / Contributors (https://swift-project.org/)
 * SPDX-FileCopyrightText: (C) 2019-2022 Lars Toenning <dev@ltoenning.de>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifndef BLACKSIM_FGSWIFTBUS_DBUSERROR_H
#define BLACKSIM_FGSWIFTBUS_DBUSERROR_H

#include <dbus/dbus.h>
#include <string>

namespace FGSwiftBus {

//! DBus error
class CDBusError
{
public:
    //! Error type
    enum ErrorType {
        NoError,
        Other
    };

    //! Default constructur
    CDBusError() = default;

    //! Constructor
    explicit CDBusError(const DBusError* error);

    //! Get error type
    ErrorType getType() const { return m_errorType; }

private:
    ErrorType m_errorType = NoError;
    std::string m_name;
    std::string m_message;
};

} // namespace FGSwiftBus

#endif // guard
