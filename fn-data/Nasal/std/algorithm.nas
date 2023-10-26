
# SPDX-FileCopyrightText: (C) 2023 Frederic Croix <thefgfseagle@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

var all = func(obj, key=nil) {
	if (!size(obj)) {
		return 0;
	}
	var res = 1;
	if (key) {
		if (!isfunc(key)) {
			die("std.all got a non-callable 'key' argument");
		}
		foreach (var o; obj) {
			res &= key(o);
			if (res == 0) {
				break;
			}
		}
	} else {
		foreach(var o; obj) {
			res &= o;
			if (res == 0) {
				break;
			}
		}
	}
	return res;
};

var any = func(obj, key=nil) {
	var res = 0;
	if (key) {
		if (!isfunc(key)) {
			die("std.any got a non-callable 'key' argument");
		}
		foreach (var o; obj) {
			res |= key(o);
			if (res == 1) {
				break;
			}
		}
	} else {
		foreach(var o; obj) {
			res |= o;
			if (res == 1) {
				break;
			}
		}
	}
	return res;
};

var map = func(function, obj) {
	if (!isfunc(function)) {
		die("std.map got a non-callable 'function' argument");
	}
	var res = [];
	foreach (var o; obj) {
		append(res, function(o));
	}
	return res;
};

var filter = func(function, obj) {
	var res = [];
	if (function) {
		if (!isfunc(function)) {
			die("std.filter got a non-callable 'function' argument");
		}
		foreach (var o; obj) {
			if (function(o)) {
				append(res, o);
			}
		}
	} elsif (o) {
		foreach (var o; obj) {
			if (o) {
				append(res, o);
			}
		}
	}
	return res;
};
