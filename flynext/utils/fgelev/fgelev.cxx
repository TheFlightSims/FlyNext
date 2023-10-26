/*
 * SPDX-FileName: fgelev.cxx
 * SPDX-FileComment: compute scenery elevation
 * SPDX-FileCopyrightText: Copyright (C) 2009 - 2012  Mathias Froehlich
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include <iostream>
#include <cstdlib>
#include <iomanip>

#include <osg/ArgumentParser>
#include <osg/Image>

#include <simgear/props/props.hxx>
#include <simgear/props/props_io.hxx>
#include <simgear/misc/sg_path.hxx>
#include <simgear/misc/ResourceManager.hxx>
#include <simgear/bvh/BVHNode.hxx>
#include <simgear/bvh/BVHLineSegmentVisitor.hxx>
#include <simgear/bvh/BVHPager.hxx>
#include <simgear/bvh/BVHPageNode.hxx>
#include <simgear/bvh/BVHMaterial.hxx>
#include <simgear/scene/material/matlib.hxx>
#include <simgear/scene/model/BVHPageNodeOSG.hxx>
#include <simgear/scene/model/ModelRegistry.hxx>
#include <simgear/scene/util/SGReaderWriterOptions.hxx>
#include <simgear/scene/util/OptionsReadFileCallback.hxx>
#include <simgear/scene/util/SGSceneFeatures.hxx>
#include <simgear/scene/tgdb/userdata.hxx>

namespace sg = simgear;

class Visitor : public sg::BVHLineSegmentVisitor {
public:
    Visitor(const SGLineSegmentd& lineSegment, sg::BVHPager& pager) :
        BVHLineSegmentVisitor(lineSegment, 0),
        _pager(pager)
    { }
    virtual ~Visitor()
    { }
    virtual void apply(sg::BVHPageNode& node)
    {
        // we have a non threaded pager so load just right here.
        _pager.use(node);
        BVHLineSegmentVisitor::apply(node);
    }
private:
    sg::BVHPager& _pager;
};

// Short circuit reading image files.
class ReadFileCallback : public sg::OptionsReadFileCallback {
public:
    virtual ~ReadFileCallback()
    { }

    virtual osgDB::ReaderWriter::ReadResult readImage(const std::string& name, const osgDB::Options*)
    { return new osg::Image; }
};

static bool
intersect(sg::BVHNode& node, sg::BVHPager& pager,
          const SGVec3d& start, SGVec3d& end, double offset, const simgear::BVHMaterial** material)
{
    SGVec3d perp = offset*perpendicular(start - end);
    Visitor visitor(SGLineSegmentd(start + perp, end + perp), pager);
    node.accept(visitor);
    if (visitor.empty())
        return false;
    end = visitor.getLineSegment().getEnd();
    * material = visitor.getMaterial();
    return true;
}

int
main(int argc, char** argv)
{
    /// Read arguments and environment variables.

    // use an ArgumentParser object to manage the program arguments.
    osg::ArgumentParser arguments(&argc, argv);

    if (arguments.read("--help")) {
        std::cout << "Usage: fgelev [Options...]\n\nQuery the elevation of lon/lat points in the scenery." << std::endl;;
        std::cout << "Input is read from STDIN line by line in the format <id> <lon> <lat>.  Output is to STDOUT in the format <id>: <elevation-m> [solid|-]" << std::endl << std::endl;
        std::cout << "Optional arguments:" << std::endl;
        std::cout << "\t[--expire N]\t\tExpire items in the cache after N requests (default 10). Use to control memory occupancy." << std::endl;
        std::cout << "\t[--print-solidness]\tOutput whether the location is on solid ground (\"solid\") or not (\"-\")." << std::endl;
        std::cout << "\t[--fg-root <path>]\tSet the FG data directory.  Used to retrieve terrain material information. Default to $FG_ROOT." << std::endl;
        std::cout << "\t[--fg-scenery <path>]\tSet the scenery directory.  Defaults to $FG_SCENERY, or $FG_ROOT/Scenery if $FG_SCENERY not set." << std::endl;
        std::cout << "\t[--use-vpb]\t\tUse VirtualPlanetBuilder (aka WS3.0)." << std::endl;
        std::cout << "\t[--tile-file <file>]\t\tSet the VPB (WS3.0) tile to read." << std::endl;
        return EXIT_FAILURE;
    }

    unsigned expire;
    if (arguments.read("--expire", expire)) {
    } else expire = 10;

    bool printSolidness = arguments.read("--print-solidness");

    std::string fg_root;
    if (arguments.read("--fg-root", fg_root)) {
    } else if (const char *fg_root_env = std::getenv("FG_ROOT")) {
        fg_root = fg_root_env;
    } else {
        fg_root = PKGLIBDIR;
    }

    SGPath fg_scenery;
    std::string s;
    if (arguments.read("--fg-scenery", s)) {
        fg_scenery = SGPath::fromLocal8Bit(s.c_str());
    } else if (std::getenv("FG_SCENERY")) {
        fg_scenery = SGPath::fromEnv("FG_SCENERY");
    } else {
        SGPath path(fg_root);
        path.append("Scenery");
        fg_scenery = path;
    }

    SGSharedPtr<SGPropertyNode> props = new SGPropertyNode;
    try {
        SGPath preferencesFile = fg_root;
        preferencesFile.append("defaults.xml");
        readProperties(preferencesFile, props);
    } catch (...) {
        // In case of an error, at least make summer :)
        props->getNode("sim/startup/season", true)->setStringValue("summer");

        SG_LOG(SG_GENERAL, SG_ALERT, "Problems loading FlightGear preferences.\n"
               << "Probably FG_ROOT is not properly set.");
    }

    bool use_vpb = arguments.read("--use-vpb");
    props->setBoolValue("/scenery/use-vpb", use_vpb);
    SGSceneFeatures::instance()->setVPBActive(use_vpb);

    /// now set up the simgears required model stuff

    simgear::ResourceManager::instance()->addBasePath(fg_root, simgear::ResourceManager::PRIORITY_DEFAULT);
    // Just reference simgears reader writer stuff so that the globals get
    // pulled in by the linker ...
    simgear::ModelRegistry::instance();

    sgUserDataInit(props.get());
    SGMaterialLibPtr ml = new SGMaterialLib;
    SGPath mpath(fg_root);
    mpath.append("Materials/default/materials.xml");
    try {
        ml->load(fg_root, mpath.local8BitStr(), props);
    } catch (...) {
        SG_LOG(SG_GENERAL, SG_ALERT, "Problems loading FlightGear materials.\n"
               << "Probably FG_ROOT is not properly set.");
    }
    simgear::SGModelLib::init(fg_root, props);

    // Set up the reader/writer options
    osg::ref_ptr<simgear::SGReaderWriterOptions> options;
    if (osgDB::Options* ropt = osgDB::Registry::instance()->getOptions())
        options = new simgear::SGReaderWriterOptions(*ropt);
    else
        options = new simgear::SGReaderWriterOptions;
    osgDB::convertStringPathIntoFilePathList(fg_scenery.local8BitStr(),
                                             options->getDatabasePathList());
    options->setMaterialLib(ml);
    options->setPropertyNode(props);
    options->setReadFileCallback(new ReadFileCallback);
    options->setPluginStringData("SimGear::FG_ROOT", fg_root);
    // we do not need the builtin boundingvolumes
    options->setPluginStringData("SimGear::BOUNDINGVOLUMES", "OFF");
    // And we only want terrain, no objects on top.
    options->setPluginStringData("SimGear::FG_ONLY_TERRAIN", "ON");

    string_list scenerySuffixes = {"Terrain"}; // Just Terrain
    options->setSceneryPathSuffixes(scenerySuffixes);

    props->getNode("sim/rendering/random-objects", true)->setBoolValue(false);
    props->getNode("sim/rendering/random-vegetation", true)->setBoolValue(false);

    std::string bvhFile = "w180s90-360x180.spt";
    if (arguments.read("--tile-file", s))
        bvhFile = s;

    // Here, all arguments are processed
    arguments.reportRemainingOptionsAsUnrecognized();
    arguments.writeErrorMessages(std::cerr);

    // Get the whole world bvh tree
    SGSharedPtr<sg::BVHNode> node;
    node = sg::BVHPageNodeOSG::load(bvhFile, options, use_vpb);

    // if no model has been successfully loaded report failure.
    if (!node.valid()) {
        SG_LOG(SG_GENERAL, SG_ALERT, arguments.getApplicationName()
               << ": No data loaded");
        return EXIT_FAILURE;
    }

    // We assume that the above is a paged database.
    sg::BVHPager pager;

    while (std::cin.good()) {
        // Increment the paging relevant number
        pager.setUseStamp(1 + pager.getUseStamp());
        // and expire everything not accessed for the past 30 requests
        pager.update(expire);

        std::string id;
        std::cin >> id;
        double lon, lat;
        std::cin >> lon >> lat;
        if (std::cin.fail())
            return EXIT_FAILURE;
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');

        SGVec3d start = SGVec3d::fromGeod(SGGeod::fromDegM(lon, lat, 10000));
        SGVec3d end = SGVec3d::fromGeod(SGGeod::fromDegM(lon, lat, -1000));

        const simgear::BVHMaterial* material = NULL;
        // Try to find an intersection
        bool found = intersect(*node, pager, start, end, 0, &material);
        double scale = 1e-5;
        while (!found && scale <= 1) {
            found = intersect(*node, pager, start, end, scale, &material);
            scale *= 2;
        }
        if (1e-5 < scale)
            std::cerr << "Found hole of minimum diameter "
                      << scale << "m at lon = " << lon
                      << "deg lat = " << lat << "deg" << std::endl;

        std::cout << id << ": ";
        std::string solid = material && material->get_solid() ? "solid" : "-";
        if (!found) {
            std::cout << "-1000" << std::endl;
        } else {
            SGGeod geod = SGGeod::fromCart(end);
            std::cout << std::fixed << std::setprecision(3) << geod.getElevationM();
            if( printSolidness )
                std::cout <<  " " << (material && material->get_solid() ? "solid" : "-");
            std::cout << std::endl;
        }
    }

    return EXIT_SUCCESS;
}
