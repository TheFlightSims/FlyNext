/*
 * SPDX-FileName: fg_io.hxx
 * SPDX-FileComment: Higher level I/O management routines
 * SPDX-FileCopyrightText: Copyright (C) 1999  Curtis L. Olson - http://www.flightgear.org/~curt
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string>
#include <vector>

#include <simgear/compiler.h>
#include <simgear/props/props.hxx>
#include <simgear/structure/subsystem_mgr.hxx>


class FGProtocol;

class FGIO : public SGSubsystem
{
public:
    FGIO() = default;
    ~FGIO() = default;

    // Subsystem API.
    void bind() override;
    void init() override;
    void reinit() override;
    void shutdown() override;
    void unbind() override;
    void update(double dt) override;

    // Subsystem identification.
    static const char* staticSubsystemClassId() { return "io"; }

    /**
     * helper to determine early in startup, if MP will be used.
     * This information is needed in the position-init code, to adjust the
     * start position off active runways.
     */
    static bool isMultiplayerRequested();

private:
    FGProtocol* add_channel(const std::string& config, bool& o_ok);

    FGProtocol* parse_port_config(const std::string& cfgstr, bool& o_ok);
    FGProtocol* parse_port_config(const string_list& tokens, bool& o_ok);

    void addToPropertyTree(const std::string name, const std::string config);
    void removeFromPropertyTree(const std::string name);
    std::string generateName(const std::string protocol);

private:
    // define the global I/O channel list
    //io_container global_io_list;

    typedef std::vector<FGProtocol*> ProtocolVec;
    ProtocolVec io_channels;

    SGPropertyNode_ptr _realDeltaTime;

    bool commandAddChannel(const SGPropertyNode* arg, SGPropertyNode* root);
    bool commandRemoveChannel(const SGPropertyNode* arg, SGPropertyNode* root);
};
