#!/bin/sh
set -e

######################################################
# Variables for modifying

# Name of the application
APP_NAME=appname
# Name of app to show in launcher
LAUNCHER_NAME=$APP_NAME

# The domain, organization and package name for the app package
PKG_DOMAIN=com
PKG_ORG=example
PKG_APP=$APP_NAME

# ABIs to build apk for
ABIS="arm64-v8a armeabi-v7a x86 x86_64"
# defines to pass to cmkae when building for the ABIs
CMAKE_DEFINES_TO_PASS="-DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=TRUE"

# Path to Android Sdk (NOTE: If directory doesn't exists, creates the directory
# and installs the required version of SDK and NDK tools)
ANDROID_HOME=$HOME/Android/Sdk

# The android api level to use (NOTE: if sdk doesn't exists, installs)
ANDROID_API_LEVEL=31

# The variables to fill in the manifest file
VERSION_CODE=1
VERSION_NAME=1.0
MIN_SDK=24
TARGET_SDK=$ANDROID_API_LEVEL
# The screen orientation portrait or landscape.
ORIENTATION=landscape

# Version of the build-tools to use (NOTE: if doesn't exists, installs)
ANDROID_BUILDTOOLS_VERSION=36.0.0

# Version of the NDK to use (NOTE: if doesn't exists, installs)
ANDROID_NDK_VERSION=29.0.13599879

# Path to the Java JDK. This folder should contain a bin folder which has javac
# and some other tools. On Linux, if Java was installed from a package manager,
# the Java path should be somewhere in /usr/lib/jvm.
JAVA=/usr/lib/jvm/java-17-openjdk
######################################################

if [ ! -e "$JAVA/bin/javac" ]
then
    echo "Please install JDK and update 'JAVA' variable!"
    exit 1
fi


# Install command line tools if they don't exists
# (you can install latest command line tools from https://developer.android.com/studio#command-line-tools-only)
if [ ! -d "$ANDROID_HOME/cmdline-tools" ]
then
    mkdir -p $ANDROID_HOME
    echo -e "\n#######################################################################################"
    echo "Downloading cmdline-tools..."
    echo "#######################################################################################"
    cd $ANDROID_HOME
    wget https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip -O android-sdk.zip
    unzip android-sdk.zip
    rm -rf android-sdk.zip
    cd -
fi

ANDROID_CMDTOOLS=$(find $ANDROID_HOME/cmdline-tools -type d -name 'bin')

ANDROID_SDK_DIR=$ANDROID_HOME/platforms/android-$ANDROID_API_LEVEL
ANDROID_PLATFORM_TOOLS=$ANDROID_HOME/platform-tools

sdkmanager_update="yes"

# Install android sdk for given api level if doesn't exists
if [ ! -d "$ANDROID_SDK_DIR" ] || [ ! -d "$ANDROID_PLATFORM_TOOLS" ]
then
    echo -e "\n#######################################################################################"
    echo "Downloading the android-$ANDROID_API_LEVEL sdk..."
    echo "#######################################################################################"

    if [ $sdkmanager_update = "yes" ]
    then
        $ANDROID_CMDTOOLS/sdkmanager --update --sdk_root=$ANDROID_HOME
        sdkmanager_update="no"
    fi

    $ANDROID_CMDTOOLS/sdkmanager --install "platform-tools" "platforms;android-$ANDROID_API_LEVEL" --sdk_root=$ANDROID_HOME
fi

ANDROID_BUILDTOOLS=$ANDROID_HOME/build-tools/$ANDROID_BUILDTOOLS_VERSION

# Install build tools for given version if doesn't exists
if [ ! -d "$ANDROID_BUILDTOOLS" ]
then
    echo -e "\n#######################################################################################"
    echo "Downloading the build-tools for version $ANDROID_BUILDTOOLS_VERSION..."
    echo "#######################################################################################"

    if [ $sdkmanager_update = "yes" ]
    then
        $ANDROID_CMDTOOLS/sdkmanager --update --sdk_root=$ANDROID_HOME
        sdkmanager_update="no"
    fi

    $ANDROID_CMDTOOLS/sdkmanager --install "build-tools;$ANDROID_BUILDTOOLS_VERSION" --sdk_root=$ANDROID_HOME
fi


ANDROID_NDK_DIR=$ANDROID_HOME/ndk/$ANDROID_NDK_VERSION

# Install NDK if doesn't exists
if [ ! -d "$ANDROID_NDK_DIR" ]
then
    echo -e "\n#######################################################################################"
    echo "Downloading the NDK version $ANDROID_NDK_VERSION..."
    echo "#######################################################################################"

    if [ $sdkmanager_update = "yes" ]
    then
        $ANDROID_CMDTOOLS/sdkmanager --update --sdk_root=$ANDROID_HOME
        sdkmanager_update="no"
    fi

    $ANDROID_CMDTOOLS/sdkmanager --install "ndk;$ANDROID_NDK_VERSION" --sdk_root=$ANDROID_HOME
fi

BUILD_ROOT=build/android
APK_BUILD=$BUILD_ROOT/build


echo -e "\n#######################################################################################"
echo "Creating directories..."
echo "#######################################################################################"
mkdir -p $BUILD_ROOT
mkdir -p $APK_BUILD
DIRS_IN_APK_BUILD="obj dex res/values src/$PKG_DOMAIN/$PKG_ORG/$PKG_APP assets res/drawable-ldpi res/drawable-mdpi res/drawable-hdpi res/drawable-xhdpi"
for dir in $DIRS_IN_APK_BUILD
do
    mkdir -p $APK_BUILD/$dir
done
# The ABI dirs
for ABI in $ABIS
do
    mkdir -p $APK_BUILD/lib/$ABI
done

# Build for specified ABIs
for ABI in $ABIS
do
    echo -e "\n#######################################################################################"
    echo "Building for ABI: $ABI"
    echo "#######################################################################################"
    if [ ! -d "$BUILD_ROOT/$ABI" ]; then
        cmake -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_DIR/build/cmake/android.toolchain.cmake" \
            -DANDROID_ABI=$ABI \
            -DANDROID_PLATFORM=android-$ANDROID_API_LEVEL \
            -DTARGET_PLATFORM=Android \
            $CMAKE_DEFINES_TO_PASS \
            -B $BUILD_ROOT/$ABI \
            -S .
    fi

    cmake --build $BUILD_ROOT/$ABI

    cp $BUILD_ROOT/$ABI/lib$APP_NAME.so $APK_BUILD/lib/$ABI/lib$APP_NAME.so
done

# Copy icons
echo -e "\n#######################################################################################"
echo "Copying icons..."
echo "#######################################################################################"
icon_ldpi=external/raylib/logo/raylib_36x36.png
icon_mdpi=external/raylib/logo/raylib_48x48.png
icon_hdpi=external/raylib/logo/raylib_72x72.png
icon_xhdpi=external/raylib/logo/raylib_96x96.png

[ -e assets/icon_ldpi.png ] && icon_ldpi=assets/icon_ldpi.png
[ -e assets/icon_mdpi.png ] && icon_ldpi=assets/icon_mdpi.png
[ -e assets/icon_hdpi.png ] && icon_ldpi=assets/icon_hdpi.png
[ -e assets/icon_xhdpi.png ] && icon_ldpi=assets/icon_xhdpi.png

cp $icon_ldpi $APK_BUILD/res/drawable-ldpi/icon.png
cp $icon_mdpi $APK_BUILD/res/drawable-mdpi/icon.png
cp $icon_hdpi $APK_BUILD/res/drawable-hdpi/icon.png
cp $icon_xhdpi $APK_BUILD/res/drawable-xhdpi/icon.png

# Copy other assets
echo -e "\n#######################################################################################"
echo "Copying other assets..."
echo "#######################################################################################"
[ -d "assets" ] && cp -r assets/ $APK_BUILD

# Java setup
echo -e "\n#######################################################################################"
echo "Writing NativeLoader java code..."
echo "#######################################################################################"
cat << EOF > $APK_BUILD/src/$PKG_DOMAIN/$PKG_ORG/$PKG_APP/NativeLoader.java
package $PKG_DOMAIN.$PKG_ORG.$PKG_APP;

public class NativeLoader extends android.app.NativeActivity {
    static {
        System.loadLibrary("$APP_NAME");
    }
}
EOF

# copy manifest file
if [ ! -f "AndroidManifest.xml" ]
then
    echo -e "\n#######################################################################################"
    echo "Generating AndroidManifest.xml file..."
    echo "#######################################################################################"
    cat << EOF > AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
        package="$PKG_DOMAIN.$PKG_ORG.$PKG_APP"
        android:versionCode="$VERSION_CODE" android:versionName="$VERSION_NAME" >
    <uses-sdk android:minSdkVersion="$MIN_SDK" android:targetSdkVersion="$TARGET_SDK"/>
    <uses-feature android:glEsVersion="0x00020000" android:required="true"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <application android:allowBackup="false"
        android:label="$LAUNCHER_NAME" android:icon="@drawable/icon">
        <activity android:name="$PKG_DOMAIN.$PKG_ORG.$PKG_APP.NativeLoader"
            android:exported="true"
            android:theme="@android:style/Theme.NoTitleBar.Fullscreen"
            android:configChanges="orientation|keyboardHidden|screenSize"
            android:screenOrientation="$ORIENTATION" android:launchMode="singleTask"
            android:clearTaskOnLaunch="true">
            <meta-data android:name="android.app.lib_name" android:value="$APP_NAME"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF
fi

echo -e "\n#######################################################################################"
echo "Copying AndroidManifest.xml file..."
echo "#######################################################################################"
cp AndroidManifest.xml $APK_BUILD/AndroidManifest.xml

# Building apk
echo -e "\n#######################################################################################"
echo "Start generating apk..."
echo "#######################################################################################"
$ANDROID_BUILDTOOLS/aapt package -f -m \
    -S $APK_BUILD/res \
    -J $APK_BUILD/src \
    -M $APK_BUILD/AndroidManifest.xml \
    -I $ANDROID_SDK_DIR/android.jar

# Compile java code
echo -e "\n#######################################################################################"
echo "Compiling the NativeLoader java code..."
echo "#######################################################################################"
$JAVA/bin/javac -verbose -source 1.8 -target 1.8 -d $APK_BUILD/obj \
    -bootclasspath $JAVA/jre/lib/rt.jar \
    -classpath $ANDROID_SDK_DIR/android.jar:$APK_BUILD/obj \
    -sourcepath src $APK_BUILD/src/$PKG_DOMAIN/$PKG_ORG/$PKG_APP/R.java \
    $APK_BUILD/src/$PKG_DOMAIN/$PKG_ORG/$PKG_APP/NativeLoader.java

$ANDROID_BUILDTOOLS/d8 \
    --lib $ANDROID_SDK_DIR/android.jar \
    --output $APK_BUILD/dex \
    $(find "$APK_BUILD/obj" -type f -name "*.class")

# Add resources and assets to APK
echo -e "\n#######################################################################################"
echo "Adding resources and assets to apk..."
echo "#######################################################################################"
$ANDROID_BUILDTOOLS/aapt package -f \
    -M $APK_BUILD/AndroidManifest.xml \
    -S $APK_BUILD/res \
    -A $APK_BUILD/assets \
    -I $ANDROID_SDK_DIR/android.jar \
    -F $BUILD_ROOT/$APP_NAME.apk $APK_BUILD/dex

# Add libraries to APK
echo -e "\n#######################################################################################"
echo "Adding libraries to the apk..."
echo "#######################################################################################"
cd $APK_BUILD
for ABI in $ABIS; do
    $ANDROID_BUILDTOOLS/aapt add ../$APP_NAME.apk lib/$ABI/lib$APP_NAME.so
done
cd -

# Align and sign
echo -e "\n#######################################################################################"
echo "Aligning the apk..."
echo "#######################################################################################"
$ANDROID_BUILDTOOLS/zipalign -f 4 $BUILD_ROOT/$APP_NAME.apk $BUILD_ROOT/$APP_NAME.aligned.apk
mv $BUILD_ROOT/$APP_NAME.aligned.apk $BUILD_ROOT/$APP_NAME.apk

if [ ! -e "$APP_NAME.keystore" ]
then
    echo -e "\n#######################################################################################"
    echo "Generating keystore..."
    echo "#######################################################################################"
    echo "Expecting keytool to be in PATH..."
    keytool -genkeypair \
        -validity 10000 \
        -dname "CN=$APP_NAME" \
        -keystore $APP_NAME.keystore \
        -storepass "$APP_NAME" \
        -keypass "$APP_NAME" \
        -alias "$APP_NAME"Key \
        -keyalg RSA
fi

echo -e "\n#######################################################################################"
echo "Signing the apk..."
echo "#######################################################################################"
$ANDROID_BUILDTOOLS/apksigner sign --ks $APP_NAME.keystore \
    --ks-pass pass:"$APP_NAME" \
    --key-pass pass:"$APP_NAME" \
    --ks-key-alias "$APP_NAME"Key \
    --out $BUILD_ROOT/$APP_NAME.apk \
    --in $BUILD_ROOT/$APP_NAME.apk

echo -e "\n#######################################################################################"
echo "Verifying the signature..."
echo "#######################################################################################"
$ANDROID_BUILDTOOLS/apksigner verify --verbose $BUILD_ROOT/$APP_NAME.apk

if [ "$1" = "-r" ]
then
    echo -e "\n#######################################################################################"
    echo "Trying to install apk..."
    echo "#######################################################################################"
    $ANDROID_PLATFORM_TOOLS/adb install -r $BUILD_ROOT/$APP_NAME.apk

    echo -e "\n#######################################################################################"
    echo "Running..."
    echo "#######################################################################################"
    $ANDROID_PLATFORM_TOOLS/adb shell am start -n $PKG_DOMAIN.$PKG_ORG.$PKG_APP/$PKG_DOMAIN.$PKG_ORG.$PKG_APP.NativeLoader
fi
