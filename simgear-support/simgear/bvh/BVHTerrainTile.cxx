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

#ifdef HAVE_CONFIG_H
#  include <simgear_config.h>
#endif

#include "BVHTerrainTile.hxx"
#include "BVHLineSegmentVisitor.hxx"
#include "BVHSubTreeCollector.hxx"
#include "simgear/scene/tgdb/VPBTechnique.hxx"

#include <algorithm>

namespace simgear {

BVHTerrainTile::BVHTerrainTile(osgTerrain::TerrainTile *tile)
{
    _tile = tile;
}

BVHTerrainTile::~BVHTerrainTile()
{
    _tile = 0;
}

BVHMaterial* BVHTerrainTile::getMaterial(simgear::BVHLineSegmentVisitor* lsv) {
    BVHMaterial* material;
    if (! lsv->empty()) {
        // LSV contains the uv coordinates of the intersection u*(v1-v0) + v*(v2-v0) and the origin indices on the drawable they refer to.
        // However it does not have any information on the actual material as this is part of the TerrainTile texture.
        simgear::VPBTechnique* technique = dynamic_cast<simgear::VPBTechnique*>(_tile->getTerrainTechnique());
        if (technique) {
            material = technique->getMaterial(lsv);
        } else {
            SG_LOG(SG_TERRAIN, SG_ALERT, "BVHTerrainTile::getMaterial unable to get technique");
        }
    } else {
        SG_LOG(SG_TERRAIN, SG_ALERT, "BVHTerrainTile::getMaterial but no LSV hit");
    }

    return material;
}

void BVHTerrainTile::accept(BVHVisitor& visitor)
{
    visitor.apply(*this);
}

SGSphered BVHTerrainTile::computeBoundingSphere() const {
    simgear::VPBTechnique* technique = dynamic_cast<simgear::VPBTechnique*>(_tile->getTerrainTechnique());
    return technique->computeBoundingSphere();
}


}
