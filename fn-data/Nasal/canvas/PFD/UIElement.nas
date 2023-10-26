# MFD UI Element - abstract class
var UIElement =
{
  new : func (name, value)
  {
    var obj = {
      parents : [ UIElement ],
      _name : name,
      _edit : 0,
      _value : value,
    };

    return obj;
  },

  getName : func() { return me._name; },
  setValue : func(value) { me._value = value; },
  getValue : func() { return me._value; },
  highlightElement : func() { },
  unhighlightElement : func() { },
  isEditable : func () { return 0; },
  isInEdit : func() { return me._edit; },
  enterElement : func() { me._edit = 0; return me._value; },
  clearElement : func() { me._edit = 0; },
  editElement : func()  { me._edit = 1; },
  setVisible : func(vis) { },
  incrSmall : func(value) { },
  incrLarge : func(value) { },
};
