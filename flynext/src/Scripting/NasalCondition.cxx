// SPDX-FileComment: expose SGCondition and SGBinding to Nasal
// SPDX-License-Identifier: GPL-2.0-or-later
// Copyright (C) 2012 James Turner <james@flightgear.org>

#include "config.h"

#include "NasalCondition.hxx"
#include "NasalSys.hxx"
#include <Main/globals.hxx>

#include <simgear/nasal/cppbind/Ghost.hxx>
#include <simgear/nasal/cppbind/NasalHash.hxx>
#include <simgear/props/condition.hxx>

using NasalBindingRef = SGSharedPtr<NasalBinding>;

typedef nasal::Ghost<SGConditionRef> NasalCondition;

void NasalBinding::innerFire() const
{
    auto nas = globals->get_subsystem<FGNasalSys>();
    m_callback(nas->wrappedPropsNode(_arg));
}

//------------------------------------------------------------------------------
static naRef f_createCondition(naContext c, naRef me, int argc, naRef* args)
{
  SGPropertyNode* node = argc > 0
                       ? ghostToPropNode(args[0])
                       : NULL;
  SGPropertyNode* root = argc > 1
                       ? ghostToPropNode(args[1])
                       : globals->get_props();

  if( !node || !root )
    naRuntimeError(c, "createCondition: invalid argument(s)");

  try
  {
    return nasal::to_nasal(c, sgReadCondition(root, node));
  }
  catch(std::exception& ex)
  {
    naRuntimeError(c, "createCondition: %s", ex.what());
  }

  return naNil();
}

//------------------------------------------------------------------------------
naRef initNasalCondition(naRef globals, naContext c)
{
  nasal::Ghost<SGConditionRef>::init("Condition")
    .method("test", &SGCondition::test);

  nasal::Hash(globals, c).set("_createCondition", f_createCondition);


  return naNil();
}
