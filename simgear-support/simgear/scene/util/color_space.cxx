// color_space.cxx - Color space conversion utilities
// Copyright (C) 2023 Fernando García Liñán
// SPDX-License-Identifier: LGPL-2.0-or-later

#include "color_space.hxx"

#include <cmath>

namespace simgear {

void
eotf_sRGB(float in[3], float out[3])
{
    for (int i = 0; i < 3; ++i) {
        float c = in[i];
        if (c <= 0.0031308f) {
            out[i] = 12.92f * c;
        } else {
            out[i] = 1.055f * std::pow(c, 1.0f / 2.4f) - 0.055f;
        }
    }
}

void
eotf_inverse_sRGB(float in[3], float out[3])
{
    for (int i = 0; i < 3; ++i) {
        float c = in[i];
        if (c <= 0.04045f) {
            out[i] = c / 12.92f;
        } else {
            out[i] = powf((c + 0.055f) / 1.055f, 2.4f);
        }
    }
}

} // namespace simgear
