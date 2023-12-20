#! /bin/bash -e

export INSTALLER_DIR=${pkg_build_base}/installer
if [ -d $INSTALLER_DIR ]; then
    rm -rf ${INSTALLER_DIR}
fi
mkdir -p $INSTALLER_DIR

if test -f ${sdk_top}/inno/inno_setup/ISCC.exe ; then
    ${sdk_top}/inno/inno_setup/ISCC.exe -O"${INSTALLER_DIR}" $TM_BUILD_DIR/packages/windows/TeXmacs.iss
    if test -f ${INSTALLER_DIR}/TeXmacs-*.exe ; then
        echo "Success! You will find the new installer at ${INSTALLER_DIR}" &&
        echo "It is an InnoSetup installer."
    fi
fi

#make a 7z installer 
OPTS7="-m0=lzma -mx=9 -md=64M"
TMPPACK="${INSTALLER_DIR}/tmp.7z"
TARGET="${INSTALLER_DIR}/texmacs_installer.7z.exe"

cd ${BUNDLE_DIR}
fileList="$(ls -p -1)"
echo "Creating archive" &&
    (7za a $OPTS7 "$TMPPACK" $fileList) &&
    (cat "$sdk_top/7-zip_lzma/bin/7zSD.sfx" &&
        echo ';!@Install@!UTF-8!' &&
        echo 'Title="TeXmacs for Windows"' &&
        echo 'BeginPrompt="This archive extracts TeXmacs for Windows"' &&
        echo 'CancelPrompt="Do you want to cancel TeXmacs installation?"' &&
        echo 'ExtractDialogText="Please, wait..."' &&
        echo 'ExtractPathText="Where do you want to install TeXmacs?"' &&
        echo 'ExtractTitle="Extracting..."' &&
        # the new "modified sfx" no longer handles these options https://github.com/git-for-windows/7-Zip/blob/v19.00-VS2019-sfx/README.md
        #echo 'GUIFlags="8+32+64+256+4096"' &&
        #echo 'GUIMode="1"' &&
        #echo 'InstallPath="%PROGRAMFILES%\\TeXmacs"' &&
        echo 'InstallPath="%%S\\TeXmacs"' &&
        #if RunProgram is empty, the sfx tries to run setup.exe
        #so we run a do-nothing program
        echo 'RunProgram="cmd.exe /q /c exit"' &&
        # where to find the program https://github.com/chrislake/7zsfxmm/wiki/Parameters#RunProgram
        # Note: the new modified sfx does not seem to expand environment variables...
        echo 'Directory="C:\\Windows\\system32\\"' &&
        #echo 'executeFile="cmd"' &&
        #echo 'executeParameters="exit"' &&
        #echo 'OverwriteMode="2"' &&
        echo ';!@InstallEnd@!' &&
        cat "$TMPPACK") > $TARGET &&
    echo "Success! You will find the new installer at $TARGET" &&
    echo "It is a self-extracting .7z archive." &&
    rm $TMPPACK
