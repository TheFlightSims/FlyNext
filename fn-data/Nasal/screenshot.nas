# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copyright (C) 2009 by Torsten Renk
# Copyright (C) 2013 by penta
# Copyright (C) 2022 by Erik Hofman
#
# Based on:
# https://forum.flightgear.org/viewtopic.php?f=6&t=6380&p=53863#p53681
# https://forum.flightgear.org/viewtopic.php?f=19&t=7713&start=15#p180816

var rotatescreen = func(heading_deg, pitch_deg, roll_deg)
{
	setprop("/sim/current-view/goal-heading-offset-deg", heading_deg);
	setprop("/sim/current-view/heading-offset-deg", heading_deg);
	setprop("/sim/current-view/goal-pitch-offset-deg", pitch_deg);
	setprop("/sim/current-view/pitch-offset-deg", pitch_deg);
	setprop("/sim/current-view/goal-roll-offset-deg", roll_deg);
	setprop("/sim/current-view/roll-offset-deg", roll_deg);
}

var takescreen = func(heading_deg, pitch_deg)
{
	print ("taking screen with heading= ", heading_deg, " and pitch= ", pitch_deg);
	var success = fgcommand("screen-capture");
	if (success) 
	{ 
		print ("screen taken with heading= ", heading_deg, " and pitch= ", pitch_deg);
	} 
	else
	{
		print("screen not taken");
	}
}

var i=0;
var j=0;
var k=0;
var tick_time=3;
var width  = getprop("/sim/startup/xsize");
var height = getprop("/sim/startup/ysize");
var menubarvalue=getprop("/sim/menubar/visibility");
var znearvalue=("sim/rendering/camera-group/znear");
var fovvalue=getprop("/sim/current-view/field-of-view");
var freezemvalue=getprop("/sim/freeze/master");
var freezecvalue=getprop("/sim/freeze/clock");
var headingvalue=getprop("/sim/current-view/heading-offset-deg");
var pitchvalue=getprop("/sim/current-view/pitch-offset-deg");
var rollvalue=getprop("/sim/current-view/roll-offset-deg");

var cube_screen_ticks = func()
{
	if (i==0 or i==2)
	{
                roll_deg=0;
		heading_deg=headingvalue;
		if (i==0) pitch_deg=-90;
		else pitch_deg=90;
	}
	else
	{
		pitch_deg=0;
		heading_deg=headingvalue-90*j;
		roll_deg = -270+j*90;
	}
        if (k==0)
	{
		k = 1;
		rotatescreen(heading_deg, pitch_deg, roll_deg);
		settimer(cube_screen_ticks, tick_time, tick_time);
	}
	elsif (k==1)
	{
		if (i<3)
		{
			k = 0;
			takescreen(heading_deg, pitch_deg);
			if (i==0 or i==2) {
				i=i+1;
				settimer(cube_screen_ticks, tick_time, tick_time);
			}
			else if (i==1)
			{
				if (j<3)
				{
					j=j+1;
					settimer(cube_screen_ticks, tick_time, tick_time);
				}
				else {
					i=i+1;
					settimer(cube_screen_ticks, tick_time, tick_time);
				}
			}
		}
		else
		{
			setprop("/sim/menubar/visibility", menubarvalue);
			setprop("/sim/current-view/field-of-view", fovvalue);
			setprop("/sim/current-view/heading-offset-deg", headingvalue);
			setprop("/sim/current-view/pitch-offset-deg", pitchvalue);
			setprop("/sim/freeze/master", freezemvalue);
			setprop("/sim/freeze/clock", freezecvalue);
		}
	}
}

var panorama_screen_ticks = func()
{
	if (i==0) {
		pitch_deg=-45;
	} else {
		pitch_deg=45;
	}
	heading_deg=j*(-90);
	if (k==0)
	{
		k=1;
		rotatescreen(heading_deg, pitch_deg, 0);
		settimer(panorama_screen_ticks, tick_time, tick_time);
	}
	else if (k==1)
	{
		k=0;
		takescreen(heading_deg, pitch_deg);
		if (j!=3)
		{
			j=j+1;
			settimer(panorama_screen_ticks, tick_time, tick_time);
		}
		else
		{
			if (i==0)
			{
				i=i+1;
				j=0;
				settimer(panorama_screen_ticks, tick_time, tick_time);
			}
			else
			{
                                k=2;
				settimer(panorama_screen_ticks, tick_time, tick_time);
			}
		}
	}
	else
	{
		setprop("/sim/menubar/visibility", menubarvalue);
		setprop("/sim/current-view/field-of-view", fovvalue);
		setprop("/sim/current-view/heading-offset-deg", headingvalue);
		setprop("/sim/current-view/pitch-offset-deg", pitchvalue);
		setprop("/sim/current-view/roll-offset-deg", rollvalue);
		setprop("/sim/freeze/master", freezemvalue);
		setprop("/sim/freeze/clock", freezecvalue);
	}
}

var make_cubemap = func()
{
	width  = getprop("/sim/startup/xsize");
	height = getprop("/sim/startup/ysize");
	menubarvalue=getprop("/sim/menubar/visibility");
	znearvalue=("sim/rendering/camera-group/znear");
	fovvalue=getprop("/sim/current-view/field-of-view");
	freezemvalue=getprop("/sim/freeze/master");
	freezecvalue=getprop("/sim/freeze/clock");
	headingvalue=getprop("/sim/current-view/heading-offset-deg");
	pitchvalue=getprop("/sim/current-view/pitch-offset-deg");
	rollvalue=getprop("/sim/current-view/roll-offset-deg");

        setprop("/sim/menubar/visibility", 'false');
        setprop("/sim/rendering/camera-group/znear",0.03);
        setprop("/sim/current-view/field-of-view", 170);
        setprop("/sim/freeze/master",'true');
        setprop("/sim/freeze/clock",'true');

	i=0;
	j=0;
	k=0;
        cube_screen_ticks();
}

var make_panorama = func()
{
	menubarvalue=getprop("/sim/menubar/visibility");
	znearvalue=("sim/rendering/camera-group/znear");
	fovvalue=getprop("/sim/current-view/field-of-view");
	freezemvalue=getprop("/sim/freeze/master");
	freezecvalue=getprop("/sim/freeze/clock");
	headingvalue=getprop("/sim/current-view/heading-offset-deg");
	pitchvalue=getprop("/sim/current-view/pitch-offset-deg");
	rollvalue=getprop("/sim/current-view/roll-offset-deg");

	setprop("/sim/menubar/visibility", 'false');
	setprop("/sim/rendering/camera-group/znear",0.03);
	setprop("/sim/current-view/field-of-view", 120);
	setprop("/sim/freeze/master",'true');
	setprop("/sim/freeze/clock",'true');

	i=0;
	j=0;
	k=0;
	panorama_screen_ticks();
}
