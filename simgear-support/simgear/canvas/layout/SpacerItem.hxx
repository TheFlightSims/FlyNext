///@file
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

#ifndef SG_CANVAS_SPACER_ITEM_HXX_
#define SG_CANVAS_SPACER_ITEM_HXX_

#include "LayoutItem.hxx"

namespace simgear
{
namespace canvas
{
  /**
   * Element for providing blank space in a layout.
   */
  class SpacerItem:
    public LayoutItem
  {
    public:
      SpacerItem( const SGVec2i& size = SGVec2i(0, 0),
                  const SGVec2i& max_size = MAX_SIZE );

  };

using SpacerItemRef = SGSharedPtr<SpacerItem> ;

} // namespace canvas
} // namespace simgear

#endif /* SG_CANVAS_SPACER_ITEM_HXX_ */
