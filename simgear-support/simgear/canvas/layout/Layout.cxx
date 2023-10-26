// Basic class for canvas layouts
//
// Copyright (C) 2014  Thomas Geymayer <tomgey@gmail.com>
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
// You should have received a copy of the GNU Library General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301, USA

#include <simgear_config.h>
#include "Layout.hxx"

#include <algorithm>

#include <simgear/debug/logstream.hxx>

namespace simgear
{
namespace canvas
{

  //----------------------------------------------------------------------------
  void Layout::removeItem(const LayoutItemRef& item)
  {
    size_t i = 0;
    while( LayoutItemRef child = itemAt(i) )
    {
      if( item == child )
        return (void)takeAt(i);

      ++i;
    }
  }

  //----------------------------------------------------------------------------
  void Layout::clear()
  {
    while( itemAt(0) )
      takeAt(0);
  }

  //----------------------------------------------------------------------------
  SGRecti Layout::alignmentRect(const SGRecti& geom) const
  {
    return alignment() == AlignFill
         // Without explicit alignment (default == AlignFill) use the whole
         // available space and let the layout and its items distribute the
         // excess space.
         ? geom

         // Otherwise align according to flags.
         : LayoutItem::alignmentRect(geom);
  }

  //----------------------------------------------------------------------------
  void Layout::contentsRectChanged(const SGRecti& rect)
  {
    doLayout(rect);

    _flags &= ~LAYOUT_DIRTY;
  }


} // namespace canvas
} // namespace simgear
