#!/bin/bash

if [[ ! -d ppsspp ]];then
	echo "You are using this script in the wrong path!"
	exit 1
fi

cd ppsspp
rm -rf build-ios
mkdir build-ios
cd build-ios
sed -i '' 's#if(GIT_FOUND AND EXISTS "${SOURCE_DIR}/.git/")#if(GIT_FOUND)#' ../git-version.cmake
sed -i '' 's#set(IPHONEOS_DEPLOYMENT_TARGET 6.0)#set(IPHONEOS_DEPLOYMENT_TARGET 12.0)#' ../cmake/Toolchains/ios.cmake
sed -i '' 's#set(DEPLOYMENT_TARGET 8.0)#set(DEPLOYMENT_TARGET 12.0)#' ../CMakeLists.txt
sed -i '' 's#set(IOS_ARCH "armv7;arm64")#set(IOS_ARCH ${ARCH_STANDARD_64_BIT})#' ../cmake/Toolchains/ios.cmake
cmake -DCMAKE_TOOLCHAIN_FILE=../cmake/Toolchains/ios.cmake -GXcode ..
xcodebuild build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO PRODUCT_BUNDLE_IDENTIFIER="org.ppsspp.ppsspp" -sdk iphoneos -configuration Release -UseModernBuildSystem=0
ln -sf Release-iphoneos Payload
echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>platform-application</key>
	<true/>
	<key>com.apple.private.security.no-container</key>
	<true/>
	<key>get-task-allow</key>
	<true/>
</dict>
</plist>' > ent.xml
ldid -Sent.xml Payload/PPSSPP.app/PPSSPP
version_number=`echo "$(git describe --tags --match="v*" | sed -e 's@-\([^-]*\)-\([^-]*\)$@-\1-\2@;s@^v@@;s@%@~@g')"`
echo "Making ipa..."
zip -r9 ../../PPSSPP_v${version_number}.ipa Payload/PPSSPP.app
echo "ipa built"
echo "Making deb..."
package_name="org.ppsspp.ppsspp-dev-latest_v${version_number}_iphoneos-arm"
mkdir $package_name
mkdir ${package_name}/DEBIAN
echo "Package: org.ppsspp.ppsspp-dev-latest
Name: PPSSPP (Dev-Latest)
Architecture: iphoneos-arm
Description: A PSP emulator 
Icon: file:///Library/PPSSPPRepoIcons/org.ppsspp.ppsspp-dev-latest.png
Homepage: https://build.ppsspp.org/
Conflicts: com.myrepospace.theavenger.PPSSPP, net.angelxwind.ppsspp, net.angelxwind.ppsspp-testing, org.ppsspp.ppsspp, org.ppsspp.ppsspp-dev-working
Provides: com.myrepospace.theavenger.PPSSPP, net.angelxwind.ppsspp, net.angelxwind.ppsspp-testing
Replaces: com.myrepospace.theavenger.PPSSPP, net.angelxwind.ppsspp, net.angelxwind.ppsspp-testing
Depiction: https://cydia.ppsspp.org/?page/org.ppsspp.ppsspp-dev-latest
Maintainer: Henrik Rydgård
Author: Henrik Rydgård
Section: Games
Version: ${version_number}
" > ${package_name}/DEBIAN/control
chmod 0755 ${package_name}/DEBIAN/control
mkdir ${package_name}/Library
mkdir ${package_name}/Library/PPSSPPRepoIcons
cp ../../org.ppsspp.ppsspp.png ${package_name}/Library/PPSSPPRepoIcons/org.ppsspp.ppsspp-dev-latest.png
chmod 0755 ${package_name}/Library/PPSSPPRepoIcons/org.ppsspp.ppsspp-dev-latest.png
mkdir ${package_name}/Applications
cp -a Release-iphoneos/PPSSPP.app ${package_name}/Applications/PPSSPP.app
dpkg -b ${package_name} ../../${package_name}.deb
sed -i '' 's#if(GIT_FOUND)#if(GIT_FOUND AND EXISTS "${SOURCE_DIR}/.git/")#' ../git-version.cmake
sed -i '' 's#set(IPHONEOS_DEPLOYMENT_TARGET 12.0)#set(IPHONEOS_DEPLOYMENT_TARGET 6.0)#' ../cmake/Toolchains/ios.cmake
sed -i '' 's#set(DEPLOYMENT_TARGET 12.0)#set(DEPLOYMENT_TARGET 8.0)#' ../CMakeLists.txt
sed -i '' 's#set(IOS_ARCH ${ARCH_STANDARD_64_BIT})#set(IOS_ARCH "armv7;arm64")#' ../cmake/Toolchains/ios.cmake
echo "deb, ipa built"
