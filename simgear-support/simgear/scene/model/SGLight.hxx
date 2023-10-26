// Copyright (C) 2018 - 2023 Fernando García Liñán
// SPDX-License-Identifier: LGPL-2.0-or-later

#pragma once

#include <osgDB/ReaderWriter>
#include <osg/Group>

#include <simgear/props/props.hxx>
#include <simgear/misc/inputvalue.hxx>


class SGLight : public osg::Node {
public:
    enum Type {
        POINT,
        SPOT
    };

    enum Priority {
        HIGH,
        MEDIUM,
        LOW
    };

    class UpdateCallback : public osg::NodeCallback {
    public:
        UpdateCallback() {}

        void operator()(osg::Node* node, osg::NodeVisitor* nv) override;
    };

    SGLight(bool legacyMode = false);
    SGLight(const SGLight& l, const osg::CopyOp& copyop = osg::CopyOp::SHALLOW_COPY);

    META_Node(simgear, SGLight);

    static osg::ref_ptr<osg::Node> appendLight(const SGPropertyNode* configNode,
                                               SGPropertyNode* modelRoot, bool legacyParseMode);

    void configure(const SGPropertyNode* configNode);

    void setType(Type type) { _type = type; }
    Type getType() const { return _type; }

    void setPriority(Priority priority) { _priority = priority ; }
    Priority getPriority() { return _priority; }

    // raw accesors : these are used to update shader data,
    // must not access properties
    float getRange() { return _range; }

    osg::Vec4 getAmbient() { return _ambient; }
    osg::Vec4 getDiffuse() { return _diffuse; }
    osg::Vec4 getSpecular() { return _specular; }

    float getConstantAttenuation() { return _constant_attenuation; }
    float getLinearAttenuation() { return _linear_attenuation; }
    float getQuadraticAttenuation() { return _quadratic_attenuation; }
    float getSpotExponent() { return _spot_exponent; }
    float getSpotCutoff() { return _spot_cutoff; }
    osg::Vec3 getColor() { return _color; }
    float getIntensity() const { return _intensity; }

protected:
    simgear::Value_ptr buildValue(const SGPropertyNode* node, double defaultVal);

    virtual ~SGLight();
    class ColorValue
    {
    public:
        ColorValue();
        ColorValue(float r, float g, float b, float a = 1.0f);
        ColorValue(const SGPropertyNode* colorNode, const SGPropertyNode* modelRoot);
        osg::Vec4 get_value();
        osg::Vec3 get_linear_sRGB_value();

    private:
        simgear::Value_ptr _red;
        simgear::Value_ptr _green;
        simgear::Value_ptr _blue;
        simgear::Value_ptr _alpha;
    };

    Type _type {Type::POINT};
    const bool _legacyPropertyNames;
    SGPropertyNode_ptr _modelRoot;

    float _range{0.0f};
    float _dim_factor {1.0};

    simgear::Value_ptr _dim_factor_value;
    simgear::Value_ptr _range_value;
    simgear::Value_ptr _constant_attenuation_value;
    simgear::Value_ptr _linear_attenuation_value;
    simgear::Value_ptr _quadratic_attenuation_value;
    simgear::Value_ptr _spot_exponent_value;
    simgear::Value_ptr _spot_cutoff_value;
    simgear::Value_ptr _intensity_value;


    ColorValue _ambient_value{0.05f, 0.05f, 0.05f};
    osg::Vec4 _ambient;
    ColorValue _diffuse_value{0.8f, 0.8f, 0.8f};
    osg::Vec4 _diffuse;
    ColorValue _specular_value{0.05f, 0.05f, 0.05f};
    osg::Vec4 _specular;

    float _constant_attenuation{1.0f};
    float _linear_attenuation{0.0f};
    float _quadratic_attenuation{0.0f};
    float _spot_exponent{0.0f};
    float _spot_cutoff {180.0f};
    Priority _priority {Priority::LOW};
    osg::MatrixTransform *_transform {nullptr};

    // Physically-based parameters. These are an alternative to the classic
    // ambient/diffuse/specular scheme.

    // Color of emitted light, as a linear sRGB color
    ColorValue _color_value{1.0f, 1.0f, 1.0f};
    osg::Vec3 _color;
    // The light's brightness. The unit depends on the renderer
    float _intensity{1.0f};
};

typedef std::vector<osg::ref_ptr<SGLight>> SGLightList;
