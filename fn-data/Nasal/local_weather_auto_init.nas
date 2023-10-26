# this routine checks whether the launcher has requested to auto-start AW
# we can't do this inside the AW namespace because that is only loaded
# on demand, and we want this at Nasal (re-)init, not at AW namespace loading

# Thorsten Renk 2018


var autoInit = func {
	var isEnabled = getprop("/nasal/local_weather/enabled");
	if (isEnabled == 1)
		{
		print ("Request detected to initialize Advanced Weather on startup..."); 
            	settimer( func {local_weather.set_tile();}, 0.2);
		}
}

autoInit();
