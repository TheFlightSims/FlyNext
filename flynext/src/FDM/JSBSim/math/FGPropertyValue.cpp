/*
 * SPDX-FileName: FGPropertyValue.cpp
 * SPDX-FileComment: Stores property values
 * SPDX-FileCopyrightText: Copyright (C) 2001  Jon S. Berndt (jon@jsbsim.org)
 * SPDX-FileContributor: Copyright (C) 2010 - 2011  Anders Gidenstam (anders(at)gidenstam.org)
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
INCLUDES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <assert.h>

#include "FGPropertyValue.h"

namespace JSBSim {

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CLASS IMPLEMENTATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

FGPropertyValue::FGPropertyValue(const std::string& propName,
                                 FGPropertyManager* propertyManager)
  : PropertyManager(propertyManager), PropertyNode(nullptr),
    PropertyName(propName), Sign(1.0)
{
  if (PropertyName[0] == '-') {
    PropertyName.erase(0,1);
    Sign = -1.0;
  }

  if (PropertyManager->HasNode(PropertyName))
    PropertyNode = PropertyManager->GetNode(PropertyName);
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FGPropertyNode* FGPropertyValue::GetNode(void) const
{
  if (!PropertyNode) {
    FGPropertyNode* node = PropertyManager->GetNode(PropertyName);
    
    if (!node)
      throw(std::string("FGPropertyValue::GetValue() The property " +
                        PropertyName + " does not exist."));

    PropertyNode = node;
  }

  return PropertyNode;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

double FGPropertyValue::GetValue(void) const
{
  return GetNode()->getDoubleValue()*Sign;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

void FGPropertyValue::SetValue(double value)
{
  // SetValue() ignores the Sign flag. So make sure it is never called with a
  // negative sign.
  assert(Sign == 1);
  GetNode()->setDoubleValue(value);
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

std::string FGPropertyValue::GetName(void) const
{
  if (PropertyNode)
    return PropertyNode->GetName();
  else
    return PropertyName;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

std::string FGPropertyValue::GetNameWithSign(void) const
{
  std::string name;

  if (Sign < 0.0) name ="-";

  name += GetName();

  return name;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

std::string FGPropertyValue::GetFullyQualifiedName(void) const
{
  if (PropertyNode)
    return PropertyNode->GetFullyQualifiedName();
  else
    return PropertyName;
}

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

std::string FGPropertyValue::GetPrintableName(void) const
{
  if (PropertyNode)
    return PropertyNode->GetPrintableName();
  else
    return PropertyName;
}

}
