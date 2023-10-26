#pragma once

class FGAIAircraft;
class SGPropertyNode;

/**
Data storage for aircraft performance data. This is used to properly simulate the flight of AIAircrafts.

	@author Thomas F�rster <t.foerster@biologie.hu-berlin.de>
*/
class PerformanceData
{
public:
    PerformanceData();

    explicit PerformanceData(const PerformanceData* clone);

    void initFromProps(SGPropertyNode* props);

    virtual ~PerformanceData() = default;

    double actualSpeed(const FGAIAircraft* ac, double tgt_speed, double dt, bool needMaxBrake);
    double actualBankAngle(const FGAIAircraft* ac, double tgt_roll, double dt);
    double actualPitch(const FGAIAircraft* ac, double tgt_pitch, double dt);
    double actualHeading(const FGAIAircraft* ac, double tgt_heading, double dt);
    double actualAltitude(const FGAIAircraft* ac, double tgt_altitude, double dt);
    double actualVerticalSpeed(const FGAIAircraft* ac, double tgt_vs, double dt);

    bool gearExtensible(const FGAIAircraft* ac);

    double climbRate() const { return _climbRate; };
    double descentRate() const { return _descentRate; };
    double vRotate() const { return _vRotate; };
    double maximumBankAngle() const { return _maxbank; };
    double acceleration() const { return _acceleration; };
    double deceleration() const { return _deceleration; };
    double brakeDeceleration() const { return _brakeDeceleration; };
    double vTaxi() const { return _vTaxi; };
    double vTakeoff() const { return _vTakeOff; };
    double vClimb() const { return _vClimb; };
    double vDescent() const { return _vDescent; };
    double vApproach() const { return _vApproach; };
    double vTouchdown() const { return _vTouchdown; };
    double vCruise() const { return _vCruise; };
    double wingSpan() const { return _wingSpan; };
    double wingChord() const { return _wingChord; };
    double weight() const { return _weight; };

    double decelerationOnGround() const;

    /**
     @brief Last-resort fallback performance data. This is to avoid special-casing
     logic in the AIAircraft code, by ensuring we always have a valid _performance pointer.
     */
    static PerformanceData* getDefaultData();

private:
    double _acceleration{0.0};
    double _deceleration{0.0};
    double _brakeDeceleration{0.0};
    double _climbRate{0.0};
    double _descentRate{0.0};
    double _vRotate{0.0};
    double _vTakeOff{0.0};
    double _vClimb{0.0};
    double _vCruise{0.0};
    double _vDescent{0.0};
    double _vApproach{0.0};
    double _vTouchdown{0.0};
    double _vTaxi{0.0};

    double _rollrate{0.0};
    double _maxbank{0.0};

    // Data for aerodynamic wake computation
    double _wingSpan{0.0};
    double _wingChord{0.0};
    double _weight{0.0};
};
