// VPBTechnique.cxx -- VirtualPlanetBuilder Effects technique
//
// Copyright (C) 2020 Stuart Buchanan
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

#include <cmath>
#include <tuple>

#include <osgTerrain/TerrainTile>
#include <osgTerrain/Terrain>

#include <osgUtil/LineSegmentIntersector>
#include <osgUtil/IntersectionVisitor>
#include <osgUtil/MeshOptimizers>
#include <osgUtil/Tessellator>

#include <osgDB/FileUtils>
#include <osgDB/ReadFile>

#include <osg/io_utils>
#include <osg/Texture2D>
#include <osg/Texture2DArray>
#include <osg/Texture1D>
#include <osg/Program>
#include <osg/Math>
#include <osg/Timer>

#include <simgear/bvh/BVHLineSegmentVisitor.hxx>
#include <simgear/bvh/BVHSubTreeCollector.hxx>
#include <simgear/debug/logstream.hxx>
#include <simgear/math/sg_random.hxx>
#include <simgear/math/SGMath.hxx>
#include <simgear/scene/material/Effect.hxx>
#include <simgear/scene/material/EffectGeode.hxx>
#include <simgear/scene/model/model.hxx>
#include <simgear/scene/tgdb/VPBElevationSlice.hxx>
#include <simgear/scene/tgdb/VPBTileBounds.hxx>
#include <simgear/scene/util/SGNodeMasks.hxx>
#include <simgear/scene/util/SGReaderWriterOptions.hxx>
#include <simgear/scene/util/SGSceneFeatures.hxx>

#include "VPBTechnique.hxx"
#include "VPBMaterialHandler.hxx"

using namespace osgTerrain;
using namespace simgear;

VPBTechnique::VPBTechnique()
{
    setFilterBias(0);
    setFilterWidth(0.1);
    setFilterMatrixAs(GAUSSIAN);
    _randomObjectsConstraintGroup = new osg::Group();

    const std::lock_guard<std::mutex> lock(VPBTechnique::_defaultCoastlineTexture_mutex); 
    if (VPBTechnique::_defaultCoastlineTexture == 0) {
        VPBTechnique::_defaultCoastlineTexture = new osg::Image();
        VPBTechnique::_defaultCoastlineTexture->allocateImage(1, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE);
        VPBTechnique::_defaultCoastlineTexture->setColor(osg::Vec4f(0.0f,0.0f,0.0f,0.0f), 0,0);
    }
}

VPBTechnique::VPBTechnique(const SGReaderWriterOptions* options, const string fileName):
    _fileName(fileName)
{
    setFilterBias(0);
    setFilterWidth(0.1);
    setFilterMatrixAs(GAUSSIAN);
    setOptions(options);
    _randomObjectsConstraintGroup = new osg::Group();

    const std::lock_guard<std::mutex> lock(VPBTechnique::_defaultCoastlineTexture_mutex); 
    if (VPBTechnique::_defaultCoastlineTexture == 0) {
        VPBTechnique::_defaultCoastlineTexture = new osg::Image();
        VPBTechnique::_defaultCoastlineTexture->allocateImage(1, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE);
        VPBTechnique::_defaultCoastlineTexture->setColor(osg::Vec4f(0.0f,0.0f,0.0f,0.0f), 0,0);
    }
}

VPBTechnique::VPBTechnique(const VPBTechnique& gt,const osg::CopyOp& copyop):
    TerrainTechnique(gt,copyop),
    _fileName(gt._fileName)
{
    setFilterBias(gt._filterBias);
    setFilterWidth(gt._filterWidth);
    setFilterMatrix(gt._filterMatrix);
    setOptions(gt._options);
    _randomObjectsConstraintGroup = new osg::Group();

    const std::lock_guard<std::mutex> lock(VPBTechnique::_defaultCoastlineTexture_mutex); 
    if (VPBTechnique::_defaultCoastlineTexture == 0) {
        VPBTechnique::_defaultCoastlineTexture = new osg::Image();
        VPBTechnique::_defaultCoastlineTexture->allocateImage(1, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE);
        VPBTechnique::_defaultCoastlineTexture->setColor(osg::Vec4f(0.0f,0.0f,0.0f,0.0f), 0,0);
    }
}

VPBTechnique::~VPBTechnique()
{
}

void VPBTechnique::setFilterBias(float filterBias)
{
    _filterBias = filterBias;
    if (!_filterBiasUniform) _filterBiasUniform = new osg::Uniform("filterBias",_filterBias);
    else _filterBiasUniform->set(filterBias);
}

void VPBTechnique::setFilterWidth(float filterWidth)
{
    _filterWidth = filterWidth;
    if (!_filterWidthUniform) _filterWidthUniform = new osg::Uniform("filterWidth",_filterWidth);
    else _filterWidthUniform->set(filterWidth);
}

void VPBTechnique::setFilterMatrix(const osg::Matrix3& matrix)
{
    _filterMatrix = matrix;
    if (!_filterMatrixUniform) _filterMatrixUniform = new osg::Uniform("filterMatrix",_filterMatrix);
    else _filterMatrixUniform->set(_filterMatrix);
}

void VPBTechnique::setOptions(const SGReaderWriterOptions* options)
{
    _options = simgear::SGReaderWriterOptions::copyOrCreate(options);
    _options->setLoadOriginHint(simgear::SGReaderWriterOptions::LoadOriginHint::ORIGIN_EFFECTS);
    _options->setInstantiateMaterialEffects(true);
}

void VPBTechnique::setFilterMatrixAs(FilterType filterType)
{
    switch(filterType)
    {
        case(SMOOTH):
            setFilterMatrix(osg::Matrix3(0.0, 0.5/2.5, 0.0,
                                         0.5/2.5, 0.5/2.5, 0.5/2.5,
                                         0.0, 0.5/2.5, 0.0));
            break;
        case(GAUSSIAN):
            setFilterMatrix(osg::Matrix3(0.0, 1.0/8.0, 0.0,
                                         1.0/8.0, 4.0/8.0, 1.0/8.0,
                                         0.0, 1.0/8.0, 0.0));
            break;
        case(SHARPEN):
            setFilterMatrix(osg::Matrix3(0.0, -1.0, 0.0,
                                         -1.0, 5.0, -1.0,
                                         0.0, -1.0, 0.0));
            break;

    };
}

void VPBTechnique::init(int dirtyMask, bool assumeMultiThreaded)
{
    if (!_terrainTile) return;
    if (dirtyMask==0) return;

    OpenThreads::ScopedLock<OpenThreads::Mutex> lock(_writeBufferMutex);

    auto start = std::chrono::system_clock::now();
    osg::ref_ptr<TerrainTile> tile = _terrainTile;

    osgTerrain::TileID tileID = tile->getTileID();
    SG_LOG(SG_TERRAIN, SG_DEBUG, "Init of tile " << tileID.x << "," << tileID.y << " level " << tileID.level << " " << dirtyMask << " _currentBufferData? " << (_currentBufferData != 0));

    osg::ref_ptr<BufferData> buffer = new BufferData;

    Locator* masterLocator = computeMasterLocator();

    osg::Vec3d centerModel = computeCenterModel(*buffer, masterLocator);

    // Generate a set of material definitions for this location.
    SGMaterialLibPtr matlib  = _options->getMaterialLib();
    const SGGeod loc = computeCenterGeod(*buffer, masterLocator);
    osg::ref_ptr<SGMaterialCache> matcache;
    if (matlib) {
        SG_LOG(SG_TERRAIN, SG_DEBUG, "Applying VPB material " << loc);
        matcache = _options->getMaterialLib()->generateMatCache(loc, _options, true);
        if (!matcache) SG_LOG(SG_TERRAIN, SG_ALERT, "Unable to create materials cache for  " << loc);
    } else {
        SG_LOG(SG_TERRAIN, SG_ALERT, "Unable to create materials lib for  " << loc);
    }

    if ((dirtyMask & TerrainTile::IMAGERY_DIRTY)==0)
    {
        generateGeometry(*buffer, masterLocator, centerModel, matcache);

        osg::ref_ptr<BufferData> read_buffer = _currentBufferData;

        osg::StateSet* stateset = read_buffer->_landGeode->getStateSet();
        if (stateset)
        {
            buffer->_landGeode->setStateSet(stateset);
        }
        else
        {
            applyColorLayers(*buffer, masterLocator, matcache);
            applyLineFeatures(*buffer, masterLocator, matcache);
            applyAreaFeatures(*buffer, masterLocator, matcache);
            applyMaterials(*buffer, masterLocator, matcache);
        }
    }
    else
    {
        generateGeometry(*buffer, masterLocator, centerModel, matcache);
        
        applyColorLayers(*buffer, masterLocator, matcache);
        applyLineFeatures(*buffer, masterLocator, matcache);
        applyAreaFeatures(*buffer, masterLocator, matcache);
        applyMaterials(*buffer, masterLocator, matcache);
    }

    if (buffer->_transform.valid()) buffer->_transform->setThreadSafeRefUnref(true);

    if (!_currentBufferData || !assumeMultiThreaded)
    {
        // no currentBufferData so we must be the first init to be applied
        _currentBufferData = buffer;
    }
    else
    {
        // there is already an active _currentBufferData so we'll request that this gets swapped on next frame.
        _newBufferData = buffer;
        if (_terrainTile->getTerrain()) _terrainTile->getTerrain()->updateTerrainTileOnNextFrame(_terrainTile);
    }

    _terrainTile->setDirtyMask(0);

    std::chrono::duration<double> elapsed_seconds = std::chrono::system_clock::now() - start;
    VPBTechnique::updateStats(tileID.level, elapsed_seconds.count());
    SG_LOG(SG_TERRAIN, SG_DEBUG, "Init complete of tile " << tileID.x << "," << tileID.y << " level " << tileID.level << " " << elapsed_seconds.count() << " seconds.  Average " << VPBTechnique::getMeanLoadTime(tileID.level));
}

Locator* VPBTechnique::computeMasterLocator()
{
    osgTerrain::Layer* elevationLayer = _terrainTile->getElevationLayer();
    osgTerrain::Layer* colorLayer = _terrainTile->getColorLayer(0);

    Locator* elevationLocator = elevationLayer ? elevationLayer->getLocator() : 0;
    Locator* colorLocator = colorLayer ? colorLayer->getLocator() : 0;

    Locator* masterLocator = elevationLocator ? elevationLocator : colorLocator;
    if (!masterLocator)
    {
        OSG_NOTICE<<"Problem, no locator found in any of the terrain layers"<<std::endl;
        return 0;
    }

    return masterLocator;
}

osg::Vec3d VPBTechnique::computeCenter(BufferData& buffer, Locator* masterLocator)
{
    if (!masterLocator) return osg::Vec3d(0.0,0.0,0.0);

    osgTerrain::Layer* elevationLayer = _terrainTile->getElevationLayer();
    osgTerrain::Layer* colorLayer = _terrainTile->getColorLayer(0);

    Locator* elevationLocator = elevationLayer ? elevationLayer->getLocator() : 0;
    Locator* colorLocator = colorLayer ? colorLayer->getLocator() : 0;

    if (!elevationLocator) elevationLocator = masterLocator;
    if (!colorLocator) colorLocator = masterLocator;

    osg::Vec3d bottomLeftNDC(DBL_MAX, DBL_MAX, 0.0);
    osg::Vec3d topRightNDC(-DBL_MAX, -DBL_MAX, 0.0);

    if (elevationLayer)
    {
        if (elevationLocator!= masterLocator)
        {
            masterLocator->computeLocalBounds(*elevationLocator, bottomLeftNDC, topRightNDC);
        }
        else
        {
            bottomLeftNDC.x() = osg::minimum(bottomLeftNDC.x(), 0.0);
            bottomLeftNDC.y() = osg::minimum(bottomLeftNDC.y(), 0.0);
            topRightNDC.x() = osg::maximum(topRightNDC.x(), 1.0);
            topRightNDC.y() = osg::maximum(topRightNDC.y(), 1.0);
        }
    }

    if (colorLayer)
    {
        if (colorLocator!= masterLocator)
        {
            masterLocator->computeLocalBounds(*colorLocator, bottomLeftNDC, topRightNDC);
        }
        else
        {
            bottomLeftNDC.x() = osg::minimum(bottomLeftNDC.x(), 0.0);
            bottomLeftNDC.y() = osg::minimum(bottomLeftNDC.y(), 0.0);
            topRightNDC.x() = osg::maximum(topRightNDC.x(), 1.0);
            topRightNDC.y() = osg::maximum(topRightNDC.y(), 1.0);
        }
    }

    OSG_INFO<<"bottomLeftNDC = "<<bottomLeftNDC<<std::endl;
    OSG_INFO<<"topRightNDC = "<<topRightNDC<<std::endl;

    osg::Vec3d centerNDC = (bottomLeftNDC + topRightNDC)*0.5;
    return centerNDC;
}

osg::Vec3d VPBTechnique::computeCenterModel(BufferData& buffer, Locator* masterLocator)
{
    osg::Vec3d centerNDC = computeCenter(buffer, masterLocator);
    osg::Vec3d centerModel = centerNDC;
    masterLocator->convertLocalToModel(centerNDC, centerModel);

    buffer._transform = new osg::MatrixTransform;
    buffer._transform->setMatrix(osg::Matrix::translate(centerModel));

    return centerModel;
}

const SGGeod VPBTechnique::computeCenterGeod(BufferData& buffer, Locator* masterLocator)
{
    const osg::Vec3d world = buffer._transform->getMatrix().getTrans();
    return SGGeod::fromCart(toSG(world));
}

class VertexNormalGenerator
{
    public:

        typedef std::vector<int> Indices;
        typedef std::pair< osg::ref_ptr<osg::Vec2Array>, Locator* > TexCoordLocatorPair;
        typedef std::map< Layer*, TexCoordLocatorPair > LayerToTexCoordMap;

        VertexNormalGenerator(Locator* masterLocator, const osg::Vec3d& centerModel, int numRows, int numColmns, float scaleHeight, float vtx_gap, bool createSkirt);

        void populateCenter(osgTerrain::Layer* elevationLayer, osgTerrain::Layer* colorLayer, osg::ref_ptr<Atlas> atlas, osg::Vec2Array* texcoords);
        void populateLeftBoundary(osgTerrain::Layer* elevationLayer, osgTerrain::Layer* colorLayer, osg::ref_ptr<Atlas> atlas);
        void populateRightBoundary(osgTerrain::Layer* elevationLayer, osgTerrain::Layer* colorLayer, osg::ref_ptr<Atlas> atlas);
        void populateAboveBoundary(osgTerrain::Layer* elevationLayer, osgTerrain::Layer* colorLayer, osg::ref_ptr<Atlas> atlas);
        void populateBelowBoundary(osgTerrain::Layer* elevationLayer, osgTerrain::Layer* colorLayer, osg::ref_ptr<Atlas> atlas);

        void computeNormals();

        unsigned int capacity() const { return _vertices->capacity(); }

        inline void setVertex(int c, int r, const osg::Vec3& v, const osg::Vec3& n)
        {
            int& i = index(c,r);
            if (i==0)
            {
                if (r<0 || r>=_numRows || c<0 || c>=_numColumns)
                {
                    i = -(1+static_cast<int>(_boundaryVertices->size()));
                    _boundaryVertices->push_back(v);
                    // OSG_NOTICE<<"setVertex("<<c<<", "<<r<<", ["<<v<<"], ["<<n<<"]), i="<<i<<" _boundaryVertices["<<-i-1<<"]="<<(*_boundaryVertices)[-i-1]<<"]"<<std::endl;
                }
                else
                {
                    i = _vertices->size() + 1;
                    _vertices->push_back(v);
                    _normals->push_back(n);
                    // OSG_NOTICE<<"setVertex("<<c<<", "<<r<<", ["<<v<<"], ["<<n<<"]), i="<<i<<" _vertices["<<i-1<<"]="<<(*_vertices)[i-1]<<"]"<<std::endl;
                }
            }
            else if (i<0)
            {
                (*_boundaryVertices)[-i-1] = v;
                // OSG_NOTICE<<"setVertex("<<c<<", "<<r<<", ["<<v<<"], ["<<n<<"] _boundaryVertices["<<-i-1<<"]="<<(*_boundaryVertices)[-i-1]<<"]"<<std::endl;
            }
            else
            {
                // OSG_NOTICE<<"Overwriting setVertex("<<c<<", "<<r<<", ["<<v<<"], ["<<n<<"]"<<std::endl;
                // OSG_NOTICE<<"     previous values ( vertex ["<<(*_vertices)[i-1]<<"], normal (*_normals)[i-1] ["<<n<<"]"<<std::endl;
                // (*_vertices)[i-1] = v;

                // average the vertex positions
                (*_vertices)[i-1] = ((*_vertices)[i-1] + v)*0.5f;

                (*_normals)[i-1] = n;
            }
        }

        inline int& index(int c, int r) { return _indices[(r+1)*(_numColumns+2)+c+1]; }

        inline int index(int c, int r) const { return _indices[(r+1)*(_numColumns+2)+c+1]; }

        inline int vertex_index(int c, int r) const { int i = _indices[(r+1)*(_numColumns+2)+c+1]; return i-1; }

        inline bool vertex(int c, int r, osg::Vec3& v) const
        {
            int i = index(c,r);
            if (i==0) return false;
            if (i<0) v = (*_boundaryVertices)[-i-1];
            else v = (*_vertices)[i-1];
            return true;
        }

        inline bool computeNormal(int c, int r, osg::Vec3& n) const
        {
#if 1
            return computeNormalWithNoDiagonals(c,r,n);
#else
            return computeNormalWithDiagonals(c,r,n);
#endif
        }

        inline bool computeNormalWithNoDiagonals(int c, int r, osg::Vec3& n) const
        {
            osg::Vec3 center;
            bool center_valid  = vertex(c, r,  center);
            if (!center_valid) return false;

            osg::Vec3 left, right, top,  bottom;
            bool left_valid  = vertex(c-1, r,  left);
            bool right_valid = vertex(c+1, r,   right);
            bool bottom_valid = vertex(c,   r-1, bottom);
            bool top_valid = vertex(c,   r+1, top);

            osg::Vec3 dx(0.0f,0.0f,0.0f);
            osg::Vec3 dy(0.0f,0.0f,0.0f);
            osg::Vec3 zero(0.0f,0.0f,0.0f);
            if (left_valid)
            {
                dx += center-left;
            }
            if (right_valid)
            {
                dx += right-center;
            }
            if (bottom_valid)
            {
                dy += center-bottom;
            }
            if (top_valid)
            {
                dy += top-center;
            }

            if (dx==zero || dy==zero) return false;

            n = dx ^ dy;
            return n.normalize() != 0.0f;
        }

        inline bool computeNormalWithDiagonals(int c, int r, osg::Vec3& n) const
        {
            osg::Vec3 center;
            bool center_valid  = vertex(c, r,  center);
            if (!center_valid) return false;

            osg::Vec3 top_left, top_right, bottom_left, bottom_right;
            bool top_left_valid  = vertex(c-1, r+1,  top_left);
            bool top_right_valid  = vertex(c+1, r+1,  top_right);
            bool bottom_left_valid  = vertex(c-1, r-1,  bottom_left);
            bool bottom_right_valid  = vertex(c+1, r-1,  bottom_right);

            osg::Vec3 left, right, top,  bottom;
            bool left_valid  = vertex(c-1, r,  left);
            bool right_valid = vertex(c+1, r,   right);
            bool bottom_valid = vertex(c,   r-1, bottom);
            bool top_valid = vertex(c,   r+1, top);

            osg::Vec3 dx(0.0f,0.0f,0.0f);
            osg::Vec3 dy(0.0f,0.0f,0.0f);
            osg::Vec3 zero(0.0f,0.0f,0.0f);
            const float ratio = 0.5f;
            if (left_valid)
            {
                dx = center-left;
                if (top_left_valid) dy += (top_left-left)*ratio;
                if (bottom_left_valid) dy += (left-bottom_left)*ratio;
            }
            if (right_valid)
            {
                dx = right-center;
                if (top_right_valid) dy += (top_right-right)*ratio;
                if (bottom_right_valid) dy += (right-bottom_right)*ratio;
            }
            if (bottom_valid)
            {
                dy += center-bottom;
                if (bottom_left_valid) dx += (bottom-bottom_left)*ratio;
                if (bottom_right_valid) dx += (bottom_right-bottom)*ratio;
            }
            if (top_valid)
            {
                dy += top-center;
                if (top_left_valid) dx += (top-top_left)*ratio;
                if (top_right_valid) dx += (top_right-top)*ratio;
            }

            if (dx==zero || dy==zero) return false;

            n = dx ^ dy;
            return n.normalize() != 0.0f;
        }

        Locator*                        _masterLocator;
        const osg::Vec3d                _centerModel;
        int                             _numRows;
        int                             _numColumns;
        float                           _scaleHeight;
        float                           _constraint_vtx_gap;

        Indices                         _indices;

        osg::ref_ptr<osg::Vec3Array>    _vertices;
        osg::ref_ptr<osg::Vec3Array>    _normals;
        osg::ref_ptr<osg::FloatArray>   _elevations;

        osg::ref_ptr<osg::Vec3Array>    _boundaryVertices;

};

VertexNormalGenerator::VertexNormalGenerator(Locator* masterLocator, const osg::Vec3d& centerModel, int numRows, int numColumns, float scaleHeight, float vtx_gap, bool createSkirt):
    _masterLocator(masterLocator),
    _centerModel(centerModel),
    _numRows(numRows),
    _numColumns(numColumns),
    _scaleHeight(scaleHeight),
    _constraint_vtx_gap(vtx_gap)
{
    int numVerticesInBody = numColumns*numRows;
    int numVerticesInSkirt = createSkirt ? numColumns*2 + numRows*2 - 4 : 0;
    int numVertices = numVerticesInBody+numVerticesInSkirt;

    _indices.resize((_numRows+2)*(_numColumns+2),0);

    _vertices = new osg::Vec3Array;
    _vertices->reserve(numVertices);

    _normals = new osg::Vec3Array;
    _normals->reserve(numVertices);

    _elevations = new osg::FloatArray;
    _elevations->reserve(numVertices);

    _boundaryVertices = new osg::Vec3Array;
    _boundaryVertices->reserve(_numRows*2 + _numColumns*2 + 4);
}

void VertexNormalGenerator::populateCenter(osgTerrain::Layer* elevationLayer, osgTerrain::Layer* colorLayer, osg::ref_ptr<Atlas> atlas, osg::Vec2Array* texcoords)
{
    // OSG_NOTICE<<std::endl<<"VertexNormalGenerator::populateCenter("<<elevationLayer<<")"<<std::endl;

    bool sampled = elevationLayer &&
                   ( (elevationLayer->getNumRows()!=static_cast<unsigned int>(_numRows)) ||
                     (elevationLayer->getNumColumns()!=static_cast<unsigned int>(_numColumns)) );

    osg::Image* landclassImage = colorLayer->getImage();
    
    for(int j=0; j<_numRows; ++j)
    {
        for(int i=0; i<_numColumns; ++i)
        {
            osg::Vec3d ndc( ((double)i)/(double)(_numColumns-1), ((double)j)/(double)(_numRows-1), 0.0);

            bool validValue = true;
            if (elevationLayer)
            {
                float value = 0.0f;
                if (sampled) validValue = elevationLayer->getInterpolatedValidValue(ndc.x(), ndc.y(), value);
                else validValue = elevationLayer->getValidValue(i,j,value);
                ndc.z() = value*_scaleHeight;
            }

            if (landclassImage)
            {
                osg::Vec4d c = landclassImage->getColor(osg::Vec2d(ndc.x(), ndc.y()));
                unsigned int lc = (unsigned int) std::abs(std::round(c.x() * 255.0));
                if (atlas->isSea(lc)) {
                    ndc.set(ndc.x(), ndc.y(), 0.0f);
                }
            }

            if (validValue)
            {
                osg::Vec3d model;

                model = VPBTechnique::checkAndDisplaceAgainstElevationConstraints(ndc, _numColumns, _numRows, _constraint_vtx_gap, _masterLocator);

                texcoords->push_back(osg::Vec2(ndc.x(), ndc.y()));

                if (_elevations.valid())
                {
                    (*_elevations).push_back(ndc.z());
                }

                // compute the local normal
                osg::Vec3d ndc_one = ndc; ndc_one.z() += 1.0;
                osg::Vec3d model_one;
                _masterLocator->convertLocalToModel(ndc_one, model_one);
                model_one = model_one - model;
                model_one.normalize();

                setVertex(i, j, osg::Vec3(model-_centerModel), model_one);
            } else {
                SG_LOG(SG_TERRAIN, SG_ALERT, "Invalid elevation value found");
            }
        }
    }
}

void VertexNormalGenerator::populateLeftBoundary(osgTerrain::Layer* elevationLayer, osgTerrain::Layer* colorLayer, osg::ref_ptr<Atlas> atlas)
{
    // OSG_NOTICE<<"   VertexNormalGenerator::populateLeftBoundary("<<elevationLayer<<")"<<std::endl;

    if (!elevationLayer) return;

    bool sampled = elevationLayer &&
                   ( (elevationLayer->getNumRows()!=static_cast<unsigned int>(_numRows)) ||
                     (elevationLayer->getNumColumns()!=static_cast<unsigned int>(_numColumns)) );

    osg::Image* landclassImage = colorLayer->getImage();
    
    for(int j=0; j<_numRows; ++j)
    {
        for(int i=-1; i<=0; ++i)
        {
            osg::Vec3d ndc( ((double)i)/(double)(_numColumns-1), ((double)j)/(double)(_numRows-1), 0.0);
            osg::Vec3d left_ndc( 1.0+ndc.x(), ndc.y(), 0.0);

            bool validValue = true;
            if (elevationLayer)
            {
                float value = 0.0f;
                if (sampled) validValue = elevationLayer->getInterpolatedValidValue(left_ndc.x(), left_ndc.y(), value);
                else validValue = elevationLayer->getValidValue((_numColumns-1)+i,j,value);
                ndc.z() = value*_scaleHeight;

                ndc.z() += 0.f;
            }

            if (landclassImage)
            {
                osg::Vec4d c = landclassImage->getColor(osg::Vec2d(ndc.x(), ndc.y()));
                unsigned int lc = (unsigned int) std::abs(std::round(c.x() * 255.0));
                if (atlas->isSea(lc)) {
                    ndc.set(ndc.x(), ndc.y(), 0.0f);
                }
            }

            if (validValue)
            {
                osg::Vec3d model;
                _masterLocator->convertLocalToModel(ndc, model);

                // compute the local normal
                osg::Vec3d ndc_one = ndc; ndc_one.z() += 1.0;
                osg::Vec3d model_one;
                _masterLocator->convertLocalToModel(ndc_one, model_one);
                model_one = model_one - model;
                model_one.normalize();

                setVertex(i, j, osg::Vec3(model-_centerModel), model_one);
                // OSG_NOTICE<<"       setVertex("<<i<<", "<<j<<"..)"<<std::endl;
            }
        }
    }
}

void VertexNormalGenerator::populateRightBoundary(osgTerrain::Layer* elevationLayer, osgTerrain::Layer* colorLayer, osg::ref_ptr<Atlas> atlas)
{
    // OSG_NOTICE<<"   VertexNormalGenerator::populateRightBoundary("<<elevationLayer<<")"<<std::endl;

    if (!elevationLayer) return;

    bool sampled = elevationLayer &&
                   ( (elevationLayer->getNumRows()!=static_cast<unsigned int>(_numRows)) ||
                     (elevationLayer->getNumColumns()!=static_cast<unsigned int>(_numColumns)) );

    osg::Image* landclassImage = colorLayer->getImage();
    
    for(int j=0; j<_numRows; ++j)
    {
        for(int i=_numColumns-1; i<_numColumns+1; ++i)
        {
            osg::Vec3d ndc( ((double)i)/(double)(_numColumns-1), ((double)j)/(double)(_numRows-1), 0.0);
            osg::Vec3d right_ndc(ndc.x()-1.0, ndc.y(), 0.0);

            bool validValue = true;
            if (elevationLayer)
            {
                float value = 0.0f;
                if (sampled) validValue = elevationLayer->getInterpolatedValidValue(right_ndc.x(), right_ndc.y(), value);
                else validValue = elevationLayer->getValidValue(i-(_numColumns-1),j,value);
                ndc.z() = value*_scaleHeight;
            }

            if (landclassImage)
            {
                osg::Vec4d c = landclassImage->getColor(osg::Vec2d(ndc.x(), ndc.y()));
                unsigned int lc = (unsigned int) std::abs(std::round(c.x() * 255.0));
                if (atlas->isSea(lc)) {
                    ndc.set(ndc.x(), ndc.y(), 0.0f);
                }
            }

            if (validValue)
            {
                osg::Vec3d model;
                _masterLocator->convertLocalToModel(ndc, model);

                // compute the local normal
                osg::Vec3d ndc_one = ndc; ndc_one.z() += 1.0;
                osg::Vec3d model_one;
                _masterLocator->convertLocalToModel(ndc_one, model_one);
                model_one = model_one - model;
                model_one.normalize();

                setVertex(i, j, osg::Vec3(model-_centerModel), model_one);
                // OSG_NOTICE<<"       setVertex("<<i<<", "<<j<<"..)"<<std::endl;
            }
        }
    }
}

void VertexNormalGenerator::populateAboveBoundary(osgTerrain::Layer* elevationLayer, osgTerrain::Layer* colorLayer, osg::ref_ptr<Atlas> atlas)
{
    // OSG_NOTICE<<"   VertexNormalGenerator::populateAboveBoundary("<<elevationLayer<<")"<<std::endl;

    if (!elevationLayer) return;

    bool sampled = elevationLayer &&
                   ( (elevationLayer->getNumRows()!=static_cast<unsigned int>(_numRows)) ||
                     (elevationLayer->getNumColumns()!=static_cast<unsigned int>(_numColumns)) );

    osg::Image* landclassImage = colorLayer->getImage();
    
    for(int j=_numRows-1; j<_numRows+1; ++j)
    {
        for(int i=0; i<_numColumns; ++i)
        {
            osg::Vec3d ndc( ((double)i)/(double)(_numColumns-1), ((double)j)/(double)(_numRows-1), 0.0);
            osg::Vec3d above_ndc( ndc.x(), ndc.y()-1.0, 0.0);

            bool validValue = true;
            if (elevationLayer)
            {
                float value = 0.0f;
                if (sampled) validValue = elevationLayer->getInterpolatedValidValue(above_ndc.x(), above_ndc.y(), value);
                else validValue = elevationLayer->getValidValue(i,j-(_numRows-1),value);
                ndc.z() = value*_scaleHeight;
            }

            if (landclassImage)
            {
                osg::Vec4d c = landclassImage->getColor(osg::Vec2d(ndc.x(), ndc.y()));
                unsigned int lc = (unsigned int) std::abs(std::round(c.x() * 255.0));
                if (atlas->isSea(lc)) {
                    ndc.set(ndc.x(), ndc.y(), 0.0f);
                }
            }

            if (validValue)
            {
                osg::Vec3d model;
                _masterLocator->convertLocalToModel(ndc, model);

                // compute the local normal
                osg::Vec3d ndc_one = ndc; ndc_one.z() += 1.0;
                osg::Vec3d model_one;
                _masterLocator->convertLocalToModel(ndc_one, model_one);
                model_one = model_one - model;
                model_one.normalize();

                setVertex(i, j, osg::Vec3(model-_centerModel), model_one);
                // OSG_NOTICE<<"       setVertex("<<i<<", "<<j<<"..)"<<std::endl;
            }
        }
    }
}

void VertexNormalGenerator::populateBelowBoundary(osgTerrain::Layer* elevationLayer, osgTerrain::Layer* colorLayer, osg::ref_ptr<Atlas> atlas)
{
    // OSG_NOTICE<<"   VertexNormalGenerator::populateBelowBoundary("<<elevationLayer<<")"<<std::endl;

    if (!elevationLayer) return;

    bool sampled = elevationLayer &&
                   ( (elevationLayer->getNumRows()!=static_cast<unsigned int>(_numRows)) ||
                     (elevationLayer->getNumColumns()!=static_cast<unsigned int>(_numColumns)) );

    osg::Image* landclassImage = colorLayer->getImage();
    
    for(int j=-1; j<=0; ++j)
    {
        for(int i=0; i<_numColumns; ++i)
        {
            osg::Vec3d ndc( ((double)i)/(double)(_numColumns-1), ((double)j)/(double)(_numRows-1), 0.0);
            osg::Vec3d below_ndc( ndc.x(), 1.0+ndc.y(), 0.0);

            bool validValue = true;
            if (elevationLayer)
            {
                float value = 0.0f;
                if (sampled) validValue = elevationLayer->getInterpolatedValidValue(below_ndc.x(), below_ndc.y(), value);
                else validValue = elevationLayer->getValidValue(i,(_numRows-1)+j,value);
                ndc.z() = value*_scaleHeight;
            }

            if (landclassImage)
            {
                osg::Vec4d c = landclassImage->getColor(osg::Vec2d(ndc.x(), ndc.y()));
                unsigned int lc = (unsigned int) std::abs(std::round(c.x() * 255.0));
                if (atlas->isSea(lc)) {
                    ndc.set(ndc.x(), ndc.y(), 0.0f);
                }
            }

            if (validValue)
            {
                osg::Vec3d model;
                _masterLocator->convertLocalToModel(ndc, model);

                // compute the local normal
                osg::Vec3d ndc_one = ndc; ndc_one.z() += 1.0;
                osg::Vec3d model_one;
                _masterLocator->convertLocalToModel(ndc_one, model_one);
                model_one = model_one - model;
                model_one.normalize();

                setVertex(i, j, osg::Vec3(model-_centerModel), model_one);
                // OSG_NOTICE<<"       setVertex("<<i<<", "<<j<<"..)"<<std::endl;
            }
        }
    }
}


void VertexNormalGenerator::computeNormals()
{
    // compute normals for the center section
    for(int j=0; j<_numRows; ++j)
    {
        for(int i=0; i<_numColumns; ++i)
        {
            int vi = vertex_index(i, j);
            if (vi>=0) computeNormal(i, j, (*_normals)[vi]);
            else OSG_NOTICE<<"Not computing normal, vi="<<vi<<std::endl;
        }
    }
}

void VPBTechnique::generateGeometry(BufferData& buffer, Locator* masterLocator, const osg::Vec3d& centerModel, osg::ref_ptr<SGMaterialCache> matcache)
{
    osg::ref_ptr<Atlas> atlas;

    Terrain* terrain = _terrainTile->getTerrain();
    osgTerrain::Layer* elevationLayer = _terrainTile->getElevationLayer();
    osgTerrain::Layer* colorLayer = _terrainTile->getColorLayer(0);

    // Determine the correct Effect for this, based on a material lookup taking into account
    // the lat/lon of the center.
    SGPropertyNode_ptr landEffectProp = new SGPropertyNode();

    if (matcache) {
      atlas = matcache->getAtlas();
      SGMaterial* landmat = matcache->find("ws30land");

      if (landmat) {
        makeChild(landEffectProp.ptr(), "inherits-from")->setStringValue(landmat->get_effect_name());
      } else {
        SG_LOG( SG_TERRAIN, SG_ALERT, "Unable to get effect for VPB - no matching material in library");
        makeChild(landEffectProp.ptr(), "inherits-from")->setStringValue("Effects/model-default");
      }
    } else {
        SG_LOG( SG_TERRAIN, SG_ALERT, "Unable to get effect for VPB - no material library available");
        makeChild(landEffectProp.ptr(), "inherits-from")->setStringValue("Effects/model-default");
    }

    buffer._landGeode = new EffectGeode();
    if (buffer._transform.valid()) buffer._transform->addChild(buffer._landGeode.get());

    buffer._landGeometry = new osg::Geometry;
    buffer._landGeode->addDrawable(buffer._landGeometry.get());
  
    osg::ref_ptr<Effect> landEffect = makeEffect(landEffectProp, true, _options);
    buffer._landGeode->setEffect(landEffect.get());
    buffer._landGeode->setNodeMask( ~(simgear::CASTSHADOW_BIT | simgear::MODELLIGHT_BIT) );

    unsigned int numRows = 20;
    unsigned int numColumns = 20;

    if (elevationLayer)
    {
        numColumns = elevationLayer->getNumColumns();
        numRows = elevationLayer->getNumRows();
    }

    double scaleHeight = SGSceneFeatures::instance()->getVPBVerticalScale();
    double sampleRatio = SGSceneFeatures::instance()->getVPBSampleRatio();
    double constraint_gap = SGSceneFeatures::instance()->getVPBConstraintGap();

    unsigned int minimumNumColumns = 16u;
    unsigned int minimumNumRows = 16u;

    if ((sampleRatio!=1.0f) && (numColumns>minimumNumColumns) && (numRows>minimumNumRows))
    {
        unsigned int originalNumColumns = numColumns;
        unsigned int originalNumRows = numRows;

        numColumns = std::max((unsigned int) (float(originalNumColumns)*sqrtf(sampleRatio)), minimumNumColumns);
        numRows = std::max((unsigned int) (float(originalNumRows)*sqrtf(sampleRatio)),minimumNumRows);
    }

    bool treatBoundariesToValidDataAsDefaultValue = _terrainTile->getTreatBoundariesToValidDataAsDefaultValue();
    OSG_INFO<<"TreatBoundariesToValidDataAsDefaultValue="<<treatBoundariesToValidDataAsDefaultValue<<std::endl;

    float skirtHeight = 0.0f;
    HeightFieldLayer* hfl = dynamic_cast<HeightFieldLayer*>(elevationLayer);
    if (hfl && hfl->getHeightField())
    {
        skirtHeight = hfl->getHeightField()->getSkirtHeight();
    }

    bool createSkirt = skirtHeight != 0.0f;

    // construct the VertexNormalGenerator which will manage the generation and the vertices and normals
    VertexNormalGenerator VNG(masterLocator, centerModel, numRows, numColumns, scaleHeight, constraint_gap, createSkirt);

    unsigned int numVertices = VNG.capacity();

    // allocate and assign vertices
    buffer._landGeometry->setVertexArray(VNG._vertices.get());

    // allocate and assign normals
    buffer._landGeometry->setNormalArray(VNG._normals.get(), osg::Array::BIND_PER_VERTEX);

    // allocate and assign color
    osg::ref_ptr<osg::Vec4Array> colors = new osg::Vec4Array(1);
    (*colors)[0].set(1.0f,1.0f,1.0f,1.0f);

    buffer._landGeometry->setColorArray(colors.get(), osg::Array::BIND_OVERALL);

    // allocate and assign texture coordinates
    auto texcoords = new osg::Vec2Array;
    VNG.populateCenter(elevationLayer, colorLayer, atlas, texcoords);
    buffer._landGeometry->setTexCoordArray(0, texcoords);

    if (terrain && terrain->getEqualizeBoundaries())
    {
        TileID tileID = _terrainTile->getTileID();

        osg::ref_ptr<TerrainTile> left_tile  = terrain->getTile(TileID(tileID.level, tileID.x-1, tileID.y));
        osg::ref_ptr<TerrainTile> right_tile = terrain->getTile(TileID(tileID.level, tileID.x+1, tileID.y));
        osg::ref_ptr<TerrainTile> top_tile = terrain->getTile(TileID(tileID.level, tileID.x, tileID.y+1));
        osg::ref_ptr<TerrainTile> bottom_tile = terrain->getTile(TileID(tileID.level, tileID.x, tileID.y-1));

        VNG.populateLeftBoundary(left_tile.valid() ? left_tile->getElevationLayer() : 0, colorLayer, atlas);
        VNG.populateRightBoundary(right_tile.valid() ? right_tile->getElevationLayer() : 0, colorLayer, atlas);
        VNG.populateAboveBoundary(top_tile.valid() ? top_tile->getElevationLayer() : 0, colorLayer, atlas);
        VNG.populateBelowBoundary(bottom_tile.valid() ? bottom_tile->getElevationLayer() : 0, colorLayer, atlas);

        _neighbours.clear();

        bool updateNeighboursImmediately = false;

        if (left_tile.valid())   addNeighbour(left_tile.get());
        if (right_tile.valid())  addNeighbour(right_tile.get());
        if (top_tile.valid())    addNeighbour(top_tile.get());
        if (bottom_tile.valid()) addNeighbour(bottom_tile.get());

        if (left_tile.valid())
        {
            if (left_tile->getTerrainTechnique()==0 || !(left_tile->getTerrainTechnique()->containsNeighbour(_terrainTile)))
            {
                int dirtyMask = left_tile->getDirtyMask() | TerrainTile::LEFT_EDGE_DIRTY;
                if (updateNeighboursImmediately) left_tile->init(dirtyMask, true);
                else left_tile->setDirtyMask(dirtyMask);
            }
        }
        if (right_tile.valid())
        {
            if (right_tile->getTerrainTechnique()==0 || !(right_tile->getTerrainTechnique()->containsNeighbour(_terrainTile)))
            {
                int dirtyMask = right_tile->getDirtyMask() | TerrainTile::RIGHT_EDGE_DIRTY;
                if (updateNeighboursImmediately) right_tile->init(dirtyMask, true);
                else right_tile->setDirtyMask(dirtyMask);
            }
        }
        if (top_tile.valid())
        {
            if (top_tile->getTerrainTechnique()==0 || !(top_tile->getTerrainTechnique()->containsNeighbour(_terrainTile)))
            {
                int dirtyMask = top_tile->getDirtyMask() | TerrainTile::TOP_EDGE_DIRTY;
                if (updateNeighboursImmediately) top_tile->init(dirtyMask, true);
                else top_tile->setDirtyMask(dirtyMask);
            }
        }

        if (bottom_tile.valid())
        {
            if (bottom_tile->getTerrainTechnique()==0 || !(bottom_tile->getTerrainTechnique()->containsNeighbour(_terrainTile)))
            {
                int dirtyMask = bottom_tile->getDirtyMask() | TerrainTile::BOTTOM_EDGE_DIRTY;
                if (updateNeighboursImmediately) bottom_tile->init(dirtyMask, true);
                else bottom_tile->setDirtyMask(dirtyMask);
            }
        }
    }

    osg::ref_ptr<osg::Vec3Array> skirtVectors = new osg::Vec3Array((*VNG._normals));
    VNG.computeNormals();

    //
    // populate the primitive data
    //
    bool swapOrientation = !(masterLocator->orientationOpenGL());
    bool smallTile = numVertices < 65536;

    // OSG_NOTICE<<"smallTile = "<<smallTile<<std::endl;

    osg::ref_ptr<osg::DrawElements> landElements = smallTile ?
        static_cast<osg::DrawElements*>(new osg::DrawElementsUShort(GL_TRIANGLES)) :
        static_cast<osg::DrawElements*>(new osg::DrawElementsUInt(GL_TRIANGLES));
    landElements->reserveElements((numRows-1) * (numColumns-1) * 6);

    buffer._landGeometry->addPrimitiveSet(landElements.get());

    unsigned int i, j;
    for(j=0; j<numRows-1; ++j)
    {
        for(i=0; i<numColumns-1; ++i)
        {
            // remap indices to final vertex positions
            int i00 = VNG.vertex_index(i,   j);
            int i01 = VNG.vertex_index(i,   j+1);
            int i10 = VNG.vertex_index(i+1, j);
            int i11 = VNG.vertex_index(i+1, j+1);

            if (swapOrientation)
            {
                std::swap(i00,i01);
                std::swap(i10,i11);
            }

            unsigned int numValid = 0;
            if (i00>=0) ++numValid;
            if (i01>=0) ++numValid;
            if (i10>=0) ++numValid;
            if (i11>=0) ++numValid;

            if (numValid==4)
            {
                // optimize which way to put the diagonal by choosing to
                // place it between the two corners that have the least curvature
                // relative to each other.
                float dot_00_11 = (*VNG._normals)[i00] * (*VNG._normals)[i11];
                float dot_01_10 = (*VNG._normals)[i01] * (*VNG._normals)[i10];

                if (dot_00_11 > dot_01_10)
                {
                    landElements->addElement(i01);
                    landElements->addElement(i00);
                    landElements->addElement(i11);

                    landElements->addElement(i00);
                    landElements->addElement(i10);
                    landElements->addElement(i11);
                }
                else
                {
                    landElements->addElement(i01);
                    landElements->addElement(i00);
                    landElements->addElement(i10);

                    landElements->addElement(i01);
                    landElements->addElement(i10);
                    landElements->addElement(i11);
                }
            }
            else if (numValid==3)
            {
                if (i00>=0) landElements->addElement(i00);
                if (i01>=0) landElements->addElement(i01);
                if (i11>=0) landElements->addElement(i11);
                if (i10>=0) landElements->addElement(i10);
            }
        }
    }


    if (createSkirt)
    {
        osg::ref_ptr<osg::Vec3Array> vertices = VNG._vertices.get();
        osg::ref_ptr<osg::Vec3Array> normals = VNG._normals.get();

        osg::ref_ptr<osg::DrawElements> skirtDrawElements = smallTile ?
            static_cast<osg::DrawElements*>(new osg::DrawElementsUShort(GL_QUAD_STRIP)) :
            static_cast<osg::DrawElements*>(new osg::DrawElementsUInt(GL_QUAD_STRIP));

        // create bottom skirt vertices
        int r,c;
        r=0;
        for(c=0;c<static_cast<int>(numColumns);++c)
        {
            int orig_i = VNG.vertex_index(c,r);
            if (orig_i>=0)
            {
                unsigned int new_i = vertices->size(); // index of new index of added skirt point
                osg::Vec3 new_v = (*vertices)[orig_i] - ((*skirtVectors)[orig_i])*skirtHeight;
                (*vertices).push_back(new_v);
                if (normals.valid()) (*normals).push_back((*normals)[orig_i]);

                texcoords->push_back((*texcoords)[orig_i]);

                skirtDrawElements->addElement(orig_i);
                skirtDrawElements->addElement(new_i);
            }
            else
            {
                if (skirtDrawElements->getNumIndices()!=0)
                {
                    buffer._landGeometry->addPrimitiveSet(skirtDrawElements.get());
                    skirtDrawElements = smallTile ?
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUShort(GL_QUAD_STRIP)) :
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUInt(GL_QUAD_STRIP));
                }

            }
        }

        if (skirtDrawElements->getNumIndices()!=0)
        {
            buffer._landGeometry->addPrimitiveSet(skirtDrawElements.get());
            skirtDrawElements = smallTile ?
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUShort(GL_QUAD_STRIP)) :
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUInt(GL_QUAD_STRIP));
        }

        // create right skirt vertices
        c=numColumns-1;
        for(r=0;r<static_cast<int>(numRows);++r)
        {
            int orig_i = VNG.vertex_index(c,r); // index of original vertex of grid
            if (orig_i>=0)
            {
                unsigned int new_i = vertices->size(); // index of new index of added skirt point
                osg::Vec3 new_v = (*vertices)[orig_i] - ((*skirtVectors)[orig_i])*skirtHeight;
                (*vertices).push_back(new_v);
                if (normals.valid()) (*normals).push_back((*normals)[orig_i]);
                texcoords->push_back((*texcoords)[orig_i]);

                skirtDrawElements->addElement(orig_i);
                skirtDrawElements->addElement(new_i);
            }
            else
            {
                if (skirtDrawElements->getNumIndices()!=0)
                {
                    buffer._landGeometry->addPrimitiveSet(skirtDrawElements.get());
                    skirtDrawElements = smallTile ?
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUShort(GL_QUAD_STRIP)) :
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUInt(GL_QUAD_STRIP));
                }

            }
        }

        if (skirtDrawElements->getNumIndices()!=0)
        {
            buffer._landGeometry->addPrimitiveSet(skirtDrawElements.get());
            skirtDrawElements = smallTile ?
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUShort(GL_QUAD_STRIP)) :
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUInt(GL_QUAD_STRIP));
        }

        // create top skirt vertices
        r=numRows-1;
        for(c=numColumns-1;c>=0;--c)
        {
            int orig_i = VNG.vertex_index(c,r); // index of original vertex of grid
            if (orig_i>=0)
            {
                unsigned int new_i = vertices->size(); // index of new index of added skirt point
                osg::Vec3 new_v = (*vertices)[orig_i] - ((*skirtVectors)[orig_i])*skirtHeight;
                (*vertices).push_back(new_v);
                if (normals.valid()) (*normals).push_back((*normals)[orig_i]);

                texcoords->push_back((*texcoords)[orig_i]);

                skirtDrawElements->addElement(orig_i);
                skirtDrawElements->addElement(new_i);
            }
            else
            {
                if (skirtDrawElements->getNumIndices()!=0)
                {
                    buffer._landGeometry->addPrimitiveSet(skirtDrawElements.get());
                    skirtDrawElements = smallTile ?
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUShort(GL_QUAD_STRIP)) :
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUInt(GL_QUAD_STRIP));
                }

            }
        }

        if (skirtDrawElements->getNumIndices()!=0)
        {
            buffer._landGeometry->addPrimitiveSet(skirtDrawElements.get());
            skirtDrawElements = smallTile ?
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUShort(GL_QUAD_STRIP)) :
                        static_cast<osg::DrawElements*>(new osg::DrawElementsUInt(GL_QUAD_STRIP));
        }

        // create left skirt vertices
        c=0;
        for(r=numRows-1;r>=0;--r)
        {
            int orig_i = VNG.vertex_index(c,r); // index of original vertex of grid
            if (orig_i>=0)
            {
                unsigned int new_i = vertices->size(); // index of new index of added skirt point
                osg::Vec3 new_v = (*vertices)[orig_i] - ((*skirtVectors)[orig_i])*skirtHeight;
                (*vertices).push_back(new_v);
                if (normals.valid()) (*normals).push_back((*normals)[orig_i]);

                texcoords->push_back((*texcoords)[orig_i]);

                skirtDrawElements->addElement(orig_i);
                skirtDrawElements->addElement(new_i);
            }
            else
            {
                if (skirtDrawElements->getNumIndices()!=0)
                {
                    buffer._landGeometry->addPrimitiveSet(skirtDrawElements.get());
                    skirtDrawElements = new osg::DrawElementsUShort(GL_QUAD_STRIP);
                }
            }
        }

        if (skirtDrawElements->getNumIndices()!=0)
        {
            buffer._landGeometry->addPrimitiveSet(skirtDrawElements.get());
        }
    }

    landElements->resizeElements(landElements->getNumIndices());

    buffer._landGeometry->setUseDisplayList(false);
    buffer._landGeometry->setUseVertexBufferObjects(true);
    buffer._landGeometry->computeBoundingBox();
    buffer._landGeode->runGenerators(buffer._landGeometry);

    // Tile-specific information for the shaders
    osg::StateSet *landStateSet = buffer._landGeode->getOrCreateStateSet();
    osg::ref_ptr<osg::Uniform> level = new osg::Uniform("tile_level", _terrainTile->getTileID().level);
    landStateSet->addUniform(level);

    // Determine the x and y texture scaling.  Has to be performed after we've generated all the vertices.
    // Because the earth is round, each tile is not a rectangle.  Apart from edge cases like the poles, the
    // difference in axis length is < 1%, so we will just take the average.
    // Note that we can ignore the actual texture coordinates as we know from above that they are always
    // [0..1.0] [0..1.0] across the entire tile.
    osg::Vec3f bottom_left, bottom_right, top_left, top_right;
    bool got_bl = VNG.vertex(0, 0, bottom_left);
    bool got_br = VNG.vertex(0, VNG._numColumns - 1, bottom_right);
    bool got_tl = VNG.vertex(VNG._numColumns - 1, 0, top_left);
    bool got_tr = VNG.vertex(VNG._numColumns - 1, VNG._numRows -1, top_right);

    if (got_bl && got_br && got_tl && got_tr) {
        osg::Vec3f s = bottom_right - bottom_left;
        osg::Vec3f t = top_left - bottom_left;
        osg::Vec3f u = top_right - top_left;
        osg::Vec3f v = top_right - bottom_right;
        buffer._width = 0.5 * (s.length() + u.length());
        buffer._height = 0.5 * (t.length() + v.length());
    }

    SG_LOG(SG_TERRAIN, SG_DEBUG, "Tile Level " << _terrainTile->getTileID().level << " width " << buffer._width << " height " << buffer._height);

    osg::ref_ptr<osg::Uniform> twu = new osg::Uniform("fg_tileWidth", buffer._width);
    landStateSet->addUniform(twu);
    osg::ref_ptr<osg::Uniform> thu = new osg::Uniform("fg_tileHeight", buffer._height);
    landStateSet->addUniform(thu);

    // Force build of KD trees?
    if (osgDB::Registry::instance()->getBuildKdTreesHint()==osgDB::ReaderWriter::Options::BUILD_KDTREES &&
        osgDB::Registry::instance()->getKdTreeBuilder())
    {

        //osg::Timer_t before = osg::Timer::instance()->tick();
        //OSG_NOTICE<<"osgTerrain::VPBTechnique::build kd tree"<<std::endl;
        osg::ref_ptr<osg::KdTreeBuilder> builder = osgDB::Registry::instance()->getKdTreeBuilder()->clone();
        buffer._landGeode->accept(*builder);
        //osg::Timer_t after = osg::Timer::instance()->tick();
        //OSG_NOTICE<<"KdTree build time "<<osg::Timer::instance()->delta_m(before, after)<<std::endl;
    }
}

void VPBTechnique::applyColorLayers(BufferData& buffer, Locator* masterLocator, osg::ref_ptr<SGMaterialCache> matcache)
{   
    const SGPropertyNode* propertyNode = _options->getPropertyNode().get();
    Atlas* atlas = matcache->getAtlas();
    buffer._BVHMaterialMap = atlas->getBVHMaterialMap();

    auto tileID = _terrainTile->getTileID();

    bool photoScenery = false;

    if (propertyNode) {
        photoScenery = _options->getPropertyNode()->getBoolValue("/sim/rendering/photoscenery/enabled");
    }

    if (photoScenery) {
        // Photoscenery is enabled, so we need to find and assign the orthophoto texture

        // Firstly, we need to work out the texture file we want to load.  Fortunately this follows the same
        // naming convention as the VPB scenery itself.
        SG_LOG(SG_TERRAIN, SG_DEBUG, "Using Photoscenery for " << _fileName << " " << tileID.level << " X" << tileID.x << " Y" << tileID.y);

        const osg::Vec3d world = buffer._transform->getMatrix().getTrans();
        const SGGeod loc = SGGeod::fromCart(toSG(world));
        const SGBucket bucket = SGBucket(loc);
        SGPath orthotexture;

        osgDB::FilePathList& pathList = _options->getDatabasePathList();
        bool found = false;

        for (auto iter = pathList.begin(); !found && iter != pathList.end(); ++iter) {
            orthotexture = SGPath(*iter);
            orthotexture.append("Orthophotos");
            orthotexture.append(bucket.gen_vpb_subtile(tileID.level, tileID.x, tileID.y) + ".dds");
            SG_LOG(SG_TERRAIN, SG_DEBUG, "Looking for phototexture " << orthotexture);

            if (orthotexture.exists()) {
                found = true;
                SG_LOG(SG_TERRAIN, SG_DEBUG, "Found phototexture " << orthotexture);
            }
        }

        if (found) {

            osg::StateSet* stateset = buffer._landGeode->getOrCreateStateSet();

            // Set up the texture with wrapping of UV to reduce black edges at tile boundaries.
            osg::Texture2D* texture = SGLoadTexture2D(SGPath(orthotexture), _options, true, true);
            texture->setWrap(osg::Texture::WRAP_S,osg::Texture::CLAMP_TO_EDGE);
            texture->setWrap(osg::Texture::WRAP_T,osg::Texture::CLAMP_TO_EDGE);
            stateset->setTextureAttributeAndModes(0, texture);
            stateset->setTextureAttributeAndModes(1, atlas->getImage(), osg::StateAttribute::ON);

            // Generate a water texture so we can use the water shader
            osg::ref_ptr<osg::Texture2D> waterTexture  = new osg::Texture2D;
            waterTexture->setImage(generateWaterTexture(atlas));
            waterTexture->setMaxAnisotropy(16.0f);
            waterTexture->setResizeNonPowerOfTwoHint(false);
            waterTexture->setFilter(osg::Texture::MIN_FILTER, osg::Texture::LINEAR);
            waterTexture->setFilter(osg::Texture::MAG_FILTER, osg::Texture::LINEAR);
            waterTexture->setWrap(osg::Texture::WRAP_S,osg::Texture::CLAMP_TO_EDGE);
            waterTexture->setWrap(osg::Texture::WRAP_T,osg::Texture::CLAMP_TO_EDGE);
            // Overload of the coast texture
            stateset->setTextureAttributeAndModes(7, waterTexture);

            stateset->addUniform(new osg::Uniform(VPBTechnique::PHOTO_SCENERY, true));
            stateset->addUniform(new osg::Uniform(VPBTechnique::Z_UP_TRANSFORM, osg::Matrixf(osg::Matrix::inverse(makeZUpFrameRelative(computeCenterGeod(buffer, masterLocator))))));
            stateset->addUniform(new osg::Uniform(VPBTechnique::MODEL_OFFSET, (osg::Vec3f) buffer._transform->getMatrix().getTrans()));
            atlas->addUniforms(stateset);

        } else {
            SG_LOG(SG_TERRAIN, SG_DEBUG, "Unable to find " << orthotexture);
            photoScenery = false;
        }
    }

    if (!photoScenery) {
        // Either photoscenery is turned off, or we failed to find a suitable texture.

        osgTerrain::Layer* colorLayer = _terrainTile->getColorLayer(0);
        if (!colorLayer) return;

        osg::Image* image = colorLayer->getImage();
        if (!image || ! image->valid()) return;

        int raster_count[256] = {0};

        // Set the "g" color channel to an index into the atlas for the landclass.
        for (unsigned int s = 0; s < (unsigned int) image->s(); s++) {
            for (unsigned int t = 0; t < (unsigned int) image->t(); t++) {
                osg::Vec4d c = image->getColor(s, t);
                unsigned int i = (unsigned int) std::abs(std::round(c.x() * 255.0));
                c.set(c.x(), (double) (atlas->getIndex(i) / 255.0), atlas->isWater(i) ? 1.0 : 0.0, c.z());
                if (i < 256) {
                    raster_count[i]++;
                } else {
                    SG_LOG(SG_TERRAIN, SG_ALERT, "Raster value out of range: " << c.x() << " " << i);
                }
                image->setColor(c, s, t);
            }
        }

        // Simple statistics on the raster
        SG_LOG(SG_TERRAIN, SG_DEBUG, "Landclass Raster " << _fileName << " Level " << tileID.level << " X" << tileID.x << " Y" << tileID.y);
        SG_LOG(SG_TERRAIN, SG_DEBUG, "Raster Information:" << image->s() << "x" << image->t() << " (" << (image->s() * image->t()) << " pixels)" << " mipmaps:" << image->getNumMipmapLevels() << " format:" << image->getInternalTextureFormat());
        for (unsigned int i = 0; i < 256; ++i) { 
            if (raster_count[i] > 0) {
                SGMaterial* mat = matcache->find(i);
                if (mat) {
                    SG_LOG(SG_TERRAIN, SG_DEBUG, "  Landclass: " << i << " Material " <<  mat->get_names()[0] << " " << mat->get_one_texture(0,0) << " count: " << raster_count[i]);
                } else {
                    SG_LOG(SG_TERRAIN, SG_DEBUG, "  Landclass: " << i << " NO MATERIAL FOUND count : " << raster_count[i]);
                }
            }
        }

        osg::ref_ptr<osg::Texture2D> texture2D  = new osg::Texture2D;
        texture2D->setImage(image);
        texture2D->setMaxAnisotropy(16.0f);
        texture2D->setResizeNonPowerOfTwoHint(false);

        // Use mipmaps only in the minimization case because on magnification this results
        // in bad interpolation of boundaries between landclasses
        texture2D->setFilter(osg::Texture::MIN_FILTER, osg::Texture::NEAREST_MIPMAP_NEAREST);
        texture2D->setFilter(osg::Texture::MAG_FILTER, osg::Texture::NEAREST);

        texture2D->setWrap(osg::Texture::WRAP_S,osg::Texture::CLAMP_TO_EDGE);
        texture2D->setWrap(osg::Texture::WRAP_T,osg::Texture::CLAMP_TO_EDGE);

        osg::ref_ptr<osg::Texture2D> coastTexture  = new osg::Texture2D;
        coastTexture->setImage(generateCoastTexture(buffer, masterLocator));
        coastTexture->setMaxAnisotropy(16.0f);
        coastTexture->setResizeNonPowerOfTwoHint(false);
        coastTexture->setFilter(osg::Texture::MIN_FILTER, osg::Texture::NEAREST_MIPMAP_NEAREST);
        coastTexture->setFilter(osg::Texture::MAG_FILTER, osg::Texture::NEAREST_MIPMAP_NEAREST);
        coastTexture->setWrap(osg::Texture::WRAP_S,osg::Texture::CLAMP_TO_EDGE);
        coastTexture->setWrap(osg::Texture::WRAP_T,osg::Texture::CLAMP_TO_EDGE);

        osg::StateSet* stateset = buffer._landGeode->getOrCreateStateSet();
        stateset->setTextureAttributeAndModes(0, texture2D, osg::StateAttribute::ON);
        stateset->setTextureAttributeAndModes(1, atlas->getImage(), osg::StateAttribute::ON);
        stateset->setTextureAttributeAndModes(7, coastTexture, osg::StateAttribute::ON);
        stateset->addUniform(new osg::Uniform(VPBTechnique::PHOTO_SCENERY, false));
        stateset->addUniform(new osg::Uniform(VPBTechnique::Z_UP_TRANSFORM, osg::Matrixf(osg::Matrix::inverse(makeZUpFrameRelative(computeCenterGeod(buffer, masterLocator))))));
        stateset->addUniform(new osg::Uniform(VPBTechnique::MODEL_OFFSET, (osg::Vec3f) buffer._transform->getMatrix().getTrans()));
        atlas->addUniforms(stateset);
        //SG_LOG(SG_TERRAIN, SG_ALERT, "modeOffset:" << buffer._transform->getMatrix().getTrans().length() << " " << buffer._transform->getMatrix().getTrans());
    }
}

double VPBTechnique::det2(const osg::Vec2d a, const osg::Vec2d b)
{
    return a.x() * b.y() - b.x() * a.y();
}

void VPBTechnique::applyMaterials(BufferData& buffer, Locator* masterLocator, osg::ref_ptr<SGMaterialCache> matcache)
{
    if (!matcache) return;
    pc_init(2718281);

    // Define all possible handlers
    VegetationHandler vegetationHandler;
    RandomLightsHandler lightsHandler;
    std::vector<VPBMaterialHandler *> all_handlers{&vegetationHandler,
                                                   &lightsHandler};

    // Filter out handlers that do not apply to the current tile
    std::vector<VPBMaterialHandler *> handlers;
    for (const auto handler : all_handlers) {
        if (handler->initialize(_options, _terrainTile)) {
            handlers.push_back(handler);
        }
    }

    // If no handlers are relevant to the current tile, return immediately
    if (handlers.size() == 0) {
        return;
    }

    SGMaterial* mat = 0;

    const SGGeod loc = computeCenterGeod(buffer, masterLocator);

    osg::Vec3d up = buffer._transform->getMatrix().getTrans();
    up.normalize();

    const osg::Vec3d world = buffer._transform->getMatrix().getTrans();
    const SGGeoc cloc = SGGeoc::fromCart(toSG(world));

    if (!matcache) return;

    const osg::Matrixd R_vert = osg::Matrixd::rotate(
     M_PI / 2.0 - loc.getLatitudeRad(), osg::Vec3d(0.0, 1.0, 0.0),
     loc.getLongitudeRad(), osg::Vec3d(0.0, 0.0, 1.0),
     0.0, osg::Vec3d(1.0, 0.0, 0.0));

    const osg::Array* vertices = buffer._landGeometry->getVertexArray();
    const osg::Array* texture_coords = buffer._landGeometry->getTexCoordArray(0);
    osgTerrain::Layer* colorLayer = _terrainTile->getColorLayer(0);

    if (!colorLayer) {
        SG_LOG(SG_TERRAIN, SG_ALERT, "No landclass image for " << _terrainTile->getTileID().x << " " << _terrainTile->getTileID().y << " " << _terrainTile->getTileID().level);
        return;
    }

    osg::Image* image = colorLayer->getImage();

    if (!image || ! image->valid()) {
        SG_LOG(SG_TERRAIN, SG_ALERT, "No landclass image for " << _terrainTile->getTileID().x << " " << _terrainTile->getTileID().y << " " << _terrainTile->getTileID().level);
        return;
    }

    const osg::Vec3* vertexPtr = static_cast<const osg::Vec3*>(vertices->getDataPointer());
    const osg::Vec2* texPtr = static_cast<const osg::Vec2*>(texture_coords->getDataPointer());

    const osg::PrimitiveSet* primSet = buffer._landGeometry->getPrimitiveSet(0);
    const osg::DrawElements* drawElements = primSet->getDrawElements();
    const unsigned int triangle_count = drawElements->getNumPrimitives();

    const double lon          = loc.getLongitudeRad();
    const double lat          = loc.getLatitudeRad();
    const double clon         = cloc.getLongitudeRad();
    const double clat         = cloc.getLatitudeRad();
    const double r_E_lat      = /* 6356752.3 */ 6.375993e+06;
    const double r_E_lon      = /* 6378137.0 */ 6.389377e+06;
    const double C            = r_E_lon * cos(lat);
    const double one_over_C   = (fabs(C) > 1.0e-4) ? (1.0 / C) : 0.0;
    const double one_over_r_E = 1.0 / r_E_lat;

    const osg::Matrix rotation_vertices_c = osg::Matrix::rotate(
     M_PI / 2 - clat, osg::Vec3d(0.0, 1.0, 0.0),
     clon, osg::Vec3d(0.0, 0.0, 1.0),
     0.0, osg::Vec3d(1.0, 0.0, 0.0));

    // Compute lat/lon deltas for each handler
    std::vector<std::pair<double, double>> deltas;
    for (const auto handler : handlers) {
        handler->setLocation(loc, r_E_lat, r_E_lon);
        deltas.push_back(
            std::make_pair(handler->get_delta_lat(), handler->get_delta_lon()));
    }

    // At the detailed tile level we are handling various materials, and
    // as we walk across the tile in a scanline, the landclass doesn't
    // change regularly from point to point.  Cache the required
    // material information for the current landclass to reduce the
    // number of lookups into the material cache.
    int current_land_class = -1;
    osg::Texture2D* object_mask = NULL;
    osg::Image* object_mask_image = NULL;
    float x_scale = 1000.0;
    float y_scale = 1000.0;

    for (unsigned int i = 0; i < triangle_count; i++)
    {
        const int i0 = drawElements->index(3 * i);
        const int i1 = drawElements->index(3 * i + 1);
        const int i2 = drawElements->index(3 * i + 2);

        const osg::Vec3 v0 = vertexPtr[i0];
        const osg::Vec3 v1 = vertexPtr[i1];
        const osg::Vec3 v2 = vertexPtr[i2];

        const osg::Vec3d v_0 = v0;
        const osg::Vec3d v_x = v1 - v0;
        const osg::Vec3d v_y = v2 - v0;

        osg::Vec3 n = v_x ^ v_y;
        n.normalize();

        const osg::Vec3d v_0_g = R_vert * v0;
        const osg::Vec3d v_1_g = R_vert * v1;
        const osg::Vec3d v_2_g = R_vert * v2;

        const osg::Vec2d ll_0 = osg::Vec2d(v_0_g.y() * one_over_C + lon, -v_0_g.x() * one_over_r_E + lat);
        const osg::Vec2d ll_1 = osg::Vec2d(v_1_g.y() * one_over_C + lon, -v_1_g.x() * one_over_r_E + lat);
        const osg::Vec2d ll_2 = osg::Vec2d(v_2_g.y() * one_over_C + lon, -v_2_g.x() * one_over_r_E + lat);

        const osg::Vec2d ll_O = ll_0;
        const osg::Vec2d ll_x = osg::Vec2d((v_1_g.y() - v_0_g.y()) * one_over_C, -(v_1_g.x() - v_0_g.x()) * one_over_r_E);
        const osg::Vec2d ll_y = osg::Vec2d((v_2_g.y() - v_0_g.y()) * one_over_C, -(v_2_g.x() - v_0_g.x()) * one_over_r_E);

        // Each handler may have a different delta/granularity in the scanline.
        // To take advantage of the material caching, we first collect all the
        // scan points from all the handlers for the current tile, and then scan
        // them in spatial order, calling the appropriate handler for each
        // point.
        //
        // We will insert <lon, lat, handler*> elements in a vector, and sort
        // all elements in increasing lon followed by increase lat, mimicking a
        // scanline reading approach for efficient landclass caching
        std::vector<std::tuple<double, double, VPBMaterialHandler *>>
            scan_points;

        for(auto iter=0u; iter!=handlers.size(); iter++) {
            const double delta_lat = deltas[iter].first;
            const double delta_lon = deltas[iter].second;
            const int off_x = ll_O.x() / delta_lon;
            const int off_y = ll_O.y() / delta_lat;
            const int min_lon = min(min(ll_0.x(), ll_1.x()), ll_2.x()) / delta_lon;
            const int max_lon = max(max(ll_0.x(), ll_1.x()), ll_2.x()) / delta_lon;
            const int min_lat = min(min(ll_0.y(), ll_1.y()), ll_2.y()) / delta_lat;
            const int max_lat = max(max(ll_0.y(), ll_1.y()), ll_2.y()) / delta_lat;

            for (int lat_int = min_lat - 1; lat_int <= max_lat + 1; lat_int++) {
                const double lat = (lat_int - off_y) * delta_lat;
                for (int lon_int = min_lon - 1; lon_int <= max_lon + 1;
                     lon_int++) {
                    const double lon = (lon_int - off_x) * delta_lon;
                    scan_points.push_back(
                        std::make_tuple(lon, lat, handlers[iter]));
                }
            }
        }

        std::sort(scan_points.begin(), scan_points.end());

        const osg::Vec2 t0 = texPtr[i0];
        const osg::Vec2 t1 = texPtr[i1];
        const osg::Vec2 t2 = texPtr[i2];

        const osg::Vec2d t_0 = t0;
        const osg::Vec2d t_x = t1 - t0;
        const osg::Vec2d t_y = t2 - t0;

        const double D = det2(ll_x, ll_y);

        for(auto const &point : scan_points) {
            const double lon = get<0>(point);
            const double lat = get<1>(point);
            VPBMaterialHandler *handler = get<2>(point);

            osg::Vec2d p(lon, lat);
            double x = det2(ll_x, p) / D;
            double y = det2(p, ll_y) / D;

            if ((x < 0.0) || (y < 0.0) || (x + y > 1.0)) continue;

            if (!image) {
                SG_LOG(SG_TERRAIN, SG_ALERT, "Image disappeared under my feet.");
                continue;
            }

            osg::Vec2 t = osg::Vec2(t_0 + t_x * x + t_y * y);
            unsigned int tx = (unsigned int) (image->s() * t.x()) % image->s();
            unsigned int ty = (unsigned int) (image->t() * t.y()) % image->t();
            const osg::Vec4 tc = image->getColor(tx, ty);
            const int land_class = int(std::round(tc.x() * 255.0));

            if (land_class != current_land_class) {
                // Use temporal locality to reduce material lookup by caching
                // some elements for future lookups against the same landclass.
                mat = matcache->find(land_class);
                if (!mat) continue;

                current_land_class = land_class;

                // We need to notify all handlers of material change, but
                // only consider the current handler being processed for
                // skipping the loop
                bool current_handler_result = true;
                for (const auto temp_handler : handlers) {
                    bool result = temp_handler->handleNewMaterial(mat);

                    if (temp_handler == handler) {
                        current_handler_result = result;
                    }
                }

                if (!current_handler_result) {
                    continue;
                }

                object_mask = mat->get_one_object_mask(0);
                object_mask_image = NULL;
                if (object_mask != NULL) {
                    object_mask_image = object_mask->getImage();
                    if (!object_mask_image || ! object_mask_image->valid()) {
                        object_mask_image = NULL;
                        continue;
                    }

                    // Texture coordinates run [0..1][0..1] across the entire tile whereas
                    // the texure itself has defined dimensions in m.
                    // We therefore need to use the tile width and height to determine the correct
                    // texture coordinate transformation.
                    x_scale = buffer._width / 1000.0;
                    y_scale = buffer._height / 1000.0;

                    if (mat->get_xsize() > 0.0) { x_scale = buffer._width / mat->get_xsize(); }
                    if (mat->get_ysize() > 0.0) { y_scale = buffer._height / mat->get_ysize(); }
                }
            }

            if (!mat) continue;

            osg::Vec2f pointInTriangle;

            if (handler->handleIteration(mat, object_mask_image,
                                         lon, lat, p,
                                         D, ll_O, ll_x, ll_y, t_0, t_x, t_y, x_scale, y_scale, pointInTriangle)) {
                // Check against constraints to stop lights on roads
                const osg::Vec3 vp = v_x * pointInTriangle.x() + v_y * pointInTriangle.y() + v_0;
                const osg::Vec3 upperPoint = vp + up * 100;
                const osg::Vec3 lowerPoint = vp - up * 100;
                if (checkAgainstRandomObjectsConstraints(buffer, lowerPoint, upperPoint))
                    continue;

                const osg::Matrixd localToGeocentricTransform = buffer._transform->getMatrix();
                if (checkAgainstElevationConstraints(lowerPoint * localToGeocentricTransform, upperPoint * localToGeocentricTransform))
                    continue;

                handler->placeObject(vp, up, n);
            }
        }
    }

    for (const auto handler : handlers) {
        handler->finish(_options, buffer._transform, loc);
    }
}

void VPBTechnique::applyLineFeatures(BufferData& buffer, Locator* masterLocator, osg::ref_ptr<SGMaterialCache> matcache)
{
    if (! matcache) {
        SG_LOG(SG_TERRAIN, SG_ALERT, "Unable to get materials library to generate roads");
        return;
    }    

    unsigned int line_features_lod_range = 6;
    float minWidth = 9999.9;

    const unsigned int tileLevel = _terrainTile->getTileID().level;
    const SGPropertyNode* propertyNode = _options->getPropertyNode().get();

    if (propertyNode) {
        const SGPropertyNode* static_lod = propertyNode->getNode("/sim/rendering/static-lod");
        line_features_lod_range = static_lod->getIntValue("line-features-lod-level", line_features_lod_range);
        if (static_lod->getChildren("lod-level").size() > tileLevel) {
            minWidth = static_lod->getChildren("lod-level")[tileLevel]->getFloatValue("line-features-min-width", minWidth);
        }
    }

    if (tileLevel < line_features_lod_range) {
        // Do not generate vegetation for tiles too far away
        return;
    }

    SG_LOG(SG_TERRAIN, SG_DEBUG, "Generating roads of width > " << minWidth << " for tile LoD level " << tileLevel);

    Atlas* atlas = matcache->getAtlas();
    SGMaterial* mat = 0;

    if (! buffer._lineFeatures) buffer._lineFeatures = new osg::Group();

    // Get all appropriate roads.  We assume that the VPB terrain tile is smaller than a Bucket size.
    LightBin lightbin;
    const osg::Vec3d world = buffer._transform->getMatrix().getTrans();
    const SGGeod loc = SGGeod::fromCart(toSG(world));
    const SGBucket bucket = SGBucket(loc);
    string material_name = "";
    for (auto roads = _lineFeatureLists.begin(); roads != _lineFeatureLists.end(); ++roads) {
        auto r = *roads;
        if (r.first != bucket) continue;
        LineFeatureBinList roadBins = r.second;

        for (LineFeatureBinList::iterator rb = roadBins.begin(); rb != roadBins.end(); ++rb)
        {
            if (material_name != (*rb)->getMaterial()) {
                // Cache the material to reduce lookups.
                mat = matcache->find((*rb)->getMaterial());
                material_name = (*rb)->getMaterial();
            }

            if (!mat) {
                SG_LOG(SG_TERRAIN, SG_ALERT, "Unable to find material " << (*rb)->getMaterial() << " at " << loc << " " << bucket);
                continue;
            }    

            const unsigned int ysize = mat->get_ysize();
            const bool   light_edge_offset = mat->get_light_edge_offset();
            const double light_edge_spacing = mat->get_light_edge_spacing_m();
            const double light_edge_height = mat->get_light_edge_height_m();
            const double x0 = mat->get_line_feature_tex_x0();
            const double x1 = mat->get_line_feature_tex_x1();
            const double elevation_offset_m = mat->get_line_feature_offset_m();

            //  Generate a geometry for this set of roads.
            osg::Vec3Array* v = new osg::Vec3Array;
            osg::Vec2Array* t = new osg::Vec2Array;
            osg::Vec3Array* n = new osg::Vec3Array;
            osg::Vec4Array* c = new osg::Vec4Array;
            osg::Vec3Array* lights = new osg::Vec3Array;

            auto lineFeatures = (*rb)->getLineFeatures();

            for (auto r = lineFeatures.begin(); r != lineFeatures.end(); ++r) {
                if (r->_width > minWidth) generateLineFeature(buffer, masterLocator, *r, world, v, t, n, lights, x0, x1, ysize, light_edge_spacing, light_edge_height, light_edge_offset, elevation_offset_m);
            }

            if (v->size() == 0) {
                v->unref();
                t->unref();
                n->unref();
                c->unref();
                lights->unref();
                continue;
            }

            c->push_back(osg::Vec4d(1.0,1.0,1.0,1.0));

            osg::ref_ptr<osg::Geometry> geometry = new osg::Geometry;
            geometry->setVertexArray(v);
            geometry->setTexCoordArray(0, t, osg::Array::BIND_PER_VERTEX);
            geometry->setTexCoordArray(1, t, osg::Array::BIND_PER_VERTEX);
            geometry->setNormalArray(n, osg::Array::BIND_PER_VERTEX);
            geometry->setColorArray(c, osg::Array::BIND_OVERALL);
            geometry->setUseDisplayList( false );
            geometry->setUseVertexBufferObjects( true );
            geometry->addPrimitiveSet( new osg::DrawArrays( GL_TRIANGLES, 0, v->size()) );

            EffectGeode* geode = new EffectGeode;
            geode->addDrawable(geometry);

            geode->setMaterial(mat);
            geode->setEffect(mat->get_one_effect(0));
            geode->runGenerators(geometry);
            geode->setNodeMask( ~(simgear::CASTSHADOW_BIT | simgear::MODELLIGHT_BIT) );

            osg::StateSet* stateset = geode->getOrCreateStateSet();
            stateset->addUniform(new osg::Uniform(VPBTechnique::Z_UP_TRANSFORM, osg::Matrixf(osg::Matrix::inverse(makeZUpFrameRelative(loc)))));
            stateset->addUniform(new osg::Uniform(VPBTechnique::MODEL_OFFSET, (osg::Vec3f) buffer._transform->getMatrix().getTrans()));

            atlas->addUniforms(stateset);

            buffer._lineFeatures->addChild(geode);

            if (lights->size() > 0) {
                const double size = mat->get_light_edge_size_cm();
                const double intensity = mat->get_light_edge_intensity_cd();
                const SGVec4f color = mat->get_light_edge_colour();
                const double horiz = mat->get_light_edge_angle_horizontal_deg();
                const double vertical = mat->get_light_edge_angle_vertical_deg();
                // Assume street lights point down.
                osg::Vec3d up = world;
                up.normalize();
                const SGVec3f direction = toSG(- (osg::Vec3f) up);

                std::for_each(lights->begin(), lights->end(), 
                    [&, size, intensity, color, direction, horiz, vertical] (osg::Vec3f p) { lightbin.insert(toSG(p), size, intensity, 1, color, direction, horiz, vertical); } );
            }
            lights->unref();
        }
    }

    if (buffer._lineFeatures->getNumChildren() > 0) {
        // We have some line features, so add them
        buffer._transform->addChild(buffer._lineFeatures.get());
    }

    if (lightbin.getNumLights() > 0) buffer._transform->addChild(createLights(lightbin, osg::Matrix::identity(), _options));
}

void VPBTechnique::generateLineFeature(BufferData& buffer, Locator* masterLocator, LineFeatureBin::LineFeature road, osg::Vec3d modelCenter, osg::Vec3Array* v, osg::Vec2Array* t, osg::Vec3Array* n, osg::Vec3Array* lights, double x0, double x1, unsigned int ysize, double light_edge_spacing, double light_edge_height, bool light_edge_offset, double elevation_offset_m)
{
    // We're in Earth-centered coordinates, so "up" is simply directly away from (0,0,0)
    osg::Vec3d up = modelCenter;
    up.normalize();
    TileBounds tileBounds(masterLocator, up);

    std::list<osg::Vec3d> nodes = tileBounds.clipToTile(road._nodes);

    // We need at least two node to make a road.
    if (nodes.size() < 2) return; 

    osg::Vec3d ma, mb;
    std::list<osg::Vec3d> roadPoints;
    auto road_iter = nodes.begin();

    ma = getMeshIntersection(buffer, masterLocator, *road_iter - modelCenter, up);
    road_iter++;

    for (; road_iter != nodes.end(); road_iter++) {
        mb = getMeshIntersection(buffer, masterLocator, *road_iter - modelCenter, up);
        auto esl = VPBElevationSlice::computeVPBElevationSlice(buffer._landGeometry, ma, mb, up);

        for(auto eslitr = esl.begin(); eslitr != esl.end(); ++eslitr) {
            roadPoints.push_back(*eslitr);
        }

        // Now traverse the next segment
        ma = mb;
    }

    if (roadPoints.size() == 0) return;

    // We now have a series of points following the topography of the elevation mesh.

    auto iter = roadPoints.begin();
    osg::Vec3d start = *iter;
    iter++;

    osg::Vec3d last_spanwise =  (*iter - start)^ up;
    last_spanwise.normalize();

    float yTexBaseA = 0.0f;
    float yTexBaseB = 0.0f;
    float last_light_distance = 0.0f;

    for (; iter != roadPoints.end(); iter++) {

        osg::Vec3d end = *iter;

        // Ignore tiny segments - likely artifacts of the elevation slicer
        if ((end - start).length2() < 1.0) continue;

        // Find a spanwise vector
        osg::Vec3d spanwise = ((end-start) ^ up);
        spanwise.normalize();

        // Define the road extents
        const osg::Vec3d a = start - last_spanwise * road._width * 0.5 + up * elevation_offset_m;
        const osg::Vec3d b = start + last_spanwise * road._width * 0.5 + up * elevation_offset_m;
        const osg::Vec3d c = end   - spanwise * road._width * 0.5 + up * elevation_offset_m;
        const osg::Vec3d d = end   + spanwise * road._width * 0.5 + up * elevation_offset_m;

        // Determine the x and y texture coordinates for the edges
        const float yTexA = yTexBaseA + (c-a).length() / ysize;
        const float yTexB = yTexBaseB + (d-b).length() / ysize;

        // Now generate two triangles, .
        v->push_back(a);
        v->push_back(b);
        v->push_back(c);

        t->push_back(osg::Vec2d(x0, yTexBaseA));
        t->push_back(osg::Vec2d(x1, yTexBaseB));
        t->push_back(osg::Vec2d(x0, yTexA));

        v->push_back(b);
        v->push_back(d);
        v->push_back(c);

        t->push_back(osg::Vec2d(x1, yTexBaseB));
        t->push_back(osg::Vec2d(x1, yTexB));
        t->push_back(osg::Vec2d(x0, yTexA));

        // Normal is straight from the quad
        osg::Vec3d normal = -(end-start)^spanwise;
        normal.normalize();
        for (unsigned int i = 0; i < 6; i++) n->push_back(normal);

        start = end;
        yTexBaseA = yTexA;
        yTexBaseB = yTexB;
        last_spanwise = spanwise;
        float edge_length = (c-a).length();
        float start_a = last_light_distance;
        float start_b = start_a;

        if ((road._attributes == 1) && (light_edge_spacing > 0.0)) {
            // We have some edge lighting.  Traverse edges a-c and b-d adding lights as appropriate.
            
            // Handle the case where lights are on alternate sides of the road rather than in pairs
            if (light_edge_offset) start_b = fmodf(start_b + light_edge_spacing * 0.5, light_edge_spacing);

            osg::Vec3f p1 = (c-a);
            p1.normalize();

            while (start_a < edge_length) {
                lights->push_back(a + (osg::Vec3f) p1 * start_a + up * (light_edge_height + 1.0));
                start_a += light_edge_spacing;
            }

            osg::Vec3f p2 = (d-b);
            p2.normalize();

            while (start_b < edge_length) {
                lights->push_back(b + (osg::Vec3f) p2 * start_b + up * (light_edge_height + 1.0));
                start_b += light_edge_spacing;
            }

            // Determine the position for the first light on the next road segment.
            last_light_distance = fmodf(start_a + edge_length, light_edge_spacing);
        }
    }
}

void VPBTechnique::applyAreaFeatures(BufferData& buffer, Locator* masterLocator, osg::ref_ptr<SGMaterialCache> matcache)
{
    if (! matcache) {
        SG_LOG(SG_TERRAIN, SG_ALERT, "Unable to get materials library to generate areas");
        return;
    }    

    unsigned int area_features_lod_range = 6;
    float minArea = 1000.0;

    const unsigned int tileLevel = _terrainTile->getTileID().level;
    const SGPropertyNode* propertyNode = _options->getPropertyNode().get();

    if (propertyNode) {
        const SGPropertyNode* static_lod = propertyNode->getNode("/sim/rendering/static-lod");
        area_features_lod_range = static_lod->getIntValue("area-features-lod-level", area_features_lod_range);
        if (static_lod->getChildren("lod-level").size() > tileLevel) {
            minArea = static_lod->getChildren("lod-level")[tileLevel]->getFloatValue("area-features-min-width", minArea);
            minArea *= minArea;
        }
    }

    if (tileLevel < area_features_lod_range) {
        // Do not generate areas for tiles too far away
        return;
    }

    SGMaterial* mat = 0;

    // Get all appropriate areas.  We assume that the VPB terrain tile is smaller than a Bucket size.
    const osg::Vec3d world = buffer._transform->getMatrix().getTrans();
    const SGGeod loc = SGGeod::fromCart(toSG(world));
    const SGBucket bucket = SGBucket(loc);
    for (auto areas = _areaFeatureLists.begin(); areas != _areaFeatureLists.end(); ++areas) {
        if (areas->first != bucket) continue;

        const AreaFeatureBinList areaBins = areas->second;

        for (auto rb = areaBins.begin(); rb != areaBins.end(); ++rb)
        {
            mat = matcache->find((*rb)->getMaterial());

            if (!mat) {
                SG_LOG(SG_TERRAIN, SG_ALERT, "Unable to find material " << (*rb)->getMaterial() << " at " << loc << " " << bucket);
                continue;
            }    

            unsigned int xsize = mat->get_xsize();
            unsigned int ysize = mat->get_ysize();

            //  Generate a geometry for this set of areas.
            osg::Vec3Array* v = new osg::Vec3Array;
            osg::Vec2Array* t = new osg::Vec2Array;
            osg::Vec3Array* n = new osg::Vec3Array;
            osg::Vec4Array* c = new osg::Vec4Array(1);

            osg::ref_ptr<osg::Geometry> geometry = new osg::Geometry;
            geometry->setVertexArray(v);
            geometry->setTexCoordArray(0, t, osg::Array::BIND_PER_VERTEX);
            geometry->setTexCoordArray(1, t, osg::Array::BIND_PER_VERTEX);
            geometry->setNormalArray(n, osg::Array::BIND_PER_VERTEX);
            geometry->setColorArray(c, osg::Array::BIND_OVERALL);
            geometry->setUseDisplayList( false );
            geometry->setUseVertexBufferObjects( true );

            auto areaFeatures = (*rb)->getAreaFeatures();

            for (auto r = areaFeatures.begin(); r != areaFeatures.end(); ++r) {
                if (r->_area > minArea) generateAreaFeature(buffer, masterLocator, *r, world, geometry, v, t, n, xsize, ysize);
            }

            if (v->size() == 0) continue;
            c->push_back(osg::Vec4(1.0,1.0,1.0,1.0));

            geometry->dirtyBound();

            EffectGeode* geode = new EffectGeode;
            geode->addDrawable(geometry);

            geode->setMaterial(mat);
            geode->setEffect(mat->get_one_effect(0));
            geode->setNodeMask( ~(simgear::CASTSHADOW_BIT | simgear::MODELLIGHT_BIT) );
            buffer._transform->addChild(geode);
        }
    }
}

void VPBTechnique::generateAreaFeature(BufferData& buffer, Locator* masterLocator, AreaFeatureBin::AreaFeature area, osg::Vec3d modelCenter, osg::Geometry* geometry, osg::Vec3Array* v, osg::Vec2Array* t, osg::Vec3Array* n, unsigned int xsize, unsigned int ysize)
{
    if (area._nodes.size() < 3) { 
        SG_LOG(SG_TERRAIN, SG_ALERT, "Coding error - AreaFeatureBin::LineFeature with fewer than three nodes"); 
        return; 
    }

    osg::Vec3d ma;

    // We're in Earth-centered coordinates, so "up" is simply directly away from (0,0,0)
    osg::Vec3d up = modelCenter;
    up.normalize();

    osg::ref_ptr<osgUtil::Tessellator> tessellator = new osgUtil::Tessellator;
    tessellator->setBoundaryOnly(false);
    tessellator->setTessellationNormal(up);
    tessellator->beginTessellation();
    tessellator->beginContour();

    // Build up the tesselator while also determining the correct elevation for the feature.
    double elev = 0;
    unsigned int elev_count = 0;
    osg::Vec3d last_pt;

    auto area_iter = area._nodes.begin();
    osg::Vec3d pt = *area_iter - modelCenter;
    ma = getMeshIntersection(buffer, masterLocator, pt, up);

    // Only build this area if the first vertex is on the mesh.  This ensures that the
    // area is only generated once, no matter how many tiles it spans.
    if (ma == pt) return;

    for (; area_iter != area._nodes.end(); area_iter++) {
        pt = *area_iter - modelCenter;

        // Ignore small segments - we really don't need resolution less than 10m
        if ((pt - last_pt).length2() < 100.0) continue;

        ma = getMeshIntersection(buffer, masterLocator, pt, up);
        if (ma !=pt) {
            elev += up*ma;
            elev_count++;
        }

        // To handle the case where the feature overlaps the edge of this particular mesh,
        // we always add vertices, even if they don't intersect the edge of the mesh.
        tessellator->addVertex(new osg::Vec3f(pt));

        last_pt = pt;
    }

    tessellator->endContour();
    tessellator->endTessellation();

    auto primList = tessellator->getPrimList();
    if (primList.size() == 0) return;

    unsigned int idx = 0;

    auto primItr = primList.begin();
    for (; primItr < primList.end(); ++ primItr) {
        auto vertices = (*primItr)->_vertices;
        std::for_each( vertices.begin(),
                        vertices.end(),
                        [v, t, n, up, elev, elev_count](auto vtx) {
                            v->push_back(*vtx + up * (elev / elev_count));
                            t->push_back(osg::Vec2f(vtx->x(), vtx->y()));
                            n->push_back(up);
                        }
                        );
        geometry->addPrimitiveSet(new osg::DrawArrays((*primItr)->_mode, idx, vertices.size()));
        idx += vertices.size();
    }
}

osg::Image* VPBTechnique::generateWaterTexture(Atlas* atlas) {  
    osg::Image* waterTexture = new osg::Image();

    osgTerrain::Layer* colorLayer = _terrainTile->getColorLayer(0);
    if (!colorLayer) return waterTexture;

    osg::Image* image = colorLayer->getImage();
    if (!image || ! image->valid()) return waterTexture;

    waterTexture->allocateImage(image->s(), image->t(), 1, GL_RGBA, GL_FLOAT);

    // Set the r color channel to indicate if this is water or not
    for (unsigned int s = 0; s < (unsigned int) image->s(); s++) {
        for (unsigned int t = 0; t < (unsigned int) image->t(); t++) {            
            osg::Vec4d c = image->getColor(s, t);
            int i = int(std::round(c.x() * 255.0));
            waterTexture->setColor(osg::Vec4f(atlas->isWater(i) ? 1.0f : 0.0f,0.0f,0.0f,0.0f), s, t);
        }
    }

    return waterTexture;
}


osg::Image* VPBTechnique::generateCoastTexture(BufferData& buffer, Locator* masterLocator) {

    unsigned int coast_features_lod_range = 4;
    unsigned int waterTextureSize = 2048;
    float coastWidth = 150.0;

    const unsigned int tileLevel = _terrainTile->getTileID().level;
    const SGPropertyNode* propertyNode = _options->getPropertyNode().get();

    if (propertyNode) {
        const SGPropertyNode* static_lod = propertyNode->getNode("/sim/rendering/static-lod");
        waterTextureSize =         static_lod->getIntValue("water-texture-size", coast_features_lod_range);
        coast_features_lod_range = static_lod->getIntValue("coastline-lod-level", coast_features_lod_range);
        coastWidth =               static_lod->getFloatValue("coastline-width", coastWidth);
    }

    if ((_coastFeatureLists.size() == 0 ) || (tileLevel < coast_features_lod_range)) {
        return VPBTechnique::_defaultCoastlineTexture;
    }

    // Get all appropriate coasts.  We assume that the VPB terrain tile is smaller than a Bucket size.
    const osg::Vec3d world = buffer._transform->getMatrix().getTrans();
    float tileSize = sqrt(buffer._width * buffer._width + buffer._height * buffer._height);
    const SGGeod loc = SGGeod::fromCart(toSG(world));
    const SGBucket bucket = SGBucket(loc);
    // We're in Earth-centered coordinates, so "up" is simply directly away from (0,0,0)
    osg::Vec3d up = world;
    up.normalize();

    TileBounds tileBounds(masterLocator, up);

    bool coastsFound = false;

    // Do a quick pass to check that there is some coastline to generate here. This is worth doing
    // because the LoD scheme results in many tiles with no coastlines.
    for (auto coasts = _coastFeatureLists.begin(); coasts != _coastFeatureLists.end(); ++coasts) {
        if (coasts->first != bucket) continue;
        const CoastlineBinList coastBins = coasts->second;

        for (auto rb = coastBins.begin(); !coastsFound && (rb != coastBins.end()); ++rb)
        {
            auto coastFeatures = (*rb)->getCoastlines();
            for (auto r = coastFeatures.begin(); !coastsFound && (r != coastFeatures.end()); ++r) {
                for (auto p = r->_nodes.begin(); !coastsFound && (p != r->_nodes.end()); ++p) {
                    if (tileBounds.insideTile(*p)) {
                        coastsFound = true;
                    }
                }
            }
        }
    }

    if (coastsFound) {
        // We have at least one coast here, so generate a coastline texture for the tile and
        // render to it.
        osg::Image* coastTexture = new osg::Image();
        coastTexture->allocateImage(waterTextureSize, waterTextureSize, 1, GL_RGBA, GL_FLOAT);
        for (unsigned int y = 0; y < waterTextureSize; ++y) {
            for (unsigned int x = 0; x < waterTextureSize; ++x) {
                coastTexture->setColor(osg::Vec4f(0.0f,0.0f,0.0f,0.0f), x, y);
            }
        }

        for (auto coasts = _coastFeatureLists.begin(); coasts != _coastFeatureLists.end(); ++coasts) {
            if (coasts->first != bucket) continue;
            const CoastlineBinList coastBins = coasts->second;

            for (auto rb = coastBins.begin(); rb != coastBins.end(); ++rb)
            {
                auto coastFeatures = (*rb)->getCoastlines();

                for (auto r = coastFeatures.begin(); r != coastFeatures.end(); ++r) {
                    auto clipped = tileBounds.clipToTile(r->_nodes);
                    if (clipped.size() > 1) {                    
                        // We need at least two points to render a line.
                        LineFeatureBin::LineFeature line = LineFeatureBin::LineFeature(clipped, coastWidth);
                        addCoastline(masterLocator, coastTexture, line, waterTextureSize, tileSize, coastWidth);
                    }
                }
            }
        }

        return coastTexture;
    }

    return VPBTechnique::_defaultCoastlineTexture;
}

// Update the color of a particular texture pixel, clipping to the texture and not over-writing a larger value.
void VPBTechnique::updateWaterTexture(osg::Image* waterTexture, unsigned int waterTextureSize, osg::Vec4 color, float x, float y) {
    if (floor(x) < 0.0) return;
    if (floor(x) > (waterTextureSize -1)) return;
    if (floor(y) < 0.0) return;
    if (floor(y) > (waterTextureSize -1)) return;
    auto clamp = [waterTextureSize](float l) { return (unsigned int) fmaxf(0, fminf(floor(l), waterTextureSize - 1)); };
    unsigned int clamped_x = clamp(x);
    unsigned int clamped_y = clamp(y);    
    osg::Vec4 new_color = max(waterTexture->getColor(clamped_x, clamped_y), color);
    waterTexture->setColor(new_color, clamped_x, clamped_y);
}


void VPBTechnique::writeShoreStripe(osg::Image* waterTexture, unsigned int waterTextureSize, float tileSize, float coastWidth, float x, float y, int dx, int dy) {

    // We need to create a shoreline of width coastWidth to define it better and to hide any discrepancy in the underlying terrain mesh
    // which may be either mis-aligned or simply of insufficient resolution.
    float waterTextureResolution = tileSize / waterTextureSize;
    int width = (int) coastWidth / waterTextureResolution;
    int aboveHWLtxUnits = 0.3*width;
    int belowHWLtxUnits = width - aboveHWLtxUnits;

    // Above the high water mark we just want sand.  However there can be interpolation artifacts right at the edge causing a border or water. To avoid
    // this we create an extra texel where the G channel is used to ensure we get a hard fall-off to the underlying texture
    // on the adjacent sand texture unit.
    updateWaterTexture(waterTexture, waterTextureSize, osg::Vec4(0.0f, 1.0f, 0.0f, 0.0), x - dx*(aboveHWLtxUnits + 1), y -dy*(aboveHWLtxUnits + 1));
    
    // Create the sand above the high water mark
    for (int d = 0; d < aboveHWLtxUnits; d++) {
        updateWaterTexture(waterTexture, waterTextureSize, osg::Vec4(0.0f, 1.0f, 0.0f, 0.0), x - dx*d, y -dy*d);
    }

    // Create the shoreline below the high water level which will gradually merge into the underlying terrain mesh
    for (int d = 0; d < belowHWLtxUnits; d++) {
        updateWaterTexture(waterTexture, waterTextureSize, osg::Vec4(0.0f, 0.0f, 1.0f, 0.0)*(belowHWLtxUnits -d)/belowHWLtxUnits, x + dx*d, y + dy*d);
    }
}

void VPBTechnique::addCoastline(Locator* masterLocator, osg::Image* waterTexture, LineFeatureBin::LineFeature line, unsigned int waterTextureSize, float tileSize, float coastWidth) {
    

    if (line._nodes.size() < 2) { 
        SG_LOG(SG_TERRAIN, SG_ALERT, "Coding error - LineFeatureBin::LineFeature with fewer than two nodes"); 
        return; 
    }

    auto iter = line._nodes.begin();

    // LineFeature is in Model coordinates, but for the rasterization we will use local coordinates.
    osg::Vec3d start;
    bool success = masterLocator->convertModelToLocal(*iter, start);
    if (!success) {
        SG_LOG(SG_TERRAIN, SG_ALERT, "Unable to convert from model coordinates to local: " << *iter); 
        return; 
    }

    iter++;
    for (; iter != line._nodes.end(); iter++) {
        osg::Vec3d end;
        success = masterLocator->convertModelToLocal(*iter, end);
        if (!success) {
            SG_LOG(SG_TERRAIN, SG_ALERT, "Unable to convert from model coordinates to local: " << *iter); 
            continue; 
        }

        // We now have two points in local (2d) space, so rasterize the line between them onto the water texture.
        // We use a simple version of a DDA to render the lines.  We should replace this with a scanline algorithm to handle coastlines
        // and waterbodies efficiently.
        // Do everything in the texture coordinates.
        float dx = (end.x() - start.x()) * waterTextureSize;
        float dy = (end.y() - start.y()) * waterTextureSize;
        float step = abs(dy);
        bool steep = true;
        if (abs(dx) >= abs(dy)) {
            step = abs(dx);
            steep = false;
        }
        dx = dx / step;
        dy = dy / step;
        float x = start.x() * waterTextureSize;
        float y = start.y() * waterTextureSize;
        int i = 0;
        while (i <= step) {
            if ((x >= 0.0f) && (y >= 0.0f) && (x < waterTextureSize) && (y < waterTextureSize)) {
                // The line defines the Mean High Water Level.  By definition, the sea is always to
                // the right of the line.  We want to fill in a section of sea and shore to cover up any issues 
                // between the OSM data and the landclass texture.

                if (steep) {
                    // A steep line, so we are should add width in the x-axis
                    if (dy < 0) {
                        // We are travelling downwards, so the seaward side is -x
                        writeShoreStripe(waterTexture, waterTextureSize, tileSize, coastWidth, x , y, -1, 0);
                    } else {
                        // We are travelling upwards, so the seaward side is +x
                        writeShoreStripe(waterTexture, waterTextureSize, tileSize, coastWidth, x , y, 1, 0);
                    }
                } else {
                    // Not a steep line, so we should add width in the y axis
                    if (dx < 0) {
                        // We are travelling right to left, so the seaward side is +y
                        writeShoreStripe(waterTexture, waterTextureSize, tileSize, coastWidth, x , y, 0, 1);
                    } else {
                        // We are travelling left to right, so the seaward side is -y
                        writeShoreStripe(waterTexture, waterTextureSize, tileSize, coastWidth, x , y, 0, -1);
                    }
                }
            } 

            x = x + dx;
            y = y + dy;
            i = i + 1;
        }

        start = end;
    }
}

// Find the intersection of a given SGGeod with the terrain mesh
osg::Vec3d VPBTechnique::getMeshIntersection(BufferData& buffer, Locator* masterLocator, osg::Vec3d pt, osg::Vec3d up) 
{
    osg::ref_ptr<osgUtil::LineSegmentIntersector> intersector;
    intersector = new osgUtil::LineSegmentIntersector(pt - up*100.0, pt + up*8000.0);
    osgUtil::IntersectionVisitor visitor(intersector.get());
    buffer._landGeometry->accept(visitor);

    if (intersector->containsIntersections()) {
        // We have an intersection with the terrain model, so return it
        return intersector->getFirstIntersection().getWorldIntersectPoint();
    } else {
        // No intersection.  Likely this point is outside our geometry.  So just return the original element.
        return pt;
    }
}

void VPBTechnique::update(osg::NodeVisitor& nv)
{
    if (_terrainTile) _terrainTile->osg::Group::traverse(nv);

    if (_newBufferData.valid())
    {
        _currentBufferData = _newBufferData;
        _newBufferData = 0;
    }
}


void VPBTechnique::cull(osg::NodeVisitor& nv)
{
    if (_currentBufferData.valid())
    {
        if (_currentBufferData->_transform.valid())
        {
            _currentBufferData->_transform->accept(nv);
        }
    }
}


void VPBTechnique::traverse(osg::NodeVisitor& nv)
{
    if (!_terrainTile) return;

    // if app traversal update the frame count.
    if (nv.getVisitorType()==osg::NodeVisitor::UPDATE_VISITOR)
    {
        //if (_terrainTile->getDirty()) _terrainTile->init(_terrainTile->getDirtyMask(), false);
        update(nv);
        return;
    }
    else if (nv.getVisitorType()==osg::NodeVisitor::CULL_VISITOR)
    {
        cull(nv);
        return;
    }


    if (_terrainTile->getDirty())
    {
        OSG_INFO<<"******* Doing init ***********"<<std::endl;
        //_terrainTile->init(_terrainTile->getDirtyMask(), false);
    }

    if (_currentBufferData.valid())
    {
        if (_currentBufferData->_transform.valid()) _currentBufferData->_transform->accept(nv);
    }
}

void VPBTechnique::cleanSceneGraph()
{
}

void VPBTechnique::releaseGLObjects(osg::State* state) const
{
    if (_currentBufferData.valid() && _currentBufferData->_transform.valid()) _currentBufferData->_transform->releaseGLObjects(state);
    if (_newBufferData.valid() && _newBufferData->_transform.valid()) _newBufferData->_transform->releaseGLObjects(state);
}

// Add an osg object representing an elevation contraint on the terrain mesh.  The generated terrain mesh will not include any vertices that
// lie above the constraint model.  (Note that geometry may result in edges intersecting the constraint model in cases where there
// are significantly higher vertices that lie just outside the constraint model.
void VPBTechnique::addElevationConstraint(osg::ref_ptr<osg::Node> constraint)
{ 
    const std::lock_guard<std::mutex> lock(VPBTechnique::_elevationConstraintMutex); // Lock the _elevationConstraintGroup for this scope
    _elevationConstraintGroup->addChild(constraint.get()); 
}

// Remove a previously added constraint.  E.g on model unload.
void VPBTechnique::removeElevationConstraint(osg::ref_ptr<osg::Node> constraint)
{ 
    const std::lock_guard<std::mutex> lock(VPBTechnique::_elevationConstraintMutex); // Lock the _elevationConstraintGroup for this scope
    _elevationConstraintGroup->removeChild(constraint.get()); 
}

// Check a given vertex against any elevation constraints  E.g. to ensure the terrain mesh doesn't
// poke through any airport meshes.  If such a constraint exists, the function will return a replacement
// vertex displaces such that it below the contraint relative to the passed in origin by vtx_gap meters.  
osg::Vec3d VPBTechnique::checkAndDisplaceAgainstElevationConstraints(osg::Vec3d ndc, int cols, int rows, float vtx_gap, Locator* masterLocator)
{
    const std::lock_guard<std::mutex> lock(VPBTechnique::_elevationConstraintMutex); // Lock the _elevationConstraintGroup for this scope

    osg::Vec3d origin, vertex, deltaX, deltaY;
    masterLocator->convertLocalToModel(osg::Vec3d(ndc.x(), ndc.y(), -1000), origin);
    masterLocator->convertLocalToModel(ndc, vertex);
    masterLocator->convertLocalToModel(ndc + osg::Vec3d(1.0 / (double) cols, 0.0,0.0), deltaX);
    masterLocator->convertLocalToModel(ndc + osg::Vec3d(0.0, 1.0 / (double) rows, 0.0), deltaY);

    double elev = ndc.z();

    for (int i = -1; i < 2; ++i) {
        for (int j = -1; j < 2; ++j) {
            osg::Vec3d delta = deltaX * i + deltaY * j;
            osg::ref_ptr<osgUtil::LineSegmentIntersector> intersector;
            intersector = new osgUtil::LineSegmentIntersector(origin + delta, vertex + delta);
            osgUtil::IntersectionVisitor visitor(intersector.get());
            _elevationConstraintGroup->accept(visitor);

            if (intersector->containsIntersections()) {
                // We have an intersection with our constraints model, so move the terrain vertex to below the intersection point by vtx_gap meters
                osg::Vec3d ray = intersector->getFirstIntersection().getWorldIntersectPoint() - (origin + delta);
                ray.normalize();
                osg::Vec3d local;
                masterLocator->convertModelToLocal(intersector->getFirstIntersection().getWorldIntersectPoint() - ray*vtx_gap, local);
                if (elev > local.z()) {
                    elev = local.z();
                }
            }
        }
    }

    // elev now contains the local elevation of a point constrained by the elevation constraints of the vertex and the 8 surrounding
    // vertices.
    osg::Vec3d constrained;
    masterLocator->convertLocalToModel(osg::Vec3d(ndc.x(), ndc.y(), elev), constrained);
    return constrained;    
}

bool VPBTechnique::checkAgainstElevationConstraints(osg::Vec3d origin, osg::Vec3d vertex)
{
    const std::lock_guard<std::mutex> lock(VPBTechnique::_elevationConstraintMutex); // Lock the _elevationConstraintGroup for this scope
    osg::ref_ptr<osgUtil::LineSegmentIntersector> intersector;
    intersector = new osgUtil::LineSegmentIntersector(origin, vertex);
    osgUtil::IntersectionVisitor visitor(intersector.get());
    _elevationConstraintGroup->accept(visitor);
    return intersector->containsIntersections();
}


bool VPBTechnique::checkAgainstRandomObjectsConstraints(BufferData& buffer, osg::Vec3d origin, osg::Vec3d vertex)
{
    if (buffer._lineFeatures) {
        osg::ref_ptr<osgUtil::LineSegmentIntersector> intersector;
        intersector = new osgUtil::LineSegmentIntersector(origin, vertex);
        osgUtil::IntersectionVisitor visitor(intersector.get());
        buffer._lineFeatures->accept(visitor);
        return intersector->containsIntersections();
    } else {
        return false;
    }
}

void VPBTechnique::clearConstraints()
{
    const std::lock_guard<std::mutex> elock(VPBTechnique::_elevationConstraintMutex); // Lock the _elevationConstraintGroup for this scope
    _elevationConstraintGroup = new osg::Group();
}

void VPBTechnique::addLineFeatureList(SGBucket bucket, LineFeatureBinList roadList)
{
    if (roadList.empty()) return;

    // Block to mutex the List alone
    {
        const std::lock_guard<std::mutex> lock(VPBTechnique::_lineFeatureLists_mutex); // Lock the _lineFeatureLists for this scope
        _lineFeatureLists.push_back(std::pair(bucket, roadList));
    }

}

void VPBTechnique::addAreaFeatureList(SGBucket bucket, AreaFeatureBinList areaList)
{
    if (areaList.empty()) return;

    // Block to mutex the List alone
    {
        const std::lock_guard<std::mutex> lock(VPBTechnique::_areaFeatureLists_mutex); // Lock the _lineFeatureLists for this scope
        _areaFeatureLists.push_back(std::pair(bucket, areaList));
    }
}

void VPBTechnique::addCoastlineList(SGBucket bucket, CoastlineBinList coastline)
{
    if (coastline.empty()) return;

    // Block to mutex the List alone
    {
        const std::lock_guard<std::mutex> lock(VPBTechnique::_coastFeatureLists_mutex); // Lock the _lineFeatureLists for this scope
        _coastFeatureLists.push_back(std::pair(bucket, coastline));
    }

}

void VPBTechnique::unloadFeatures(SGBucket bucket)
{
    SG_LOG(SG_TERRAIN, SG_DEBUG, "Erasing all features with entry " << bucket);

    {
        const std::lock_guard<std::mutex> locklines(VPBTechnique::_lineFeatureLists_mutex); // Lock the _lineFeatureLists for this scope
        for (auto lf = _lineFeatureLists.begin(); lf != _lineFeatureLists.end(); ++lf) {
            if (lf->first == bucket) {
                SG_LOG(SG_TERRAIN, SG_DEBUG, "Unloading  line feature for " << bucket);
                auto linefeatureBinList = lf->second;
                linefeatureBinList.clear();
            }
        }
    }

    {
        const std::lock_guard<std::mutex> lockareas(VPBTechnique::_areaFeatureLists_mutex); // Lock the _areaFeatureLists for this scope
        for (auto lf = _areaFeatureLists.begin(); lf != _areaFeatureLists.end(); ++lf) {
            if (lf->first == bucket) {
                SG_LOG(SG_TERRAIN, SG_DEBUG, "Unloading  area feature for " << bucket);
                auto areafeatureBinList = lf->second;
                areafeatureBinList.clear();
            }
        }
    }

    {
        const std::lock_guard<std::mutex> lockcoasts(VPBTechnique::_coastFeatureLists_mutex); // Lock the _coastFeatureLists for this scope
        for (auto lf = _coastFeatureLists.begin(); lf != _coastFeatureLists.end(); ++lf) {
            if (lf->first == bucket) {
                SG_LOG(SG_TERRAIN, SG_DEBUG, "Unloading  area feature for " << bucket);
                auto coastfeatureBinList = lf->second;
                coastfeatureBinList.clear();
            }
        }
    }
}

void VPBTechnique::updateStats(int tileLevel, float loadTime) {
    const std::lock_guard<std::mutex> lock(VPBTechnique::_stats_mutex); // Lock the _stats_mutex for this scope
    if (_loadStats.find(tileLevel) == _loadStats.end()) {
        _loadStats[tileLevel] = LoadStat(1, loadTime);
    } else {
        _loadStats[tileLevel].first++;
        _loadStats[tileLevel].second +=loadTime;
    }
}

float VPBTechnique::getMeanLoadTime(int tileLevel) {
    const std::lock_guard<std::mutex> lock(VPBTechnique::_stats_mutex); // Lock the _stats_mutex for this scope
    if (_loadStats.find(tileLevel) == _loadStats.end()) return 0.0;

    return _loadStats[tileLevel].second / _loadStats[tileLevel].first;
}

BVHMaterial* VPBTechnique::getMaterial(simgear::BVHLineSegmentVisitor* lsv) {
    const osg::Array* texCoords = _currentBufferData->_landGeometry->getTexCoordArray(0);
    const osg::Vec2* texPtr = static_cast<const osg::Vec2*>(texCoords->getDataPointer());
    const std::array<unsigned, 3> index = lsv->getIndices();

    osg::Vec2 tc =   texPtr[index[0]] + 
                   ( texPtr[index[1]] -  texPtr[index[0]] ) * lsv->getUV().x() +
                   ( texPtr[index[2]] -  texPtr[index[0]] ) * lsv->getUV().y();

    auto image = _terrainTile->getColorLayer(0)->getImage();
    // Blue channel indicates if this is water, green channel is an index into the landclass data
    unsigned int tx = (unsigned int) (image->s() * tc.x()) % image->s();
    unsigned int ty = (unsigned int) (image->t() * tc.y()) % image->t();
    auto c = image->getColor(tx, ty);
    unsigned int lc = (unsigned int) std::abs(std::round(c.g() * 255.0));
    SGSharedPtr<SGMaterial> mat = _currentBufferData->_BVHMaterialMap[lc];
    if (mat) {
        return mat;
    } else {
        SG_LOG(SG_TERRAIN, SG_ALERT, "Unexpected Landclass index in landclass texture: " << lc << " original texture value: " << c.g());
        return new BVHMaterial();
    }
}

SGSphered VPBTechnique::computeBoundingSphere() const {
    SGSphered bs;
    osg::Vec3d center = _currentBufferData->_transform->getBound().center();
    bs.setCenter(SGVec3d(center.x(), center.y(), center.z()));
    bs.setRadius(_currentBufferData->_transform->getBound().radius());
    return bs;
}