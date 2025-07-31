cmake_minimum_required(VERSION 3.15...3.31)

project(projectname VERSION 0.0.0)

set(TARGET_PLATFORM "Desktop" CACHE STRING "Target platform (desktop, android)")
set_property(CACHE TARGET_PLATFORM PROPERTY STRINGS Desktop Android)

message(STATUS "TARGET_PLATFORM = ${TARGET_PLATFORM}")

set(APP_NAME appname)

if(TARGET_PLATFORM STREQUAL "Desktop")
    add_executable(${APP_NAME})
elseif(TARGET_PLATFORM STREQUAL "Android")
    add_library(${APP_NAME} SHARED)
endif()

add_subdirectory(external EXCLUDE_FROM_ALL)

add_subdirectory(src)
