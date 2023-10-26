# Copyright (C) 2023 Fernando García Liñán
# SPDX-License-Identifier: GPL-2.0-or-later

#-------------------------------------------------------------------------------
# Utilities for the HDR Pipeline
#
# Shaders usually need to be fed uniforms that are either too expensive to
# compute on the GPU or can be precomputed once per frame. In this file we
# transform values from already existing properties into data that can be used
# by the shaders directly.
#-------------------------------------------------------------------------------

################################################################################
# Atmosphere
################################################################################
setprop("/sim/rendering/hdr/atmos/aerosol-absorption-cross-section[0]", 2.8722e-24);
setprop("/sim/rendering/hdr/atmos/aerosol-absorption-cross-section[1]", 4.6168e-24);
setprop("/sim/rendering/hdr/atmos/aerosol-absorption-cross-section[2]", 7.9706e-24);
setprop("/sim/rendering/hdr/atmos/aerosol-absorption-cross-section[3]", 1.3578e-23);

setprop("/sim/rendering/hdr/atmos/aerosol-scattering-cross-section[0]", 1.5908e-22);
setprop("/sim/rendering/hdr/atmos/aerosol-scattering-cross-section[1]", 1.7711e-22);
setprop("/sim/rendering/hdr/atmos/aerosol-scattering-cross-section[2]", 2.0942e-22);
setprop("/sim/rendering/hdr/atmos/aerosol-scattering-cross-section[3]", 2.4033e-22);

setprop("/sim/rendering/hdr/atmos/aerosol-base-density", 1.3681e17);
setprop("/sim/rendering/hdr/atmos/aerosol-relative-background-density", 1.4619e-17);
setprop("/sim/rendering/hdr/atmos/aerosol-scale-height", 0.73);
setprop("/sim/rendering/hdr/atmos/fog-density", 0.0);
setprop("/sim/rendering/hdr/atmos/fog-scale-height", 1.0);
setprop("/sim/rendering/hdr/atmos/ozone-mean-dobson", 347.0);

setprop("/sim/rendering/hdr/atmos/ground-albedo[0]", 0.4);
setprop("/sim/rendering/hdr/atmos/ground-albedo[1]", 0.4);
setprop("/sim/rendering/hdr/atmos/ground-albedo[2]", 0.4);
setprop("/sim/rendering/hdr/atmos/ground-albedo[3]", 0.4);

################################################################################
# Environment map
################################################################################

var envmap_frame_listener = nil;
var envmap_updating = false;
var envmap_current_face = 0;
var envmap_prefiltering_active = false;
var envmap_instant_update_active = false;

var envmap_reset_internal_variables = func {
    if (envmap_frame_listener != nil) {
        removelistener(envmap_frame_listener);
        envmap_frame_listener = nil;
    }
    envmap_updating = false;
    envmap_current_face = 0;
    envmap_prefiltering_active = false;
    envmap_instant_update_active = false;
}

var envmap_set_render_face = func(face, active) {
    setprop("/sim/rendering/hdr/envmap/should-render-face-" ~ face, active);
}

var envmap_set_render_all_faces = func(active) {
    for (var i = 0; i < 6; i += 1) {
        envmap_set_render_face(i, active);
    }
}

var envmap_set_prefilter = func(active) {
    setprop("/sim/rendering/hdr/envmap/should-prefilter", active);
}

# Update all the faces of the environment cubemap in a single frame
var envmap_update_instant_callback = func {
    if (!envmap_instant_update_active) {
        # This is the first time this callback has been called so enable
        # rendering for all faces.
        envmap_set_render_all_faces(true);
        envmap_set_prefilter(true);
        envmap_instant_update_active = true;
    } else {
        # This is the second time this callback has been called. Disable
        # rendering for all faces.
        envmap_set_render_all_faces(false);
        envmap_set_prefilter(false);
        envmap_reset_internal_variables();
    }
}

# Update a single cubemap face each frame. The prefiltering step is also done
# in a separate step, totalling 7 frames to update the entire environment map.
var envmap_update_progressive_callback = func {
    if (envmap_prefiltering_active) {
        # Last frame we activated the prefiltering, which is the last step.
        # Now disable it and reset all variables for the next update cycle.
        envmap_set_prefilter(false);
        envmap_reset_internal_variables();
        return;
    }
    if (envmap_current_face < 6) {
        # Render the current face
        envmap_set_render_face(envmap_current_face, true);
    }
    if (envmap_current_face > 0) {
        # Stop rendering the previous face
        envmap_set_render_face(envmap_current_face - 1, false);
    }
    if (envmap_current_face < 6) {
        # Go to next face and update it next frame
        envmap_current_face += 1;
    } else {
        # We have finished updating all faces. Reset the face counter and
        # prefilter the envmap.
        envmap_current_face = 0;
        envmap_prefiltering_active = true;
        envmap_set_prefilter(true);
    }
}

var update_envmap = func(instant = false) {
    if (getprop("/sim/rendering/hdr/envmap/update-continuously"))
        return;

    if (envmap_updating) {
        # We were already updating the envmap. If the requested update is
        # instant, cancel the ongoing update and start over. If it is a
        # progressive update, let the ongoing one finish and do nothing.
        if (instant) {
            envmap_set_render_all_faces(false);
            envmap_set_prefilter(false);
            envmap_reset_internal_variables();
            envmap_updating = true;
        } else {
            return;
        }
    } else {
        envmap_updating = true;
    }

    var callback = instant ? envmap_update_instant_callback
        : envmap_update_progressive_callback;
    # We use a listener to the frame signal because it is guaranteed to be
    # fired at a defined moment, while a settimer() with interval 0 might
    # not if subsystems are re-ordered.
    envmap_frame_listener = setlistener("/sim/signals/frame", callback);
}

# Continuous update
setlistener("/sim/rendering/hdr/envmap/update-continuously", func(p) {
    if (p.getValue()) {
        envmap_set_render_all_faces(true);
        envmap_set_prefilter(true);
        envmap_reset_internal_variables();
    } else {
        envmap_set_render_all_faces(false);
        envmap_set_prefilter(false);
    }
}, 1, 0);

# Manual update
setlistener("/sim/rendering/hdr/envmap/force-update", func(p) {
    if (p.getValue()) {
        update_envmap(true);
        p.setValue(false);
    }
}, 0, 0);

# Automatically update the envmap every so often
var envmap_timer = maketimer(getprop("/sim/rendering/hdr/envmap/update-rate-s"),
                             func {
                                 update_envmap(false);
                             });
envmap_timer.simulatedTime = true;

# Start updating when the FDM is initialized
setlistener("/sim/signals/fdm-initialized", func {
    update_envmap(true);
    envmap_timer.start();
    # Do a single update after 5 seconds when most of the scenery is loaded
    settimer(func {
        update_envmap(true);
    }, 5);
});

# If the update rate is modified at runtime, force an envmap update and restart
# the timer with the new period.
setlistener("/sim/rendering/hdr/envmap/update-rate-s", func(p) {
    if (envmap_timer.isRunning) {
        update_envmap(false);
        envmap_timer.restart(p.getValue());
    }
});

# Update the envmap at a much faster rate when time warp is active
var envmap_warp_listener = nil;
var prev_warp = getprop("/sim/time/warp");

var envmap_warp_listener_callback = func {
    removelistener(envmap_warp_listener);
    envmap_warp_timer.start();
}

var envmap_warp_timer_callback = func {
    # Check if the time warp has ended so we can stop updating the envmap so
    # regularly.
    var current_warp = getprop("/sim/time/warp");
    if (current_warp == prev_warp) {
        # Time warp has ended, so stop the timer and reattach the listener
        envmap_warp_timer.stop();
        envmap_warp_listener = setlistener("/sim/time/warp",
                                           envmap_warp_listener_callback, 0, 0);
        # Do a final update to make sure the envmap corresponds to the new
        # time of day.
        update_envmap(true);
    } else {
        # Time warp is still going so store the previous warp value and update
        # the envmap.
        prev_warp = current_warp;
        update_envmap(true);
    }
}

var envmap_warp_timer = maketimer(0.5, envmap_warp_timer_callback);
envmap_warp_timer.simulatedTime = true;

envmap_warp_listener = setlistener("/sim/time/warp",
                                   envmap_warp_listener_callback, 0, 0);

# Update the envmap when the view changes
setlistener("/sim/current-view/view-number", func {
    update_envmap(true);
}, 0, 0);
