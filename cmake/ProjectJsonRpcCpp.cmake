# HTTP client from JSON RPC CPP requires curl library. It can find it itself,
# but we need to know the libcurl location for static linking.
find_package(CURL REQUIRED)

# HTTP server from JSON RPC CPP requires microhttpd library. It can find it itself,
# but we need to know the MHD location for static linking.
find_package(MHD REQUIRED)

set(CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
               -DCMAKE_BUILD_TYPE=Release
               # Build static lib but suitable to be included in a shared lib.
               -DCMAKE_POSITION_INDEPENDENT_CODE=${BUILD_SHARED_LIBS}
               -DBUILD_STATIC_LIBS=On
               -DBUILD_SHARED_LIBS=Off
               -DUNIX_DOMAIN_SOCKET_SERVER=Off
               -DUNIX_DOMAIN_SOCKET_CLIENT=Off
               -DHTTP_SERVER=On
               -DHTTP_CLIENT=On
               -DCOMPILE_TESTS=Off
               -DCOMPILE_STUBGEN=Off
               -DCOMPILE_EXAMPLES=Off
               # Point to jsoncpp library.
               -DJSONCPP_INCLUDE_DIR=${JSONCPP_INCLUDE_DIR}
               # Select jsoncpp include prefix: <json/...> or <jsoncpp/json/...>
               -DJSONCPP_INCLUDE_PREFIX=json
               -DJSONCPP_LIBRARY=${JSONCPP_LIBRARY}
               -DCURL_INCLUDE_DIR=${CURL_INCLUDE_DIR}
               -DCURL_LIBRARY=${CURL_LIBRARY}
               -DMHD_INCLUDE_DIR=${MHD_INCLUDE_DIR}
               -DMHD_LIBRARY=${MHD_LIBRARY}
               -DCMAKE_C_FLAGS=-Wa,-march=generic64
               -DCMAKE_CXX_FLAGS=-Wa,-march=generic64
               -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
               -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
               )

if (WIN32)
    # For Windows we have to provide also locations for debug libraries.
    set(CMAKE_ARGS ${CMAKE_ARGS}
        -DJSONCPP_LIBRARY_DEBUG=${JSONCPP_LIBRARY}
        -DCURL_LIBRARY_DEBUG=${CURL_LIBRARY}
        -DMHD_LIBRARY_DEBUG=${MHD_LIBRARY})
endif()

ExternalProject_Add(jsonrpccpp
    PREFIX ${CMAKE_SOURCE_DIR}/deps
    DOWNLOAD_NAME jsonrcpcpp-0.7.0.tar.gz
    DOWNLOAD_NO_PROGRESS 1
    URL https://github.com/cinemast/libjson-rpc-cpp/archive/v0.7.0.tar.gz
    URL_HASH SHA256=669c2259909f11a8c196923a910f9a16a8225ecc14e6c30e2bcb712bab9097eb
    # On Windows it tries to install this dir. Create it to prevent failure.
    PATCH_COMMAND ${CMAKE_COMMAND} -E make_directory <SOURCE_DIR>/win32-deps/include
    CMAKE_ARGS ${CMAKE_ARGS}
    LOG_CONFIGURE 1
    # Overwrite build and install commands to force Release build on MSVC.
    BUILD_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --config Release
    INSTALL_COMMAND ${CMAKE_COMMAND} --build <BINARY_DIR> --config Release --target install
    LOG_INSTALL 1
)

add_dependencies(jsonrpccpp jsoncpp)

# Create imported libraries
if (WIN32)
    # On Windows CMAKE_INSTALL_PREFIX is ignored and installs to dist dir.
    ExternalProject_Get_Property(jsonrpccpp BINARY_DIR)
    set(INSTALL_DIR ${BINARY_DIR}/dist)
else()
    ExternalProject_Get_Property(jsonrpccpp INSTALL_DIR)
endif()
set(JSONRPCCPP_INCLUDE_DIR ${INSTALL_DIR}/include)
file(MAKE_DIRECTORY ${JSONRPCCPP_INCLUDE_DIR})  # Must exist.

add_library(JsonRpcCpp::Common STATIC IMPORTED)
set_property(TARGET JsonRpcCpp::Common PROPERTY IMPORTED_LOCATION ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}jsonrpccpp-common${CMAKE_STATIC_LIBRARY_SUFFIX})
set_property(TARGET JsonRpcCpp::Common PROPERTY INTERFACE_LINK_LIBRARIES JsonCpp)
set_property(TARGET JsonRpcCpp::Common PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${JSONRPCCPP_INCLUDE_DIR} ${JSONCPP_INCLUDE_DIR})
add_dependencies(JsonRpcCpp::Common jsonrpccpp)

add_library(JsonRpcCpp::Client STATIC IMPORTED)
set_property(TARGET JsonRpcCpp::Client PROPERTY IMPORTED_LOCATION ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}jsonrpccpp-client${CMAKE_STATIC_LIBRARY_SUFFIX})
set_property(TARGET JsonRpcCpp::Client PROPERTY INTERFACE_LINK_LIBRARIES JsonRpcCpp::Common ${CURL_LIBRARY})
set_property(TARGET JsonRpcCpp::Client PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${CURL_INCLUDE_DIR})
add_dependencies(JsonRpcCpp::Client jsonrpccpp)

add_library(JsonRpcCpp::Server STATIC IMPORTED)
set_property(TARGET JsonRpcCpp::Server PROPERTY IMPORTED_LOCATION ${INSTALL_DIR}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}jsonrpccpp-server${CMAKE_STATIC_LIBRARY_SUFFIX})
set_property(TARGET JsonRpcCpp::Server PROPERTY INTERFACE_LINK_LIBRARIES JsonRpcCpp::Common ${MHD_LIBRARY})
set_property(TARGET JsonRpcCpp::Server PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${MHD_INCLUDE_DIR})
add_dependencies(JsonRpcCpp::Server jsonrpccpp)

unset(BINARY_DIR)
unset(INSTALL_DIR)
unset(CMAKE_ARGS)
