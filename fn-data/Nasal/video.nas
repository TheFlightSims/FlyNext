#print("A");

var save = func()
{
  var _props = [
    "random-objects",
    "random-vegetation",
    "random-vegetation-shadows",
    "random-vegetation-normals",
    "vegetation-density",
    "random-buildings",
    "building-density",
    "point-sprites",
    "particles",
    "clouds3d-enable",
    "clouds3d-vis-range",
    "clouds3d-detail-range",
    "clouds3d-density",
    "shadows/enabled"];
  var sprop = props.globals.getNode("/sim/rendering/");
  var dprop = props.globals.getNode("/tmp/rendering/", 1);
  props.copy(sprop.getNode("shaders"), dprop.getNode("shaders", 1), 1);
  foreach (var p; _props) {
    var src = sprop.getNode(p);
    var dest = dprop.getNode(p, 1);
    var type = src.getType();
    var val = src.getValue();
    if(type == "ALIAS" or type == "NONE") return;
    elsif(type == "BOOL") dest.setBoolValue(val);
    elsif(type == "INT" or type == "LONG") dest.setIntValue(val);
    elsif(type == "FLOAT" or type == "DOUBLE") dest.setDoubleValue(val);
    else dest.setValue(val);
    dest.setAttribute(src.getAttribute());
  }

  var fg_home = getprop("/sim/fg-home");
  var renderer = getprop("/sim/rendering/gl-renderer");
  var file = renderer;
  var pos = find("x86/", renderer);
  if (pos == -1) pos = find("/", renderer);
  if (pos == -1) pos = find(" (", renderer);
  if (pos != -1) file = substr(renderer, 0, int(pos));

  var path = fg_home ~ "/Export/" ~ file ~ ".xml";
  io.write_properties( path, dprop);
  gui.popupTip("Configuration is written to:\n" ~ path, 6);
}
