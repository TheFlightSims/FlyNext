// SPDX-FileComment: expose SGCondition and SGBinding to Nasal
// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2012 James Turner <james@flightgear.org>

#pragma once

// std
#include <functional>

#include <simgear/nasal/nasal.h>
#include <simgear/structure/SGBinding.hxx>

naRef initNasalCondition(naRef globals, naContext c);

/**
 * @brief implementation of SGAbstractBinding which
 * invokes a Nasal callback. (without it being registered
 * as a command).
 * 
 * The binding argument properties are converted to a wrapped
 * Nasal Props.Node before the binding is fired
 * 
 */
class NasalBinding : public SGAbstractBinding
{
public:
    using NasalCallback = std::function<void(naRef)>;

    NasalBinding(NasalCallback cb) : m_callback(cb){};

private:
    void innerFire() const override;

    NasalCallback m_callback;
};
