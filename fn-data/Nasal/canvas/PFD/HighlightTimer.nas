# Timer used for highlight UI elements

var HighlightTimer = {
  _elementList : {},
  _highlightTimer : nil,
  _timerPeriod : 0.5,

  # Start highlighting an element for period time.  Use -1 period argument to
  # highlight until explicitly stopped by a call to stopHighlight.
  startHighlight : func(element, period) {
    me._elementList[element.getName()] = { Element: element, FlashCount : int(period / me._timerPeriod) };

    if (me._highlightTimer == nil) {
      me._highlightTimer = maketimer(me._timerPeriod, me, me.flashElements);
      me._highlightTimer.singleShot = 0;
    }

    if (me._highlightTimer.isRunning == 0) {
      me._highlightTimer.restart(me._timerPeriod);
    }
  },

  stopHighlight : func(element) {
    # Set the flashcount to 0 so that it is unhighlighted below.
    if (me._elementList[element.getName()] != nil) me._elementList[element.getName()].FlashCount = 0;
    #delete(me._elementList, element.getName());
  },

  flashElements : func() {
    foreach (var element_name; keys(me._elementList)) {
      if (me._elementList[element_name] == nil) continue;
      var element = me._elementList[element_name].Element;
      var flashCount = me._elementList[element_name].FlashCount;

      if (flashCount == 0) {
        # Calling unhighlightElement will also stop the timer, as it calls stopHighlight, above
        if (element.isHighlighted() == 1) element.unhighlightElement();
      } else {
        me._elementList[element_name].FlashCount = flashCount - 1;
        element._flashElement();
      }
    }

    if (size(me._elementList) == 0) me._highlightTimer.stop();
  },
};
