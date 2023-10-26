///@file
/// A text on the Canvas
//
// Copyright (C) 2012  Thomas Geymayer <tomgey@gmail.com>
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

#ifndef CANVAS_TEXT_HXX_
#define CANVAS_TEXT_HXX_

#include "CanvasElement.hxx"
#include <osgText/Text>
#include <map>
#include <vector>

namespace simgear
{
namespace canvas
{

  class TextLine;
  class Text:
    public Element
  {
    public:
      static const std::string TYPE_NAME;
      static void staticInit();

      Text( const CanvasWeakPtr& canvas,
            const SGPropertyNode_ptr& node,
            const Style& parent_style,
            ElementWeakPtr parent = 0 );
      ~Text();

      void setText(const std::string& text);
      void setFont(const std::string& name);
      void setAlignment(const std::string& align_string);

      int heightForWidth(int w) const;
      int maxWidth() const;

      /// Number of text lines.
      size_t lineCount() const;

      /// Number of characters in @a line.
      size_t lineLength(size_t line) const;

      /**
       * @brief map a pixel location to a line,char position
       * Rounding is applied to make this work 'as expected' for
       * clicking on text, i.e clicks closer to the right edge
       * return the character to the right.
      */
      osg::Vec2i getNearestCursor(const osg::Vec2& pos) const;
      
      /**
       * @brief Map line,char location to the top-left of the
       * glyph's box.
       * 
       * @param line 
       * @param character 
       * @return osg::Vec2 : top-left of the glyph box in pixels
       */
      osg::Vec2 getCursorPos(size_t line, size_t character) const;

    protected:

      friend class TextLine;
      class TextOSG;
      osg::ref_ptr<TextOSG> _text;

      virtual osg::StateSet* getOrCreateStateSet();

  };

} // namespace canvas
} // namespace simgear

#endif /* CANVAS_TEXT_HXX_ */
