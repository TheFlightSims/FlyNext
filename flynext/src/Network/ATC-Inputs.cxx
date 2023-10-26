// ATC-Inputs.hxx -- Translate ATC hardware inputs to FGFS properties
//
// Written by Curtis Olson, started November 2004.
//
// Copyright (C) 2004  Curtis L. Olson - http://www.flightgear.org/~curt
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
//
// $Id$


#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include <simgear/compiler.h>

#if defined( unix ) || defined( __CYGWIN__ )
#  include <sys/types.h>
#  include <sys/stat.h>
#  include <fcntl.h>
#  include <stdlib.h>
#  include <unistd.h>
#  include <istream>
#endif

#include <errno.h>
#include <cmath>
#include <cstdio>

#include <string>

#include <simgear/debug/logstream.hxx>
#include <simgear/misc/sg_path.hxx>
#include <simgear/props/props_io.hxx>

#include <Main/fg_props.hxx>

#include "ATC-Inputs.hxx"

using std::string;
using std::vector;


// Constructor: The _board parameter specifies which board to
// reference.  Possible values are 0 or 1.  The _config_file parameter
// specifies the location of the input config file (xml)
FGATCInput::FGATCInput( const int _board, const SGPath &_config_file ) :
    is_open(false),
    ignore_flight_controls(NULL),
    ignore_pedal_controls(NULL),
    analog_in_node(NULL),
    radio_in_node(NULL),
    switches_node(NULL)
{
    board = _board;
    config = _config_file;
}


// Read analog inputs
static void ATCReadAnalogInputs( int fd, unsigned char *analog_in_bytes ) {
#if defined( unix ) || defined( __CYGWIN__ )
    // rewind
    lseek( fd, 0, SEEK_SET );

    int result = read( fd, analog_in_bytes, ATC_ANAL_IN_BYTES );
    if ( result != ATC_ANAL_IN_BYTES ) {
	SG_LOG( SG_IO, SG_ALERT, "Read failed" );
	exit( -1 );
    }
#endif
}


// Read status of radio switches and knobs
static void ATCReadRadios( int fd, unsigned char *switch_data ) {
#if defined( unix ) || defined( __CYGWIN__ )
    // rewind
    lseek( fd, 0, SEEK_SET );

    int result = read( fd, switch_data, ATC_RADIO_SWITCH_BYTES );
    if ( result != ATC_RADIO_SWITCH_BYTES ) {
	SG_LOG( SG_IO, SG_ALERT, "Read failed" );
	exit( -1 );
    }
#endif
}


// Read switch inputs
static void ATCReadSwitches( int fd, unsigned char *switch_bytes ) {
#if defined( unix ) || defined( __CYGWIN__ )
    // rewind
    lseek( fd, 0, SEEK_SET );

    int result = read( fd, switch_bytes, ATC_SWITCH_BYTES );
    if ( result != ATC_SWITCH_BYTES ) {
	SG_LOG( SG_IO, SG_ALERT, "Read failed" );
	exit( -1 );
    }
#endif
}


void FGATCInput::init_config() {
#if defined( unix ) || defined( __CYGWIN__ )
    if ( !config.isAbsolute() ) {
        // not an absolute path, prepend the standard location
        SGPath tmp = SGPath::home();
        tmp.append( ".atcflightsim" );
        tmp.append( config.utf8Str() );
    }
    readProperties( config, globals->get_props() );
#endif
}


// Open and initialize the ATC hardware
bool FGATCInput::open() {
    if ( is_open ) {
	SG_LOG( SG_IO, SG_ALERT, "This board is already open for input! "
                << board );
	return false;
    }

    // This loads the config parameters generated by "simcal"
    init_config();

    SG_LOG( SG_IO, SG_ALERT,
	    "Initializing ATC input hardware, please wait ..." );

    snprintf( analog_in_file, 256,
              "/proc/atcflightsim/board%d/analog_in", board );
    snprintf( radios_file, 256,
              "/proc/atcflightsim/board%d/radios", board );
    snprintf( switches_file, 256,
              "/proc/atcflightsim/board%d/switches", board );

#if defined( unix ) || defined( __CYGWIN__ )

    /////////////////////////////////////////////////////////////////////
    // Open the /proc files
    /////////////////////////////////////////////////////////////////////

    analog_in_fd = ::open( analog_in_file, O_RDONLY );
    if ( analog_in_fd == -1 ) {
	SG_LOG( SG_IO, SG_ALERT, "errno = " << errno );
	char msg[300];
	snprintf( msg, 300, "Error opening %s", analog_in_file );
	perror( msg );
	exit( -1 );
    }

    radios_fd = ::open( radios_file, O_RDWR );
    if ( radios_fd == -1 ) {
	SG_LOG( SG_IO, SG_ALERT, "errno = " << errno );
	char msg[300];
	snprintf( msg, 300, "Error opening %s", radios_file );
	perror( msg );
	exit( -1 );
    }

    switches_fd = ::open( switches_file, O_RDONLY );
    if ( switches_fd == -1 ) {
	SG_LOG( SG_IO, SG_ALERT, "errno = " << errno );
	char msg[300];
	snprintf( msg, 300, "Error opening %s", switches_file );
	perror( msg );
	exit( -1 );
    }

#endif

    /////////////////////////////////////////////////////////////////////
    // Finished initing hardware
    /////////////////////////////////////////////////////////////////////

    SG_LOG( SG_IO, SG_ALERT,
	    "Done initializing ATC input hardware." );

    is_open = true;

    /////////////////////////////////////////////////////////////////////
    // Connect up to property values
    /////////////////////////////////////////////////////////////////////

    ignore_flight_controls
        = fgGetNode( "/input/atcsim/ignore-flight-controls", true );
    ignore_pedal_controls
        = fgGetNode( "/input/atcsim/ignore-pedal-controls", true );

    char base_name[256];

    snprintf( base_name, 256, "/input/atc-board[%d]/analog-in", board );
    analog_in_node = fgGetNode( base_name );

    snprintf( base_name, 256, "/input/atc-board[%d]/radio-switches", board );
    radio_in_node = fgGetNode( base_name );

    snprintf( base_name, 256, "/input/atc-board[%d]/switches", board );
    switches_node = fgGetNode( base_name );

    return true;
}


/////////////////////////////////////////////////////////////////////
// Read analog inputs
/////////////////////////////////////////////////////////////////////

// scale a number between min and max (with center defined) to a scale
// from -1.0 to 1.0.  The deadband value is symmetric, so specifying
// '1' will give you a deadband of +/-1
static double scale( int center, int deadband, int min, int max, int value ) {
    // cout << center << " " << min << " " << max << " " << value << " ";
    double result;
    double range;

    if ( value <= (center - deadband) ) {
        range = (center - deadband) - min;
        result = (value - (center - deadband)) / range;
    } else if ( value >= (center + deadband) ) {
        range = max - (center + deadband);
        result = (value - (center + deadband)) / range;
    } else {
        result = 0.0;
    }

    if ( result < -1.0 ) result = -1.0;
    if ( result > 1.0 ) result = 1.0;

    // cout << result << endl;

    return result;
}


// scale a number between min and max to a scale from 0.0 to 1.0
static double scale( int min, int max, int value ) {
    // cout << center << " " << min << " " << max << " " << value << " ";
    double result;
    double range;

    range = max - min;
    result = (value - min) / range;

    if ( result < 0.0 ) result = 0.0;
    if ( result > 1.0 ) result = 1.0;

    // cout << result << endl;

    return result;
}


static double clamp( double min, double max, double value ) {
    double result = value;

    if ( result < min ) result = min;
    if ( result > max ) result = max;

    // cout << result << endl;

    return result;
}


static int tony_magic( int raw, int obs[3] ) {
    int result = 0;

    obs[0] = raw;

    if ( obs[1] < 30 ) {
        if ( obs[2] >= 68 && obs[2] < 480 ) {
            result = -6;
        } else if ( obs[2] >= 480 ) {
            result = 6;
        }
        obs[2] = obs[1];
        obs[1] = obs[0];
    } else if ( obs[1] < 68 ) {
        // do nothing
        obs[1] = obs[0];
    } else if ( obs[2] < 30 ) {
        if ( obs[1] >= 68 && obs[1] < 480 ) {
            result = 6;
	    obs[2] = obs[1];
	    obs[1] = obs[0];
        } else if ( obs[1] >= 480 ) {
	    result = -6;
            if ( obs[0] < obs[1] ) {
		obs[2] = obs[1];
		obs[1] = obs[0];
	    } else {
	        obs[2] = obs[0];
		obs[1] = obs[0];
	    }
        }
    } else if ( obs[1] > 980 ) {
        if ( obs[2] <= 956 && obs[2] > 480 ) {
            result = 6;
        } else if ( obs[2] <= 480 ) {
            result = -6;
        }
        obs[2] = obs[1];
        obs[1] = obs[0];
    } else if ( obs[1] > 956 ) {
        // do nothing
        obs[1] = obs[0];
    } else if ( obs[2] > 980 ) {
        if ( obs[1] <= 956 && obs[1] > 480 ) {
            result = -6;
	    obs[2] = obs[1];
	    obs[1] = obs[0];
        } else if ( obs[1] <= 480 ) {
	    result = 6;
            if ( obs[0] > obs[1] ) {
		obs[2] = obs[1];
		obs[1] = obs[0];
	    } else {
		obs[2] = obs[0];
		obs[1] = obs[0];
	    }
        }
    } else {
        if ( obs[1] < 480 && obs[2] > 480 ) {
	    // crossed gap going up
	    if ( obs[0] < obs[1] ) {
	        // caught a bogus intermediate value coming out of the gap
	        obs[1] = obs[0];
	    }
	} else if ( obs[1] > 480 && obs[2] < 480 ) {
	    // crossed gap going down
	    if ( obs[0] > obs[1] ) {
	        // caught a bogus intermediate value coming out of the gap
	      obs[1] = obs[0];
	    }
	} else if ( obs[0] > 480 && obs[1] < 480 && obs[2] < 480 ) {
            // crossed the gap going down
	    if ( obs[1] > obs[2] ) {
	        // caught a bogus intermediate value coming out of the gap
	        obs[1] = obs[2];
	    }
	} else if ( obs[0] < 480 && obs[1] > 480 && obs[2] > 480 ) {
            // crossed the gap going up
	    if ( obs[1] < obs[2] ) {
	        // caught a bogus intermediate value coming out of the gap
	        obs[1] = obs[2];
	    }
	}
        result = obs[1] - obs[2];
        if ( abs(result) > 400 ) {
            // ignore
            result = 0;
        }
        obs[2] = obs[1];
        obs[1] = obs[0];
    }

    // cout << " result = " << result << endl;
    if ( result < -500 ) { result += 1024; }
    if ( result > 500 ) { result -= 1024; }

    return result;
}


static double instr_pot_filter( double ave, double val ) {
    if ( fabs(ave - val) < 400 || fabs(val) < fabs(ave) ) {
        return 0.5 * ave + 0.5 * val;
    } else {
        return ave;
    }
}


bool FGATCInput::do_analog_in() {
    // Read raw data in byte form
    ATCReadAnalogInputs( analog_in_fd, analog_in_bytes );

    // Convert to integer values
    for ( int channel = 0; channel < ATC_ANAL_IN_VALUES; ++channel ) {
	unsigned char hi = analog_in_bytes[2 * channel] & 0x03;
	unsigned char lo = analog_in_bytes[2 * channel + 1];
	analog_in_data[channel] = hi * 256 + lo;

	// printf("%02x %02x ", hi, lo );
	// printf("%04d ", value );
    }

    // Process analog inputs
    if ( analog_in_node != NULL ) {
        for ( int i = 0; i < analog_in_node->nChildren(); ++i ) {
            // read the next config entry from the property tree

            SGPropertyNode *child = analog_in_node->getChild(i);
            string cname = child->getNameString();
            int index = child->getIndex();
            string name = "";
            string type = "";
            string subtype = "";
            vector <SGPropertyNode *> output_nodes;
            int center = -1;
            int min = 0;
            int max = 1023;
	    int deadband = 0;
	    int hysteresis = 0;
            float offset = 0.0;
            float factor = 1.0;
            if ( cname == "channel" ) {
                SGPropertyNode *prop;
                prop = child->getChild( "name" );
                if ( prop != NULL ) {
                    name = prop->getStringValue();
                }
                prop = child->getChild( "type", 0 );
                if ( prop != NULL ) {
                    type = prop->getStringValue();
                }
                prop = child->getChild( "type", 1 );
                if ( prop != NULL ) {
                    subtype = prop->getStringValue();
                }
                int j = 0;
                while ( (prop = child->getChild("prop", j)) != NULL ) {
                    SGPropertyNode *tmp
                        = fgGetNode( prop->getStringValue(), true );
                    output_nodes.push_back( tmp );
                    j++;
                }
                prop = child->getChild( "center" );
                if ( prop != NULL ) {
                    center = prop->getIntValue();
                }
                prop = child->getChild( "min" );
                if ( prop != NULL ) {
                    min = prop->getIntValue();
                }
                prop = child->getChild( "max" );
                if ( prop != NULL ) {
                    max = prop->getIntValue();
                }
                prop = child->getChild( "deadband" );
                if ( prop != NULL ) {
                    deadband = prop->getIntValue();
                }
                prop = child->getChild( "hysteresis" );
                if ( prop != NULL ) {
                    hysteresis = prop->getIntValue();
                }
                prop = child->getChild( "offset" );
                if ( prop != NULL ) {
                    offset = prop->getFloatValue();
                }
                prop = child->getChild( "factor" );
                if ( prop != NULL ) {
                    factor = prop->getFloatValue();
                }

                // Fetch the raw value

                int raw_value = analog_in_data[index];

                // Update the target properties

                if ( type == "flight"
                     && !ignore_flight_controls->getBoolValue() )
                {
                    if ( subtype != "pedals" ||
                         ( subtype == "pedals"
                           && !ignore_pedal_controls->getBoolValue() ) )
                    {
                        // "Cook" the raw value
                        float scaled_value = 0.0f;

			if ( hysteresis > 0 ) {
			    int last_raw_value = 0;
			    prop = child->getChild( "last-raw-value", 0, true );
			    last_raw_value = prop->getIntValue();

			    if ( abs(raw_value - last_raw_value) < hysteresis )
			    {
				// not enough movement stay put
				raw_value = last_raw_value;
			    } else {
				// update last raw value
				prop->setIntValue( raw_value );
			    }
			}

                        if ( center >= 0 ) {
                            scaled_value = scale( center, deadband,
						  min, max, raw_value );
                        } else {
                            scaled_value = scale( min, max, raw_value );
                        }
                        scaled_value *= factor;
                        scaled_value += offset;

                        // final sanity clamp
                        if ( center >= 0 ) {
                            scaled_value = clamp( -1.0, 1.0, scaled_value );
                        } else {
                            scaled_value = clamp( 0.0, 1.0, scaled_value );
                        }

                        // update the property tree values
                        for ( j = 0; j < (int)output_nodes.size(); ++j ) {
                            output_nodes[j]->setDoubleValue( scaled_value );
                        }
                    }
                } else if ( type == "avionics-simple" ) {
                    // "Cook" the raw value
                    float scaled_value = 0.0f;
                    if ( center >= 0 ) {
                        scaled_value = scale( center, deadband,
					      min, max, raw_value );
                    } else {
                        scaled_value = scale( min, max, raw_value );
                    }
                    scaled_value *= factor;
                    scaled_value += offset;

                    // final sanity clamp
                    if ( center >= 0 ) {
                        scaled_value = clamp( -1.0, 1.0, scaled_value );
                    } else {
                        scaled_value = clamp( 0.0, 1.0, scaled_value );
                    }

                    // update the property tree values
                    for ( j = 0; j < (int)output_nodes.size(); ++j ) {
                        output_nodes[j]->setDoubleValue( scaled_value );
                    }
                } else if ( type == "avionics-resolver" ) {
                    // this type of analog input impliments a
                    // rotational knob.  We first caclulate the amount
                    // of knob rotation (slightly complex to work with
                    // hardware specific goofiness) and then multiply
                    // that amount of movement by a scaling factor,
                    // and finally add the result to the original
                    // value.

                    bool do_init = false;
                    float scaled_value = 0.0f;

                    // fetch intermediate values from property tree

                    prop = child->getChild( "is-inited", 0 );
                    if ( prop == NULL ) {
                        do_init = true;
                        prop = child->getChild( "is-inited", 0, true );
                        prop->setBoolValue( true );
                    }

                    int raw[3];
                    for ( j = 0; j < 3; ++j ) {
                        prop = child->getChild( "raw", j, true );
                        if ( do_init ) {
                            raw[j] = analog_in_data[index];
                        } else {
                            raw[j] = prop->getIntValue();
                        }
                    }

                    // do Tony's magic to calculate knob movement
                    // based on current analog input position and
                    // historical data.
                    int diff = tony_magic( analog_in_data[index], raw );

                    // write raw intermediate values (updated by
                    // tony_magic()) back to property tree
                    for ( j = 0; j < 3; ++j ) {
                        prop = child->getChild( "raw", j, true );
                        prop->setIntValue( raw[j] );
                    }

                    // filter knob position
                    prop = child->getChild( "diff-average", 0, true );
                    double diff_ave = prop->getDoubleValue();
                    diff_ave = instr_pot_filter( diff_ave, diff );
                    prop->setDoubleValue( diff_ave );

                    // calculate value adjustment in real world units
                    scaled_value = diff_ave * factor;

                    // update the property tree values
                    for ( j = 0; j < (int)output_nodes.size(); ++j ) {
                        float value = output_nodes[j]->getDoubleValue();
                        value += scaled_value;

                        prop = child->getChild( "min-clamp" );
                        if ( prop != NULL ) {
                            double min = prop->getDoubleValue();
                            if ( value < min ) { value = min; }
                        }

                        prop = child->getChild( "max-clamp" );
                        if ( prop != NULL ) {
                            double max = prop->getDoubleValue();
                            if ( value > max ) { value = max; }
                        }

                        prop = child->getChild( "compass-heading" );
                        if ( prop != NULL ) {
                            bool compass = prop->getBoolValue();
                            if ( compass ) {
                                while ( value >= 360.0 ) { value -= 360.0; }
                                while ( value < 0.0 ) { value += 360.0; }
                            }
                        }

                        output_nodes[j]->setDoubleValue( value );
                    }

                } else {
                    SG_LOG( SG_IO, SG_DEBUG, "Invalid channel type =  "
                            << type );
                }
            } else {
                SG_LOG( SG_IO, SG_DEBUG,
                        "Input config error, expecting 'channel' but found "
                        << cname );
            }
        }
    }

    return true;
}


/////////////////////////////////////////////////////////////////////
// Read the switch positions
/////////////////////////////////////////////////////////////////////

// decode the packed switch data
static void update_switch_matrix(
        int board,
	unsigned char switch_data[ATC_SWITCH_BYTES],
	int switch_matrix[2][ATC_NUM_COLS][ATC_SWITCH_BYTES] )
{
    for ( int row = 0; row < ATC_SWITCH_BYTES; ++row ) {
	unsigned char switches = switch_data[row];

	for( int column = 0; column < ATC_NUM_COLS; ++column ) {
            if ( row < 8 ) {
                switch_matrix[board][column][row] = switches & 1;
            } else {
                switch_matrix[board][row-8][8+column] = switches & 1;
            }
            switches = switches >> 1;
        }
    }
}

bool FGATCInput::do_switches() {
    // Read the raw data
    ATCReadSwitches( switches_fd, switch_data );

    // unpack the switch data
    int switch_matrix[2][ATC_NUM_COLS][ATC_SWITCH_BYTES];
    update_switch_matrix( board, switch_data, switch_matrix );

    // Process the switch inputs
    if ( switches_node != NULL ) {
        for ( int i = 0; i < switches_node->nChildren(); ++i ) {
            // read the next config entry from the property tree

            SGPropertyNode *child = switches_node->getChild(i);
            string cname = child->getNameString();
            string name = "";
            string type = "";
            vector <SGPropertyNode *> output_nodes;
            int row = -1;
            int col = -1;
            float factor = 1.0;
            int filter = -1;
            float scaled_value = 0.0f;
	    bool invert = false;

            // get common options

            SGPropertyNode *prop;
            prop = child->getChild( "name" );
            if ( prop != NULL ) {
                name = prop->getStringValue();
            }
            prop = child->getChild( "type" );
            if ( prop != NULL ) {
                type = prop->getStringValue();
            }
            int j = 0;
            while ( (prop = child->getChild("prop", j)) != NULL ) {
                SGPropertyNode *tmp
                    = fgGetNode( prop->getStringValue(), true );
                output_nodes.push_back( tmp );
                j++;
            }
            prop = child->getChild( "factor" );
            if ( prop != NULL ) {
                factor = prop->getFloatValue();
            }
            prop = child->getChild( "invert" );
            if ( prop != NULL ) {
                invert = prop->getBoolValue();
            }
            prop = child->getChild( "steady-state-filter" );
            if ( prop != NULL ) {
                filter = prop->getIntValue();
            }

            // handle different types of switches

            if ( cname == "switch" ) {
                prop = child->getChild( "row" );
                if ( prop != NULL ) {
                    row = prop->getIntValue();
                }
                prop = child->getChild( "col" );
                if ( prop != NULL ) {
                    col = prop->getIntValue();
                }

                // Fetch the raw value
                int raw_value = switch_matrix[board][row][col];

		// Invert
		if ( invert ) {
		    raw_value = !raw_value;
		}

                // Cook the value
                scaled_value = (float)raw_value * factor;

            } else if ( cname == "combo-switch" ) {
                float combo_value = 0.0f;

                SGPropertyNode *pos;
                int k = 0;
                while ( (pos = child->getChild("position", k++)) != NULL ) {
                    // read the combo position entries from the property tree

                    prop = pos->getChild( "row" );
                    if ( prop != NULL ) {
                        row = prop->getIntValue();
                    }
                    prop = pos->getChild( "col" );
                    if ( prop != NULL ) {
                        col = prop->getIntValue();
                    }
                    prop = pos->getChild( "value" );
                    if ( prop != NULL ) {
                        combo_value = prop->getFloatValue();
                    }

                    // Fetch the raw value
                    int raw_value = switch_matrix[board][row][col];
                    // cout << "sm[" << board << "][" << row << "][" << col
                    //      << "] = " << raw_value << endl;

                    if ( raw_value ) {
                        // set scaled_value to the first combo_value
                        // that matches and jump out of loop.
                        scaled_value = combo_value;
                        break;
                    }
                }

                // Cook the value
                scaled_value *= factor;
            } else if ( cname == "additive-switch" ) {
                float additive_value = 0.0f;
		float increment = 0.0f;

                SGPropertyNode *pos;
                int k = 0;
                while ( (pos = child->getChild("position", k++)) != NULL ) {
                    // read the combo position entries from the property tree

                    prop = pos->getChild( "row" );
                    if ( prop != NULL ) {
                        row = prop->getIntValue();
                    }
                    prop = pos->getChild( "col" );
                    if ( prop != NULL ) {
                        col = prop->getIntValue();
                    }
                    prop = pos->getChild( "value" );
                    if ( prop != NULL ) {
                        increment = prop->getFloatValue();
                    }

                    // Fetch the raw value
                    int raw_value = switch_matrix[board][row][col];
                    // cout << "sm[" << board << "][" << row << "][" << col
                    //      << "] = " << raw_value << endl;

                    if ( raw_value ) {
                        // set scaled_value to the first combo_value
                        // that matches and jump out of loop.
                        additive_value += increment;
                    }
                }

                // Cook the value
                scaled_value = additive_value * factor;
            }

            // handle filter request.  The value of the switch must be
            // steady-state for "n" frames before the property value
            // is updated.

            bool update_prop = true;

            if ( filter > 1 ) {
                SGPropertyNode *fv = child->getChild( "filter-value", 0, true );
                float filter_value = fv->getFloatValue();
                SGPropertyNode *fc = child->getChild( "filter-count", 0, true );
                int filter_count = fc->getIntValue();

                if ( fabs(scaled_value - filter_value) < 0.0001 ) {
                    filter_count++;
                } else {
                    filter_count = 0;
                }

                if ( filter_count < filter ) {
                    update_prop = false;
                }

                fv->setFloatValue( scaled_value );
                fc->setIntValue( filter_count );
            }

            if ( update_prop ) {
                if ( type == "engine" || type == "flight" ) {
                    if ( ! ignore_flight_controls->getBoolValue() ) {
                        // update the property tree values
                        for ( j = 0; j < (int)output_nodes.size(); ++j ) {
                            output_nodes[j]->setDoubleValue( scaled_value );
                        }
                    }
                } else if ( type == "avionics" ) {
                    // update the property tree values
                    for ( j = 0; j < (int)output_nodes.size(); ++j ) {
                        output_nodes[j]->setDoubleValue( scaled_value );
                    }
                }
            }
        }
    }

    return true;
}


/////////////////////////////////////////////////////////////////////
// Read radio switches
/////////////////////////////////////////////////////////////////////

bool FGATCInput::do_radio_switches() {
    // Read the raw data
    ATCReadRadios( radios_fd, radio_switch_data );

    // Process the radio switch/knob inputs
    if ( radio_in_node != NULL ) {
        for ( int i = 0; i < radio_in_node->nChildren(); ++i ) {
            // read the next config entry from the property tree

            SGPropertyNode *child = radio_in_node->getChild(i);
            string cname = child->getNameString();

            if ( cname == "switch" ) {
                string name = "";
                string type = "";
                vector <SGPropertyNode *> output_nodes;
                int byte_num = -1;
                int right_shift = 0;
                int mask = 0xff;
                int factor = 1;
                int offset = 0;
                bool invert = false;
                int scaled_value = 0;
                // get common options

                SGPropertyNode *prop;
                prop = child->getChild( "name" );
                if ( prop != NULL ) {
                    name = prop->getStringValue();
                }
                prop = child->getChild( "type" );
                if ( prop != NULL ) {
                    type = prop->getStringValue();
                }
                int j = 0;
                while ( (prop = child->getChild("prop", j)) != NULL ) {
                    SGPropertyNode *tmp
                        = fgGetNode( prop->getStringValue(), true );
                    output_nodes.push_back( tmp );
                    j++;
                }
                prop = child->getChild( "byte" );
                if ( prop != NULL ) {
                    byte_num = prop->getIntValue();
                }
                prop = child->getChild( "right-shift" );
                if ( prop != NULL ) {
                    right_shift = prop->getIntValue();
                }
                prop = child->getChild( "mask" );
                if ( prop != NULL ) {
                    mask = prop->getIntValue();
                }
                prop = child->getChild( "factor" );
                if ( prop != NULL ) {
                    factor = prop->getIntValue();
                }
                prop = child->getChild( "offset" );
                if ( prop != NULL ) {
                    offset = prop->getIntValue();
                }
                prop = child->getChild( "invert" );
                if ( prop != NULL ) {
                    invert = prop->getBoolValue();
                }

                // Fetch the raw value
                int raw_value
                    = (radio_switch_data[byte_num] >> right_shift) & mask;

                // Cook the value
                if ( invert ) {
                    raw_value = !raw_value;
                }
                scaled_value = raw_value * factor + offset;

                // update the property tree values
                for ( j = 0; j < (int)output_nodes.size(); ++j ) {
                    output_nodes[j]->setIntValue( scaled_value );
                }
            }
        }
    }

    return true;
}


// process the hardware inputs.  This code assumes the calling layer
// will lock the hardware.
bool FGATCInput::process() {
    if ( !is_open ) {
	SG_LOG( SG_IO, SG_ALERT, "This board has not been opened for input! "
                << board );
	return false;
    }

    do_analog_in();
    do_switches();
    do_radio_switches();

    return true;
}


bool FGATCInput::close() {

#if defined( unix ) || defined( __CYGWIN__ )

    if ( !is_open ) {
        return true;
    }

    int result;

    result = ::close( analog_in_fd );
    if ( result == -1 ) {
	SG_LOG( SG_IO, SG_ALERT, "errno = " << errno );
	char msg[300];
	snprintf( msg, 300, "Error closing %s", analog_in_file );
	perror( msg );
	exit( -1 );
    }

    result = ::close( radios_fd );
    if ( result == -1 ) {
	SG_LOG( SG_IO, SG_ALERT, "errno = " << errno );
	char msg[300];
	snprintf( msg, 300, "Error closing %s", radios_file );
	perror( msg );
	exit( -1 );
    }

    result = ::close( switches_fd );
    if ( result == -1 ) {
	SG_LOG( SG_IO, SG_ALERT, "errno = " << errno );
	char msg[300];
	snprintf( msg, 300, "Error closing %s", switches_file );
	perror( msg );
	exit( -1 );
    }

#endif

    return true;
}
