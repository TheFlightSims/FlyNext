#pragma once

#include <simgear/compiler.h>

#include <iostream>
#include <string>
#include <queue>

#include <simgear/misc/stdint.hxx>
#include <simgear/io/iochannel.hxx>
#include <simgear/serial/serial.hxx>


// Manage UGear Command Channel
class UGCommand {

private:

    int cmd_send_index;
    int cmd_recv_index;
    bool prime_state;
    std::queue <std::string> cmd_queue;

public:

    UGCommand();
    ~UGCommand();

    // send current command until acknowledged
    int update( SGSerialPort *serial );

    void add( const std::string command );
    inline int cmd_queue_size() {
        return cmd_queue.size();
    }
    inline void update_cmd_sequence( int sequence ) {
        cmd_recv_index = sequence;
    }
};


extern UGCommand command_mgr;
