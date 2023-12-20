#! /bin/bash -e

echo "package() cwd=${PWD}"

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

export BUNDLE_DIR="${pkg_build_base}/distr"

###############################################################################
# Make a Windows installer
# here we mimick what would do "make WINDOWS_BUNDLE", plus our own extras
###############################################################################

dlls_for_exes () {
    # Add DLLs' transitive dependencies (taken from git for windows)
    # echo "regexp(tDLL Name)=s|^\tDLL Name: ${MINGW_PREFIX}/bin/|p"
    # ${MINGW_PREFIX}にあるとは限らないので、PATHの中を順繰りに見なければいけない。
    # むしろ見つからなかったらパッケージ作れない勢い。
    # さらに、DLLが他のDLLを呼んでいるかもしれないので再帰的に行わなければならない。
    dlls=
    todo="$* "
    while test -n "$todo"
    do
        path=${todo%% *}
        todo=${todo#* }
        case "$path" in ''|' ') continue;; esac
        for dll in $(objdump -p "$path" | sed -n "s|^\tDLL Name: |${MINGW_PREFIX}/bin/|p")
        do
            if [ -f $dll ]; then
                # since all the dependencies have been resolved for
                # building, if we do not find a dll in ${MINGW_PREFIX}/bin/
                # it must be a Windows-provided dll and then we ignore it
                # otherwise we add it to the dlls to scan
                case "$dlls" in
                    *"$dll"*) ;; # already found
                    *) dlls="$dlls $dll"; todo="$todo $dll ";;
                esac
            fi
        done
    done
    echo "$dlls"
}

#------------------------------------------------------------------------

# rm -r -f $BUNDLE_DIR
if test ! -d $BUNDLE_DIR ; then
    mkdir -p $BUNDLE_DIR
fi

if [ -f $BUNDLE_DIR/bin/texmacs.exe ]; then
    rm $BUNDLE_DIR/bin/texmacs.*
fi

cd $TM_BUILD_DIR

cp -r -f  -u TeXmacs/* $BUNDLE_DIR/

mv -f $BUNDLE_DIR/bin/texmacs.bin $BUNDLE_DIR/bin/texmacs.exe
strip -s $BUNDLE_DIR/bin/texmacs.exe
rm -f -r $BUNDLE_DIR/bin/texmacs
cp -r -f packages/windows/*.exe $BUNDLE_DIR/bin

cd /

# the additional programs we bundle with TeXmacs
DEPS="${MINGW_PREFIX}/bin/pdftocairo.exe \
    ${MINGW_PREFIX}/bin/rsvg-convert.exe \
    ${MINGW_PREFIX}/bin/hunspell.exe \
    ${MINGW_PREFIX}/bin/gswin32c.exe \
    ${MINGW_PREFIX}/bin/wget.exe \
    ${sdk_top}/winsparkle/WinSparkle.dll \
    ${sdk_top}/SumatraPDF/SumatraPDF.exe \
    ${MINGW_PREFIX}/bin/magick.exe"

PROGS="$DEPS $TM_BUILD_DIR/TeXmacs/bin/texmacs.bin"

# lookup all the Mingw32 ddls needed by Texmacs + additional programs
# MINGW_DLLs_NEEDED=$(dlls_for_exes $PROGS)
MINGW_DLLs_NEEDED=$(dlls_for_exes $PROGS)
echo "MINGW_DLLs_NEEDED=$MINGW_DLLs_NEEDED"

for DLL in $MINGW_DLLs_NEEDED ; do
    cp -u $DLL $BUNDLE_DIR/bin
done

for prog in "$DEPS" ; do
    cp -u $prog $BUNDLE_DIR/bin
done

mv $BUNDLE_DIR/bin/gswin32c.exe $BUNDLE_DIR/bin/gs.exe

# Qt plugins TeXmacs presently uses
QT_NEEDED_PLUGINS_LIST="generic imageformats" #qt5 platforms/qwindows.dll handled separately below
#QT_NEEDED_PLUGINS_LIST="accessible imageformats" #qt4
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
