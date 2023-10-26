/* -*-c++-*-
 *
 * Copyright (C) 2023 James Hogan
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 */

#ifndef _SG_SOURCE_LOCATION_HXX
#define _SG_SOURCE_LOCATION_HXX 1

#include <map>
#include <memory>
#include <string>

class SGPath;
class sg_location;

/**
 * Information encapsulating a single location in an external resource.
 *
 * A position in the resource my optionally be provided, either by
 * line number, or line number and column number.
 *
 * This is based on sg_location from simgear/structure/exception.hxx, but is
 * more space efficient, with the file path string deduplicated, and is
 * permitted to raise exceptions. This makes it more suitable for fairly compact
 * storage of debug information for later debug output.
 */
class SGSourceLocation
{
public:
    SGSourceLocation();
    SGSourceLocation(const sg_location& location);
    SGSourceLocation(const std::string& path, int line = -1, int column = -1);
    SGSourceLocation(const SGPath& path, int line = -1, int column = -1);
    explicit SGSourceLocation(const char* path, int line = -1, int column = -1);

    bool isValid() const
    {
        return (bool)_path;
    }

    const char* getPath() const
    {
        return _path ? _path->c_str() : "";
    }

    int getLine() const
    {
        return _line;
    }

    int getColumn() const
    {
        return _column;
    }

    friend std::ostream& operator<<(std::ostream& out,
                                    const SGSourceLocation& loc);

private:
    void setPath(const std::string& str);

    static std::map<std::string, std::shared_ptr<std::string>> _paths;

    std::shared_ptr<std::string> _path;
    int _line;
    int _column;
};

#endif // _SG_SOURCE_LOCATION_HXX
