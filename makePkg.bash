#! /bin/bash -e

# MINGW_ARCH=mingw32 makepkg-mingw -sL --noconfirm

_realname=texmacs
pkgbase=mingw-w64-${_realname}
pkgname=${MINGW_PACKAGE_PREFIX}-${_realname}
_pkgname=texmacs
pkgver=r1
pkgrel=1
pkgdesc="Free scientific text editor, inspired by TeX and GNU Emacs. WYSIWYG editor and CAS-interface. (mingw-w64)"
arch=('any')
url="http://www.texmacs.org/"
license=('GPL')
makedepends=("${MINGW_PACKAGE_PREFIX}-gcc"
             "${MINGW_PACKAGE_PREFIX}-pkg-config"
             p7zip
             "${MINGW_PACKAGE_PREFIX}-autotools"
            )
depends=(
          "${MINGW_PACKAGE_PREFIX}-hunspell"
          "${MINGW_PACKAGE_PREFIX}-wget"
          "${MINGW_PACKAGE_PREFIX}-gc"
          "${MINGW_PACKAGE_PREFIX}-ghostscript"
          "${MINGW_PACKAGE_PREFIX}-imagemagick"
          "${MINGW_PACKAGE_PREFIX}-librsvg"
          "${MINGW_PACKAGE_PREFIX}-lcms2"
          "${MINGW_PACKAGE_PREFIX}-freetype"
          "${MINGW_PACKAGE_PREFIX}-iconv"
          "${MINGW_PACKAGE_PREFIX}-qt5-base"
          "${MINGW_PACKAGE_PREFIX}-qt5-imageformats"
          "${MINGW_PACKAGE_PREFIX}-qt5-svg"
          "${MINGW_PACKAGE_PREFIX}-guile1.8"
          "${MINGW_PACKAGE_PREFIX}-poppler"
        )
source=("${_pkgname}::git+https://github.com/unimiso/texmacs.git")

provides=('texmacs')
conflicts=('texmacs')

export pkg_build_base=`pwd`
echo "pkg_build_base=${pkg_build_base}"

precond() {
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

	cd $sdk_top
	# if [ ! -d mingw-w64-texmacs ]; then
	#   git clone https://github.com/slowphil/mingw-w64-texmacs.git
	# fi
	# cd $sdk_top/mingw-w64-texmacs
}

prepare() {
	echo "prepare() cwd=${PWD}"

    export TM_BUILD_DIR=${pkg_build_base}/${_pkgname}
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
}

build() {
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
}

package() {
	echo "package() cwd=${PWD}"

    export BUNDLE_DIR="${pkg_build_base}/distr"

    ###############################################################################
    # Make a Windows installer
    # here we mimick what would do "make WINDOWS_BUNDLE", plus our own extras
    ###############################################################################

    dlls_for_exes () {
        # Add DLLs' transitive dependencies (taken from git for windows)
        # echo "regexp(tDLL Name)=s|^\tDLL Name: ${MINGW_PREFIX}/bin/|p"
        dlls=
        todo="$* "
        while test -n "$todo"
        do
            path=${todo%% *}
            todo=${todo#* }
            case "$path" in ''|' ') continue;; esac
            for dll in $(objdump -p "$path" | sed -n -e "s|^\tDLL Name: |${MINGW_PREFIX}/bin/|p")
            do
                if [ -f $dll ]; then 
                    # since all the dependencies have been resolved for
                    # building, if we do not find a dll in ${MINGW_PREFIX}/bin/
                    # it must be a Windows-provided dll and then we ignore it
                    # otherwise we add it to the dlls to scan
                    case "$dlls" in
                      *"$dll"*) ;; # already found
                      *) dlls="$dlls $dll"; todo="$todo /$dll ";;
                    esac
                fi
            done
        done
        echo "$dlls"
    }

    # the additional programs we bundle with TeXmacs
    DEPS="${MINGW_PREFIX}/bin/pdftocairo.exe \
        ${MINGW_PREFIX}/bin/rsvg-convert.exe \
        ${MINGW_PREFIX}/bin/hunspell.exe \
        ${MINGW_PREFIX}/bin/gswin32c.exe \
        ${MINGW_PREFIX}/bin/wget.exe \
        ${sdk_top}/winsparkle/WinSparkle.dll \
        ${sdk_top}/SumatraPDF/SumatraPDF.exe \
        ${MINGW_PREFIX}/bin/magick.exe"

    PROGS="$DEPS  $TM_BUILD_DIR/TeXmacs/bin/texmacs.bin"

    # lookup all the Mingw32 ddls needed by Texmacs + additional programs
    MINGW_DLLs_NEEDED=$(dlls_for_exes $PROGS)
    echo "MINGW_DLLs_NEEDED=$MINGW_DLLs_NEEDED"

    # Qt plugins TeXmacs presently uses
    QT_NEEDED_PLUGINS_LIST="generic imageformats" #qt5 platforms/qwindows.dll handled separately below
    #QT_NEEDED_PLUGINS_LIST="accessible imageformats" #qt4
    rm -r -f $BUNDLE_DIR

    if test ! -d $BUNDLE_DIR ; then
        mkdir -p $BUNDLE_DIR
    fi

    cd $TM_BUILD_DIR
    if test -f $BUNDLE_DIR/bin/texmacs.exe ; then
        rm $BUNDLE_DIR/bin/texmacs.*
    fi

    cp -r -f  -u TeXmacs/* $BUNDLE_DIR/

    mv -f $BUNDLE_DIR/bin/texmacs.bin $BUNDLE_DIR/bin/texmacs.exe
    strip -s $BUNDLE_DIR/bin/texmacs.exe
    rm -f -r $BUNDLE_DIR/bin/texmacs
    cp -r -f packages/windows/*.exe $BUNDLE_DIR/bin

    cd /

    for DLL in $MINGW_DLLs_NEEDED ; do
        cp -u $DLL $BUNDLE_DIR/bin
    done

    for prog in "$DEPS" ; do
        cp -u $prog $BUNDLE_DIR/bin
    done

    mv $BUNDLE_DIR/bin/gswin32c.exe $BUNDLE_DIR/bin/gs.exe

    for PLUGIN in $QT_NEEDED_PLUGINS_LIST ; do
        cp -r -f -u ${MINGW_PREFIX}/share/qt5/plugins/$PLUGIN $BUNDLE_DIR/bin
    done
    mkdir $BUNDLE_DIR/bin/platforms
    cp -r -f -u ${MINGW_PREFIX}/share/qt5/plugins/platforms/qwindows.dll $BUNDLE_DIR/bin/platforms

    # pick up ice-9 for guile
    export GUILE_LOAD_PATH="${MINGW_PREFIX}/share/guile/1.8"
    find `guile-config info pkgdatadir` -type d -name ice-9 -exec cp -r -f {} $BUNDLE_DIR/progs/ \;

    # create dir where hunspell looks for dictionaries
    mkdir $BUNDLE_DIR/share
    mkdir $BUNDLE_DIR/share/hunspell

    # list of dictionaries languages that will be packaged 
    # Add as many as you want separated by spaces : dicts="en_US fr_FR en_GB"
    # (the language of the current session is automatically added to the list)

    dicts="en_US" 
    local_lang=$(echo $LANG | cut -d'.' -f1)
    if [[ $local_lang = "" ]]; then
        local_lang=$(echo $LC_CTYPE | cut -d'.' -f1)
    fi
    if [[ $dicts != *"$local_lang"* ]]; then
        dicts="$dicts $local_lang"
    fi 
    echo $dicts

    # now fetch dictionaries.
    # We use Lyx Repo's because they are all nicely and systematically organized in a single location
    # (unlike LibreOffice dictionaries https://github.com/LibreOffice/dictionaries)

    cd $BUNDLE_DIR/share/hunspell

    lang_list=
    for dic in $dicts ; do
        if test "$(svn export --force svn://svn.lyx.org/lyx/dictionaries/trunk/dicts/${dic}.dic ./ )"; then
            lang_list="$lang_list $(locale -av | grep -A2 -m1 $dic | sed -n -e 's/^ language | //p' | tr '[A-Z]' '[a-z]')"
            svn export --force  svn://svn.lyx.org/lyx/dictionaries/trunk/dicts/${dic}.aff ./
        else
            echo "Cannot download dictionary $dic , sorry"
        fi
    done
    lang_list=$(echo $lang_list | sed -n -e 's/english/american/p')

    # now fetch dictionaries' licences and doc.
    # if the dictionary documentation & licence is not included properly
    # then define the language list ($lang_list) manually (not much work anyway)

    echo "$lang_list"

    for language in $lang_list ; do
        svn export --force "svn://svn.lyx.org/lyx/dictionaries/trunk/dicts/info/${language}" ./$language
    done

    #pull additional plugins from tm-forge and slowphil
    #mkdir -p $BUNDLE_DIR/plugins
    cd $BUNDLE_DIR/plugins
    svn export https://github.com/texmacs/tm-forge/trunk/miscellanea/komments komments
    svn export https://github.com/texmacs/tm-forge/trunk/miscellanea/outline outline
    svn export https://github.com/texmacs/tm-forge/trunk/miscellanea/fontawesome fontawesome
    svn export https://github.com/slowphil/zotexmacs/trunk/plugin/zotexmacs zotexmacs


    # -------------------------------------------------------

    export INSTALLER_DIR=${pkg_build_base}/installer
    if [ -d $INSTALLER_DIR ]; then
        rm -rf ${INSTALLER_DIR}
    fi
    mkdir -p $INSTALLER_DIR

    if test -f ${sdk_top}/inno/inno_setup/ISCC.exe ; then
        ${sdk_top}/inno/inno_setup/ISCC.exe /O"${INSTALLER_DIR}" $TM_BUILD_DIR/packages/windows/TeXmacs.iss
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
    #fi
}

pushd ./ > /dev/null
    precond
popd > /dev/null
pushd ./ > /dev/null
    prepare
popd > /dev/null
pushd ./ > /dev/null
    build
popd > /dev/null
pushd ./ > /dev/null
    package
popd > /dev/null

echo "All finished."
