#-------------------------------------------------------------------------------
# SPDX-License-Identifier: GPL-2.0-or-later
#-------------------------------------------------------------------------------
# std.nut - Nasal Unit Test for std.nas
# author:  Henning Stahlke
# created: 06/2020
#-------------------------------------------------------------------------------

var setUp = func {
};

var tearDown = func {
};

#-- test std.Hash
var test_hash = func {
    var hash = std.Hash.new({}, "testhash");
    unitTest.assert(isa(hash, std.Hash), "std.Hash.new");
    unitTest.assert(hash.getName() == "testhash" , "std.Hash.getName");

    unitTest.assert(hash.set("foo", 42) == hash, "std.Hash.set");
    unitTest.assert(hash.get("foo") == 42 , "std.Hash.get");
    unitTest.assert(hash.contains("foo"), "std.Hash.contains");

    hash.set("bar", 21);
    unitTest.assert(isvec(hash.getKeys()), "std.Hash.getKeys isvec");
    unitTest.assert(size(hash.getKeys()) == 2, "std.Hash.getKeys size");

    unitTest.assert(hash.clear() == hash, "std.Hash.clear");
    unitTest.assert(!hash.contains("foo"), "std.Hash.contains after clear");
    unitTest.assert(size(hash.getKeys()) == 0, "std.Hash.getKeys after clear");
    
    var cb_hash = {};
    unitTest.assert(hash.addCallback(func(key, val) { cb_hash[key] = val; }) == hash,
        "std.Hash.addCallback");
    hash.set("foo", 21);
    unitTest.assert(cb_hash["foo"] == 21, "std.addCallback worked");
    
    hash.set("funct", func {});
    hash.set("vec", [0,1,2]);
    hash.set("hsh", {a:1, b:2});    

    var tmp = props.Node.new();
    hash.keys2props(tmp);
    unitTest.assert(isa(tmp.getNode("foo"), props.Node), "std.keys2props node ok");
    
    var tmp = props.Node.new();
    hash.hash2props(tmp);
    unitTest.assert(tmp.getNode("foo").getValue() == 21, "std.hash2props ok");    
}
    
#-- test std.String
var test_stoul = func {
    unitTest.assert(std.stoul("123") == 123, "std.stoul 123");
    unitTest.assert(std.stoul("A0", 16) == 160, "std.stoul 0xAF");
}

var test_string = func {
    var x = std.String.new("FlightGear");
    unitTest.assert(isa(x, std.String), "std.String.new");
    unitTest.assert(x.compare("FlightGear"), "std.String.compare");
    
    unitTest.assert(x.starts_with("Fli"), "std.String.starts_with");
    unitTest.assert(!x.starts_with("Gear"), "std.String.starts_with");
    
    unitTest.assert(x.find_first_of("i") == 2, "std.String.find_first_of");
    unitTest.assert(x.find_first_of("i", 3) == -1, "std.String.find_first_of");
    unitTest.assert(x.find_first_not_of("F") == 1, "std.String.find_first_not_of");
    unitTest.assert(x.find_first_not_of("F", 2) == 2, "std.String.find_first_not_of");
    unitTest.assert(x.find_first_not_of("F", 3) == 3, "std.String.find_first_not_of");
}
    
#-- test std.Vector
var test_vector = func {
    var x = std.Vector.new();
    unitTest.assert(isa(x, std.Vector), "std.Vector.new()");
    unitTest.assert(x.size() == 0);

    x = std.Vector.new(["x", "y"]);
    unitTest.assert_equal(x.vector, ["x", "y"], "std.Vector.new(['x', 'y'])");
    unitTest.assert(x.size() == 2, "std.Vector.new size 2");
    x.clear();
    unitTest.assert(isvec(x.vector) and x.size() == 0);

    x = std.Vector.new([], "testvector");
    var cb_vector = [];
    unitTest.assert(x.getName() == "testvector" , "std.Vector.getName");
    unitTest.assert(x.addCallback(func (index, item) {
            if (index >= size(cb_vector)) append(cb_vector, item);
            else cb_vector = cb_vector[0:index]~[item]~subvec(cb_vector, index);
        }) == x, "std.Vector.addCallback");

    # append():
    x.append("a");
    x.append("b");
    x.append("c");
    unitTest.assert_equal(x.vector, ["a", "b", "c"]);
    unitTest.assert_equal(cb_vector, ["a", "b", "c"]);
    unitTest.assert(x.size() == 3);

    # extend():
    x.extend(["d", "e"]);
    unitTest.assert_equal(x.vector, ["a", "b", "c", "d", "e"]);
    unitTest.assert(x.size() == 5);

    # insert():
    x.insert(2, "cc");
    unitTest.assert_equal(x.vector, ["a", "b", "cc", "c", "d", "e"]);
    unitTest.assert(x.size() == 6);

    # pop():
    unitTest.assert(x.pop(3), "c");
    unitTest.assert_equal(x.vector, ["a", "b", "cc", "d", "e"]);
    unitTest.assert(x.size() == 5);

    unitTest.assert(x.pop(), "e");
    unitTest.assert_equal(x.vector, ["a", "b", "cc", "d"]);
    unitTest.assert(x.size() == 4);


    # extend():
    x.clear();
    x.extend(["a", "b", "c", "d"]);
    unitTest.assert_equal(x.vector, ["a", "b", "c", "d"]);
    unitTest.assert(x.size() == 4);

    # index():
    unitTest.assert(x.index("c"), 2);

    # contains():
    unitTest.assert(x.contains("c"));
    unitTest.assert(x.contains("e") == 0);

    # remove():
    x.remove("c");
    unitTest.assert_equal(x.vector, ["a", "b", "d"]);
    unitTest.assert(x.size() == 3);

    # insert():
    x.insert(0, "f");
    unitTest.assert_equal(x.vector, ["f", "a", "b", "d"]);
    unitTest.assert(x.size() == 4);
    x.remove("f");
    unitTest.assert_equal(x.vector, ["a", "b", "d"]);

    x.insert(1, "f");
    unitTest.assert_equal(x.vector, ["a", "f", "b", "d"]);
    unitTest.assert(x.size() == 4);
    x.remove("f");
    unitTest.assert_equal(x.vector, ["a", "b", "d"]);

    x.insert(2, "f");
    unitTest.assert_equal(x.vector, ["a", "b", "f", "d"]);
    x.remove("f");
    unitTest.assert_equal(x.vector, ["a", "b", "d"]);

    x.insert(3, "g");
    unitTest.assert_equal(x.vector, ["a", "b", "d", "g"]);
    x.remove("g");

    x.insert(4, "g");
    unitTest.assert_equal(x.vector, ["a", "b", "d", "g"]);
    x.remove("g");

    x.insert(-1, "h");
    unitTest.assert_equal(x.vector, ["a", "b", "h", "d"]);
    x.remove("h");

    x.insert(-2, "h");
    unitTest.assert_equal(x.vector, ["a", "h", "b", "d"]);
    x.remove("h");

    x.insert(-3, "h");
    unitTest.assert_equal(x.vector, ["h", "a", "b", "d"]);
    x.remove("h");

    x.insert(-4, "h");
    unitTest.assert_equal(x.vector, ["h", "a", "b", "d"]);
    x.remove("h");

    # pop():
    unitTest.assert(x.pop(-1) == "d");
    unitTest.assert_equal(x.vector, ["a", "b"]);
    x.append("d");

    unitTest.assert(x.pop(-2) == "b");
    unitTest.assert_equal(x.vector, ["a", "d"]);
    x.insert(1, "b");

    unitTest.assert(x.pop(-3) == "a");
    unitTest.assert_equal(x.vector, ["b", "d"]);
    x.insert(0, "a");
    unitTest.assert_equal(x.vector, ["a", "b", "d"]);    
}
    
