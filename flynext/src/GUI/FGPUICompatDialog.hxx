// SPDX-FileName: FGPUICompatDialog.hxx
// SPDX-FileComment: XML dialog class without using PUI
// SPDX-FileCopyrightText: Copyright (C) 2022 James Turner
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <functional>

#include "dialog.hxx"


#include <simgear/misc/sg_path.hxx>
#include <simgear/nasal/cppbind/NasalHash.hxx>
#include <simgear/nasal/cppbind/NasalObject.hxx>
#include <simgear/props/condition.hxx>
#include <simgear/props/props.hxx>


#include <vector>


class NewGUI;
class FGColor;

class PUICompatObject;
using PUICompatObjectRef = SGSharedPtr<PUICompatObject>;

/**
 * An XML-configured dialog box.
 *
 * The GUI manager stores only the property tree for the dialog
 * boxes.  This class creates a PUI dialog box on demand from
 * the properties in that tree.  The manager recreates the dialog
 * every time it needs to show it.
 */
class FGPUICompatDialog : public FGDialog
{
public:
    static void setupGhost(nasal::Hash& compatModule);

    /**
     * Construct a new GUI widget configured by a property tree.
     *
     * The configuration properties are not part of the main
     * FlightGear property tree; the GUI manager reads them
     * from individual configuration files.
     *
     * @param props A property tree describing the dialog.
     */
    FGPUICompatDialog(SGPropertyNode* props);


    /**
     * Destructor.
     */
    virtual ~FGPUICompatDialog();


    /**
     * Update the values of all GUI objects with a specific name,
     * or all if an empty name is given (default).
     *
     * This method copies values from the FlightGear property tree to
     * the GUI object(s).
     *
     * @param objectName The name of the GUI object(s) to update.
     *        Use the empty name for all objects.
     */
    virtual void updateValues(const std::string& objectName = "");


    /**
     * Apply the values of all GUI objects with a specific name,
     * or all if an empty name is given (default).
     *
     * This method copies values from the GUI object(s) to the
     * FlightGear property tree.
     *
     * @param objectName The name of the GUI object(s) to update.
     *        Use the empty name for all objects.
     */
    virtual void applyValues(const std::string& objectName = "");

    bool init();

    /**
     * Update state.  Called on active dialogs before rendering.
     */
    void update() override;

    /**
     * Recompute the dialog's layout
     */
    void relayout();


    void setNeedsLayout()
    {
        _needsRelayout = true;
    }

    virtual const char* getName();
    virtual void bringToFront();

    std::string nameString() const;
    std::string nasalModule() const;

    SGRectd geometry() const;

    double getX() const;
    double getY() const;
    double width() const;
    double height() const;

    void close() override;

private:
    friend naRef f_makeDialogPeer(const nasal::CallContext& ctx);
    friend naRef f_dialogRootObject(FGPUICompatDialog& dialog, naContext c);

    // Show the dialog.
    void display(SGPropertyNode* props);

    void requestClose();

#if 0
    // Build the dialog or a subobject of it.
    puObject* makeObject(SGPropertyNode* props,
                         int parentWidth, int parentHeight);

    // Common configuration for all GUI objects.
    void setupObject(puObject* object, SGPropertyNode* props);

    // Common configuration for all GUI group objects.
    void setupGroup(puGroup* group, SGPropertyNode* props,
                    int width, int height, bool makeFrame = false);

    // Set object colors: the "which" argument defines which color qualities
    // (PUCOL_LABEL, etc.) should pick up the <color> property.
    void setColor(puObject* object, SGPropertyNode* props, int which = 0);
#endif
    // return key code number for keystring
    int getKeyCode(const char* keystring);

    /**
     * Apply layout sizes to a tree of puObjects
     */
    //void applySize(puObject* object);

    // // The top-level PUI object.
    // puObject* _object;


    // The source xml tree, so that we can pass data back, such as the
    // last position.
    SGPropertyNode_ptr _props;

    bool _needsRelayout;

    // Nasal module.
    std::string _module;
    SGPropertyNode_ptr _nasal_close;

    class DialogPeer;

    SGSharedPtr<DialogPeer> _peer;

    std::string _name;
    PUICompatObjectRef _root;

    // // PUI provides no way for userdata to be deleted automatically
    // // with a GUI object, so we have to keep track of all the special
    // // data we allocated and then free it manually when the dialog
    // // closes.
    // std::vector<void*> _info;
    // struct PropertyObject {
    //     PropertyObject(const char* name,
    //                    puObject* object,
    //                    SGPropertyNode_ptr node);
    //     std::string name;
    //     puObject* object;
    //     SGPropertyNode_ptr node;
    // };

    // std::vector<PropertyObject*> _propertyObjects;
    // std::vector<PropertyObject*> _liveObjects;

    // class ConditionalObject : public SGConditional
    // {
    // public:
    //     ConditionalObject(const std::string& aName, puObject* aPu) : _name(aName),
    //                                                                  _pu(aPu)
    //     {
    //         ;
    //     }

    //     void update(FGPUIDialog* aDlg);

    // private:
    //     const std::string _name;
    //     puObject* _pu;
    // };

    // typedef SGSharedPtr<ConditionalObject> ConditionalObjectRef;
    // std::vector<ConditionalObjectRef> _conditionalObjects;

    // std::vector<ActiveWidget*> _activeWidgets;
};
