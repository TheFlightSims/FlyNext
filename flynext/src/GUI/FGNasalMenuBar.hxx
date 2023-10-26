/*
 * SPDX-FileName: NasalMenuBar.hxx
 * SPDX-FileComment: XML-configured menu bar
 * SPDX-License-Identifier: GPL-2.0-or-later
 * SPDX-FileCopyrightText: Copyright (C) 2023 James Turner
 */

#pragma once

#include <GUI/menubar.hxx>

// std
#include <memory>
#include <string>
#include <vector>

// SimGear
#include <simgear/nasal/cppbind/NasalHash.hxx>
#include <simgear/props/propsfwd.hxx>


/**
 * XML-configured menu bar.
 *
 * This class creates a menu bar from a tree of XML properties.  These
 * properties are not part of the main FlightGear property tree, but
 * are read from a separate file ($FG_ROOT/gui/menubar.xml).
 *
 */
class FGNasalMenuBar : public FGMenuBar
{
public:
    /**
     * Constructor.
     */
    FGNasalMenuBar();
    virtual ~FGNasalMenuBar() = default;


    /**
     * Initialize the menu bar from $FG_ROOT/gui/menubar.xml
     */
    void init() override;

    void postinit() override;

    /**
     * Make the menu bar visible.
     */
    void show() override;


    /**
     * Make the menu bar invisible.
     */
    void hide() override;


    /**
     * Test whether the menu bar is visible.
     */
    bool isVisible() const override;

    void setHideIfOverlapsWindow(bool hide) override;

    bool getHideIfOverlapsWindow() const override;


    static void setupGhosts(nasal::Hash& compatModule);


private:
    void recomputeVisibility();

    void configure(SGPropertyNode_ptr config);


    class NasalMenuBarPrivate;
    std::shared_ptr<NasalMenuBarPrivate> _d;
};
