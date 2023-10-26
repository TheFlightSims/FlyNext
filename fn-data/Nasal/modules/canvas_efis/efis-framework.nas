#------------------------------------------
# efis-framework.nas - Canvas EFIS framework
# author:       jsb
#------------------------------------------
var EFIS_root_node = props.getNode("/efis", 1);

io.include("display-unit.nas");
io.include("efis.nas");
io.include("efis-canvas.nas");
