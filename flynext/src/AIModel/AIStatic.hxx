/*
 * SPDX-FileName: AIStatic.hxx
 * SPDX-FileComment: AIBase derived class creates AI static object
 * SPDX-FileCopyrightText: Copyright (C) 2005  David P. Culp - davidculp2@comcast.net
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string_view>

#include "AIBase.hxx"
#include "AIManager.hxx"


class FGAIStatic : public FGAIBase
{
public:
    FGAIStatic();
    virtual ~FGAIStatic() = default;

    std::string_view getTypeString(void) const override { return "static"; }
    void update(double dt) override;
};
