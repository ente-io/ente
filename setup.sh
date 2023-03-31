#!/usr/bin/env bash

# Originally from https://github.com/am15h/tflite_flutter_plugin/blob/master/install.sh

cd "$(dirname "$(readlink -f "$0")")"

# Pull from the latest tag where binaries were built
ANDROID_TAG="tf_2.5"
IOS_TAG="v0.5.0"

IOS_URL="https://github.com/am15h/tflite_flutter_plugin/releases/download/"
ANDROID_URL="https://github.com/am15h/tflite_flutter_plugin/releases/download/"

IOS_ASSET="TensorFlowLiteC.framework.zip"
IOS_FRAMEWORK="TensorFlowLiteC.framework"
IOS_DIR="ios/.symlinks/plugins/tflite_flutter/ios/"
MACOSX_METADATA_DIR="__MACOSX"

ANDROID_DIR="android/app/src/main/jniLibs/"
ANDROID_LIB="libtensorflowlite_c.so"

ARM_DELEGATE="libtensorflowlite_c_arm_delegate.so"
ARM_64_DELEGATE="libtensorflowlite_c_arm64_delegate.so"
ARM="libtensorflowlite_c_arm.so"
ARM_64="libtensorflowlite_c_arm64.so"
X86="libtensorflowlite_c_x86.so"
X86_64="libtensorflowlite_c_x86_64.so"

delegate=0

while getopts "d" OPTION
do
	case $OPTION in
		d)  delegate=1;;
	esac
done

wget "${IOS_URL}${IOS_TAG}/${IOS_ASSET}"
unzip ${IOS_ASSET}
rm -rf ${MACOSX_METADATA_DIR}
rm ${IOS_ASSET}
rm -rf "${IOS_DIR}/${IOS_FRAMEWORK}"
mv ${IOS_FRAMEWORK} ${IOS_DIR}

download () {
    wget "${ANDROID_URL}${ANDROID_TAG}/$1"
    mkdir -p "${ANDROID_DIR}$2/"
    mv $1 "${ANDROID_DIR}$2/${ANDROID_LIB}"
}

if [ ${delegate} -eq 1 ]
then

download ${ARM_DELEGATE} "armeabi-v7a"
download ${ARM_64_DELEGATE} "arm64-v8a"

else

download ${ARM} "armeabi-v7a"
download ${ARM_64} "arm64-v8a"

fi

download ${X86} "x86"
download ${X86_64} "x86_64"
