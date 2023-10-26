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

#include <simgear_config.h>
#include <simgear/structure/SGSourceLocation.hxx>

#include <sstream>

#include <simgear/misc/sg_path.hxx>
#include <simgear/structure/exception.hxx>

std::map<std::string, std::shared_ptr<std::string>> SGSourceLocation::_paths;

SGSourceLocation::SGSourceLocation()
    : _line(-1),
      _column(-1)
{
}

SGSourceLocation::SGSourceLocation(const sg_location& location)
    : _line(location.getLine()),
      _column(location.getColumn())
{
    setPath(location.getPath());
}

SGSourceLocation::SGSourceLocation(const std::string& path, int line, int column)
    : _line(line),
      _column(column)
{
    setPath(path);
}

SGSourceLocation::SGSourceLocation(const SGPath& path, int line, int column)
    : _line(line),
      _column(column)
{
    setPath(path.utf8Str());
}

SGSourceLocation::SGSourceLocation(const char* path, int line, int column)
    : _line(line),
      _column(column)
{
    setPath(path);
}

void SGSourceLocation::setPath(const std::string& str)
{
    auto it = _paths.find(str);
    if (it == _paths.end()) {
        _path = std::make_shared<std::string>(str);
        _paths[str] = _path;
    } else {
        _path = (*it).second;
    }
}

std::ostream& operator<<(std::ostream& out,
                         const SGSourceLocation& loc)
{
    if (loc._path)
        out << *loc._path;
    if (loc._line >= 0)
        out << ":" << loc._line;
    if (loc._column >= 0)
        out << ":" << loc._column;
    return out;
}
