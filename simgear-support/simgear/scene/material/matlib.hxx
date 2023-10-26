// matlib.hxx -- class to handle material properties
//
// Written by Curtis Olson, started May 1998.
//
// Copyright (C) 1998 - 2000  Curtis L. Olson  - http://www.flightgear.org/~curt
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation; either version 2 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// $Id$


#ifndef _MATLIB_HXX
#define _MATLIB_HXX


#include <simgear/compiler.h>

#include <simgear/math/SGMath.hxx>
#include <simgear/structure/SGReferenced.hxx>
#include <simgear/structure/SGSharedPtr.hxx>
#include <osg/Texture2DArray>
#include <osg/Texture1D>
#include "Atlas.hxx"

#include <memory>
#include <string>		// Standard C++ string library
#include <map>			// STL associative "array"
#include <vector>		// STL "array"

class SGMaterial;
class SGPropertyNode;
class SGPath;

namespace simgear { class Effect; class SGReaderWriterOptions; }
namespace osg { class Geode; }

// Material cache class
class SGMaterialCache : public osg::Referenced
{
public:

    // A texture Atlas with multiple levels of indirection:

    // - A given landclass maps to an index in the materialLookup.
    // - The materialLookup results in a set of texture indexes that
    //   represent the textures referenced by the texture-set in the material
    // - the texture indexes index into the Atlas itself.
 
    // Constructor
    SGMaterialCache();

    // Insertion
    void insert( const std::string& name, SGSharedPtr<SGMaterial> material );
    void insert( int lc, SGSharedPtr<SGMaterial> material );

    // Lookup
    SGMaterial *find( const std::string& material ) const;
    SGMaterial *find( int material ) const;

    void setAtlas(osg::ref_ptr<simgear::Atlas> atlas) { _atlas = atlas; };
    osg::ref_ptr<simgear::Atlas> getAtlas() { return _atlas; };

    // Destructor
    ~SGMaterialCache ( void );

private:
    typedef std::map < std::string, SGSharedPtr<SGMaterial> > material_cache;
    material_cache cache;
    osg::ref_ptr<simgear::Atlas> _atlas;

    const std::string getNameFromLandclass(int lc) const {
        return std::string("WS30_").append(std::to_string(lc));
    }
};

// Material management class
class SGMaterialLib : public SGReferenced
{

public:
    typedef std::map <const std::string, osg::ref_ptr<simgear::Atlas> > atlas_map;


private:
    class MatLibPrivate;
    std::unique_ptr<MatLibPrivate> d;
    
    // associative array of materials
    typedef std::vector< SGSharedPtr<SGMaterial> > material_list;    
    typedef material_list::iterator material_list_iterator;
    
    typedef std::map < std::string,  material_list> material_map;
    typedef material_map::iterator material_map_iterator;
    typedef material_map::const_iterator const_material_map_iterator;

    struct landclass_info {
        std::string _mat;
        bool _water;
        bool _sea;
    };

    typedef std::map < int, landclass_info> landclass_map;
    typedef landclass_map::iterator landclass_map_iterator;
    typedef landclass_map::const_iterator const_landclass_map_iterator;

    material_map matlib;
    landclass_map landclasslib;

    // Get a (cached) texture atlas for this material cache
    osg::ref_ptr<simgear::Atlas> getOrCreateAtlas(SGMaterialLib::landclass_map, SGVec2f center, const simgear::SGReaderWriterOptions* const_options);
    static atlas_map _atlasCache;
    static std::mutex _atlasCacheMutex;

    SGMaterial* internalFind(const std::string& material, const SGVec2f center) const;

public:

    // Constructor
    SGMaterialLib ( void );

    // Load a library of material properties
    bool load( const SGPath &fg_root, const SGPath& mpath,
            SGPropertyNode *prop_root );
    // find a material record by material name
    SGMaterial *find( const std::string& material, SGVec2f center ) const;
    SGMaterial *find( const std::string& material, const SGGeod& center ) const;
    SGMaterial *find( const int lc, SGVec2f center ) const;
    SGMaterial *find( const int lc, const SGGeod& center ) const;

    /**
     * Material lookup involves evaluation of position and SGConditions to
     * determine which possible material (by season, region, etc) is valid.
     * This involves property tree queries, so repeated calls to find() can cause
     * race conditions when called from the osgDB pager thread. (especially
     * during startup)
     *
     * To fix this, and also avoid repeated re-evaluation of the material
     * conditions, we provide factory method to generate a material library
     * cache of the valid materials based on the current state and a given position.
     */

    SGMaterialCache *generateMatCache( SGVec2f center, const simgear::SGReaderWriterOptions* options, bool generatAtlas = false);
    SGMaterialCache *generateMatCache( SGGeod center, const simgear::SGReaderWriterOptions* options, bool generatAtlas = false);

    material_map_iterator begin() { return matlib.begin(); }
    const_material_map_iterator begin() const { return matlib.begin(); }

    material_map_iterator end() { return matlib.end(); }
    const_material_map_iterator end() const { return matlib.end(); }

    static const SGMaterial *findMaterial(const osg::Geode* geode);

    // Destructor
    ~SGMaterialLib ( void );

};

typedef SGSharedPtr<SGMaterialLib> SGMaterialLibPtr;

#endif // _MATLIB_HXX 
