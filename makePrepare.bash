#! /bin/bash -e

echo "prepare() cwd=${PWD}"

export TM_BUILD_DIR=${pkg_build_base}/texmacs
echo "TM_BUILD_DIR=${TM_BUILD_DIR}"

if [ ! -d ${TM_BUILD_DIR} ]; then
    git clone https://github.com/unimiso/texmacs.git ${TM_BUILD_DIR}
fi

cd $TM_BUILD_DIR
echo "cwd=$TM_BUILD_DIR"

echo "patching... winsparkle_config.patch"
if [ ! -f src/winsparkle_config.patch.applied ]; then
    patch -i ${pkg_build_base}/winsparkle_config.patch -p1
    touch src/winsparkle_config.patch.applied
fi

echo "patching... my_current.patch"
if [ ! -f src/TeXmacs-mingw-w64.patch.applied ]; then
    git --work-tree=. apply ${pkg_build_base}/TeXmacs-mingw-w64.patch
    touch src/TeXmacs-mingw-w64.patch.applied
fi

if test ! -d TeXmacs/misc/updater_key ; then
    mkdir -p TeXmacs/misc/updater_key
fi
cp ${pkg_build_base}/slowphil_github_texmacs_updates_dsa_pub.pem packages/windows/dsa_pub.pem

autoreconf
sed -i 's|#! /bin/sh|#! /bin/bash|' configure

# get exes that are no longer in current svn but still needed
wget "https://svn.savannah.gnu.org/viewvc/*checkout*/texmacs/trunk/src/packages/windows/FullName.exe?revision=10795&pathrev=10795" -O packages/windows/FullName.exe
wget "https://svn.savannah.gnu.org/viewvc/*checkout*/texmacs/trunk/src/packages/windows/winwallet.exe?revision=10795&pathrev=10795" -O packages/windows/winwallet.exe
