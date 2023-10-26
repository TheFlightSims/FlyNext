/*
 * SPDX-FileName: generic.hxx
 * SPDX-FileComment: generic protocol class
 * SPDX-FileCopyrightText: Copyright (C) 1999  Curtis L. Olson - http://www.flightgear.org/~curt
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string>

#include <simgear/compiler.h>

#include "protocol.hxx"


class FGGeneric : public FGProtocol
{
public:
    FGGeneric(std::vector<std::string>);
    ~FGGeneric();

    bool gen_message();
    bool parse_message_len(int length);

    // open hailing frequencies
    bool open();

    void reinit();

    // process work for this port
    bool process();

    // close the channel
    bool close();

    void setExitOnError(bool val) { exitOnError = val; }
    bool getExitOnError() { return exitOnError; }
    bool getInitOk(void) { return initOk; }

protected:
    enum e_type { FG_BOOL = 0,
                  FG_INT,
                  FG_FLOAT,
                  FG_DOUBLE,
                  FG_STRING,
                  FG_FIXED,
                  FG_BYTE,
                  FG_WORD };

    typedef struct {
        std::string format;
        e_type type;
        double offset;
        double factor;
        double min, max;
        bool wrap;
        bool rel;
        SGPropertyNode_ptr prop;
    } _serial_prot;

private:
    std::string file_name;

    int length;
    char buf[FG_MAX_MSG_SIZE];

    std::string preamble;
    std::string postamble;
    std::string var_separator;
    std::string line_separator;
    std::string var_sep_string;
    std::string line_sep_string;
    std::vector<_serial_prot> _out_message;
    std::vector<_serial_prot> _in_message;

    bool binary_mode;
    enum { FOOTER_NONE,
           FOOTER_LENGTH,
           FOOTER_MAGIC } binary_footer_type;
    int binary_footer_value;
    int binary_record_length;
    enum { BYTE_ORDER_NEEDS_CONVERSION,
           BYTE_ORDER_MATCHES_NETWORK_ORDER } binary_byte_order;

    bool gen_message_ascii();
    bool gen_message_binary();
    bool parse_message_ascii(int length);
    bool parse_message_binary(int length);
    bool read_config(SGPropertyNode* root, std::vector<_serial_prot>& msg);
    bool exitOnError;
    bool initOk;

    class FGProtocolWrapper* wrapper;

    template <class T>
    static void updateValue(_serial_prot& prot, const T& val)
    {
        T new_val = (prot.rel ? getValue<T>(prot.prop) : 0) + prot.offset + prot.factor * val;

        if (prot.max > prot.min) {
            if (prot.wrap)
                new_val = SGMisc<double>::normalizePeriodic(prot.min, prot.max, new_val);
            else
                new_val = SGMisc<T>::clip(new_val, prot.min, prot.max);
        }

        setValue(prot.prop, new_val);
    }

    // Special handling for bool (relative change = toggle, no min/max, no wrap)
    static void updateValue(_serial_prot& prot, bool val);
};
