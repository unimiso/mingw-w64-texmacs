#! /bin/bash -e

echo "precond() cwd=${PWD}"

pacman -S --needed --noconfirm base python less openssh patch make tar diffutils ca-certificates \
    git subversion mintty vim p7zip markdown winpty unrar mingw-w64-i686-toolchain base-devel

export sdk_top=${pkg_build_base}/sdk
echo "sdk_top=${sdk_top}"

if [ ! -d $sdk_top ]; then
    mkdir -p $sdk_top
fi

if [ ! -d $sdk_top/mingw-w64-guile1.8 ]; then
    mkdir -p $sdk_top/mingw-w64-guile1.8
    cd $sdk_top/mingw-w64-guile1.8/
    wget https://github.com/slowphil/mingw-w64-guile1.8/releases/download/v1.8.8-mingw-w64-i686-1/mingw-w64-i686-guile1.8-1.8.8-1-any.pkg.tar.xz
    pacman --noconfirm -U mingw-w64-i686-guile1.8-1.8.8-1-any.pkg.tar.xz
fi

if [ ! -d $sdk_top/inno ]; then
    mkdir -p $sdk_top/inno
    cd $sdk_top/inno/
    if [ ! -z $sdk_top/inno/innounp.exe ]; then
        wget https://downloads.sourceforge.net/project/innounp/innounp/innounp%200.49/innounp049.rar
        unrar e innounp049.rar
        rm *.rar
    fi
    if [ ! -z $sdk_top/inno/inno_setup/ISCC.exe ]; then
        wget http://files.jrsoftware.org/is/6/innosetup-6.0.3.exe
        ./innounp.exe -dinno_setup -c{app} -v -x innosetup-6.0.3.exe
        rm innosetup-6.0.3.exe
    fi
fi

if [ ! -d $sdk_top/winsparkle ]; then
    mkdir $sdk_top/winsparkle
    cd $sdk_top/winsparkle
    wget https://github.com/vslavik/winsparkle/releases/download/v0.6.0/WinSparkle-0.6.0.zip
    7z x WinSparkle-0.6.0.zip
    rm *.zip
    cd WinSparkle-*
    cp include/* ..
    cp Release/* ..
fi

if [ ! -d $sdk_top/SumatraPDF ]; then
    mkdir $sdk_top/SumatraPDf
    cd $sdk_top/SumatraPDF
    wget https://kjkpub.nyc3.digitaloceanspaces.com/software/sumatrapdf/rel/SumatraPDF-3.1.2.zip
    7z x SumatraPDF-3.1.2.zip
    rm *.zip
fi

if [ ! -d $sdk_top/7-zip_lzma ]; then
    mkdir $sdk_top/7-zip_lzma
    cd $sdk_top/7-zip_lzma
    wget https://www.7-zip.org/a/lzma2301.7z
    7z x lzma2301.7z
    rm *.7z
fi
