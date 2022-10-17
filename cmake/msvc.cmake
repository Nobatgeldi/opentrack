# this file only serves as toolchain file when specified so explicitly
# when building the software. from repository's root directory:
# mkdir build && cmake -DCMAKE_TOOLCHAIN_FILE=$(pwd)/../cmake/msvc.cmake build/

SET(CMAKE_SYSTEM_NAME Windows)
SET(CMAKE_SYSTEM_VERSION 5.01)
if(opentrack-64bit)
    set(CMAKE_SYSTEM_PROCESSOR AMD64)
else()
    set(CMAKE_SYSTEM_PROCESSOR x86)
endif()

if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/opentrack-policy.cmake")
    include("${CMAKE_CURRENT_LIST_DIR}/opentrack-policy.cmake" NO_POLICY_SCOPE)
endif()

# search for programs in the host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# don't poison with system compile-time data
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(CMAKE_GENERATOR "Ninja")

#add_definitions(-D_ITERATOR_DEBUG_LEVEL=0)
#add_compile_options(-Qvec-report:2)
#add_compile_options(-d2cgsummary)
add_definitions(-D_HAS_EXCEPTIONS=0)
if(NOT CMAKE_PROJECT_NAME STREQUAL "OpenCV")
    add_definitions(-D_CRT_USE_BUILTIN_OFFSETOF)
endif()

include("${CMAKE_CURRENT_LIST_DIR}/opentrack-policy.cmake" NO_POLICY_SCOPE)
set(CMAKE_POLICY_DEFAULT_CMP0069 NEW CACHE INTERNAL "" FORCE)
#set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)

set(CMAKE_C_EXTENSIONS FALSE)
set(CMAKE_CXX_EXTENSIONS FALSE)

if(CMAKE_PROJECT_NAME STREQUAL "opentrack")
    #include("${CMAKE_CURRENT_LIST_DIR}/opentrack-policy.cmake" NO_POLICY_SCOPE)

    add_compile_options("-W4")

    # C4265: class has virtual functions, but destructor is not virtual
    # C4005: macro redefinition
    set(warns-error 4265 4005)

    foreach(i ${warns-error})
        add_compile_options(-w1${i} -we${i})
    endforeach()
endif()

if(CMAKE_PROJECT_NAME STREQUAL "QtBase")
    unset(CMAKE_CROSSCOMPILING)
    set(QT_BUILD_TOOLS_WHEN_CROSSCOMPILING TRUE CACHE BOOL "" FORCE)
    set(QT_DEBUG_OPTIMIZATION_FLAGS TRUE CACHE BOOL "" FORCE)
    set(QT_USE_DEFAULT_CMAKE_OPTIMIZATION_FLAGS TRUE CACHE BOOL "" FORCE)

    set(FEATURE_debug OFF)
    set(FEATURE_debug_and_release OFF)
    set(FEATURE_force_debug_info ON)
    set(FEATURE_ltcg ON)
    set(FEATURE_shared ON)
endif()

if(CMAKE_PROJECT_NAME STREQUAL "OpenCV")
    set(PARALLEL_ENABLE_PLUGINS FALSE)
    set(HIGHGUI_ENABLE_PLUGINS FALSE)
    set(VIDEOIO_ENABLE_PLUGINS FALSE)

    set(OPENCV_SKIP_MSVC_EXCEPTIONS_FLAG TRUE)
    set(OPENCV_DISABLE_THREAD_SUPPORT TRUE)

    set(ENABLE_FAST_MATH    ON)
    set(BUILD_TESTS         OFF)
    set(BUILD_PERF_TESTS    OFF)
    set(BUILD_opencv_apps   OFF)
    set(BUILD_opencv_gapi   OFF)
endif()

set(opentrack-simd "SSE2")

if(CMAKE_PROJECT_NAME STREQUAL "onnxruntime")
    set(opentrack-simd "AVX")

    set(onnxruntime_USE_AVX ON)
    set(onnxruntime_USE_AVX2 OFF)
    set(onnxruntime_USE_AVX512 OFF)
elseif(opentrack-64bit)
    set(opentrack-simd "")
endif()

set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

add_link_options(-cgthreads:1)

set(_CFLAGS "-diagnostics:classic -Zc:preprocessor -wd4117 -Zi -Zf -Zo -bigobj -cgthreads1 -vd0")
if(NOT opentrack-no-static-crt)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded" CACHE INTERNAL "" FORCE)
else()
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL" CACHE INTERNAL "" FORCE)
endif()
set(_CXXFLAGS "${_CFLAGS} -Zc:throwingNew -Zc:lambda -Zc:inline")
set(_CFLAGS_RELEASE "-O2 -Oit -Oy- -Ob3 -fp:fast -GS- -GF -GL -Gw -Gy")
if(NOT opentrack-simd STREQUAL "")
    set(_CFLAGS_RELEASE "${_CFLAGS_RELEASE} -arch:${opentrack-simd}")
endif()
set(_CFLAGS_DEBUG "-guard:cf -MTd -Gs0 -RTCs")
set(_CXXFLAGS_RELEASE "${_CFLAGS_RELEASE}")
set(_CXXFLAGS_DEBUG "${_CFLAGS_DEBUG}")

set(_LDFLAGS "")
set(_LDFLAGS_RELEASE "-OPT:REF,ICF=10 -LTCG:INCREMENTAL -DEBUG:FULL")
set(_LDFLAGS_DEBUG "-DEBUG:FULL")

set(_LDFLAGS_STATIC "")
set(_LDFLAGS_STATIC_RELEASE "-LTCG:INCREMENTAL")
set(_LDFLAGS_STATIC_DEBUG "")

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE STRING "" FORCE)
endif()

set(CMAKE_BUILD_TYPE_INIT "RELEASE" CACHE INTERNAL "")

string(TOUPPER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE)
set(CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING "" FORCE)
if (NOT CMAKE_BUILD_TYPE STREQUAL "RELEASE" AND NOT CMAKE_BUILD_TYPE STREQUAL "DEBUG")
    set(CMAKE_BUILD_TYPE "RELEASE" CACHE STRING "" FORCE)
endif()
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS RELEASE DEBUG)

foreach(k "" "_${CMAKE_BUILD_TYPE}")
    set("FLAGS_CXX${k}"     "" CACHE STRING "More CMAKE_CXX_FLAGS${k}")
    #set("FLAGS_C${k}"     "" CACHE STRING "More CMAKE_C_FLAGS${k} (almost never used)")
    set("FLAGS_LD${k}"      "" CACHE STRING "More CMAKE_(SHARED|EXE|MODULE)_LINKER_FLAGS${k}")
    set("FLAGS_ARCHIVE${k}" "" CACHE STRING "More CMAKE_STATIC_LINKER_FLAGS${k}")
endforeach()

foreach(k "" _DEBUG _RELEASE)
    #set(CMAKE_STATIC_LINKER_FLAGS${k} "${CMAKE_STATIC_LINKER_FLAGS${k}} ${_LDFLAGS_STATIC${k}}")
    set(CMAKE_STATIC_LINKER_FLAGS${k} "${_LDFLAGS_STATIC${k}} ${FLAGS_ARCHIVE${k}}" CACHE STRING "" FORCE)
endforeach()
foreach(j "" _DEBUG _RELEASE)
    foreach(i MODULE EXE SHARED)
        #set(CMAKE_${i}_LINKER_FLAGS${j} "${CMAKE_${i}_LINKER_FLAGS${j}} ${_LDFLAGS${j}}")
        set(CMAKE_${i}_LINKER_FLAGS${j} "${_LDFLAGS${j}} ${FLAGS_LD${j}}" CACHE STRING "" FORCE)
    endforeach()
endforeach()

foreach(j C CXX)
    foreach(i "" _DEBUG _RELEASE)
        #set(CMAKE_${j}_FLAGS${i} "${CMAKE_${j}_FLAGS${i}} ${_${j}FLAGS${i}}")
        set(CMAKE_${j}_FLAGS${i} "${_${j}FLAGS${i}} ${FLAGS_${j}${i}}" CACHE STRING "" FORCE)
    endforeach()
endforeach()
