// Copyright (C) 2023 Fernando García Liñán
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <osg/Matrixd>

namespace simgear {

/**
 * @brief Utility functions for manipulating projection matrices.
 *
 * They allow transparent handling of both standard OpenGL and reverse depth
 * projection matrices. It is recommended to always use these functions to
 * obtain a projection matrix and not OSG's own functions for consistent
 * behaviour.
 *
 * Based on osgEarth's handling of projection matrices and some math borrowed
 * from GLM (OpenGL Mathematics).
 */
namespace ProjectionMatrix {

enum Type {
    STANDARD,
    REVERSE_DEPTH_ZO,
    REVERSE_DEPTH_NO
};

bool isOrtho(const osg::Matrixd &m);

bool isPerspective(const osg::Matrixd &m);

Type getType(const osg::Matrixd &m);

void makePerspective(osg::Matrixd &m,
                     double vfov, double aspect, double near, double far,
                     Type type = STANDARD);

void makeFrustum(osg::Matrixd &m,
                 double left, double right,
                 double bottom, double top,
                 double near, double far,
                 Type type = STANDARD);

void makeOrtho(osg::Matrixd &m,
               double left, double right,
               double bottom, double top,
               double near, double far,
               Type type = STANDARD);

bool getFrustum(const osg::Matrixd &m,
                double &left, double &right,
                double &bottom, double &top,
                double &near, double &far);

bool getOrtho(const osg::Matrixd &m,
              double &left, double &right,
              double &bottom, double &top,
              double &near, double &far);

/**
 * Given a projection matrix, return a new one with the same frustum sides and
 * new near/far planes.
 */
void clampNearFarPlanes(osg::Matrixd &old_proj, double near, double far,
                        osg::Matrixd &new_proj);

} // namespace ProjectionMatrix
} // namespace simgear
