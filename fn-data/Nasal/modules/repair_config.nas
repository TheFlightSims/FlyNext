#-------------------------------------------------------------------------------
# repair_config.mod 
# This code repairs the userarchive flags for core nasal modules listed in 
# defaults.xml, they may be wrongly set in the users home directory by earlier
# versions of FlightGear
#-------------------------------------------------------------------------------
var defaults_path = getprop("/sim/fg-root")~"/defaults.xml";

var printNodeInfo = func(n) {
    print(sprintf("%-20s enabled=%s, userarchive=%s", 
        n.getName(),
        n.getNode("enabled").getValue(),
        n.getNode("enabled").getAttribute("userarchive")
    ));
}

var printConfig = func(name, cfg) {
    print("== "~name~" ==");
    foreach (var mod; cfg.getChildren()) {
        if (mod.getChild("enabled") != nil)
            printNodeInfo(mod);
    }
}

var loadDefaultsNasal = func {
    var defaults = io.readxml(defaults_path);
    if (defaults != nil) {
        defaults = defaults.getNode("PropertyList/nasal");
        foreach (var mod; defaults.getChildren()) {
            var enabled = mod.getNode("enabled",1);
            if (string.lc(enabled.getValue()) == "true") enabled.setIntValue(1);
            else enabled.setIntValue(0);
            enabled.setAttribute("userarchive",
                (mod.getNode("enabled/___userarchive",1).getValue() == "y")
            );
        }
    }
    return defaults;
}

var compareConfigs = func(ref_cfg, check_cfg) {
    var mismatch = 0;
    # printConfig("default", mod_default_cfg);
    # printConfig("actual", mod_runtime_cfg);
    foreach (var mod; ref_cfg.getChildren()) {
        var name = mod.getName();
        var ref_ena = mod.getChild("enabled");
        var ref_ua = ref_ena.getAttribute("userarchive");
        var check_mod = check_cfg.getChild(name);
        if (check_mod != nil) {
            var check_ena = check_mod.getChild("enabled");
            var check_ua = check_ena.getAttribute("userarchive");
            # if (ref_ena.getValue() != check_ena.getValue())
                # printf("%-20s enable flag mismatch", name);
            if (ref_ua != check_ua) {
                printf("%-20s userarchive mismatch", name);
                mismatch = 1;
            }
        }
    }
    return mismatch;
}

var repairUserArchiveFlag = func(ref_cfg, check_cfg) {
    foreach (var mod; ref_cfg.getChildren()) {
        var name = mod.getName();
        var ref_ua = mod.getChild("enabled").getAttribute("userarchive");
        var check_mod = check_cfg.getChild(name);
        if (check_mod != nil) {
            check_mod.getChild("enabled").setAttribute("userarchive", ref_ua);
            check_mod.setAttribute("userarchive", ref_ua);
        }
    }
}

var mod_default_cfg = loadDefaultsNasal();
var mod_runtime_cfg = props.getNode("/nasal");

if (compareConfigs(mod_default_cfg, mod_runtime_cfg)) {
    print("-- Resetting userarchive flags to defaults --");
    repairUserArchiveFlag(mod_default_cfg, mod_runtime_cfg);
}
