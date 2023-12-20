#! /bin/bash -e

# MINGW_ARCH=mingw32 makepkg-mingw -sL --noconfirm

export pkg_build_base=`pwd`
echo "pkg_build_base=${pkg_build_base}"

pushd ./ > /dev/null
    source makePrecond.bash
popd > /dev/null
pushd ./ > /dev/null
    source makePrepare.bash
popd > /dev/null
pushd ./ > /dev/null
    source makeBuild.bash
popd > /dev/null
pushd ./ > /dev/null
    source makeBundle.bash
popd > /dev/null
pushd ./ > /dev/null
    source makeInstaller.bash
popd > /dev/null

echo "All finished."
