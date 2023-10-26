// VectorMath - class for vector calculations
// Written by Keith Paterson
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
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301, USA.

#include <simgear/debug/logstream.hxx>
#include <simgear/math/SGGeod.hxx>

#include "VectorMath.hxx"

std::array<double, 2> VectorMath::innerTangentsAngle( SGGeod m1, SGGeod m2, double r1, double r2) {
  std::array<double, 2> ret;
  double hypothenuse = SGGeodesy::distanceM(m1, m2);
  if (hypothenuse <= r1 + r2) {
      SG_LOG(SG_AI, SG_WARN, "innerTangentsAngle turn circles too near");
  }
  double opposite = r1 + r2;
  double angle = asin(opposite/hypothenuse) * SG_RADIANS_TO_DEGREES;
  double crs;
  if (r1>r2) {
     crs = SGGeodesy::courseDeg(m2, m1);
  } else {
     crs = SGGeodesy::courseDeg(m1, m2);
  }
  ret[0] = SGMiscd::normalizePeriodic(0, 360, crs - angle);
  ret[1] = SGMiscd::normalizePeriodic(0, 360, crs + angle);
  return ret;
}

double VectorMath::innerTangentsLength( SGGeod m1, SGGeod m2, double r1, double r2) {
  double hypothenuse = SGGeodesy::distanceM(m1, m2);
  if (hypothenuse <= r1 + r2) {
      SG_LOG(SG_AI, SG_WARN, "innerTangentsLength turn circles too near");
  }

  double opposite = r1 + r2;
  double angle = asin(opposite/hypothenuse) * SG_RADIANS_TO_DEGREES;
  double crs;
  if (r1>r2) {
     crs = SGGeodesy::courseDeg(m2, m1);
  } else {
     crs = SGGeodesy::courseDeg(m1, m2);
  }
  double angle1 = SGMiscd::normalizePeriodic(0, 360, crs - angle + 90);
  double angle2 = SGMiscd::normalizePeriodic(0, 360, crs - angle - 90);
  SGGeod p1 = SGGeodesy::direct(m1, angle1, r1);
  SGGeod p2 = SGGeodesy::direct(m2, angle2, r2);

  return SGGeodesy::distanceM(p1, p2);
}

std::array<double, 2> VectorMath::outerTangentsAngle( SGGeod m1, SGGeod m2, double r1, double r2) {
  std::array<double, 2> ret;
  double hypothenuse = SGGeodesy::distanceM(m1, m2);
  double radiusDiff = abs(r1 - r2);
  double beta = atan2( radiusDiff, hypothenuse ) * SG_RADIANS_TO_DEGREES;
  double gamma = SGGeodesy::courseDeg(m1, m2);
  ret[0] = SGMiscd::normalizePeriodic(0, 360, gamma - beta);
  ret[1] = SGMiscd::normalizePeriodic(0, 360, gamma + beta);
  return ret;
}

double VectorMath::outerTangentsLength( SGGeod m1, SGGeod m2, double r1, double r2) {
  double hypothenuse = SGGeodesy::distanceM(m1, m2);
  double radiusDiff = abs(r1 - r2);
  double dist = sqrt(pow(hypothenuse,2)-pow(radiusDiff,2));
  return dist;
}
