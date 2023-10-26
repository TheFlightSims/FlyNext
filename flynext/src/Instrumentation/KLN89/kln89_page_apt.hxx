/*
 * SPDX-FileName: kln89_page_apt.hxx
 * SPDX-FileComment: this file is one of the "pages" that are used in the KLN89 GPS unit simulation.
 * SPDX-FileCopyrightText: Copyright (C) 2005 - David C Luff - daveluff AT ntlworld.com
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

#pragma once

#include "kln89.hxx"


class FGRunway;

struct AptFreq {
    std::string service;
    unsigned short int freq;
};

class KLN89AptPage : public KLN89Page
{
public:
    KLN89AptPage(KLN89* parent);
    ~KLN89AptPage();

    void Update(double dt);

    void CrsrPressed();
    void ClrPressed();
    void EntPressed();
    void Knob1Left1();
    void Knob1Right1();
    void Knob2Left1();
    void Knob2Right1();

    void SetId(const std::string& s);

private:
    // Update the cached airport details
    void UpdateAirport(const std::string& id);

    std::string _apt_id;
    std::string _last_apt_id;
    std::string _save_apt_id;
    const FGAirport* ap;

    std::vector<FGRunway*> _aptRwys;
    std::vector<AptFreq> _aptFreqs;

    iap_list_type _iaps;
    unsigned int _curIap;                        // The index into _iaps of the IAP we are currently selecting
    std::vector<GPSFlightPlan*> _approachRoutes; // The approach route(s) from the IAF(s) to the IF.
    std::vector<GPSWaypoint*> _IAP;              // The compulsory waypoints of the approach procedure (may duplicate one of the above).
                                                 // _IAP includes the FAF and MAF.
    std::vector<GPSWaypoint*> _MAP;              // The missed approach procedure (doesn't include the MAF).
    unsigned int _curIaf;                        // The index into _approachRoutes of the IAF we are currently selecting, and then remembered as the one we selected

    // Position in rwy pages
    unsigned int _curRwyPage;
    unsigned int _nRwyPages;

    // Position in freq pages
    unsigned int _curFreqPage;
    unsigned int _nFreqPages;

    // Position in IAP list (0-based number of first IAP displayed)
    unsigned int _iapStart;
    // ditto for IAF list (can't test this since can't find an approach with > 3 IAF at the moment!)
    unsigned int _iafStart;
    // ditto for list of approach fixes when asking load confirmation
    unsigned int _fStart;

    // Various IAP related dialog states that we might need to remember
    bool _iafDialog;
    bool _addDialog;
    bool _replaceDialog;
};
