// Copyright (C) 2018 - 2023 Fernando García Liñán
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <simgear/props/condition.hxx>
#include <simgear/props/props.hxx>
#include <simgear/scene/tgdb/userdata.hxx>

#include "CompositorUtil.hxx"

namespace simgear {
namespace compositor {

bool
checkConditional(const SGPropertyNode *node)
{
    const SGPropertyNode *p_condition = node->getChild("condition");
    if (!p_condition)
        return true;
    SGSharedPtr<SGCondition> condition =
        sgReadCondition(getPropertyRoot(), p_condition);
    return !condition || condition->test();
}

const SGPropertyNode *
getPropertyNode(const SGPropertyNode *prop)
{
    if (!prop)
        return 0;
    if (prop->nChildren() > 0) {
        const SGPropertyNode *propertyProp = prop->getChild("property");
        if (!propertyProp)
            return prop;
        return getPropertyRoot()->getNode(propertyProp->getStringValue());
    }
    return prop;
}

const SGPropertyNode *
getPropertyChild(const SGPropertyNode *prop,
                 const char *name)
{
    const SGPropertyNode *child = prop->getChild(name);
    if (!child)
        return 0;
    return getPropertyNode(child);
}

} // namespace compositor
} // namespace simgear
