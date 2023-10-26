/*
 * SPDX-FileName: AIManager.hxx
 * SPDX-FileComment: a global management type for AI objects, based on David Luff's AIMgr
 * SPDX-FileCopyrightText: Copyright (C) 2002  David C Luff - david.luff@nottingham.ac.uk
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <list>
#include <map>

#include <simgear/math/SGVec3.hxx>
#include <simgear/misc/sg_path.hxx>
#include <simgear/props/props.hxx>
#include <simgear/structure/SGSharedPtr.hxx>
#include <simgear/structure/subsystem_mgr.hxx>

class FGAIBase;
class FGAIThermal;
class FGAIAircraft;

typedef SGSharedPtr<FGAIBase> FGAIBasePtr;

class FGAIManager : public SGSubsystem
{
public:
    FGAIManager();
    virtual ~FGAIManager();

    // Subsystem API.
    void bind() override;
    void init() override;
    void postinit() override;
    void reinit() override;
    void shutdown() override;
    void unbind() override;
    void update(double dt) override;

    // Subsystem identification.
    static const char* staticSubsystemClassId() { return "ai-model"; }

    void updateLOD(SGPropertyNode* node);
    void attach(const SGSharedPtr<FGAIBase>& model);

    const FGAIBase* calcCollision(double alt, double lat, double lon, double fuse_range);

    inline double get_user_heading() const { return user_heading; }
    inline double get_user_pitch() const { return user_pitch; }
    inline double get_user_speed() const { return user_speed; }
    inline double get_wind_from_east() const { return wind_from_east; }
    inline double get_wind_from_north() const { return wind_from_north; }
    inline double get_user_roll() const { return user_roll; }
    inline double get_user_agl() const { return user_altitude_agl; }

    bool loadScenario(const std::string& id);

    /**
     * Static helper to register scenarios. This has to happen very early because
     * we need carrier scenarios to start the position-init process for a
     * carrier start.
     */
    static void registerScenarios(SGPropertyNode_ptr root = {});
    static SGPropertyNode_ptr registerScenarioFile(SGPropertyNode_ptr root, const SGPath& p);
    static SGPropertyNode_ptr loadScenarioFile(const std::string& id, SGPath& outPath);

    FGAIBasePtr addObject(const SGPropertyNode* definition);
    bool isVisible(const SGGeod& pos) const;

    /**
     * @brief given a reference to an /ai/models/<foo>[n] node, return the
     * corresponding AIObject implementation, or NULL.
     */
    FGAIBasePtr getObjectFromProperty(const SGPropertyNode* aProp) const;

    typedef std::vector<FGAIBasePtr> ai_list_type;
    const ai_list_type& get_ai_list() const
    {
        return ai_list;
    }

    double calcRangeFt(const SGVec3d& aCartPos, const FGAIBase* aObject) const;

    /**
     * @brief Retrieve the representation of the user's aircraft in the AI manager
     * the position and velocity of this object are slaved to the user's aircraft,
     * so that AI systems such as parking and ATC can see the user and process /
     * avoid correctly.
     */
    FGAIAircraft* getUserAircraft() const;

    bool isRadarEnabled() const
    {
        return _radarEnabled;
    }

    bool enableRadarDebug() const
    {
        return _radarDebugMode;
    }

    double radarRangeM() const
    {
        return _radarRangeM;
    }

private:
    // FGSubmodelMgr is a friend for access to the AI_list
    friend class FGSubmodelMgr;

    // A list of pointers to AI objects
    typedef ai_list_type::iterator ai_list_iterator;
    typedef ai_list_type::const_iterator ai_list_const_iterator;

    int getNumAiObjects() const;

    void removeDeadItem(FGAIBase* base);

    // Returns true on success, e.g. returns false if scenario is already loaded.
    bool loadScenarioCommand(const SGPropertyNode* args, SGPropertyNode* root);

    bool unloadScenarioCommand(const SGPropertyNode* args, SGPropertyNode* root);
    bool addObjectCommand(const SGPropertyNode* arg, const SGPropertyNode* root);
    bool removeObjectCommand(const SGPropertyNode* arg, const SGPropertyNode* root);

    bool removeObject(const SGPropertyNode* args);
    bool unloadScenario(const std::string& filename);
    void unloadAllScenarios();

    SGPropertyNode_ptr root;
    SGPropertyNode_ptr enabled;
    SGPropertyNode_ptr thermal_lift_node;
    SGPropertyNode_ptr user_altitude_agl_node;
    SGPropertyNode_ptr user_speed_node;
    SGPropertyNode_ptr wind_from_east_node;
    SGPropertyNode_ptr wind_from_north_node;
    SGPropertyNode_ptr _environmentVisiblity;
    SGPropertyNode_ptr _groundSpeedKts_node;

    ai_list_type ai_list;

    double user_altitude_agl = 0.0;
    double user_heading = 0.0;
    double user_pitch = 0.0;
    double user_roll = 0.0;
    double user_speed = 0.0;
    double wind_from_east = 0.0;
    double wind_from_north = 0.0;

    void fetchUserState(double dt);

    // used by thermals
    double range_nearest = 0.0;
    double strength = 0.0;
    void processThermal(double dt, FGAIThermal* thermal);

    SGPropertyChangeCallback<FGAIManager> cb_ai_bare;
    SGPropertyChangeCallback<FGAIManager> cb_ai_detailed;
    SGPropertyChangeCallback<FGAIManager> cb_interior;

    class Scenario;
    typedef std::map<std::string, Scenario*> ScenarioDict;
    ScenarioDict _scenarios;

    SGSharedPtr<FGAIAircraft> _userAircraft;

    SGPropertyNode_ptr _simRadarControl,
        _radarRangeNode, _radarDebugNode;
    bool _radarEnabled = true,
         _radarDebugMode = false;
    double _radarRangeM = 0.0;
};
