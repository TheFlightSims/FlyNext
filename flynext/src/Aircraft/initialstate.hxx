/*
 * SPDX-FileName: initialstate.hxx
 * SPDX-FileComment: setup initial state of the aircraft
 * SPDX-FileCopyrightText: Copyright (C) 2016 James Turner <zakalawe@mac.com>
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string>


namespace flightgear {

/**
 * @brief is the supplied name a defined initial-state, or alias of one
 */
bool isInitialStateName(const std::string& name);

void applyInitialState();

} // namespace flightgear
