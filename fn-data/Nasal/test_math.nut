

# fgcommand("nasal-test", props.Node.new({"path":"test_math.nut"}));


# note you can omit this if not needed
var setUp = func {
    print("Did set-up");
};

# same, cab be ommitted
var tearDown = func {
    print("Did tear-down");
};


# all test macros take an option 'message' argument
var test_abc = func {
    print("Ran test ABC");

# fails if first argument is zero
    unitTest.assert(1 == 1, "Math equality");
    unitTest.assert(1 < 2, "Math less than");
  
  # always fails the test
  #  unitTest.fail("broken");

    print("Fofofo");
    unitTest.assert(4 != 1, "Math inequality");

    var c = "ap" ~ "ples";
    unitTest.assert_equal("apples", c);
};

var test_def = func {
    print("Ran test DEF");

    var a = 1.0 + 2.0;
    var b = 99.0;

    unitTest.assert_equal(a,  3, "addition");

# compare with a tolerance, this will fail
    unitTest.assert_doubles_equal(3.141, 3, 0.1, "Pi-ish");
}


