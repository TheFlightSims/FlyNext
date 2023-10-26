#pragma once

#include <simgear/compiler.h>

//#include STL_STRSTREAM
#include <sstream>

#include "uiuc_parsefile.h"
#include "uiuc_aircraft.h"
#include "uiuc_warnings_errors.h"


int uiuc_1DdataFileReader( std::string file_name, 
                            double x[], 
                            double y[], 
                            int &xmax );
int uiuc_1DdataFileReader( std::string file_name, 
                           double x[], 
                           int y[], 
                           int &xmax );
