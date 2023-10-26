include(SimGearComponent)

set(HEADERS
  ../include/vg/openvg.h
  ../include/vg/vgu.h
)

set(SOURCES
  shaders.c
  shArrays.c
  shContext.c
  shExtensions.c
  shGeometry.c
  shImage.c
  shPaint.c
  shParams.c
  shPath.c
  shPipeline.c
  shVectors.c
  shVgu.c
)

simgear_scene_component(ShaderVG canvas/ShaderVG "${SOURCES}" "${HEADERS}")
