/*
 * SPDX-FileName: initialstate.cxx
 * SPDX-FileComment: setup initial state of the aircraft
 * SPDX-FileCopyrightText: Copyright (C) 2016 James Turner <zakalawe@mac.com>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#include "config.h"

#include <algorithm>

#include <simgear/debug/logstream.hxx>
#include <simgear/props/props_io.hxx>

#include <GUI/MessageBox.hxx>
#include <Main/fg_props.hxx>

#include "initialstate.hxx"

using namespace simgear;


namespace {

class NodeValue
{
public:
    explicit NodeValue(const std::string& s) : v(s) {}
    bool operator()(const SGPropertyNode_ptr n) const
    {
        return (v == n->getStringValue());
    }

private:
    std::string v;
};

SGPropertyNode_ptr nodeForState(const std::string& nm)
{
    SGPropertyNode_ptr sim = fgGetNode("/sim");
    const PropertyList& states = sim->getChildren("state");
    PropertyList::const_iterator it;
    for (it = states.begin(); it != states.end(); ++it) {
        const PropertyList& names = (*it)->getChildren("name");
        if (std::find_if(names.begin(), names.end(), NodeValue(nm)) != names.end()) {
            return *it;
        }
    }

    return SGPropertyNode_ptr();
}

} // namespace

namespace flightgear {

bool isInitialStateName(const std::string& name)
{
    SGPropertyNode_ptr n = nodeForState(name);
    return n.valid();
}

void applyInitialState()
{
    std::string nm = fgGetString("/sim/aircraft-state");
    if (nm.empty()) {
        return;
    }

    SGPropertyNode_ptr stateNode = nodeForState(nm);
    if (!stateNode) {
        SG_LOG(SG_AIRCRAFT, SG_WARN, "missing state node for:" << nm);
        std::string aircraft = fgGetString("/sim/aircraft");
        modalMessageBox("Unknown aircraft state",
                        "The selected aircraft (" + aircraft + ") does not have a state '" + nm + "'");

        return;
    }

    SG_LOG(SG_AIRCRAFT, SG_INFO, "Applying aircraft state:" << nm);

    // copy all overlay properties to the tree
    copyProperties(stateNode->getChild("overlay"), globals->get_props());
}

} // namespace flightgear
