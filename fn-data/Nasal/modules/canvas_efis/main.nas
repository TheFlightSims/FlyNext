#
# canvas-efis loader
#
var EFIS_namespace = "_uninitalized_";

var unload = func(module) {
    globals[EFIS_namespace].DisplayUnit.unload();
    globals[EFIS_namespace].EFISCanvas.unload();
    globals[EFIS_namespace].EFIS.unload();
}

var main = func(module) {
    EFIS_namespace = module.getNamespaceName();
    io.load_nasal(module.getFilePath()~"efis-framework.nas", EFIS_namespace);
    io.load_nasal(module.getFilePath()~"eicas-message-sys.nas", EFIS_namespace);
}
