/**
 * Wraps json properties into something like SGPropertyNodes
 */
(function(factory) {
    if (typeof define === "function" && define.amd)// AMD. Register as an anonymous module.
    define([
    ], factory); else // Browser globals
    factory();
}(function() {

    var SGPropertyNode = function(json) {
        this.json = json;
    };

    SGPropertyNode.prototype.getValue = function(child,deflt) {
        if( typeof(child) === 'undefined' )
            return this.json.value;

        var c = this.getNode(child);
        if( c ) return c.getValue();
        else return deflt;
    }

    SGPropertyNode.prototype.getName = function() {
        return this.json.name;
    }

    SGPropertyNode.prototype.getPath = function() {
        return this.json.path;
    }

    SGPropertyNode.prototype.getIndex = function() {
        return this.json.index;
    }

    SGPropertyNode.prototype.getChildren = function(name) {
        var reply = [];
        this.json.children.forEach(function(child) {
            if (name && child.name == name)
                reply.push(new SGPropertyNode(child));
        });
        return reply;
    }

    SGPropertyNode.prototype.getNode = function(name, index) {
        if (!index)
            index = 0;
        for (var i = 0; i < this.json.children.length; i++) {
            var child = this.json.children[i];
            if (child.name == name && child.index == index)
                return new SGPropertyNode(child);
        }
    }

    return SGPropertyNode;
}));
