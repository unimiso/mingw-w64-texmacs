#! /bin/bash -e

echo "build() cwd=${PWD}"

export GUILE_LOAD_PATH="${MINGW_PREFIX}/share/guile/1.8"

cd $TM_BUILD_DIR

./configure \
    --prefix=${MINGW_PREFIX} \
    --build=${MINGW_CHOST} \
    --host=${MINGW_CHOST} \
    --with-guile="${MINGW_PREFIX}/bin/guile-config" \
    --with-qt="${MINGW_PREFIX}/bin/" \
    --with-sparkle="${sdk_top}/winsparkle/WinSparkle*" \
    #--enable-console \
    #--disable-qtpipes \
    #--enable-debug  # must not strip in this case (line 37 and 159) !!

echo "#define GS_EXE \"bin/gs.exe\"" >> src/System/tm_configure.hpp
make -j$(nproc)
