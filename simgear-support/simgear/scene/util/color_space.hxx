// color_space.hxx - Color space conversion utilities
// Copyright (C) 2023 Fernando García Liñán
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

namespace simgear {

/// Transform a linear sRGB color to sRGB (gamma correction)
void eotf_sRGB(float in[3], float out[3]);
/// Transform an sRGB color to linear sRGB
void eotf_inverse_sRGB(float in[3], float out[3]);

} // namespace simgear
