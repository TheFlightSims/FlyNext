#include "animation.hxx"

#include <osg/MatrixTransform>

#include "SGLight.hxx"

SGLightAnimation::SGLightAnimation(simgear::SGTransientModelData &modelData) :
    SGAnimation(modelData)
{
    _light = SGLight::appendLight(modelData.getConfigNode(), modelData.getModelRoot(), true);
}

osg::Group*
SGLightAnimation::createAnimationGroup(osg::Group& parent)
{
    osg::Group* group = new osg::Group;
    group->setName("light animation node");
    parent.addChild(group);
    group->addChild(_light);
    return group;
}

void
SGLightAnimation::install(osg::Node& node)
{
    SGAnimation::install(node);
    // Hide the legacy light geometry
    node.setNodeMask(0);
}
