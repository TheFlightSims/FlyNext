// galaxy.cxx -- model the celestial sphere brightness by unresolved
// sources, i.e. the milky way and its nebulae: our Galaxy
//
// Started November 2021 (Chris Ringeval)
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
// $Id$


#ifndef _SG_GALAXY_HXX_
#define _SG_GALAXY_HXX_


#include <osg/ref_ptr>
#include <osg/MatrixTransform>
#include <osg/Material>

#include <simgear/math/SGMath.hxx>
#include <simgear/structure/SGReferenced.hxx>

#include <simgear/misc/sg_path.hxx>


class SGGalaxy : public SGReferenced {

  osg::ref_ptr<osg::MatrixTransform> galaxy_transform;
  osg::ref_ptr<osg::Uniform> zenith_brightness_magnitude;
  
  SGPropertyNode_ptr _magDarkSkyProperty;

  // the darkest sky at zenith has a brightness equals to (in
  // magnitude per arcsec^2 for the V band)
  const double _magDarkSkyDefault = 22.0;
  
public:

  // Constructor
  SGGalaxy( SGPropertyNode* props = nullptr );

  // Destructor
  ~SGGalaxy( void );

  // build the galaxy object
  osg::Node *build( SGPath path, double galaxy_size, simgear::SGReaderWriterOptions *options);

  // basic repainting according to sky lighting
  bool repaint( double sun_angle, double altitude_m );

};


#endif // _SG_GALAXY_HXX_
