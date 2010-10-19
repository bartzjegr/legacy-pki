#
# This script create a list of compiled Java class files to be added to a
# jar file. This avoids including cmake files which get created in the
# binary directory.
#
#=============================================================================
# Copyright 2010      Andreas schneider <asn@redhat.com>
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distributed this file outside of CMake, substitute the full
#  License text for the above reference.)

if (CMAKE_JAVA_CLASS_OUTPUT_PATH)
    if (EXISTS "${CMAKE_JAVA_CLASS_OUTPUT_PATH}")
        # glob for class files
        file(GLOB_RECURSE _JAVA_GLOBBED_FILES "${CMAKE_JAVA_CLASS_OUTPUT_PATH}/*.class")

        # create relative path
        set(_JAVA_CLASS_FILES)
        foreach(_JAVA_GLOBBED_FILE ${_JAVA_GLOBBED_FILES})
            file(RELATIVE_PATH _JAVA_CLASS_FILE ${CMAKE_JAVA_CLASS_OUTPUT_PATH} ${_JAVA_GLOBBED_FILE})
            set(_JAVA_CLASS_FILES "${_JAVA_CLASS_FILES}${_JAVA_CLASS_FILE}\n")
        endforeach(_JAVA_GLOBBED_FILE ${_JAVA_GLOBBED_FILES})

        # write to file
        file(WRITE ${CMAKE_JAVA_CLASS_OUTPUT_PATH}/java_class_filelist ${_JAVA_CLASS_FILES})

    else (EXISTS "${CMAKE_JAVA_CLASS_OUTPUT_PATH}")
        message(SEND_ERROR "FATAL: Java class output path doesn't exist")
    endif (EXISTS "${CMAKE_JAVA_CLASS_OUTPUT_PATH}")
else (CMAKE_JAVA_CLASS_OUTPUT_PATH)
    message(SEND_ERROR "FATAL: Can't find CMAKE_JAVA_CLASS_OUTPUT_PATH")
endif (CMAKE_JAVA_CLASS_OUTPUT_PATH)
