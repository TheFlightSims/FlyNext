gui.widgets.LineEdit = {
  new: func(parent, style, cfg)
  {
    var m = gui.Widget.new(gui.widgets.LineEdit);
    m._cfg = Config.new(cfg);
    m._focus_policy = m.StrongFocus;
    m._setView( style.createWidget(parent, "line-edit", m._cfg) );
    
    m.setLayoutMinimumSize([28, 16]);
    m.setLayoutSizeHint([150, 28]);

    m._text = "";
    m._max_length = 32767;
    m._cursor = 0;
    m._selection_start = 0;
    m._selection_end = 0;

    m.context_menu = gui.Menu.new();
    m.context_menu.createItem(text: "Copy", cb: func() { m.copy(); }, shortcut: "<Ctrl>+C");
    m.context_menu.createItem(text: "Cut", cb: func() { m.cut(); }, shortcut: "<Ctrl>+X");
    m.context_menu.createItem(text: "Paste", cb: func() { m.paste(); }, shortcut: "<Ctrl>+V");
    m.context_menu.createItem(text: "Clear", cb: func() { m.clear(); }, shortcut: "<Ctrl>+D");
    m.context_menu.createItem(text: "Select all", cb: func() { m.selectAll(); }, shortcut: "<Ctrl>+A");
    m.context_menu.setCanvasItem(m);

    return m;
  },
  showContextMenu: func(e) {
    me.context_menu.show(e.screenX, e.screenY);
  },
  setText: func(text)
  {
     if (text == nil) {
       me.clear();
       return me;
     }

    me._text = utf8.substr(text, 0, me._max_length);
    me._cursor = utf8.size(me._text);
    me.clearSelection();

    if( me._view != nil )
      me._view.setText(me, me._text);
    me._trigger("text-changed");

    return me;
  },
  clear: func
  {
    me._text = "";
    me._cursor = 0;
    me.clearSelection();

    if( me._view != nil )
      me._view.setText(me, "");
    me._trigger("text-changed");
    me._onStateChange();
  },
  text: func()
  {
    return me._text;
  },
  selectedText: func() {
    return utf8.substr(me._text, me._selection_start, me._selection_end);
  },
  setMaxLength: func(len)
  {
    me._max_length = len;

    if (utf8.size(me._text) <= len) {
      return me;
    }

    me._text = utf8.substr(me._text, 0, me._max_length);
    if( me._view != nil )
      me._view.setText(me, "");
    me._trigger("text-changed");
    me.moveCursor(me._cursor);
    return me;
  },
  moveCursor: func(pos, mark = 0)
  {
    var len = utf8.size(me._text);
    me._cursor = math.max(0, math.min(pos, len));

    me._onStateChange();
    return me;
  },
  clearSelection: func {
    me._selection_start = me._selection_end = 0;
    me._onStateChange();
  },
  setSelection: func(start, end) {
    me._selection_start = start;
    me._selection_end = end;
    me._onStateChange();
  },
  getSelection: func {
    if (me._selection_start != me._selection_end) {
      return [me._selection_start, me._selection_end];
    } else {
      return nil;
    }
  },
  _getNearestCursorPos: func(x) {
    var crs = me._getNearestCursor(x);
    return me._view._text.getCursorPos(crs[0], crs[1]);
  },
  _getNearestCursor: func(x) {
    return me._view._text.getNearestCursor([x, 5]);
  },
  moveCursorX: func(x) {
    me._cursor = me._getNearestCursor(x)[1];
    me._onStateChange();
    return me;
  },
  home: func()
  {
    me.moveCursor(0);
    me.clearSelection();
  },
  end: func()
  {
    me.moveCursor(utf8.size(me._text));
    me.clearSelection();
  },
  # Insert given text after cursor (and first remove selection if set)
  insert: func(text)
  {
    var after = utf8.substr(me._text, me._cursor);
    me._text = utf8.substr(me._text, 0, me._cursor);

    # Replace selected text, insert new text and place cursor after inserted
    # text
    var remaining = me._max_length - me._cursor - utf8.size(after);
    if (remaining > 0) {
      me._text ~= utf8.substr(text, 0, remaining);
    }

    #me.clearSelection();
    me._cursor = utf8.size(me._text);

    me._text ~= after;

    if (me._view != nil) {
      me._view.setText(me, me._text);
    }
    me._trigger("text-changed");

    me._onStateChange();
    return me;
  },
  copy: func() {
    clipboard.setText(me.selectedText());
  },
  cut: func() {
    clipboard.setText(me.selectedText());
    me.removeSelection();
  },
  paste: func(mode = nil)
  {
    me.insert(clipboard.getText(mode != nil ? mode : clipboard.CLIPBOARD));
  },
  selectAll: func() {
    me.setSelection(0, utf8.size(me._text));
  },
  # Remove selected text
  removeSelection: func()
  {
    if (me._selection_start == me._selection_end) {
      me._selection_start = me._selection_end = 0;
      return me;
    }

    me._text = utf8.substr(me._text, 0, me._selection_start)
             ~ utf8.substr(me._text, me._selection_end);

    me._cursor = me._selection_start;
    me.clearSelection();

    if (me._view != nil) {
      me._view.setText(me, me._text);
    }
    me._trigger("text-changed");

    me._onStateChange();
    return me
  },
  # Remove selection or if nothing is selected the character before the cursor
  backspace: func()
  {
    if (me._selection_start == me._selection_end) {
      if (me._cursor == 0) {
        # Before first character...
        return me;
      }
      me._selection_start = me._cursor - 1;
      me._selection_end = me._cursor;
    }

    me.removeSelection();
    return me;
  },
  # Remove selection or if nothing is selected the character after the cursor
  delete: func()
  {
    if (me._selection_start == me._selection_end) {
      if (me._cursor == utf8.size(me._text)) {
        # After last character...
        return me;
      }

      me._selection_start = me._cursor;
      me._selection_end = me._cursor + 1;
    }

    me.removeSelection();
    return me;
  },
# protected:
  _setView: func(view)
  {
    call(gui.Widget._setView, [view], me);

    var el = view._root;
    el.addEventListener("keypress", func (e) {
      if (!e.ctrlKey and !e.altKey and !e.metaKey) {
        me.removeSelection();
        me.insert(e.key);
      }
    });
    el.addEventListener("keydown", func (e)
    {
      if( me._view == nil )
        return;

      if (e.key == "Enter") {
        me._trigger("editingFinished", {text: me.text()}); # TODO validator/etc.
      } elsif (e.key == "Backspace") {
        me.backspace();
      } elsif (e.key == "Delete") {
        me.delete();
      } elsif (e.key == "Left") {
        if (e.shiftKey) {
          if (me._selection_start == 0 and me._selection_end == 0) {
            var start = me._cursor;
            var end = me._cursor;
          } else {
            var start = me._selection_start;
            var end = me._selection_end;
          }
          if (start > 0) {
            me.setSelection(start - 1, end);
          } 
        } else {
          if (me._selection_start != 0 or me._selection_end != 0) {
            me.moveCursor(me._selection_start);
            me.clearSelection();
          } else {
            me.moveCursor(me._cursor - 1);
          }
        }
      } elsif (e.key == "Right") {
        if (e.shiftKey) {
          if (me._selection_start == 0 and me._selection_end == 0) {
            var start = me._cursor;
            var end = me._cursor;
          } else {
            var start = me._selection_start;
            var end = me._selection_end;
          }
          if (end + 1< utf8.size(me._text)) {
            me.setSelection(start, end + 1);
          } 
        } else {
          if (me._selection_end != 0 or me._selection_start != 0) {
            me.moveCursor(me._selection_end);
            me.clearSelection();
          } else {
            me.moveCursor(me._cursor + 1);
          }
        }
      } elsif (e.key == "Home") {
        me.home();
      } elsif (e.key == "End") {
        me.end();
      }
    });
    el.addEventListener("click", func(e) {
      if (e.button == 2) {
        me.showContextMenu(e);
      } elsif (e.button == 0) {
      	me.clearSelection();
      	me.moveCursorX(e.localX - view._text.getTranslation()[0]);
      }
    });
    el.addEventListener("dblclick", func(e) {
      me.selectAll();
    });
    el.addEventListener("drag", func(e) {
      var pos = me._getNearestCursor(e.localX - view._text.getTranslation()[0])[1];
      if (me._selection_start < pos and me._selection_end > pos) { # dragging within existing selection
        # TODO: implement full drag / drop support
      } elsif (me._selection_start != me._selection_end) { # existing selection, but dragging outside
        if (e.deltaX < 0) {
          me.setSelection(pos, me._selection_end);
        } elsif (e.deltaX > 0) {
          me.setSelection(me._selection_start, pos);
        }
      } else { # no existing selection, create one from drag position
        if (math.abs(e.deltaX) > 1) {
          var start = pos;
          var end = pos + math.sgn(e.deltaX);
          me.setSelection(math.min(start, end), math.max(start, end));
        }
      }
    });
  },
  del: func() {
    me.context_menu.del();
    me._view._cursor_blink_timer.stop();
  }
};
