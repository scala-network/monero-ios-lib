#!/bin/bash

SOURCE_DIR=`pwd`

EXTERNAL_DIR_PATH="$SOURCE_DIR/SharedExternal"

IOKIT_INCLUDE_DIR="/usr/local/include/IOKit"

# BOOST_URL="https://github.com/WooKeyWallet/ofxiOSBoost.git"
BOOST_URL="git@github.com:danoli3/ofxiOSBoost.git"
BOOST_DIR_PATH="$EXTERNAL_DIR_PATH/ofxiOSBoost"

OPEN_SSL_URL="https://github.com/x2on/OpenSSL-for-iPhone.git"
OPEN_SSL_DIR_PATH="$EXTERNAL_DIR_PATH/OpenSSL"

LMDB_DIR_URL="https://github.com/LMDB/lmdb.git"
LMDB_DIR_PATH="lmdb/Sources"

SODIUM_URL="https://github.com/jedisct1/libsodium --branch stable"
SODIUM_PATH="$EXTERNAL_DIR_PATH/libsodium"

SCALA_URL="https://github.com/scala-network/scala.git"
SCALA_DIR_PATH="$SOURCE_DIR/scala"

BOOST_LIBRARYDIR="${BOOST_DIR_PATH}/libs/boost/ios"
BOOST_INCLUDEDIR="${BOOST_DIR_PATH}/libs/boost/include"

OPENSSL_INCLUDE_DIR="${OPEN_SSL_DIR_PATH}/include"
OPENSSL_ROOT_DIR=$OPEN_SSL_DIR_PATH

SODIUM_LIBRARY="${SODIUM_PATH}/libsodium-ios/lib/libsodium.a"
SODIUM_INCLUDE="${SODIUM_PATH}/libsodium-ios/include"

ZMQ_ROOT_DIR="${EXTERNAL_DIR_PATH}/ZMQ"
ZMQ_INCLUDE_PATH="${EXTERNAL_DIR_PATH}/ZMQ/include"
ZMQ_LIB="${EXTERNAL_DIR_PATH}/ZMQ/src/libzmq.a"
ZMQ_VERSION="v4.3.2"

INSTALL_PREFIX="${SOURCE_DIR}/dist"

if [[ -d build ]]; then
    echo "Init external libs. EXTERNAL_DIR_PATH already exists"
else
    echo "Init external libs."
    mkdir -p $EXTERNAL_DIR_PATH

fi

echo "============================ Boost ============================"

if [[ -d $BOOST_DIR_PATH ]]; then
    echo "Building Boost skipped. Remove $BOOST_DIR_PATH to rebuild"
else
    echo "Cloning ofxiOSBoost from - $BOOST_URL"
    git clone -b master $BOOST_URL $BOOST_DIR_PATH
    cd $SOURCE_DIR
fi

echo "============================ OpenSSL ============================"

if [[ -d $OPEN_SSL_DIR_PATH ]]; then
    echo "Building Open SSL skipped. Remove $OPEN_SSL_DIR_PATH to rebuild"
else
    echo "Cloning Open SSL from - $OPEN_SSL_URL"
    git clone $OPEN_SSL_URL $OPEN_SSL_DIR_PATH

    cd $OPEN_SSL_DIR_PATH
    git checkout OpenSSL-1.0.2l
    ./build-libssl.sh --archs="arm64"
    cd $SOURCE_DIR
fi


echo "============================ LMDB ============================"

if [[ -d $LMDB_DIR_PATH ]]; then
    echo "Building LMDB skipped. Remove $LMDB_DIR_PATH to rebuild"
else
    echo "Cloning lmdb from - $LMDB_DIR_URL"
    git clone $LMDB_DIR_URL $LMDB_DIR_PATH
    cd $LMDB_DIR_PATH
    git checkout b9495245b4b96ad6698849e1c1c816c346f27c3c
    cd $SOURCE_DIR
fi


echo "============================ SODIUM ============================"

if [[ -d $SODIUM_PATH ]]; then
    echo "Building SODIUM skipped. Remove $SODIUM_PATH to rebuild"
else
    echo "Cloning SODIUM from - $SODIUM_URL"
    git clone -b build $SODIUM_URL $SODIUM_PATH
    cd $SODIUM_PATH
    ./dist-build/ios.sh
    cd $SOURCE_DIR
fi

echo "============================ ZMQ ============================"

if [[ -d $ZMQ_ROOT_DIR ]]; then
    echo "Building SODIUM skipped. Remove $ZMQ_ROOT_DIR to rebuild"
else
    git clone https://github.com/zeromq/libzmq.git -b ${ZMQ_VERSION} ${ZMQ_ROOT_DIR}
    cd ${ZMQ_ROOT_DIR}
    SDK_ROOT="/Developer/Platforms/iPhoneOS.platform/Developer"
    ./autogen.sh
    ./configure --disable-dependency-tracking --enable-static --disable-shared --host=arm-apple-darwin10 
    make
fi

echo "============================ Scala ============================"

if [[ -d $SCALA_DIR_PATH ]]; then
    echo "Cloning Scala skipped. Remove $SCALA_DIR_PATH to reclone"
else
    git clone $SCALA_URL $SCALA_DIR_PATH
	cd $SCALA_DIR_PATH
	git checkout 65505e28b34c95847a94872d3bd647b9e9ff0d2c
	git submodule update --recursive --init
fi


echo "============================ Test Deps ============================"
if [[ -d $BOOST_INCLUDEDIR ]]; then
    echo " √ BOOST_INCLUDEDIR"
else
   echo " X $BOOST_INCLUDEDIR"
   exit
fi
if [[ -d $BOOST_LIBRARYDIR ]]; then
    echo " √ BOOST_LIBRARYDIR"
else
   echo " X $BOOST_LIBRARYDIR"
   exit
fi
if [[ -d $SODIUM_INCLUDE ]]; then
    echo " √ SODIUM_INCLUDE"
else
   echo " X $SODIUM_INCLUDE"
   exit
fi
if [[ -d $SCALA_DIR_PATH ]]; then
    echo " √ SCALA_DIR_PATH"
else
   echo " X $SCALA_DIR_PATH"
   exit
fi
if [[ -d $ZMQ_ROOT_DIR ]]; then
    echo " √ ZMQ_ROOT_DIR"
else
   echo " X $ZMQ_ROOT_DIR"
   exit
fi


echo "============================ Building ============================"

cd $SOURCE_DIR


if [[ -d build ]]; then
    rm -rf build > /dev/null
fi


mkdir -p build
pushd build
cmake \
 -D CMAKE_BUILD_TYPE=release \
 -D BUILD_GUI_DEPS=ON \
 -D STATIC=ON \
 -D IOS=ON \
 -D ARCH=arm64 \
 -D Boost_LIBRARIES=${BOOST_LIBRARYDIR} \
 -D BOOST_LIBRARYDIR=${BOOST_LIBRARYDIR} \
 -D Boost_INCLUDE_DIR=${BOOST_INCLUDEDIR} \
 -D OPENSSL_INCLUDE_DIR=${OPENSSL_INCLUDE_DIR} \
 -D OPENSSL_ROOT_DIR=${OPENSSL_ROOT_DIR} \
 -D INSTALL_VENDORED_LIBUNBOUND=ON \
 -D SODIUM_LIBRARY=$SODIUM_LIBRARY \
 -D SODIUM_INCLUDE_DIR=$SODIUM_INCLUDE \
 -D ZMQ_INCLUDE_PATH=$ZMQ_INCLUDE_PATH \
 -D ZMQ_LIB=$ZMQ_LIB \
 -D IOKIT_INCLUDE_DIR=$IOKIT_INCLUDE_DIR \
 -D CMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
 -D MANUAL_SUBMODULES=1 \
 -D MONERUJO_HIDAPI=ON \
 -D USE_DEVICE_TREZOR=OFF \
 -D IOS_DEPLOYMENT_TARGET=12.0 \
 ..
 
if [[ -d $SOURCE_DIR/dist ]]; then
	rm -rf $SOURCE_DIR/dist > /dev/null
fi

make wallet_api -j`sysctl -n hw.physicalcpu` && make install

if [[ -d SOURCE_DIR/build/external/randomx ]]; then
    cp $SOURCE_DIR/build/external/randomx/librandomx.a $INSTALL_PREFIX/lib-armv8-a/
fi

if [[ -d $SOURCE_DIR/build/external/filedae ]]; then
    cp $SOURCE_DIR/build/external/filedae/filedae.a $INSTALL_PREFIX/lib-armv8-a/
fi
