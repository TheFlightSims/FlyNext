
#pragma once

#include "uiuc_aircraft.h"
#include "uiuc_convert.h"
#include "uiuc_1DdataFileReader.h"
#include "uiuc_2DdataFileReader.h"
#include "uiuc_menu_functions.h"
#include <FDM/LaRCsim/ls_generic.h>
#include <FDM/LaRCsim/ls_cockpit.h>    /* Long_trim defined */
#include <FDM/LaRCsim/ls_constants.h>  /* INVG defined */

void parse_Cl( const std::string& linetoken2, const std::string& linetoken3,
               const std::string& linetoken4, const std::string& linetoken5, 
               const std::string& linetoken6, const std::string& linetoken7,
               const std::string& linetoken8, const std::string& linetoken9,
               const std::string& linetoken10, const std::string& aircraft_directory,
               LIST command_line );
