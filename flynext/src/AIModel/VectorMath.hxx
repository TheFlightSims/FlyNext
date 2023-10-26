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

#pragma once

#include <array>

class SGGeod;

class VectorMath {
  public:
  /**Angles of inner tangent between two circles.*/
  static std::array<double, 2> innerTangentsAngle( SGGeod m1, SGGeod m2, double r1, double r2);
  /**Length of inner tangent between two circles.*/
  static double innerTangentsLength( SGGeod m1, SGGeod m2, double r1, double r2);
  /**Angles of outer tangent between two circles normalized to 0-360*/
  static std::array<double, 2> outerTangentsAngle( SGGeod m1, SGGeod m2, double r1, double r2);
  /**Length of outer tangent between two circles.*/
  static double outerTangentsLength( SGGeod m1, SGGeod m2, double r1, double r2);
};
