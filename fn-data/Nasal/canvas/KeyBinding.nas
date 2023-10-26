PrintableKeys = {
	0: 0x30,
	1: 0x31,
	2: 0x32,
	3: 0x33,
	4: 0x34,
	5: 0x35,
	6: 0x36,
	7: 0x37,
	8: 0x38,
	9: 0x39,
	A: 0x61,
	a: 0x61,
	B: 0x62,
	b: 0x62,
	C: 0x63,
	c: 0x63,
	D: 0x64,
	d: 0x64,
	E: 0x65,
	e: 0x65,
	F: 0x66,
	f: 0x66,
	G: 0x67,
	g: 0x67,
	H: 0x68,
	h: 0x68,
	I: 0x69,
	i: 0x69,
	J: 0x6a,
	j: 0x6a,
	K: 0x6b,
	k: 0x6b,
	L: 0x6c,
	l: 0x6c,
	M: 0x6d,
	m: 0x6d,
	N: 0x6e,
	n: 0x6e,
	O: 0x6f,
	o: 0x6f,
	P: 0x70,
	p: 0x70,
	Q: 0x71,
	q: 0x71,
	R: 0x72,
	r: 0x72,
	S: 0x73,
	s: 0x73,
	T: 0x74,
	t: 0x74,
	U: 0x75,
	u: 0x75,
	V: 0x76,
	v: 0x76,
	W: 0x77,
	w: 0x77,
	X: 0x78,
	x: 0x78,
	Y: 0x79,
	y: 0x79,
	Z: 0x7a,
	z: 0x7a,
	"!": 0x21,
	Exclaim: 0x21,
	'"': 0x22,
	DoubleQuote: 0x22,
	"#": 0x23,
	Hash: 0x23,
	"$": 0x24,
	Dollar: 0x24,
	"&": 0x26,
	Ampersand: 0x26,
	"'": 0x27,
	SingleQuote: 0x27,
	"(": 0x28,
	OpeningParenthesis: 0x28,
	")": 0x29,
	ClosingParenthesis: 0x29,
	"*": 0x2a,
	Asterisk: 0x2A,
	"+": 0x2b,
	Plus: 0x2B,
	",": 0x2c,
	Comma: 0x2C,
	"-": 0x2d,
	Minus: 0x2D,
	".": 0x2e,
	Period: 0x2E,
	"/": 0x2f,
	Slash: 0x2F,
	",": 0x3a,
	Colon: 0x3A,
	";": 0x3b,
	SemiColon: 0x3B,
	"<": 0x3c,
	Less: 0x3C,
	"=": 0x3d,
	Equals: 0x3D,
	">": 0x3e,
	Greater: 0x3E,
	"?": 0x3f,
	Question: 0x3F,
	"@": 0x40,
	At: 0x40,
	"[": 0x5b,
	OpeningBracket: 0x5B,
	"\\": 0x5c,
	BackSlash: 0x5C,
	"]": 0x5d,
	ClosingBracket: 0x5D,
	"^": 0x5e,
	Caret: 0x5E,
	"_": 0x5f,
	Underscore: 0x5F,
	"`": 0x60,
	BackQuote: 0x60,
};

FunctionKeys = {
	Space: 0x20,
	Backspace: 0xFF08,
	Tab: 0xFF09,
	Linefeed: 0xFF0A,
	Clear: 0xFF0B,
	Return: 0xFF0D,
	Pause: 0xFF13,
	Sys_Req: 0xFF15,
	"Esc": 0xff1b,
	Escape: 0xFF1B,
	"Del": 0xffff,
	Delete: 0xFFFF,
	Home: 0xFF50,
	Left: 0xFF51,
	Up: 0xFF52,
	Right: 0xFF53,
	Down: 0xFF54,
	Prior: 0xFF55,
	Page_Up: 0xFF55,
	Next: 0xFF56,
	Page_Down: 0xFF56,
	End: 0xFF57,
	Begin: 0xFF58,
	Select: 0xFF60,
	Print: 0xFF61,
	Execute: 0xFF62,
	Insert: 0xFF63,
	Undo: 0xFF65,
	Redo: 0xFF66,
	Menu: 0xFF67,
	Find: 0xFF68,
	Cancel: 0xFF69,
	Help: 0xFF6A,
	Break: 0xFF6B,
	
	# Any key binding using these would be pretty confusing …
	Mode_switch: 0xFF7E,
	Script_switch: 0xFF7E,
	Num_Lock: 0xFF7F,
	Scroll_Lock: 0xFF14,
	
	# Keypad keys probably should not be used because their normal key equivalent will be passed by OSG AFAIK
	KP_Space: 0xFF80,
	KP_Tab: 0xFF89,
	KP_Enter: 0xFF8D,
	KP_F1: 0xFF91,
	KP_F2: 0xFF92,
	KP_F3: 0xFF93,
	KP_F4: 0xFF94,
	KP_Home: 0xFF95,
	KP_Left: 0xFF96,
	KP_Up: 0xFF97,
	KP_Right: 0xFF98,
	KP_Down: 0xFF99,
	KP_Prior: 0xFF9A,
	KP_Page_Up: 0xFF9A,
	KP_Next: 0xFF9B,
	KP_Page_Down: 0xFF9B,
	KP_End: 0xFF9C,
	KP_Begin: 0xFF9D,
	KP_Insert: 0xFF9E,
	KP_Delete: 0xFF9F,
	KP_Equal: 0xFFBD,
	KP_Multiply: 0xFFAA,
	KP_Add: 0xFFAB,
	KP_Separator: 0xFFAC,
	KP_Subtract: 0xFFAD,
	KP_Decimal: 0xFFAE,
	KP_Divide: 0xFFAF,
	KP_0: 0xFFB0,
	KP_1: 0xFFB1,
	KP_2: 0xFFB2,
	KP_3: 0xFFB3,
	KP_4: 0xFFB4,
	KP_5: 0xFFB5,
	KP_6: 0xFFB6,
	KP_7: 0xFFB7,
	KP_8: 0xFFB8,
	KP_9: 0xFFB9,
	F1: 0xFFBE,
	F2: 0xFFBF,
	F3: 0xFFC0,
	F4: 0xFFC1,
	F5: 0xFFC2,
	F6: 0xFFC3,
	F7: 0xFFC4,
	F8: 0xFFC5,
	F9: 0xFFC6,
	F10: 0xFFC7,
	F11: 0xFFC8,
	F12: 0xFFC9,
	
	# most keyboards only have F1 - F12, so better not use any of the below FunctionKeys
	F13: 0xFFCA,
	F14: 0xFFCB,
	F15: 0xFFCC,
	F16: 0xFFCD,
	F17: 0xFFCE,
	F18: 0xFFCF,
	F19: 0xFFD0,
	F20: 0xFFD1,
	F21: 0xFFD2,
	F22: 0xFFD3,
	F23: 0xFFD4,
	F24: 0xFFD5,
	F25: 0xFFD6,
	F26: 0xFFD7,
	F27: 0xFFD8,
	F28: 0xFFD9,
	F29: 0xFFDA,
	F30: 0xFFDB,
	F31: 0xFFDC,
	F32: 0xFFDD,
	F33: 0xFFDE,
	F34: 0xFFDF,
	F35: 0xFFE0,
	
	# Do not use the below keys !
	Shift_L: 0xFFE1,
	Shift_R: 0xFFE2,
	Control_L: 0xFFE3,
	Control_R: 0xFFE4,
	Caps_Lock: 0xFFE5,
	Shift_Lock: 0xFFE6,
	Meta_L: 0xFFE7,
	Meta_R: 0xFFE8,
	Alt_L: 0xFFE9,
	Alt_R: 0xFFEA,
	#Super_L: 0xFFEB,
	#Super_R: 0xFFEC,
	#Hyper_L: 0xFFED,
	#Hyper_R: 0xFFEE,
};

ModifierKeys = {
	Shift_L: 0x0001,
	Shift_R: 0x0002,
	Control_L: 0x0004,
	Control_R: 0x0008,
	Alt_L: 0x0010,
	Alt_R: 0x0020,
	Meta_L: 0x0040,
	Meta_R: 0x0080,
	
	# These do not seem to be available in OSG events
	#Super_L: 0x0100,
	#Super_R: 0x0200,
	#Hyper_L: 0x0400,
	#Hyper_R: 0x0800,
	#Num_Lock: 0x1000,
	Caps_Lock: 0x2000,
};
	
# Only use the below keys !
ModifierKeys.Ctrl = (ModifierKeys.Control_L | ModifierKeys.Control_R);
ModifierKeys.Shift = (ModifierKeys.Shift_L | ModifierKeys.Shift_R);
ModifierKeys.Alt = (ModifierKeys.Alt_L | ModifierKeys.Alt_R);
ModifierKeys.Meta = (ModifierKeys.Meta_L | ModifierKeys.Meta_R);

# These do not seem to be available in OSG events
#ModifierKeys.Super = (ModifierKeys.Super_L | ModifierKeys.Super_R);
#ModifierKeys.Hyper = (ModifierKeys.Hyper_L | ModifierKeys.Hyper_R);

var parseShortcut = func(s) 
{
	if (!s or !isstr(s) or size(s) == 0) {
		return nil;
	}
	
	var baseKey = nil;
	var modifiers = [];
	var input = split("+", s);
	foreach (var key; input) {
		if (string.match(key, "<*>")) {
			append(modifiers, substr(key, 1, size(key) - 2));
		} else {
			baseKey = key;
		}
	}
	
	var modMask = 0;
	foreach (var mod; modifiers) {
		var mm = ModifierKeys[mod];
		if (mm == nil) {
			logprint(LOG_ALERT, "Unknown modifier key '" ~ mod ~ "' !");
		} else {
			modMask = modMask + mm;
		}
	}
	
	var keyCode = PrintableKeys[baseKey];
	if (keyCode == nil) {
		keyCode = FunctionKeys[baseKey];
	}

	if (keyCode == nil) {
		logprint(LOG_ALERT, "Unknown key '" ~ baseKey ~ "'");
		return nil;
	}

	return  [modMask, keyCode];
}


var findKeyName = func(key) {
	foreach (var mod; keys(ModifierKeys)) {
		if (ModifierKeys[mod] == key) {
			return mod;
		}
	}
	foreach (var printable; keys(PrintableKeys)) {
		if (PrintableKeys[printable] == key) {
			return printable;
		}
	}
	foreach (var function; keys(FunctionKeys)) {
		if (FunctionKeys[function] == key) {
			return function;
		}
	}
	return nil;
};

var namesToKeys = func(strings...) 
{
	var res = [];
	foreach (var s; strings) {
		var key = ModifierKeys[s] or PrintableKeys[s] or FunctionKeys[s];
		if (!key) {
			logprint(LOG_ALERT, "keyboard.namesToKeys: unknown key '" ~ key ~ "' - skipping !");
			continue;
		}
		append(res, key);
	}
	return res;
};

# here we're extendin the built-in KeyBinding class defined in NasalCanvas.cxx,
# with some helper functions which rely on the tables defined above.

KeyBinding['fromShortcut'] = func(shortcutString, cb = nil)
{
	if (!isstr(shortcutString)) {
		return nil;
	}

	var res = KeyBinding.new();
	var t = parseShortcut(shortcutString);
	
	if (t) {
		res.modifiers = t[0];
		res.keyCode = t[1];
	}

	if (!isfunc(cb)) {
		logprint(LOG_ALERT, "callback argument to KeyBinding.fromShortcut is not a function")
	} else {
		res.addBinding(cb);
	}

	return res;
};

KeyBinding['repr'] = func(kb)
{
	if (!kb) {
		return "";
	}
	var names = [];
	foreach (var mod; keys(ModifierKeys)) {
		if (kb.modifiers & ModifierKeys[mod]) {
			append(names, "<" ~ mod ~ ">");
		}
	}
	append(names, findKeyName(kb.keyCode));
	return string.join(" + ", names);
};

