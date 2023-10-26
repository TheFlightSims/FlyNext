// AirportList.hxx - scrolling list of airports.

/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <simgear/compiler.h>

// ensure we include this before puAux.h, so that 
// #define _PU_H_ 1 has been done, and hence we don't
// include the un-modified system pu.h
#include "FlightGear_pu.h"

#include <plib/puAux.h>

#include "FGPUIDialog.hxx"

class FGAirportList;

class AirportList : public puaList, public GUI_ID {
public:
    AirportList(int x, int y, int width, int height);
    virtual ~AirportList();

    virtual void create_list();
    virtual void destroy_list();
    virtual void setValue(const char *);

private:
    char **_content;
    std::string _filter;
};

