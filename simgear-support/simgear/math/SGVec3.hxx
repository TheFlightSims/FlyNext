// Copyright (C) 2006-2009  Mathias Froehlich - Mathias.Froehlich@web.de
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

#ifndef SGVec3_H
#define SGVec3_H

#include <iosfwd>

#include <simgear/math/SGVec2.hxx>
#include <simgear/math/SGGeodesy.hxx>
#include <simgear/math/simd.hxx>

/// 3D Vector Class
template<typename T>
class SGVec3 {
public:
  typedef T value_type;

#ifdef __GNUC__
// Avoid "_data not initialized" warnings (see comment below).
#   pragma GCC diagnostic ignored "-Wuninitialized"
#endif

  /// Default constructor. Does not initialize at all.
  /// If you need them zero initialized, use SGVec3::zeros()
  SGVec3(void)
  {
    /// Initialize with nans in the debug build, that will guarantee to have
    /// a fast uninitialized default constructor in the release but shows up
    /// uninitialized values in the debug build very fast ...
#ifndef NDEBUG
    for (unsigned i = 0; i < 3; ++i)
      data()[i] = SGLimits<T>::quiet_NaN();
#endif
  }

#ifdef __GNUC__
  // Restore warning settings.
#   pragma GCC diagnostic warning "-Wuninitialized"
#endif

  /// Constructor. Initialize by the given values
  SGVec3(T x, T y, T z)
  { _data = simd4_t<T,3>(x, y, z); }
  /// Constructor. Initialize by the content of a plain array,
  /// make sure it has at least 3 elements
  explicit SGVec3(const T* d)
  { _data = d ? simd4_t<T,3>(d) : simd4_t<T,3>(T(0)); }
  template<typename S>
  explicit SGVec3(const SGVec3<S>& d)
  { data()[0] = d[0]; data()[1] = d[1]; data()[2] = d[2]; }
  explicit SGVec3(const SGVec2<T>& v2, const T& v3 = 0)
  { _data = v2.simd2(); data()[2] = v3; }

  /// Access by index, the index is unchecked
  const T& operator()(unsigned i) const
  { return data()[i]; }
  /// Access by index, the index is unchecked
  T& operator()(unsigned i)
  { return data()[i]; }

  /// Access raw data by index, the index is unchecked
  const T& operator[](unsigned i) const
  { return data()[i]; }
  /// Access raw data by index, the index is unchecked
  T& operator[](unsigned i)
  { return data()[i]; }

  /// Access the x component
  const T& x(void) const
  { return data()[0]; }
  /// Access the x component
  T& x(void)
  { return data()[0]; }
  /// Access the y component
  const T& y(void) const
  { return data()[1]; }
  /// Access the y component
  T& y(void)
  { return data()[1]; }
  /// Access the z component
  const T& z(void) const
  { return data()[2]; }
  /// Access the z component
  T& z(void)
  { return data()[2]; }

  /// Readonly raw storage interface
  const T (&data(void) const)[3]
  { return _data.ptr(); }
  /// Readonly raw storage interface
  T (&data(void))[3]
  { return _data.ptr(); }
  /// Readonly raw storage interface
  const simd4_t<T,3> &simd3(void) const
  { return _data; }
  /// Readonly raw storage interface
  simd4_t<T,3> &simd3(void)
  { return _data; }

  /// Inplace addition
  SGVec3& operator+=(const SGVec3& v)
  { _data += v.simd3(); return *this; }
  /// Inplace subtraction
  SGVec3& operator-=(const SGVec3& v)
  { _data -= v.simd3(); return *this; }
  /// Inplace scalar multiplication
  template<typename S>
  SGVec3& operator*=(S s)
  { _data *= s; return *this; }
  /// Inplace scalar multiplication by 1/s
  template<typename S>
  SGVec3& operator/=(S s)
  { _data*=(1/T(s)); return *this; }

  /// Return an all zero vector
  static SGVec3 zeros(void)
  { return SGVec3(0, 0, 0); }
  /// Return unit vectors
  static SGVec3 e1(void)
  { return SGVec3(1, 0, 0); }
  static SGVec3 e2(void)
  { return SGVec3(0, 1, 0); }
  static SGVec3 e3(void)
  { return SGVec3(0, 0, 1); }

  /// Constructor. Initialize by a geodetic coordinate
  /// Note that this conversion is relatively expensive to compute
  static SGVec3 fromGeod(const SGGeod& geod);
  /// Constructor. Initialize by a geocentric coordinate
  /// Note that this conversion is relatively expensive to compute
  static SGVec3 fromGeoc(const SGGeoc& geoc);

private:
  simd4_t<T,3> _data;
  
};

template<>
inline
SGVec3<double>
SGVec3<double>::fromGeod(const SGGeod& geod)
{
  SGVec3<double> cart;
  SGGeodesy::SGGeodToCart(geod, cart);
  return cart;
}

template<>
inline
SGVec3<float>
SGVec3<float>::fromGeod(const SGGeod& geod)
{
  SGVec3<double> cart;
  SGGeodesy::SGGeodToCart(geod, cart);
  return SGVec3<float>(cart(0), cart(1), cart(2));
}

template<>
inline
SGVec3<double>
SGVec3<double>::fromGeoc(const SGGeoc& geoc)
{
  SGVec3<double> cart;
  SGGeodesy::SGGeocToCart(geoc, cart);
  return cart;
}

template<>
inline
SGVec3<float>
SGVec3<float>::fromGeoc(const SGGeoc& geoc)
{
  SGVec3<double> cart;
  SGGeodesy::SGGeocToCart(geoc, cart);
  return SGVec3<float>(cart(0), cart(1), cart(2));
}

/// Unary +, do nothing ...
template<typename T>
inline
const SGVec3<T>&
operator+(const SGVec3<T>& v)
{ return v; }

/// Unary -, do nearly nothing
template<typename T>
inline
SGVec3<T>
operator-(SGVec3<T> v)
{ v *= -1; return v; }

/// Binary +
template<typename T>
inline
SGVec3<T>
operator+(SGVec3<T> v1, const SGVec3<T>& v2)
{ v1.simd3() += v2.simd3(); return v1; }

/// Binary -
template<typename T>
inline
SGVec3<T>
operator-(SGVec3<T> v1, const SGVec3<T>& v2)
{ v1.simd3() -= v2.simd3(); return v1; }

/// Scalar multiplication
template<typename S, typename T>
inline
SGVec3<T>
operator*(S s, SGVec3<T> v)
{ v.simd3() *= s; return v; }

/// Scalar multiplication
template<typename S, typename T>
inline
SGVec3<T>
operator*(SGVec3<T> v, S s)
{ v.simd3() *= s; return v; }

/// multiplication as a multiplicator, that is assume that the first vector
/// represents a 3x3 diagonal matrix with the diagonal elements in the vector.
/// Then the result is the product of that matrix times the second vector.
template<typename T>
inline
SGVec3<T>
mult(SGVec3<T> v1, const SGVec3<T>& v2)
{ v1.simd3() *= v2.simd3(); return v1; }

/// component wise min
template<typename T>
inline
SGVec3<T>
min(SGVec3<T> v1, const SGVec3<T>& v2)
{ v1.simd3() = simd4::min(v1.simd3(), v2.simd3()); return v1; }
template<typename S, typename T>
inline
SGVec3<T>
min(SGVec3<T> v, S s)
{ v.simd3() = simd4::min(v.simd3(), simd4_t<T,3>(s)); return v; }
template<typename S, typename T>
inline
SGVec3<T>
min(S s, SGVec3<T> v)
{ v.simd3() = simd4::min(v.simd3(), simd4_t<T,3>(s)); return v; }

/// component wise max
template<typename T>
inline
SGVec3<T>
max(SGVec3<T> v1, const SGVec3<T>& v2)
{ v1.simd3() = simd4::max(v1.simd3(), v2.simd3()); return v1; }
template<typename S, typename T>
inline
SGVec3<T>
max(SGVec3<T> v, S s)
{ v.simd3() = simd4::max(v.simd3(), simd4_t<T,3>(s)); return v; }
template<typename S, typename T>
inline
SGVec3<T>
max(S s, SGVec3<T> v)
{ v.simd3() = simd4::max(v.simd3(), simd4_t<T,3>(s)); return v; }

/// Add two vectors taking care of (integer) overflows. The values are limited
/// to the respective minimum and maximum values.
template<class T>
SGVec3<T> addClipOverflow(SGVec3<T> const& lhs, SGVec3<T> const& rhs)
{
  return SGVec3<T>(
    SGMisc<T>::addClipOverflow(lhs.x(), rhs.x()),
    SGMisc<T>::addClipOverflow(lhs.y(), rhs.y()),
    SGMisc<T>::addClipOverflow(lhs.z(), rhs.z())
  );
}

/// Scalar dot product
template<typename T>
inline
T
dot(const SGVec3<T>& v1, const SGVec3<T>& v2)
{ return simd4::dot(v1.simd3(), v2.simd3()); }

/// The euclidean norm of the vector, that is what most people call length
template<typename T>
inline
T
norm(const SGVec3<T>& v)
{ return simd4::magnitude(v.simd3()); }

/// The squared euclidean norm of the vector
/// Comparing two squared values prevents two computionally heavy sqrt calls.
template<typename T>
inline
T
norm2(const SGVec3<T>& v)
{ return simd4::magnitude2(v.simd3()); }


/// The euclidean norm of the vector, that is what most people call length
template<typename T>
inline
T
length(const SGVec3<T>& v)
{ return simd4::magnitude(v.simd3()); }

/// The 1-norm of the vector, this one is the fastest length function we
/// can implement on modern cpu's
template<typename T>
inline
T
norm1(SGVec3<T> v)
{ v.simd3() = simd4::abs(v.simd3()); return (v(0)+v(1)+v(2)); }

/// The inf-norm of the vector
template<typename T>
inline
T
normI(SGVec3<T> v)
{
  v.simd3() = simd4::abs(v.simd3());
  return SGMisc<T>::max(v(0), v(1), v(2));
}

/// Vector cross product
template<typename T>
inline
SGVec3<T>
cross(SGVec3<T> v1, const SGVec3<T>& v2)
{ v1.simd3() = simd4::cross(v1.simd3(), v2.simd3()); return v1; }

/// return any normalized vector perpendicular to v
template<typename T>
inline
SGVec3<T>
perpendicular(const SGVec3<T>& v)
{
  T absv1 = fabs(v(0));
  T absv2 = fabs(v(1));
  T absv3 = fabs(v(2));

  if (absv2 < absv1 && absv3 < absv1) {
    T quot = v(1)/v(0);
    return (1/sqrt(1+quot*quot))*SGVec3<T>(quot, -1, 0);
  } else if (absv3 < absv2) {
    T quot = v(2)/v(1);
    return (1/sqrt(1+quot*quot))*SGVec3<T>(0, quot, -1);
  } else if (SGLimits<T>::min() < absv3) {
    T quot = v(0)/v(2);
    return (1/sqrt(1+quot*quot))*SGVec3<T>(-1, 0, quot);
  } else {
    // the all zero case ...
    return SGVec3<T>(0, 0, 0);
  }
}

/// Construct a unit vector in the given direction.
/// or the zero vector if the input vector is zero.
template<typename T>
inline
SGVec3<T>
normalize(const SGVec3<T>& v)
{
  T normv = norm(v);
  if (normv <= SGLimits<T>::min())
    return SGVec3<T>::zeros();
  return (1/normv)*v;
}

/// Return true if exactly the same
template<typename T>
inline
bool
operator==(const SGVec3<T>& v1, const SGVec3<T>& v2)
{ return v1(0) == v2(0) && v1(1) == v2(1) && v1(2) == v2(2); }

/// Return true if not exactly the same
template<typename T>
inline
bool
operator!=(const SGVec3<T>& v1, const SGVec3<T>& v2)
{ return ! (v1 == v2); }

/// Return true if smaller, good for putting that into a std::map
template<typename T>
inline
bool
operator<(const SGVec3<T>& v1, const SGVec3<T>& v2)
{
  if (v1(0) < v2(0)) return true;
  else if (v2(0) < v1(0)) return false;
  else if (v1(1) < v2(1)) return true;
  else if (v2(1) < v1(1)) return false;
  else return (v1(2) < v2(2));
}

template<typename T>
inline
bool
operator<=(const SGVec3<T>& v1, const SGVec3<T>& v2)
{
  if (v1(0) < v2(0)) return true;
  else if (v2(0) < v1(0)) return false;
  else if (v1(1) < v2(1)) return true;
  else if (v2(1) < v1(1)) return false;
  else return (v1(2) <= v2(2));
}

template<typename T>
inline
bool
operator>(const SGVec3<T>& v1, const SGVec3<T>& v2)
{ return operator<(v2, v1); }

template<typename T>
inline
bool
operator>=(const SGVec3<T>& v1, const SGVec3<T>& v2)
{ return operator<=(v2, v1); }

/// Return true if equal to the relative tolerance tol
template<typename T>
inline
bool
equivalent(const SGVec3<T>& v1, const SGVec3<T>& v2, T rtol, T atol)
{ return norm1(v1 - v2) < rtol*(norm1(v1) + norm1(v2)) + atol; }

/// Return true if equal to the relative tolerance tol
template<typename T>
inline
bool
equivalent(const SGVec3<T>& v1, const SGVec3<T>& v2, T rtol)
{ return norm1(v1 - v2) < rtol*(norm1(v1) + norm1(v2)); }

/// Return true if about equal to roundoff of the underlying type
template<typename T>
inline
bool
equivalent(const SGVec3<T>& v1, const SGVec3<T>& v2)
{
  T tol = 100*SGLimits<T>::epsilon();
  return equivalent(v1, v2, tol, tol);
}

/// The euclidean distance of the two vectors
template<typename T>
inline
T
dist(const SGVec3<T>& v1, const SGVec3<T>& v2)
{ return simd4::magnitude(v1.simd3() - v2.simd3()); }

/// The squared euclidean distance of the two vectors
template<typename T>
inline
T
distSqr(SGVec3<T> v1, const SGVec3<T>& v2)
{ return simd4::magnitude2(v1.simd3() - v2.simd3()); }

// calculate the projection of u along the direction of d.
template<typename T>
inline
SGVec3<T>
projection(const SGVec3<T>& u, const SGVec3<T>& d)
{
  T denom = simd4::magnitude2(d.simd3());
  T ud = dot(u, d);
  if (SGLimits<T>::min() < denom) return u;
  else return d * (dot(u, d) / denom);
}

template<typename T>
inline
SGVec3<T>
interpolate(T tau, const SGVec3<T>& v1, const SGVec3<T>& v2)
{
  SGVec3<T> r;
  r.simd3() = simd4::interpolate(tau, v1.simd3(), v2.simd3());
  return r;
}

template<typename T>
inline
bool
isNaN(const SGVec3<T>& v)
{
  return SGMisc<T>::isNaN(v(0)) ||
    SGMisc<T>::isNaN(v(1)) || SGMisc<T>::isNaN(v(2));
}

/// Output to an ostream
template<typename char_type, typename traits_type, typename T>
inline
std::basic_ostream<char_type, traits_type>&
operator<<(std::basic_ostream<char_type, traits_type>& s, const SGVec3<T>& v)
{ return s << "[ " << v(0) << ", " << v(1) << ", " << v(2) << " ]"; }

inline
SGVec3f
toVec3f(const SGVec3d& v)
{ SGVec3f f(v); return f; }

inline
SGVec3d
toVec3d(const SGVec3f& v)
{ SGVec3d d(v); return d; }

#endif
