#pragma once

#include <simgear/compiler.h>

//#include STL_STRSTREAM
#include <sstream>

#include "uiuc_parsefile.h"
#include "uiuc_aircraft.h"


void uiuc_2DdataFileReader( std::string file_name, 
                            double x[100][100], 
                            double y[100], 
                            double z[100][100], 
                            int xmax[100], 
                            int &ymax);
