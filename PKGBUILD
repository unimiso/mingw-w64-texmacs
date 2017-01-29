# PKGBUILD for MinGW-w64 derived from archlinux PKGBUILD - Philippe Joyez   
# archlinux Maintainer: Ronald van Haren <ronald.archlinux.org>
# Contributor: Damir Perisa <damir.perisa@bluewin.ch> # Contributor: Christopher Reimer <c.reimer1993@gmail.com>
# Contributor: wangjiezhe <wangjiezhe AT yandex DOT com>

_realname=texmacs
pkgbase=mingw-w64-${_realname}
pkgname="${MINGW_PACKAGE_PREFIX}-${_realname}"
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
            )
depends=(
          #"${MINGW_PACKAGE_PREFIX}-aspell"
		  "${MINGW_PACKAGE_PREFIX}-hunspell"
		  "${MINGW_PACKAGE_PREFIX}-wget"
          "${MINGW_PACKAGE_PREFIX}-gc"
          "${MINGW_PACKAGE_PREFIX}-ghostscript"
          "${MINGW_PACKAGE_PREFIX}-imagemagick"
          "${MINGW_PACKAGE_PREFIX}-lcms2"
          "${MINGW_PACKAGE_PREFIX}-freetype"
          "${MINGW_PACKAGE_PREFIX}-iconv"
          "${MINGW_PACKAGE_PREFIX}-qt4"
          "${MINGW_PACKAGE_PREFIX}-guile1.8"
		  "${MINGW_PACKAGE_PREFIX}-poppler-qt4"

        )
source=("${_pkgname}::svn://svn.savannah.gnu.org/texmacs/trunk/src"
        )
sha1sums=('SKIP'
		  )
options=('!emptydirs' '!ccache' 'strip')
provides=('texmacs')
conflicts=('texmacs')

# the function pkgver() does not seem to work. disabling. 
#pkgver() {
# cd "${srcdir}/../${_pkgname}"
#  svn info | awk '/Revision/{r=$2}/Date/{gsub(/-/,"");d=$4}END{print d"."r}'
#}

prepare() {
  cd "${srcdir}/../${_pkgname}"
  pkgver="svn$(svnversion)+extras"
  echo ${pkgver}
  echo ${pkgver} > SVNREV
  if [ -d "${srcdir}/${_pkgname}-build" ]; then
    rm -rf "${srcdir}/${_pkgname}-build"
  fi 
  mv "${srcdir}/${_pkgname}" "${srcdir}/${_pkgname}-build"
  # svn export "${srcdir}/${_pkgname}" "${srcdir}/${_pkgname}-build"

  cd "${srcdir}/${_pkgname}-build"

  patch -i ../../qt_m4.patch -p2
  patch -i ../../raux_win.patch -p0
  patch -i ../../better-image-i-o.patch -p1
  patch -i ../../win_unicode.patch -p1
  patch -i ../../winsparkle.patch -p1
  patch -i ../../adjust-windows-versioning.patch -p1
  sed -i 's|^SVNREV=\${SVNREV/:/_}|SVNREV='${pkgver}'|' configure.in
  autoreconf

  
#  patch -i ../../configure.patch -p2

  sed -i 's|#! /bin/sh|#! /bin/bash|' configure
}

build() {
  export GUILE_LOAD_PATH="${MINGW_PREFIX}/share/guile/1.8"

  cd "${srcdir}/${_pkgname}-build"

./configure \
    --prefix=${MINGW_PREFIX} \
    --build=${MINGW_CHOST} \
    --host=${MINGW_CHOST} \
    --with-guile="/mingw32/bin/guile-config" \
    --with-qt="/mingw32/bin/" \
    --with-sparkle="/build/winsparkle" \
    #--enable-console --enable-debug

  make -j$(nproc)
}

package() {
export TM_BUILD_DIR="${srcdir}/${_pkgname}-build"
export BUNDLE_DIR="${srcdir}/distr/TeXmacs-Windows"

###############################################################################
# Make a Windows installer
# here we mimick what would do "make WINDOWS_BUNDLE", plus our own extras
###############################################################################

dlls_for_exes () {
	# Add DLLs' transitive dependencies (taken from git for windows)
	dlls=
	todo="$* "
	while test -n "$todo"
	do
		path=${todo%% *}
		todo=${todo#* }
		case "$path" in ''|' ') continue;; esac
		for dll in $(objdump -p "$path" |
			sed -n 's/^\tDLL Name: /mingw32\/bin\//p')
		do
           if test -f "/"$dll ; then 
		   # since all the dependencies have been resolved for
		   # building, if we do not find a dll in /mingw32/bin/
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

DEPS="/mingw32/bin/pdftocairo.exe \
 /mingw32/bin/hunspell.exe \
 /mingw32/bin/gswin32c.exe \
 /mingw32/bin/wget.exe"

PROGS="$DEPS  $TM_BUILD_DIR/TeXmacs/bin/texmacs.bin"

# lookup all the Mingw32 ddls needed by Texmacs + additional programs
MINGW_DLLs_NEEDED=$(dlls_for_exes $PROGS)

WINSPARKLE_DLL="WinSparkle.dll"
WINSPARKLE_PATH="/build/winsparkle"
MINGW_DLLs_NEEDED+=" "$WINSPARKLE_PATH/$WINSPARKLE_DLL

echo $MINGW_DLLs_NEEDED

# Qt plugins TeXmacs presently uses
QT_NEEDED_PLUGINS_LIST="accessible imageformats"

GS_UTILS_PATH=/mingw32/share/ghostscript/9.19/lib/
GS_UTILS=( ps2epsi.ps ps2epsi.bat cat.ps gssetgs.bat )

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
cp -r -f misc/admin/texmacs_updates_dsa_pub.pem $BUNDLE_DIR/bin
cp -r -f packages/windows/*.exe $BUNDLE_DIR/bin

cd /

for DLL in $MINGW_DLLs_NEEDED ; do
cp -u $DLL $BUNDLE_DIR/bin
done

for prog in "$DEPS" ; do
cp -u $prog $BUNDLE_DIR/bin
done

for PLUGIN in $QT_NEEDED_PLUGINS_LIST ; do
            cp -r -f -u /mingw32/share/qt4/plugins/$PLUGIN $BUNDLE_DIR/bin
        done

# pick up ice-9 for guile
export GUILE_LOAD_PATH="${MINGW_PREFIX}/share/guile/1.8"
find `guile-config info pkgdatadir` -type d -name ice-9 -exec cp -r -f {} $BUNDLE_DIR/progs/ \;

# create dir where hunspell looks for dictionaries
mkdir $BUNDLE_DIR/share
mkdir $BUNDLE_DIR/share/hunspell

# list of dictionaries languages that will be packaged 
# (the last one is that of the language of the current session)
# Add as many as you want

local_lang=$(echo $LANG | cut -d'.' -f1)

dicts="en_US $local_lang"
 
echo $dicts

# now fetch dictionaries.
# We use Lyx Repo's because they are all nicely and systematically organized in a single location
# (unlike LibreOffice dictionaries)

cd $BUNDLE_DIR/share/hunspell

lang_list=
for dic in $dicts ; do
lang_list="$lang_list $(locale -av | grep -A2 -m1 $dic | sed -n -e 's/^ language | //p' | tr '[A-Z]' '[a-z]')"
 svn export svn://svn.lyx.org/lyx/dictionaries/trunk/dicts/${dic}.dic ./
 svn export svn://svn.lyx.org/lyx/dictionaries/trunk/dicts/${dic}.aff ./
done

lang_list=$(echo $lang_list | sed -n -e 's/english/american/p')

# now fetch dictionaries' licences and doc.
# if the dictionary documentation & licence is not included properly
# then define the language list ($lang_list) manually (not much work anyway)

for language in $lang_list ; do
svn export "svn://svn.lyx.org/lyx/dictionaries/trunk/dicts/info/${language}" ./$language
done

if test -f /build/inno/inno_setup/ISCC.exe ; then
rm -rf ${srcdir}/distr/windows
/build/inno/inno_setup/ISCC.exe $TM_BUILD_DIR/packages/windows/TeXmacs.iss
TARGET="/texmacs_installer.exe"
if test -f ${srcdir}/distr/windows/TeXmacs-*.exe ; then
cp ${srcdir}/distr/windows/TeXmacs-*.exe ${srcdir}/distr/windows$TARGET 
mv ${srcdir}/distr/windows$TARGET /
echo "Success! You will find the new installer at \"$(cygpath -aw $TARGET)\"." &&
echo "It is an InnoSetup installer."
fi

else

OPTS7="-m0=lzma -mx=9 -md=64M"
TMPPACK="${srcdir}/tmp.7z"
TARGET="/texmacs_installer.exe"

fileList="$(ls -dp -1 $BUNDLE_DIR/*)"

echo "Creating archive" &&
(cd / && 7za a $OPTS7 "$TMPPACK" $fileList) &&
(cat "/7zSD.sfx" &&
 echo ';!@Install@!UTF-8!' &&
 echo 'Title="TeXmacs for Windows"' &&
 echo 'BeginPrompt="This archive extracts TeXmacs for Windows"' &&
 echo 'CancelPrompt="Do you want to cancel TeXmacs installation?"' &&
 echo 'ExtractDialogText="Please, wait..."' &&
 echo 'ExtractPathText="Where do you want to install TeXmacs?"' &&
 echo 'ExtractTitle="Extracting..."' &&
 echo 'GUIFlags="8+32+64+256+4096"' &&
 echo 'GUIMode="1"' &&
 echo 'InstallPath="%PROGRAMFILES%\\TeXmacs"' &&
 echo 'OverwriteMode="2"' &&
 echo ';!@InstallEnd@!' &&
 cat "$TMPPACK") > "$TARGET" &&
echo "Success! You will find the new installer at \"$(cygpath -aw $TARGET)\"." &&
echo "It is a self-extracting .7z archive." &&
rm $TMPPACK

fi
}

