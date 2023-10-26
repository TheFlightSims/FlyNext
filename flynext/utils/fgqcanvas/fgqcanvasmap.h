//
// Copyright (C) 2017 James Turner  zakalawe@mac.com
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License as
// published by the Free Software Foundation; either version 2 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#ifndef FGQCANVASMAP_H
#define FGQCANVASMAP_H

#include "fgcanvasgroup.h"

class FGQCanvasMap : public FGCanvasGroup
{
public:
    FGQCanvasMap(FGCanvasGroup* pr, LocalProp* prop);

protected:
    virtual void doPaint(FGCanvasPaintContext* context) const;

    virtual bool onChildAdded(LocalProp* prop);

private:
    void markProjectionDirty();

private:
    double _projectionCenterLat;
    double _projectionCenterLon;
    double _range;

    mutable bool _projectionChanged;
};

#endif // FGQCANVASMAP_H
