// Copyright (C) 2023 Fernando García Liñán
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "ProjectionMatrix.hxx"

namespace simgear {
namespace ProjectionMatrix {

bool
isOrtho(const osg::Matrixd &m)
{
    return !m.isIdentity() && m(3, 3) > 0.0;
}

bool
isPerspective(const osg::Matrixd &m)
{
    return m(3, 3) == 0.0;
}

Type
getType(const osg::Matrixd &m)
{
    if (m(2,2) > 0.0)
        return REVERSE_DEPTH_ZO;
    else
        return STANDARD;
}

void
makePerspective(osg::Matrixd &m,
                double vfov, double aspect, double near, double far,
                Type type)
{
    if (type == REVERSE_DEPTH_ZO) {
        double f = 1.0 / std::tan(osg::DegreesToRadians(vfov * 0.5));
        m.set(f / aspect, 0.0, 0.0, 0.0,
              0.0, f, 0.0, 0.0,
              0.0, 0.0, near / (far - near), -1.0,
              0.0, 0.0, -(far * near) / (near - far), 0.0);
    } else if (type == REVERSE_DEPTH_NO) {
        m.makePerspective(vfov, aspect, far, near);
    } else {
        m.makePerspective(vfov, aspect, near, far);
    }
}

void
makeFrustum(osg::Matrixd &m,
            double left, double right,
            double bottom, double top,
            double near, double far,
            Type type)
{
    if (type == REVERSE_DEPTH_ZO) {
        m.set(
            2.0 * near / (right - left), 0.0, 0.0, 0.0,
            0.0, 2.0 * near / (top - bottom), 0.0, 0.0,
            (right + left) / (right - left), (top + bottom) / (top - bottom), near / (far - near), -1.0,
            0.0, 0.0, far * near / (far - near), 0.0);
    } else if (type == REVERSE_DEPTH_NO) {
        m.makeFrustum(left, right, bottom, top, far, near);
    } else {
        m.makeFrustum(left, right, bottom, top, near, far);
    }
}

void
makeOrtho(osg::Matrixd &m,
          double left, double right,
          double bottom, double top,
          double near, double far,
          Type type)
{
    if (type == REVERSE_DEPTH_ZO) {
        double tx = -(right + left) / (right - left);
        double ty = -(top + bottom) / (top - bottom);
        double tz = far / (far - near);
        m.set(2.0 / (right - left), 0.0, 0.0, 0.0,
              0.0, 2.0 / (top - bottom), 0.0, 0.0,
              0.0, 0.0, 1.0 / (far - near), 0.0,
              tx, ty, tz, 1.0);
    } else if (type == REVERSE_DEPTH_NO) {
        m.makeOrtho(left, right, bottom, top, far, near);
    } else {
        m.makeOrtho(left, right, bottom, top, near, far);
    }
}

bool
getFrustum(const osg::Matrixd &m,
           double &left, double &right,
           double &bottom, double &top,
           double &near, double &far)
{
    if (!isPerspective(m))
        return false;

    Type type = getType(m);
    if (type == REVERSE_DEPTH_ZO) {
        near   = m(3,2) / (1.0 + m(2,2));
        far    = m(3,2) / m(2,2);
        left   = near * (m(2,0) - 1.0) / m(0,0);
        right  = near * (1.0 + m(2,0)) / m(0,0);
        top    = near * (1.0 + m(2,1)) / m(1,1);
        bottom = near * (m(2,1) - 1.0) / m(1,1);
    } else {
        m.getFrustum(left, right, bottom, top, near, far);
        if (near > far) {
            // REVERSED_DEPTH_NO
            double tmp = far;
            far = near;
            near = tmp;
        }
    }

    return true;
}

bool
getOrtho(const osg::Matrixd &m,
         double &left, double &right,
         double &bottom, double &top,
         double &near, double &far)
{
    if (!isOrtho(m))
        return false;

    Type type = getType(m);
    if (type == REVERSE_DEPTH_ZO) {
        double c = 1.0 / m(2,2);
        far    = m(3,2) * c;
        near   = far - c;
        left   = -(1.0 + m(3,0)) / m(0,0);
        right  =  (1.0 - m(3,0)) / m(0,0);
        bottom = -(1.0 + m(3,1)) / m(1,1);
        top    =  (1.0 - m(3,1)) / m(1,1);
    } else {
        m.getOrtho(left, right, bottom, top, near, far);
        if (near > far) {
            // REVERSED_DEPTH_NO
            double tmp = far;
            far = near;
            near = tmp;
        }
    }

    return true;
}

void
clampNearFarPlanes(osg::Matrixd &old_proj, double near, double far,
                   osg::Matrixd &new_proj)
{
    new_proj = old_proj;

    Type type = getType(old_proj);
    if (type != STANDARD) {
        // TODO: Projection matrix clamping is only implemented for
        // standard matrices using the default OpenGL convention.
        return;
    }

    // Slightly inflate the near & far planes to avoid objects at the
    // extremes being clipped out.
    near *= 0.999;
    far  *= 1.001;

    if (isOrtho(old_proj)) {
        double e = -1.0 / (far - near);
        new_proj(2,2) = 2.0 * e;
        new_proj(3,2) = (far + near) * e;
    } else {
        double trans_near = (-near * new_proj(2,2) + new_proj(3,2)) /
            (-near * new_proj(2,3) + new_proj(3,3));
        double trans_far = (-far * new_proj(2,2) + new_proj(3,2)) /
            (-far * new_proj(2,3) + new_proj(3,3));
        double ratio = fabs(2.0 / (trans_near - trans_far));
        double center = -0.5 * (trans_near + trans_far);

        new_proj.postMult(osg::Matrixd(1.0, 0.0, 0.0, 0.0,
                                       0.0, 1.0, 0.0, 0.0,
                                       0.0, 0.0, ratio, 0.0,
                                       0.0, 0.0, center*ratio, 1.0));
    }
}

} // namespace ProjectionMatrix
} // namespace simgear
