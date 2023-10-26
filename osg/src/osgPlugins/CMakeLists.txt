#---------------------------------------------------
# OSG CMAKE SUPPORT
# (C) by Michael Wagner, mtw@shared-reality.com 2005
# (C) Eric Wing, Luigi Calori and Robert Osfield 2006-2007
#---------------------------------------------------

PROJECT(OSG_PLUGINS_MASTER)

IF(NOT DYNAMIC_OPENSCENEGRAPH)
    ADD_DEFINITIONS(-DOSG_LIBRARY_STATIC)
ENDIF()

IF(NOT MSVC)
    SET(LIBRARY_OUTPUT_PATH "${LIBRARY_OUTPUT_PATH}/${OSG_PLUGINS}")
    SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/${OSG_PLUGINS}")
ENDIF()

SET(CMAKE_SHARED_MODULE_PREFIX ${OSG_PLUGIN_PREFIX})

IF(MSVC80 OR MSVC90)
    IF(NOT OSG_MSVC_GENERATE_PLUGINS_AND_WRAPPERS_MANIFESTS)
        SET(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /MANIFEST:NO")
    ENDIF()
ENDIF()

SET(TARGET_DEFAULT_PREFIX "osgdb_")
SET(TARGET_DEFAULT_LABEL_PREFIX "Plugins")
SET(TARGET_COMMON_LIBRARIES
    OpenThreads
    osg
    osgDB
    osgUtil
)

OPTION(BUILD_OSG_PLUGINS_BY_DEFAULT "If set, all available plugins are built by default and each plugin can be disabled from the build by setting BUILD_OSG_PLUGIN_<PLUGINNAME> to 0. If not set, no plugins are built by default and each desired plugin must be explicitly enabled by setting BUILD_OSG_PLUGIN_<PLUGINNAME> to 1." ON)

# Macro used for adding plugins below. By default, all plugins are built
# but can be disabled by setting the CMake Variable BUILD_OSG_PLUGIN_<PLUGINNAME> to 0.
macro(ADD_PLUGIN_DIRECTORY DIRECTORY)
    STRING(TOUPPER "${DIRECTORY}" DIRECTORY_UPPER)
    SET(VARNAME "BUILD_OSG_PLUGIN_${DIRECTORY_UPPER}")
    if (NOT DEFINED ${VARNAME})
        if (BUILD_OSG_PLUGINS_BY_DEFAULT)
            SET(${VARNAME} 1)
        else()
            SET(${VARNAME} 0)
        endif()
    endif()

    if ("${${VARNAME}}")
        ADD_SUBDIRECTORY("${DIRECTORY}")
    endif()
endmacro()

############################################################
#
#  NodeKit/Psudo loader plugins
#
 ADD_SUBDIRECTORY(osga)
# ADD_SUBDIRECTORY(rot)
# ADD_SUBDIRECTORY(scale)
# ADD_SUBDIRECTORY(trans)
# ADD_SUBDIRECTORY(normals)
# ADD_SUBDIRECTORY(revisions)
# ADD_SUBDIRECTORY(view)
#ADD_SUBDIRECTORY(shadow)
ADD_SUBDIRECTORY(terrain)

############################################################
#
#  Main native plugins
#
ADD_PLUGIN_DIRECTORY(osg)
#ADD_PLUGIN_DIRECTORY(ive)

############################################################
#
#  Viewer plugins
#
#ADD_SUBDIRECTORY(cfg)

############################################################
#
#  Shader plugins
#
#ADD_SUBDIRECTORY(glsl)

############################################################
#
#  Image plugins
#
ADD_SUBDIRECTORY(rgb)
#ADD_SUBDIRECTORY(bmp)
#ADD_SUBDIRECTORY(pnm)
ADD_SUBDIRECTORY(dds)
#ADD_SUBDIRECTORY(tga)
#ADD_SUBDIRECTORY(hdr)
#ADD_SUBDIRECTORY(dot)
#ADD_SUBDIRECTORY(vtf)
#ADD_SUBDIRECTORY(ktx)

IF(JPEG_FOUND)
    ADD_PLUGIN_DIRECTORY(jpeg)
ENDIF()
IF(JASPER_FOUND)
#    ADD_SUBDIRECTORY(jp2)
ENDIF()
IF(OPENEXR_FOUND AND ZLIB_FOUND AND OSG_CPP_EXCEPTIONS_AVAILABLE)
 #   ADD_SUBDIRECTORY(exr)
ENDIF()
IF(GIFLIB_FOUND)
  #  ADD_SUBDIRECTORY(gif)
ENDIF()
IF(PNG_FOUND AND ZLIB_FOUND)
    ADD_PLUGIN_DIRECTORY(png)
ENDIF()
IF(TIFF_FOUND)
    ADD_PLUGIN_DIRECTORY(tiff)
ENDIF()
IF(GDAL_FOUND)
    ADD_PLUGIN_DIRECTORY(gdal)
    ADD_PLUGIN_DIRECTORY(ogr)
ENDIF()
IF(GTA_FOUND AND OSG_CPP_EXCEPTIONS_AVAILABLE)
   # ADD_SUBDIRECTORY(gta)
ENDIF()


############################################################
#
# 3D Image plugins
#
# IF(DCMTK_FOUND AND ZLIB_FOUND)
#     ADD_SUBDIRECTORY(dicom)
# ELSE()
#     IF(ITK_FOUND)
#         ADD_SUBDIRECTORY(dicom)
#     ENDIF()
# ENDIF()

############################################################
#
#  3rd party 3d plugins
#

#ADD_SUBDIRECTORY(3dc)

#ADD_PLUGIN_DIRECTORY(p3d)

IF(CURL_FOUND)
 #   ADD_SUBDIRECTORY(curl)
ENDIF()

IF(ZLIB_FOUND)
#    ADD_SUBDIRECTORY(gz)
ENDIF()

# IF(NOT OSG_GLES1_AVAILABLE AND NOT OSG_GLES2_AVAILABLE)
#     IF(INVENTOR_FOUND)
#         ADD_SUBDIRECTORY(Inventor)
#     ENDIF()

#     IF(PERFORMER_FOUND)
#         ADD_SUBDIRECTORY(pfb)
#     ENDIF()
# ENDIF()

# IF(OPENVRML_FOUND AND OSG_CPP_EXCEPTIONS_AVAILABLE)
#     ADD_SUBDIRECTORY(vrml)
# ENDIF()

# IF(COLLADA_FOUND AND OSG_CPP_EXCEPTIONS_AVAILABLE)
#     ADD_SUBDIRECTORY(dae)
# ENDIF()

# IF(FBX_FOUND AND OSG_CPP_EXCEPTIONS_AVAILABLE)
#     ADD_SUBDIRECTORY(fbx)
# ENDIF()


#ADD_SUBDIRECTORY(dw)
#ADD_SUBDIRECTORY(bvh)
#ADD_SUBDIRECTORY(x)
# ADD_SUBDIRECTORY(dxf)
# ADD_SUBDIRECTORY(OpenFlight)

#ADD_SUBDIRECTORY(obj)

#ADD_SUBDIRECTORY(pic)
#ADD_SUBDIRECTORY(stl)
IF(NOT ANDROID)
    ADD_PLUGIN_DIRECTORY(3ds)
ENDIF()
ADD_SUBDIRECTORY(ac)
#ADD_SUBDIRECTORY(pov)

#ADD_SUBDIRECTORY(logo)
#ADD_SUBDIRECTORY(lws)
#ADD_SUBDIRECTORY(md2)
#ADD_SUBDIRECTORY(osgtgz)

#ADD_SUBDIRECTORY(tgz)
#ADD_SUBDIRECTORY(shp)
ADD_SUBDIRECTORY(txf)

#ADD_SUBDIRECTORY(bsp)
ADD_SUBDIRECTORY(mdl)

#ADD_SUBDIRECTORY(gles)
#ADD_SUBDIRECTORY(osgjs)

# IF(OSG_CPP_EXCEPTIONS_AVAILABLE)
#     ADD_SUBDIRECTORY(lwo)
#     ADD_SUBDIRECTORY(ply)
#     ADD_SUBDIRECTORY(txp)
# ENDIF()

# IF(XINE_FOUND)
#     ADD_SUBDIRECTORY(xine)
# ENDIF()

# IF(FFMPEG_FOUND AND OSG_CPP_EXCEPTIONS_AVAILABLE)
#     ADD_SUBDIRECTORY(ffmpeg)
# ENDIF()

# IF(GSTREAMER_FOUND AND GLIB_FOUND)
#     ADD_SUBDIRECTORY(gstreamer)
# ENDIF()

# IF(DIRECTSHOW_FOUND)
#     ADD_SUBDIRECTORY(directshow)
# ENDIF()

# IF(OPENAL_FOUND)
#    ADD_SUBDIRECTORY(OpenAL)
# ENDIF()

IF(APPLE AND NOT ANDROID)
    ADD_PLUGIN_DIRECTORY(imageio)
ENDIF()

# IF(AV_FOUNDATION_FOUND)
#     ADD_PLUGIN_DIRECTORY(avfoundation)
# ENDIF()

# IF(QUICKTIME_FOUND)
#     ADD_PLUGIN_DIRECTORY(quicktime)
# ENDIF()

# IF(QTKIT_FOUND)
#     ADD_PLUGIN_DIRECTORY(QTKit)
# ENDIF()

IF(NVTT_FOUND)
    ADD_PLUGIN_DIRECTORY(nvtt)
ENDIF()


IF(FREETYPE_FOUND)
    ADD_SUBDIRECTORY(freetype)
ENDIF()

# IF (QT4_FOUND)
#     ADD_SUBDIRECTORY(qfont)
# ENDIF()

# IF(ZLIB_FOUND)
#     ADD_SUBDIRECTORY(zip)
# ENDIF()

# IF(RSVG_FOUND)
#     ADD_SUBDIRECTORY(svg)
# ENDIF()

# IF(POPPLER_FOUND)
#     ADD_PLUGIN_DIRECTORY(pdf)
# ENDIF()

# IF(LIBVNCSERVER_FOUND)
#     ADD_SUBDIRECTORY(vnc)
# ENDIF()

# ADD_SUBDIRECTORY(pvr)

# ADD_SUBDIRECTORY(osc)
# ADD_SUBDIRECTORY(trk)
# ADD_SUBDIRECTORY(tf)

# IF(LIBLAS_FOUND)
#     ADD_SUBDIRECTORY(las)
# ENDIF()


####################################################
#
# ScriptEngines
#
# IF ((LUA_LIBRARIES AND LUA_INCLUDE_DIR) OR (LUA_SOURCE_DIR AND LUA_INCLUDE_DIR) OR (OSG_USE_LOCAL_LUA_SOURCE))
#     ADD_SUBDIRECTORY(lua)
# ENDIF()


# V8 and Python plugins are tests for linking against these libraries but aren't functionality beyond this.
# IF (V8_FOUND)
#     ADD_PLUGIN_DIRECTORY(V8)
# ENDIF()
#
# IF (PYTHONLIBS_FOUND)
#     ADD_PLUGIN_DIRECTORY(python)
# ENDIF()

####################################################
#
# Device integration plugins
#
# IF   (SDL_FOUND)
#     ADD_SUBDIRECTORY(sdl)
# ENDIF(SDL_FOUND)

# IF(ASIO_FOUND)
#     ADD_SUBDIRECTORY(RestHttpDevice)
# ENDIF(ASIO_FOUND)


# IF(ZEROCONF_FOUND)
#     ADD_SUBDIRECTORY(ZeroConfDevice)
# ENDIF()

##########to get all the variables of Cmake
#GET_CMAKE_PROPERTY(MYVARS VARIABLES)
#FOREACH(myvar ${MYVARS})
#    FILE(APPEND ${CMAKE_CURRENT_BINARY_DIR}/AllVariables.txt
#        "${myvar} -->${${myvar}}<-\n"
#    )
#ENDFOREACH(myvar)


