# UIGroup.nas.  A group of UI Elements that can be scrolled through
var GroupElement =
{

new : func (pageName, svg, elementNames, displaysize, highlightElement, arrow=0, scrollTroughElement=nil, scrollThumbElement=nil, scrollHeight=0, style=nil)
{
  var obj = {
    parents : [ GroupElement ],
    _pageName : pageName,
    _svg : svg,
    _style : style,
    _scrollTroughElement : nil,
    _scrollThumbElement : nil,
    _scrollBaseTransform : nil,

    # A hash mapping keys to the element name prefix of an SVG element
    _elementNames : elementNames,

    # The size of the group.  For each of the ._elementNames hash values there
    # must be an SVG Element [pageName][elementName]{0...(displaysize-1)}
    _size : displaysize,

    # ElementName to be highlighted.  Must be an hash value from ._elementNames
    _highlightElement : highlightElement,

    # Whether this is an arrow'd list.  If so then highlightElement will be
    # hidden/shown for highlighting purposes.
    _arrow : arrow,

    # Length of the scroll bar.
    _scrollHeight : scrollHeight,

    # List of values to display
    _values : [],

    # List of SVG elements to display the values
    _elements : [],

    # Cursor index into the _values array
    _crsrIndex : 0,

    # Whether the CRSR is enabled
    _crsrEnabled : 0,

    # Page index - which _values index element[0] refers to.  The currently
    # selected _element has index (_crsrIndex - _pageIndex)
    _pageIndex : 0,
  };

  # Optional scroll bar elements, consisting of the Thumb and the Trough *,
  # which will be used to display the scroll position.
  # * Yes, these are the terms of art for the elements.
  assert(((scrollTroughElement == nil) and (scrollThumbElement == nil)) or
         ((scrollTroughElement != nil) and (scrollThumbElement != nil)),
         "Both the scroll trough element and the scroll thumb element must be defined, or neither");

  # Verify that all values exist.
  for (var i = 0; i < displaysize; i = i + 1) {
    foreach (var element; elementNames) {
      var elementName = obj._pageName ~ element ~ i;
      assert(obj._svg.getElementById(elementName) != nil, "Unable to find element " ~ elementName);
    }
  }

  if (scrollTroughElement != nil) {
    obj._scrollTroughElement = svg.getElementById(pageName ~ scrollTroughElement);
    assert(obj._scrollTroughElement != nil, "Unable to find scroll element " ~ pageName ~ scrollTroughElement);
  }
  if (scrollThumbElement != nil) {
    obj._scrollThumbElement = svg.getElementById(pageName ~ scrollThumbElement);
    assert(obj._scrollThumbElement != nil, "Unable to find scroll element " ~ pageName ~ scrollThumbElement);
    obj._scrollBaseTransform = obj._scrollThumbElement.getTranslation();
  }

  if (style == nil) obj._style = PFD.DefaultStyle;

  for (var i = 0; i < displaysize; i = i + 1) {
    if (obj._arrow == 1) {
      append(obj._elements, PFD.HighlightElement.new(pageName, svg, highlightElement ~ i, i, obj._style));
    } else {
      append(obj._elements, PFD.TextElement.new(pageName, svg, highlightElement ~ i, i, obj._style));
    }
  }

  return obj;
},

# Set the values of the group. values_array is an array of hashes, each of which
# has keys that match those of ._elementNames
setValues : func (values_array) {
  me._values = values_array;
  me._pageIndex = 0;
  me._crsrIndex = 0;

  if (size(me._values) > me._size) {
    # Number of elements exceeds our ability to display them, so enable
    # the scroll bar.
    if (me._scrollThumbElement  != nil) me._scrollThumbElement.setVisible(1);
    if (me._scrollTroughElement != nil) me._scrollTroughElement.setVisible(1);
  } else {
    # There is no scrolling to do, so hide the scrollbar.
    if (me._scrollThumbElement  != nil) me._scrollThumbElement.setVisible(0);
    if (me._scrollTroughElement != nil) me._scrollTroughElement.setVisible(0);
  }

  me.displayGroup();
},

displayGroup : func () {

  # The _crsrIndex element should be displayed as close to the middle of the
  # group as possible. So as the user scrolls the list appears to move around
  # a static cursor position.
  #
  # The exceptions to this is as the _crsrIndex approaches the ends of the list.
  # In these cases, we let the cursor move to the top or bottom of the list.

  # Determine the middle element
  var middle_element_index = math.ceil(me._size / 2);
  me._pageIndex = me._crsrIndex - middle_element_index;

  if ((size(me._values) <= me._size) or (me._crsrIndex < middle_element_index)) {
    # Start of list or the list is too short to require scrolling
    me._pageIndex = 0;
  } else if (me._crsrIndex > (size(me._values) - middle_element_index - 1)) {
    # End of list
    me._pageIndex = size(me._values) - me._size;
  }

  for (var i = 0; i < me._size; i = i + 1) {
    if (me._pageIndex + i < size(me._values)) {
      var value = me._values[me._pageIndex + i];
      foreach (var k; keys(value)) {
        if (k == me._highlightElement) {
          me._elements[i].unhighlightElement();

          if (me._arrow) {
            # If we're using a HighlightElement, then we only show the element
            # the cursor is on.
            if (i + me._pageIndex  == me._crsrIndex) {
              me._elements[i].setVisible(1);
              if (me._crsrEnabled) me._elements[i].highlightElement();
            } else {
              me._elements[i].setVisible(0);
            }

          } else {
            me._elements[i].setVisible(1);
            if (me._crsrEnabled and (i + me._pageIndex == me._crsrIndex))
              me._elements[i].highlightElement();
          }

          me._elements[i].setValue(value[k]);
        } else {
          var name = me._pageName ~ k ~ i;
          var element  = me._svg.getElementById(name);
          assert(element != nil, "Unable to find element " ~ name);
          element.setVisible(1);
          element.setText(value[k]);
        }
      }
    } else {
      # We've gone off the end of the values list, so hide any further values.
      foreach (var k; me._elementNames) {
        if (k == me._highlightElement) {
          me._elements[i].setVisible(0);
          me._elements[i].setValue("");
        } else {
          var name = me._pageName ~ k ~ i;
          var element  = me._svg.getElementById(name);
          assert(element != nil, "Unable to find element " ~ name);
          element.setVisible(0);
          element.setText("");
        }
      }
    }
  }

  if ((me._scrollThumbElement != nil) and (me._size < size(me._values))) {
    # Shift the scrollbar if it's relevant
    me._scrollThumbElement.setTranslation([
      me._scrollBaseTransform[0],
      me._scrollBaseTransform[1] + me._scrollHeight * (me._crsrIndex / (size(me._values) -1))
    ]);
  }
},

# Methods to add dynamic elements to the group.  Must be called in the
# scroll order, as they are simply appended to the end of the list of elements!
addHighlightElement : func(name, value) {
  append(me._elements, HighlightElement.new(me._pageName, me._svg, name, value));
},
addTextElement : func(name, value) {
  append(me._elements, TextElement.new(me._pageName, me._svg, name, value));
},

showCRSR : func() {
  if (size(me._values) == 0) return;
  me._crsrEnabled = 1;
  me._elements[me._crsrIndex - me._pageIndex].highlightElement();
},
hideCRSR : func() {
  if (me._crsrEnabled == 0) return;
  me._elements[me._crsrIndex - me._pageIndex].unhighlightElement();

  # If we're using a HighlightElement, then we need to make the cursor position visible
  if (me._arrow) me._elements[me._crsrIndex - me._pageIndex].setVisible(1);
  me._crsrEnabled = 0;
},
setCRSR : func(index) {
  me._crsrIndex = math.min(index, size(me._values) -1);
  me._crsrIndex = math.max(0, me._crsrIndex);
},
getCRSR : func() {
  return me._crsrIndex;
},
getCursorElementName : func() {
  if (me._crsrEnabled == -1) return nil;
  return me._elements[me._crsrIndex - me._pageIndex].name;
},
isCursorOnDataEntryElement : func() {
  if (me._crsrEnabled == -1) return 0;
  return isa(me._elements[me._crsrIndex - me._pageIndex], DataEntryElement);
},
enterElement : func() {
  if (me._crsrEnabled == 0) return;
  return me._elements[me._crsrIndex - me._pageIndex].enterElement();
},
getValue : func() {
  if (me._crsrEnabled == -1) return nil;
  return me._elements[me._crsrIndex - me._pageIndex].getValue();
},
setValue : func(idx, key, value) {
  me._values[idx][key] = value;
},
clearElement : func() {
  if (me._crsrEnabled == 0) return;
  me._elements[me._crsrIndex - me._pageIndex].clearElement();
},
incrSmall : func(value) {
  if (me._crsrEnabled == 0) return;

  var incr_or_decr = (value > 0) ? 1 : -1;
  if (me._elements[me._crsrIndex - me._pageIndex].isInEdit()) {
    # We're editing, so pass to the element.
    me._elements[me._crsrIndex - me._pageIndex].incrSmall(val);
  } else {
    # Move to next selection element
    me._crsrIndex = me._crsrIndex + incr_or_decr;
    if (me._crsrIndex <  0               ) me._crsrIndex = 0;
    if (me._crsrIndex == size(me._values)) me._crsrIndex = size(me._values) -1;
    me.displayGroup();
  }
},
incrLarge : func(val) {
  if (me._crsrEnabled == 0) return;
  var incr_or_decr = (val > 0) ? 1 : -1;
  if (me._elements[me._crsrIndex - me._pageIndex].isInEdit()) {
    # We're editing, so pass to the element.
    me._elements[me._crsrIndex - me._pageIndex].incrLarge(val);
  } else {
    # Move to next selection element
    me._crsrIndex = me._crsrIndex + incr_or_decr;
    if (me._crsrIndex <  0               ) me._crsrIndex = 0;
    if (me._crsrIndex == size(me._values)) me._crsrIndex = size(me._values) -1;
    me.displayGroup();
  }
},
};
