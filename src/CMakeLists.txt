set(SRCS
    main.c
)

target_sources(${APP_NAME} PRIVATE ${SRCS})

if(TARGET_PLATFORM STREQUAL "Desktop")
    target_link_libraries(${APP_NAME} PRIVATE raylib)
elseif(TARGET_PLATFORM STREQUAL "Android")
    target_link_libraries(${APP_NAME} PRIVATE
        raylib
        android
        log
        EGL
        GLESv2
        OpenSLES
        atomic
        m
        dl
    )
    target_link_options(${APP_NAME} PRIVATE
        -Wl,--exclude-libs,libatomic.a
        -Wl,-z,relro
        -Wl,-z,now
        -Wl,--warn-shared-textrel
        -Wl,--fatal-warnings
        -Wl,-u,ANativeActivity_onCreate
    )
endif()

target_include_directories(${APP_NAME} PRIVATE ${PROJECT_SOURCE_DIR}/external/raylib/src)
