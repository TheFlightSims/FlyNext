// Copyright (C) 2018 - 2023 Fernando García Liñán
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <unordered_map>

namespace simgear {
namespace compositor {

/**
 * Lookup table that ties a string property value to a type that cannot be
 * represented in the property tree. Useful for OSG or OpenGL enums.
 */
template<class T>
using PropStringMap = std::unordered_map<std::string, T>;

template <class T>
bool findPropString(const std::string &str,
                    T &value,
                    const PropStringMap<T> &map)
{
    auto itr = map.find(str);
    if (itr == map.end())
        return false;

    value = itr->second;
    return true;
}

template <class T>
bool findPropString(const SGPropertyNode *parent,
                    const std::string &child_name,
                    T &value,
                    const PropStringMap<T> &map)
{
    const SGPropertyNode *child = parent->getNode(child_name);
    if (child) {
        if (findPropString<T>(child->getStringValue(), value, map))
            return true;
    }
    return false;
}

/**
 * Check if node should be enabled based on a condition tag.
 * If no condition tag is found inside or it is malformed, it will be enabled.
 */
bool checkConditional(const SGPropertyNode *node);

const SGPropertyNode *getPropertyNode(const SGPropertyNode *prop);
const SGPropertyNode *getPropertyChild(const SGPropertyNode *prop,
                                       const char *name);

} // namespace compositor
} // namespace simgear
