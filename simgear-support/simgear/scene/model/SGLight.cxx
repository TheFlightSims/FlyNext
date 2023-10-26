// Copyright (C) 2018 - 2023 Fernando García Liñán
// SPDX-License-Identifier: LGPL-2.0-or-later

#include <stdexcept>

#include "SGLight.hxx"

#include <osg/Geode>
#include <osg/MatrixTransform>
#include <osg/PolygonMode>
#include <osg/ShapeDrawable>
#include <osg/Switch>

#include <simgear/math/SGMath.hxx>
#include <simgear/scene/tgdb/userdata.hxx>
#include <simgear/scene/util/color_space.hxx>
#include <simgear/props/props_io.hxx>

#include "animation.hxx"

class SGLightDebugListener : public SGPropertyChangeListener {
public:
    SGLightDebugListener(osg::Switch *sw) : _sw(sw) {}
    void valueChanged(SGPropertyNode* node) override
    {
        _sw->setValue(0, node->getBoolValue());
    }

private:
    osg::ref_ptr<osg::Switch> _sw;
};

osg::Vec3f toVec3f(const osg::Vec4f& v)
{
    return osg::Vec3f{v.x(), v.y(), v.z()};
}

void SGLight::UpdateCallback::operator()(osg::Node* node, osg::NodeVisitor* nv)
{
    auto light = dynamic_cast<SGLight*>(node);
    assert(light);

    // since we're in an update callback, it's safe to evaluate conditions
    // and expressions here.
    light->_dim_factor = light->_dim_factor_value->get_value();
    light->_ambient = light->_ambient_value.get_value() * light->_dim_factor;
    light->_diffuse = light->_diffuse_value.get_value() * light->_dim_factor;
    light->_specular = light->_specular_value.get_value() * light->_dim_factor;
    light->_range = light->_range_value->get_value();
    light->_constant_attenuation = light->_constant_attenuation_value->get_value();
    light->_linear_attenuation = light->_linear_attenuation_value->get_value();
    light->_quadratic_attenuation = light->_quadratic_attenuation_value->get_value();
    light->_spot_exponent = light->_spot_exponent_value->get_value();
    light->_spot_cutoff = light->_spot_cutoff_value->get_value();
    light->_intensity = light->_intensity_value->get_value();
    light->_color = toVec3f(light->_color_value.get_value());
}

class SGLightConfigListener : public SGPropertyChangeListener {
public:
    SGLightConfigListener(SGLight* light) : _light(light) {}

    void valueChanged(SGPropertyNode* node) override
    {
        // walk up to find the light node
        while (node->getNameString() != "light" && node->getParent()) {
            node = node->getParent();
        }

        _light->configure(node);
    }

private:
    SGLight* _light;
};

static simgear::Value_ptr buildColorValue(const SGPropertyNode* modelRoot, const SGPropertyNode* node, const std::string& componentName, double defaultVal)
{
    if (!node || !node->hasChild(componentName)) {
        return new simgear::Value(defaultVal);
    }

    auto mr = const_cast<SGPropertyNode*>(modelRoot);
    auto n = const_cast<SGPropertyNode*>(node); // cast away the const-ness so we can call getChild
    auto componentNode = n->getChild(componentName);
    simgear::Value_ptr expr = new simgear::Value(*mr, *componentNode, defaultVal);
    return expr;
}

SGLight::ColorValue::ColorValue() : ColorValue(1.0f, 1.0f, 1.0f, 1.0f)
{
}

SGLight::ColorValue::ColorValue(float r, float g, float b, float a)
{
    _red = new simgear::Value(r);
    _green = new simgear::Value(g);
    _blue = new simgear::Value(b);
    _alpha = new simgear::Value(a);
}

SGLight::ColorValue::ColorValue(const SGPropertyNode* colorNode, const SGPropertyNode* modelRoot)
{
    _red = buildColorValue(modelRoot, colorNode, "r", 1.0);
    _green = buildColorValue(modelRoot, colorNode, "g", 1.0);
    _blue = buildColorValue(modelRoot, colorNode, "b", 1.0);
    _alpha = buildColorValue(modelRoot, colorNode, "a", 1.0);
}

osg::Vec4 SGLight::ColorValue::get_value()
{
    return {static_cast<float>(_red->get_value()),
            static_cast<float>(_green->get_value()),
            static_cast<float>(_blue->get_value()),
            static_cast<float>(_alpha->get_value())};
}

osg::Vec3 SGLight::ColorValue::get_linear_sRGB_value()
{
    const osg::Vec3 srgb = toVec3f(get_value());
    float linear_srgb[3];
    simgear::eotf_inverse_sRGB(const_cast<float*>(srgb.ptr()), linear_srgb);
    return {linear_srgb[0], linear_srgb[1], linear_srgb[2]};
}

SGLight::SGLight(const bool legacy) : _legacyPropertyNames(legacy)
{
    // Do not let OSG cull lights by default, we usually leave that job to
    // other algorithms, like clustered shading.
    setCullingActive(false);
}

SGLight::SGLight(const SGLight& l, const osg::CopyOp& copyop) : osg::Node(l, copyop),
                                                                _type(l._type),
                                                                _legacyPropertyNames(l._legacyPropertyNames),
                                                                _range(l._range),
                                                                _ambient(l._ambient),
                                                                _diffuse(l._diffuse),
                                                                _specular(l._specular),
                                                                _constant_attenuation(l._constant_attenuation),
                                                                _linear_attenuation(l._linear_attenuation),
                                                                _quadratic_attenuation(l._quadratic_attenuation),
                                                                _spot_exponent(l._spot_exponent),
                                                                _spot_cutoff(l._spot_cutoff)
{
    _range_value = l._range_value;
    _dim_factor_value = l._dim_factor_value;
    _ambient_value = l._ambient_value;
    _diffuse_value = l._diffuse_value;
    _specular_value = l._specular_value;
    _constant_attenuation_value = l._constant_attenuation_value;
    _linear_attenuation_value = l._linear_attenuation_value;
    _quadratic_attenuation_value = l._quadratic_attenuation_value;
}

osg::ref_ptr<osg::Node>
SGLight::appendLight(const SGPropertyNode* configNode,
                     SGPropertyNode* modelRoot, bool legacy)
{
    //-- create return variable
    osg::ref_ptr<osg::MatrixTransform> align = new osg::MatrixTransform;

    SGLight* light = new SGLight{legacy};
    light->_transform = align;
    light->_modelRoot = modelRoot;

    align->addChild(light);
    //-- copy config to prop tree --
    const std::string propPath {"/scenery/lights"};
    const std::string propName {"light"};
    SGPropertyNode_ptr _pConfig = simgear::getPropertyRoot()->getNode(propPath, true);
    _pConfig->setAttribute(SGPropertyNode::VALUE_CHANGED_DOWN, true);
    _pConfig = _pConfig->addChild(propName);

    copyProperties(configNode, _pConfig);

    //-- configure light and add listener to conf in prop tree
    _pConfig->addChangeListener(new SGLightConfigListener(light), true);
    light->setUpdateCallback(new SGLight::UpdateCallback());
    light->configure(configNode);

    //-- debug visualisation --
    osg::Shape *debug_shape = nullptr;
    if (light->getType() == SGLight::Type::POINT) {
        debug_shape = new osg::Sphere(osg::Vec3(0, 0, 0), light->getRange());
    } else if (light->getType() == SGLight::Type::SPOT) {
        debug_shape = new osg::Cone(
            // Origin of the cone is at its center of mass
            osg::Vec3(0, 0, -0.75 * light->getRange()),
            tan(light->getSpotCutoff() * SG_DEGREES_TO_RADIANS) * light->getRange(),
            light->getRange());
    } else {
        throw std::domain_error("Unsupported SGLight::Type");
    }

    osg::ShapeDrawable *debug_drawable = new osg::ShapeDrawable(debug_shape);
    debug_drawable->setColor(
        osg::Vec4(configNode->getFloatValue("debug-color/r", 1.0f),
                  configNode->getFloatValue("debug-color/g", 0.0f),
                  configNode->getFloatValue("debug-color/b", 0.0f),
                  configNode->getFloatValue("debug-color/a", 1.0f)));
    osg::Geode *debug_geode = new osg::Geode;
    debug_geode->addDrawable(debug_drawable);

    osg::StateSet *debug_ss = debug_drawable->getOrCreateStateSet();
    debug_ss->setAttributeAndModes(
        new osg::PolygonMode(osg::PolygonMode::FRONT_AND_BACK, osg::PolygonMode::LINE),
        osg::StateAttribute::ON);
    debug_ss->setMode(GL_LIGHTING, osg::StateAttribute::OFF);

    osg::Switch *debug_switch = new osg::Switch;
    debug_switch->addChild(debug_geode);
    simgear::getPropertyRoot()->getNode("/sim/debug/show-light-volumes", true)->
        addChangeListener(new SGLightDebugListener(debug_switch), true);
    align->addChild(debug_switch);
    //-- end debug visualisation --

    SGConstPropertyNode_ptr p;
    if ((p = configNode->getNode("name")) != NULL)
        align->setName(p->getStringValue());
    else
        align->setName("light");

    return align;
}

SGLight::~SGLight() = default;

simgear::Value_ptr SGLight::buildValue(const SGPropertyNode* node, double defaultVal)
{
    if (!node) {
        return new simgear::Value(defaultVal);
    }

    simgear::Value_ptr expr = new simgear::Value(*_modelRoot, *(const_cast<SGPropertyNode*>(node)), defaultVal);
    return expr;
}

void SGLight::configure(const SGPropertyNode* configNode)
{
    SGConstPropertyNode_ptr p;
    if ((p = configNode->getNode(_legacyPropertyNames ? "light-type" : "type")) != NULL) {
        std::string type = p->getStringValue();
        if (type == "point")
            setType(SGLight::Type::POINT);
        else if (type == "spot")
            setType(SGLight::Type::SPOT);
        else
            SG_LOG(SG_GENERAL, SG_ALERT, "ignoring unknown light type '" << type << "'");
    }

    std::string priority = configNode->getStringValue("priority", "low");
    if (priority == "high")
        setPriority(SGLight::HIGH);
    else if (priority == "medium")
        setPriority(SGLight::MEDIUM);

    _dim_factor_value = buildValue(configNode->getChild("dim-factor"), 1.0f);
    _range_value = buildValue(configNode->getChild(_legacyPropertyNames ? "far-m" : "range-m"), 1.0f);

    _diffuse_value = ColorValue(configNode->getChild("diffuse"), _modelRoot);
    _ambient_value = ColorValue(configNode->getChild("ambient"), _modelRoot);
    _specular_value = ColorValue(configNode->getChild("specular"), _modelRoot);

    _constant_attenuation_value = buildValue(configNode->getNode("attenuation/c"), 1.0f);
    _linear_attenuation_value = buildValue(configNode->getNode("attenuation/l"), 0.0f);
    _quadratic_attenuation_value = buildValue(configNode->getNode("attenuation/q"), 0.0f);

    _spot_exponent_value = buildValue(configNode->getNode(_legacyPropertyNames ? "exponent" : "spot-exponent"), 0.0f);
    _spot_cutoff_value = buildValue(configNode->getNode(_legacyPropertyNames ? "cutoff" : "spot-cutoff"), 180.0f);

    _color_value = ColorValue(configNode->getChild("color"), _modelRoot);
    _intensity_value = buildValue(configNode->getNode("intensity"), 1.0f);

    osg::Matrix t;
    osg::Vec3 pos(configNode->getFloatValue("position/x-m"),
                  configNode->getFloatValue("position/y-m"),
                  configNode->getFloatValue("position/z-m"));
    t.makeTranslate(pos);

    osg::Matrix r;
    if (const SGPropertyNode *dirNode = configNode->getNode("direction")) {
        if (dirNode->hasValue("pitch-deg")) {
            r.makeRotate(
                dirNode->getFloatValue("pitch-deg")*SG_DEGREES_TO_RADIANS,
                osg::Vec3(0, 1, 0),
                dirNode->getFloatValue("roll-deg")*SG_DEGREES_TO_RADIANS,
                osg::Vec3(1, 0, 0),
                dirNode->getFloatValue("heading-deg")*SG_DEGREES_TO_RADIANS,
                osg::Vec3(0, 0, 1));
        } else if (dirNode->hasValue("lookat-x-m")) {
            osg::Vec3 lookAt(dirNode->getFloatValue("lookat-x-m"),
                             dirNode->getFloatValue("lookat-y-m"),
                             dirNode->getFloatValue("lookat-z-m"));
            osg::Vec3 dir = lookAt - pos;
            r.makeRotate(osg::Vec3(0, 0, -1), dir);
        } else if (dirNode->hasValue("pointing_x")) { // ALS compatible
            r.makeRotate(osg::Vec3(0, 0, -1),
                         osg::Vec3(-dirNode->getFloatValue("pointing_x"),
                                   -dirNode->getFloatValue("pointing_y"),
                                   -dirNode->getFloatValue("pointing_z")));
        } else {
            r.makeRotate(osg::Vec3(0, 0, -1),
                         osg::Vec3(dirNode->getFloatValue("x"),
                                   dirNode->getFloatValue("y"),
                                   dirNode->getFloatValue("z")));
        }
    }
    if (_transform) _transform->setMatrix(r * t);
}
