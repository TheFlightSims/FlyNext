/*
 * SPDX-FileName: AddonMetadataParser.hxx
 * SPDX-FileComment: Parser for FlightGear add-on metadata files
 * SPDX-FileCopyrightText: Copyright (C) 2018  Florent Rougon
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include <string>
#include <tuple>
#include <vector>

#include <simgear/misc/sg_path.hxx>

#include "addon_fwd.hxx"
#include "Addon.hxx"
#include "AddonVersion.hxx"
#include "contacts.hxx"

class SGPropertyNode;

namespace flightgear::addons {

class Addon::Metadata
{
public:
    // Comments about these fields can be found in Addon.hxx
    std::string id;
    std::string name;
    AddonVersion version;

    std::vector<AuthorRef> authors;
    std::vector<MaintainerRef> maintainers;

    std::string shortDescription;
    std::string longDescription;

    std::string licenseDesignation;
    SGPath licenseFile;
    std::string licenseUrl;

    std::vector<std::string> tags;

    std::string minFGVersionRequired;
    std::string maxFGVersionRequired;

    std::string homePage;
    std::string downloadUrl;
    std::string supportUrl;
    std::string codeRepositoryUrl;
};

class Addon::MetadataParser
{
public:
    // “Compute” a path to the metadata file from the add-on base path
    static SGPath getMetadataFile(const SGPath& addonPath);

    // Parse the add-on metadata file inside 'addonPath' (as defined by
    // getMetadataFile()) and return the corresponding Addon::Metadata instance.
    static Addon::Metadata parseMetadataFile(const SGPath& addonPath);

private:
    static std::tuple<std::string, SGPath, std::string>
    parseLicenseNode(const SGPath& addonPath, SGPropertyNode* addonNode);

    // Parse an addon-metadata.xml node such as <authors> or <maintainers>.
    // Return the corresponding vector<AuthorRef> or vector<MaintainerRef>. If
    // the 'mainNode' argument is nullptr, return an empty vector.
    template <class T>
    static std::vector<typename contact_traits<T>::strong_ref>
    parseContactsNode(const SGPath& metadataFile, SGPropertyNode* mainNode);
};

} // namespace flightgear::addons
