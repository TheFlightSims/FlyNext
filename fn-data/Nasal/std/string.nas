# ------------------------------------------------------------------------------
# A C++ like string class (http://en.cppreference.com/w/cpp/string/basic_string)
# ------------------------------------------------------------------------------
# SPDX-License-Identifier: GPL-2.0-or-later
#
# NOTE! This copyright does *not* cover user models that use these Nasal
# services by normal function calls - this is merely considered normal use
# of the code, and does *not* fall under the heading of "derived work."
#
# Copyright (C) 2012-2013 by Thomas Geymayer

#load only once (via /Nasal/std.nas) not via C++ module loader
if (ishash(globals["std"]) and ishash(std["String"]))
    return;

var String = {
# public:
  new: func(str)
  {
    return { parents: [String], _str: str };
  },
  # compare(s)
  # compare(pos, n, s)
  #
  # @param s    String to compare to
  # @param pos  Position of first character used to compare
  # @param n    Number of characters to compare
  compare: func
  {
    var s = "";
    var pos = 0;
    var n = -1;

    var num = size(arg);
    if( num == 1 )
      s = arg[0];
    else if( num == 3 )
    {
      pos = arg[0];
      n = arg[1];
      s = arg[2];
    }
    else
      die("std::string::compare: Invalid args");

    if( n < 0 )
      n = me.size();
    else if( n > me.size() )
      return 0;

    if( n != size(s) )
      return 0;

    for(var i = pos; i < n; i += 1)
      if( me._str[i] != s[i] )
        return 0;
    return 1;
  },
  
  # returns index (zero based) of first occurrence of s
  # searching from pos
  find_first_of: func(s, pos = 0)
  {
    return me._find(pos, size(me._str), s, 1);
  },
  find: func(s, pos = 0)
  {
    return me.find_first_of(s, pos);
  },
  find_first_not_of: func(s, pos = 0)
  {
    return me._find(pos, size(me._str), s, 0);
  },
  substr: func(pos, len = nil)
  {
    return substr(me._str, pos, len);
  },
  starts_with: func(s)
  {
    return me.compare(0, size(s), s);
  },
  size: func()
  {
    return size(me._str);
  },
# private:
  _eq: func(pos, s)
  {
    for(var i = 0; i < size(s); i += 1)
      if( me._str[pos] == s[i] )
        return 1;
    return 0;
  },
  _find: func(first, last, s, eq)
  {
    if( first < 0 or last < 0 )
      return -1;

    var sign = first <= last ? 1 : -1;
    for(var i = first; sign * i < last; i += sign)
      if( me._eq(i, s) == eq )
        return i;
    return -1;
  }
};

# for backward compatibility
var string = {parents: [String]};
string.new = func {
    logprint(LOG_ALERT, "Deprecated use of std.string, please use std.String instead.");
    return String.new(arg[0]);
}

# converts a string to an unsigned integer
var stoul = func(str, base = 10)
{
  var val = 0;
  for(var pos = 0; pos < size(str); pos += 1)
  {
    var c = str[pos];

    if( globals.string.isdigit(c) )
      var digval = c - `0`;
    else if( globals.string.isalpha(c) )
      var digval = globals.string.toupper(c) - `A` + 10;
    else
      break;

    if( digval >= base )
      break;

    val = val * base + digval;
  }

  return val;
};
