// Copyright (C) 2023  Stuart Buchanan - stuart13@gmail.com
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Library General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Library General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#ifndef BVHTerrainTile_hxx
#define BVHTerrainTile_hxx

#include <simgear/structure/SGSharedPtr.hxx>
#include "BVHGroup.hxx"
#include "BVHLineSegmentVisitor.hxx"
#include "BVHMaterial.hxx"
#include "BVHVisitor.hxx"
#include <osgTerrain/TerrainTile>

namespace simgear {

class BVHTerrainTile : public BVHGroup {
public:
    BVHTerrainTile(osgTerrain::TerrainTile *tile);
    virtual ~BVHTerrainTile();
    virtual void accept(BVHVisitor& visitor);
    virtual SGSphered computeBoundingSphere() const;
    BVHMaterial* getMaterial(BVHLineSegmentVisitor* lsv);
private:
    osg::ref_ptr<osgTerrain::TerrainTile> _tile;
};

}

#endif
