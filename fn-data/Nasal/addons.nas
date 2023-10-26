##
# Initialize addons configured with --addon=foobar command line switch:
# - get the list of registered add-ons
# - load the addon-main.nas file of each add-on into namespace
#   __addon[ADDON_ID]__
# - call function main() from every such addon-main.nas with the add-on ghost
#   as argument (an addons.Addon instance).

# Example:
#
# fgfs --addon=/foo/bar/baz
#
# - AddonManager.cxx parses /foo/bar/baz/addon-metadata.xml
# - AddonManager.cxx creates prop nodes under /addons containing add-on metadata
# - AddonManager.cxx loads /foo/bar/baz/addon-config.xml into the Property Tree
# - AddonManager.cxx adds /foo/bar/baz to the list of aircraft paths (to get
#   permissions to read files from there)
# - this script loads /foo/bar/baz/addon-main.nas into namespace
#   __addon[ADDON_ID]__
# - this script calls main(addonGhost) from /foo/bar/baz/addon-main.nas.
# - the add-on ghost can be used to retrieve most of the add-on metadata, for
#   instance:
#      addonGhost.id                   the add-on identifier
#      addonGhost.name                 the add-on name
#      addonGhost.version.str()        the add-on version as a string
#      addonGhost.basePath             the add-on base path (realpath() of
#                                      "/foo/bar/baz" here)
#      etc.
#
# For more details, see $FG_ROOT/Docs/README.add-ons.

# hashes to store listeners and timers per addon ID
var _modules = {};

var getNamespaceName = func(a) {
    return "__addon[" ~ a.id ~ "]__";
}

var load = func(a) {
    var namespace = getNamespaceName(a);
    var loaded = a.node.getNode("loaded", 1);
    loaded.setBoolValue(0);

    var module = modules.Module.new(a.id, namespace, a.node);
    module.setFilePath(a.basePath);
    module.setMainFile("addon-main.nas");
    
    if (module.load(a) != nil) {
        logprint(LOG_INFO, "[OK] '" ~ a.name ~ "' (V. " ~ a.version.str() ~
                    ") loaded.");
        module.printTrackedResources();
    } else {
        logprint(DEV_ALERT, "Failed loading addon-main.nas for " ~ a.id);
    }
    _modules[a.id] = module;
}


var remove = func(a) {
    logprint(LOG_INFO, "- Removing add-on ", a.id);
    _modules[a.id].unload();
}

var _reloadFlags = {};

var reload = func(a) {
    addons.remove(a);
    addons.load(a);
}

var commandAddonReload = func(node)
{
    var a = addons.getAddon(node.getChild("id").getValue());
    if (_modules[a.id] == nil) {
        logprint(DEV_ALERT, "Unknown add-on to reload: "~id);
        return;
    }
    addons.reload(a)
};

var init = func {
    addcommand("addon-reload", commandAddonReload);
    foreach (var addon; addons.registeredAddons()) {
        addons._reloadFlags[addon.id] = addon.node.getNode("reload", 1);
        addons._reloadFlags[addon.id].setBoolValue(0);
        var makeListener = func(a) {
            return func(n) {
                if (n.getValue()) {
                    n.setValue(0);
                    addons.reload(a);
                }
            };
        }
        setlistener(addons._reloadFlags[addon.id], makeListener(addon));
        addons.load(addon);
    }
}

var id = setlistener("/sim/signals/fdm-initialized", func {
    removelistener(id);
    addons.init();
}, 0, 0);
