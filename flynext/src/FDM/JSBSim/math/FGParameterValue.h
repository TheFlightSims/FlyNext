/*
 * SPDX-FileName: FGParameterValue.h
 * SPDX-FileComment: Author: Bertrand Coconnier, Date started: December 09 2018
 * SPDX-FileCopyrightText: Copyright (C) 2018  B. Coconnier (bcoconni@users.sf.net)
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  SENTRY
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#pragma once

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  INCLUDES
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <stdexcept>

#include "input_output/FGXMLElement.h"
#include "math/FGPropertyValue.h"
#include "math/FGRealValue.h"

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  FORWARD DECLARATIONS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

namespace JSBSim {

class FGPropertyManager;

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  CLASS DOCUMENTATION
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/** Represents a either a real value or a property value
    @author Bertrand Coconnier
*/

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  DECLARATION: FGParameterValue
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

class FGParameterValue : public FGParameter
{
public:
    FGParameterValue(Element* el, FGPropertyManager* pm)
    {
        std::string value = el->GetDataLine();

        if (el->GetNumDataLines() != 1 || value.empty()) {
            std::cerr << el->ReadFrom()
                      << "The element <" << el->GetName()
                      << "> must either contain a value number or a property name."
                      << std::endl;
            throw std::invalid_argument("FGParameterValue: Illegal argument defining: " + el->GetName());
        }

        Construct(value, pm);
    }

    FGParameterValue(const std::string& value, FGPropertyManager* pm)
    {
        Construct(value, pm);
    }

    double GetValue(void) const override { return param->GetValue(); }
    bool IsConstant(void) const override { return param->IsConstant(); }

    std::string GetName(void) const override
    {
        FGPropertyValue* v = dynamic_cast<FGPropertyValue*>(param.ptr());
        if (v)
            return v->GetNameWithSign();
        else
            return std::to_string(param->GetValue());
    }

    bool IsLateBound(void) const
    {
        FGPropertyValue* v = dynamic_cast<FGPropertyValue*>(param.ptr());
        return v != nullptr && v->IsLateBound();
    }

private:
    FGParameter_ptr param;

    void Construct(const std::string& value, FGPropertyManager* pm)
    {
        if (is_number(value)) {
            param = new FGRealValue(atof(value.c_str()));
        } else {
            // "value" must be a property if execution passes to here.
            param = new FGPropertyValue(value, pm);
        }
    }
};

typedef SGSharedPtr<FGParameterValue> FGParameterValue_ptr;

} // namespace JSBSim
