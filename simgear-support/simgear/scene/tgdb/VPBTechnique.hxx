// VPBTechnique.hxx -- VirtualPlanetBuilder Effects technique
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

#ifndef VPBTECHNIQUE
#define VPBTECHNIQUE 1

#include <mutex>

#include <osg/MatrixTransform>
#include <osg/Geode>
#include <osg/Geometry>

#include <osgTerrain/TerrainTechnique>
#include <osgTerrain/Locator>

#include <simgear/bucket/newbucket.hxx>
#include <simgear/bvh/BVHLineSegmentVisitor.hxx>
#include <simgear/bvh/BVHMaterial.hxx>
#include <simgear/math/SGGeometry.hxx>
#include <simgear/scene/material/EffectGeode.hxx>
#include <simgear/scene/material/matlib.hxx>
#include <simgear/scene/tgdb/AreaFeatureBin.hxx>
#include <simgear/scene/tgdb/LightBin.hxx>
#include <simgear/scene/tgdb/LineFeatureBin.hxx>
#include <simgear/scene/tgdb/CoastlineBin.hxx>

using namespace osgTerrain;

namespace simgear {

class VPBTechnique : public TerrainTechnique
{
    public:

        VPBTechnique();
        VPBTechnique(const SGReaderWriterOptions* options, const string fileName);

        /** Copy constructor using CopyOp to manage deep vs shallow copy.*/
        VPBTechnique(const VPBTechnique&,const osg::CopyOp& copyop=osg::CopyOp::SHALLOW_COPY);

        META_Object(osgTerrain, VPBTechnique);

        virtual void init(int dirtyMask, bool assumeMultiThreaded);

        virtual Locator* computeMasterLocator();


        virtual void update(osg::NodeVisitor& nv);

        virtual void cull(osg::NodeVisitor& nv);

        /** Traverse the terain subgraph.*/
        virtual void traverse(osg::NodeVisitor& nv);

        virtual BVHMaterial* getMaterial(simgear::BVHLineSegmentVisitor* visitor);
        virtual SGSphered computeBoundingSphere() const;

        virtual void cleanSceneGraph();

        void setFilterBias(float filterBias);
        float getFilterBias() const { return _filterBias; }

        void setFilterWidth(float filterWidth);
        float getFilterWidth() const { return _filterWidth; }

        void setFilterMatrix(const osg::Matrix3& matrix);
        osg::Matrix3& getFilterMatrix() { return _filterMatrix; }
        const osg::Matrix3& getFilterMatrix() const { return _filterMatrix; }

        enum FilterType
        {
            GAUSSIAN,
            SMOOTH,
            SHARPEN
        };

        void setFilterMatrixAs(FilterType filterType);

        void setOptions(const SGReaderWriterOptions* options);

        /** If State is non-zero, this function releases any associated OpenGL objects for
        * the specified graphics context. Otherwise, releases OpenGL objects
        * for all graphics contexts. */
        virtual void releaseGLObjects(osg::State* = 0) const;

        // Elevation constraints ensure that the terrain mesh is placed underneath objects such as airports.
        // As airports are generated in a separate loading thread, these are static.
        static void addElevationConstraint(osg::ref_ptr<osg::Node> constraint);
        static void removeElevationConstraint(osg::ref_ptr<osg::Node> constraint);
        static osg::Vec3d checkAndDisplaceAgainstElevationConstraints(osg::Vec3d ndc, int cols, int rows, float vtx_gap, Locator* masterLocator);
        static bool checkAgainstElevationConstraints(osg::Vec3d origin, osg::Vec3d vertex);

        static void clearConstraints();

        // LineFeatures and AreaFeatures are draped over the underlying mesh.
        static void addLineFeatureList(SGBucket bucket, LineFeatureBinList roadList);
        static void addAreaFeatureList(SGBucket bucket, AreaFeatureBinList areaList);
        static void addCoastlineList(SGBucket bucket, CoastlineBinList areaList);
        static void unloadFeatures(SGBucket bucket);

    protected:

        virtual ~VPBTechnique();

        class BufferData : public osg::Referenced
        {
        public:
            BufferData() : _transform(0), _landGeode(0), _landGeometry(0), _lineFeatures(0), _width(0.0), _height(0.0)            
            {}

            osg::ref_ptr<osg::MatrixTransform>  _transform;
            osg::ref_ptr<EffectGeode>           _landGeode;
            osg::ref_ptr<osg::Geometry>         _landGeometry;
            osg::ref_ptr<osg::Group>            _lineFeatures;
            float                               _width;
            float                               _height;
            Atlas::AtlasMap                     _BVHMaterialMap;

        protected:
            ~BufferData() {}
        };

        virtual osg::Vec3d computeCenter(BufferData& buffer, Locator* masterLocator);
        virtual osg::Vec3d computeCenterModel(BufferData& buffer, Locator* masterLocator);
        const virtual SGGeod computeCenterGeod(BufferData& buffer, Locator* masterLocator);

        virtual void generateGeometry(BufferData& buffer, Locator* masterLocator, const osg::Vec3d& centerModel, osg::ref_ptr<SGMaterialCache> matcache);

        virtual void applyColorLayers(BufferData& buffer, Locator* masterLocator, osg::ref_ptr<SGMaterialCache> matcache);

        virtual double det2(const osg::Vec2d a, const osg::Vec2d b);

        virtual void applyMaterials(BufferData& buffer, Locator* masterLocator, osg::ref_ptr<SGMaterialCache> matcache);

        virtual void applyLineFeatures(BufferData& buffer, Locator* masterLocator, osg::ref_ptr<SGMaterialCache> matcache);
        virtual void generateLineFeature(BufferData& buffer, 
            Locator* masterLocator, 
            LineFeatureBin::LineFeature road, 
            osg::Vec3d modelCenter, 
            osg::Vec3Array* v, 
            osg::Vec2Array* t, 
            osg::Vec3Array* n,
            osg::Vec3Array* lights,
            double x0,
            double x1,
            unsigned int ysize,
            double light_edge_spacing,
            double light_edge_height,
            bool light_edge_offset,
            double elevation_offset_m);

        virtual void applyAreaFeatures(BufferData& buffer, Locator* masterLocator, osg::ref_ptr<SGMaterialCache> matcache);
        virtual void generateAreaFeature(BufferData& buffer, 
            Locator* masterLocator, 
            AreaFeatureBin::AreaFeature area, 
            osg::Vec3d modelCenter, 
            osg::Geometry* geometry,
            osg::Vec3Array* v, 
            osg::Vec2Array* t, 
            osg::Vec3Array* n,
            unsigned int xsize,
            unsigned int ysize);

        virtual osg::Image* generateCoastTexture(BufferData& buffer, Locator* masterLocator);
        virtual osg::Image* generateWaterTexture(Atlas* atlas);
        virtual void addCoastline(Locator* masterLocator, osg::Image* waterTexture, LineFeatureBin::LineFeature line, unsigned int waterTextureSize, float tileSize, float coastWidth);        
        virtual void updateWaterTexture(osg::Image* waterTexture, unsigned int waterTextureSize, osg::Vec4 color, float x, float y);
        virtual void writeShoreStripe(osg::Image* waterTexture, unsigned int waterTextureSize, float tileSize, float coastWidth, float x, float y, int dx, int dy);

        virtual osg::Vec3d getMeshIntersection(BufferData& buffer, Locator* masterLocator, osg::Vec3d pt, osg::Vec3d up);

        static void updateStats(int tileLevel, float loadTime);
        static float getMeanLoadTime(int tileLevel);

        // Check a given vertex against any constraints  E.g. to ensure we
        // don't get objects like trees sprouting from roads or runways.
        bool checkAgainstRandomObjectsConstraints(BufferData& buffer, 
                                                  osg::Vec3d origin, osg::Vec3d vertex);

        OpenThreads::Mutex                  _writeBufferMutex;
        osg::ref_ptr<BufferData>            _currentBufferData;
        osg::ref_ptr<BufferData>            _newBufferData;

        float                               _filterBias;
        osg::ref_ptr<osg::Uniform>          _filterBiasUniform;
        float                               _filterWidth;
        osg::ref_ptr<osg::Uniform>          _filterWidthUniform;
        osg::Matrix3                        _filterMatrix;
        osg::ref_ptr<osg::Uniform>          _filterMatrixUniform;
        osg::ref_ptr<SGReaderWriterOptions> _options;
        const string                        _fileName;
        osg::ref_ptr<osg::Group>            _randomObjectsConstraintGroup;

        inline static osg::ref_ptr<osg::Group>  _elevationConstraintGroup = new osg::Group();
        inline static std::mutex _elevationConstraintMutex;  // protects the _elevationConstraintGroup;

        typedef std::pair<SGBucket, LineFeatureBinList> BucketLineFeatureBinList;
        typedef std::pair<SGBucket, AreaFeatureBinList> BucketAreaFeatureBinList;
        typedef std::pair<SGBucket, CoastlineBinList> BucketCoastlineBinList;

        inline static std::list<BucketLineFeatureBinList>  _lineFeatureLists;
        inline static std::mutex _lineFeatureLists_mutex;  // protects the _lineFeatureLists;

        inline static std::list<BucketAreaFeatureBinList>  _areaFeatureLists;
        inline static std::mutex _areaFeatureLists_mutex;  // protects the _areaFeatureLists;

        inline static std::list<BucketCoastlineBinList>  _coastFeatureLists;
        inline static std::mutex _coastFeatureLists_mutex;  // protects the _areaFeatureLists;

        inline static std::mutex _stats_mutex; // Protects the loading statistics
        typedef std::pair<unsigned int, float> LoadStat;
        inline static std::map<int, LoadStat> _loadStats;

        inline static osg::ref_ptr<osg::Image> _defaultCoastlineTexture;
        inline static std::mutex _defaultCoastlineTexture_mutex;

        inline static const char* Z_UP_TRANSFORM = "fg_zUpTransform";
        inline static const char* MODEL_OFFSET   = "fg_modelOffset";
        inline static const char* PHOTO_SCENERY  = "fg_photoScenery";
};

};

#endif
