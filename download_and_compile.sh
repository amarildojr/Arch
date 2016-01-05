#!/bin/bash
#* Written by Francesco Angelo Brisa, started January 2008.
#
# Copyright (C) 2013 Francesco Angelo Brisa
# email: fbrisa@gmail.com   -   fbrisa@yahoo.it
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

VERSION="2.33"
FGVERSION="release/3.6.0"

#######################################################
# THANKS TO
#######################################################
# Special thanks to Alessandro Garosi for FGComGui and 
# other patches
# Thanks to "Pat Callahan" for patches for fgrun compilation
# Thanks to "F-JJTH" for bug fixes and suggestions
# Thanks again to "F-JJTH" for OpenRTI and FGX 
# Thanks to André, (taureau89_9) for debian stable packages fixes

LOGFILE=compilation_log.txt
WHATTOBUILD=
#AVAILABLE VALUES: PLIB OPENRTI OSG SIMGEAR FGFS DATA FGRUN FGO FGX OPENRADAR ATCPIE TERRAGEAR TERRAGEARGUI
WHATTOBUILDALL=(SIMGEAR FGFS DATA)
STABLE=
APT_GET_UPDATE="y"
DOWNLOAD_PACKAGES="y"
COMPILE="y"
RECONFIGURE="y"
DOWNLOAD="y"
JOPTION=""
OOPTION=""
DEBUG=""
SG_CMAKEARGS=""
FG_CMAKEARGE=""

while getopts "shc:p:a:d:r:j:O:i" OPTION; do
  case $OPTION in
    s) STABLE="STABLE" ;;
    h) HELP="HELP" ;;
    a) APT_GET_UPDATE=$OPTARG ;;
    c) COMPILE=$OPTARG ;;
    p) DOWNLOAD_PACKAGES=$OPTARG ;;
    d) DOWNLOAD=$OPTARG ;;
    r) RECONFIGURE=$OPTARG ;;
    j) JOPTION=" -j"$OPTARG" " ;;
    O) OOPTION=" -O"$OPTARG" " ;;
    i) OPENRTI="OPENRTI" ;;
    ?) HELP="HELP" ;;
  esac
done
shift $(($OPTIND - 1))

if [ ! "$#" = "0" ]; then
  for arg in $*
  do
    WHATTOBUILD=( "${WHATTOBUILD[@]}" "$arg" )
  done
else
  WHATTOBUILD=( "${WHATTOBUILDALL[@]}" )
fi

if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="ALL"' ]]; then
  WHATTOBUILD=( "${WHATTOBUILDALL[@]}" )
fi


if [ "$STABLE" = "STABLE" ]; then
  FGVERSION=$FGVERSION
else
  FGVERSION="next"
fi


if [ "$OPENRTI" = "OPENRTI" ]; then
  SG_CMAKEARGS="$SG_CMAKEARGS-DENABLE_RTI=ON;"
  FG_CMAKEARGS="$FG_CMAKEARGS-DENABLE_RTI=ON;"
  WHATTOBUILD=( "${WHATTOBUILD[@]}" OPENRTI )
fi



#############################################################"
# Some helper for redundant task

function _logSep(){
  echo "***********************************" >> $LOGFILE
}

function _gitUpdate(){
  if [ "$DOWNLOAD" != "y" ]; then
    return
  fi
  branch=$1
  set +e
  git diff --exit-code 2>&1 > /dev/null
  if [ $? != 1 ]; then
    set -e
    git checkout -f $branch
    git pull -r
  else
    set -e
    git stash save -u -q
    git checkout -f $branch
    git pull -r
    git stash pop -q
  fi
}

function _gitDownload(){
  if [ "$DOWNLOAD" != "y" ]; then
    return
  fi
  repo=$1
  if [ -f "README" -o -f "README.txt" ]; then
    echo "$repo exists already"
  else
    git clone $repo .
  fi
}

function _make(){
  if [ "$COMPILE" = "y" ]; then
    pkg=$1
    cd "$CBD"/build/$pkg
    echo "MAKE $pkg" >> $LOGFILE
    make $JOPTION $OOPTION 2>&1 | tee -a $LOGFILE
    echo "INSTALL $pkg" >> $LOGFILE
    make install 2>&1 | tee -a $LOGFILE
  fi
}

#######################################################
# set script to stop if an error occours
set -e

if [ "$HELP" = "HELP" ]; then
  echo "$0 Version $VERSION"
  echo "Usage:"
  echo "./$0 [-h] [-s] [-e] [-f] [-i] [-g] [-a y|n] [-c y|n] [-p y|n] [-d y|n] [-r y|n] [ALL|PLIB|OPENRTI|SIMGEAR|FGFS|DATA|FGRUN|FGO|FGX|OPENRADAR|ATCPIE|TERRAGEAR|TERRAGEARGUI]"
  echo "* without options or with ALL it recompiles the content of the WHATTOBUILDALL variable."
  echo "* Feel you free to customize the WHATTOBUILDALL variable available on the top of this script"
  echo "Switches:"
  echo "* -h  show this help"
  echo "* -e  compile FlightGear with --with-eventinput option (experimental)"
  echo "* -i  compile SimGear and FlightGear with -D ENABLE_RTI=ON option (experimental)"
  echo "* -g  compile with debug info for gcc"
  echo "* -a y|n  y=do an pacman -Syu n=skip pacman -Syu                                default=y"
  echo "* -p y|n  y=download packages n=skip download packages                          default=y"
  echo "* -c y|n  y=compile programs  n=do not compile programs                         default=y"
  echo "* -d y|n  y=fetch programs from internet (cvs, svn, etc...)  n=do not fetch     default=y"
  echo "* -j X    Add -jX to the make compilation                                       default=None"
  echo "* -O X    Add -OX to the make compilation                                       default=None"
  echo "* -r y|n  y=reconfigure programs before compiling them  n=do not reconfigure    default=y"
  echo "* -s compile only last stable known versions                                    default=y"
  exit
fi

#######################################################
#######################################################
# Warning about compilation time and size
# Idea from Jester
echo "**************************************"
echo "*                                    *"
echo "* Warning, the compilation process   *"
echo "* is going to use 12 or more Gbytes  *"
echo "* of space and at least a couple of  *"
echo "* hours to download and build FG.    *"
echo "*                                    *"
echo "* Please, be patient ......          *"
echo "*                                    *"
echo "**************************************"

#######################################################
#######################################################

echo $0 $* > $LOGFILE
echo "VERSION=$VERSION" >> $LOGFILE
echo "APT_GET_UPDATE=$APT_GET_UPDATE" >> $LOGFILE
echo "DOWNLOAD_PACKAGES=$DOWNLOAD_PACKAGES" >> $LOGFILE
echo "COMPILE=$COMPILE" >> $LOGFILE
echo "RECONFIGURE=$RECONFIGURE" >> $LOGFILE
echo "DOWNLOAD=$DOWNLOAD" >> $LOGFILE
echo "JOPTION=$JOPTION" >> $LOGFILE
echo "OOPTION=$OOPTION" >> $LOGFILE
echo "DEBUG=$DEBUG" >> $LOGFILE
_logSep

#######################################################
#######################################################
# Minimum
PKG="build-essential cmake git"
# TG
PKG="$PKG libcgal-dev libgdal-dev libtiff5-dev"
# TGGUI/OpenRTI
PKG="$PKG libqt4-dev"
# SG/FG
PKG="$PKG zlib1g-dev freeglut3-dev libboost-dev libopenscenegraph-dev"
# FG
PKG="$PKG libopenal-dev libudev-dev qt5-default libdbus-1-dev libpng12-dev libplib-dev"
# FGPanel
PKG="$PKG fluid libbz2-dev libfltk1.3-dev libxi-dev libxmu-dev"
# FGAdmin
PKG="$PKG libxinerama-dev libjpeg-dev libxft-dev"
# ATC-Pie
PKG="$PKG python3-pyqt5 python3-pyqt5.qtmultimedia libqt5multimedia5-plugins"
# FGo
PKG="$PKG python-tk"
# FGx (FGx is not compatible with Qt5, however we have installed Qt5 by default)
#PKG="$PKG libqt5xmlpatterns5-dev libqt5webkit5-dev"

if [ "$DOWNLOAD_PACKAGES" = "n" ]; then
  echo "Asking password for pacman -S operations..."
  if [ "$APT_GET_UPDATE" = "n" ]; then
    sudo pacman -Syu
  fi
  sudo pacman -S $PKG
fi

#######################################################
#######################################################

CBD=$(pwd)
LOGFILE=$CBD/$LOGFILE
echo "DIRECTORY= $CBD" >> $LOGFILE
_logSep
mkdir -p install
SUB_INSTALL_DIR=install
INSTALL_DIR=$CBD/$SUB_INSTALL_DIR
cd "$CBD"
mkdir -p build

#######################################################
# BACKWARD COMPATIBILITY WITH 1.9.14a
#######################################################

if [ -d "$CBD"/fgfs/flightgear ]; then
  echo "Move to the new folder structure"
  rm -rf OpenSceneGraph
  rm -rf plib
  rm -rf build
  rm -rf install/fgo
  rm -rf install/fgx
  rm -rf install/osg
  rm -rf install/plib
  rm -rf install/simgear
  rm -f *.log*
  rm -f run_*.sh
  mv openrti/openrti tmp && rm -rf openrti && mv tmp openrti
  mv fgfs/flightgear tmp && rm -rf fgfs && mv tmp flightgear
  mv simgear/simgear tmp && rm -rf simgear && mv tmp simgear
  mkdir -p install/flightgear && mv install/fgfs/fgdata install/flightgear/fgdata
  echo "Done"
fi

#######################################################
# PLIB
#######################################################
PLIB_INSTALL_DIR=plib
INSTALL_DIR_PLIB=$INSTALL_DIR/$PLIB_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="PLIB"' ]]; then
  echo "****************************************" | tee -a $LOGFILE
  echo "**************** PLIB ******************" | tee -a $LOGFILE
  echo "****************************************" | tee -a $LOGFILE

  mkdir -p "plib"
  cd "$CBD"/plib
  _gitDownload git://git.code.sf.net/p/libplib/code
  _gitUpdate master

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/plib
    echo "CONFIGURING plib" >> $LOGFILE
    cd "$CBD"/build/plib
    cmake -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_PLIB" \
          ../../plib 2>&1 | tee -a $LOGFILE
  fi

  _make plib
fi

#######################################################
# OPENRTI
#######################################################
OPENRTI_INSTALL_DIR=openrti
INSTALL_DIR_OPENRTI=$INSTALL_DIR/$OPENRTI_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="OPENRTI"' ]]; then
  echo "****************************************" | tee -a $LOGFILE
  echo "**************** OPENRTI ***************" | tee -a $LOGFILE
  echo "****************************************" | tee -a $LOGFILE

  mkdir -p "openrti"
  cd "$CBD"/openrti
  _gitDownload git://git.code.sf.net/p/openrti/OpenRTI

  if [ "$STABLE" = "STABLE" ]; then
    _gitUpdate release-0.7
  else
    _gitUpdate master
  fi

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/openrti
    cd "$CBD"/build/openrti
    rm -f CMakeCache.txt
    cmake -DCMAKE_BUILD_TYPE="Release" \
          -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_OPENRTI" \
          ../../openrti 2>&1 | tee -a $LOGFILE
  fi
	
  _make openrti
fi

#######################################################
# OpenSceneGraph
#######################################################
OSG_INSTALL_DIR=openscenegraph
INSTALL_DIR_OSG=$INSTALL_DIR/$OSG_INSTALL_DIR
cd "$CBD"
mkdir -p "openscenegraph"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="OSG"' ]]; then
echo "****************************************" | tee -a $LOGFILE
echo "**************** OSG *******************" | tee -a $LOGFILE
echo "****************************************" | tee -a $LOGFILE
cd "$CBD"/openscenegraph
_gitDownload https://github.com/poweroftwo/osgearth.git
_gitUpdate $OSG_STABLE_GIT_BRANCH

if [ "$RECONFIGURE" = "y" ]; then
cd "$CBD"
mkdir -p build/openscenegraph
cd "$CBD"/build/openscenegraph
rm -f CMakeCache.txt
cmake -DCMAKE_BUILD_TYPE="Release" \
-DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_OSG" ../../openscenegraph/ 2>&1 | tee -a $LOGFILE
fi

_make openscenegraph
#FIX FOR 64 BIT COMPILATION
if [ -d "$INSTALL_DIR_OSG/lib64" ]; then
if [ -L "$INSTALL_DIR_OSG/lib" ]; then
echo "link already done"
else
ln -s "$INSTALL_DIR_OSG/lib64" "$INSTALL_DIR_OSG/lib"
fi
fi
fi

#######################################################
# SIMGEAR
#######################################################
SIMGEAR_INSTALL_DIR=simgear
INSTALL_DIR_SIMGEAR=$INSTALL_DIR/$SIMGEAR_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="SIMGEAR"' ]]; then
  echo "****************************************" | tee -a $LOGFILE
  echo "**************** SIMGEAR ***************" | tee -a $LOGFILE
  echo "****************************************" | tee -a $LOGFILE

  mkdir -p "simgear"
  cd "$CBD"/simgear
  _gitDownload git://gitorious.org/fg/simgear-osgearth.git simgear
  _gitUpdate $FGVERSION
	
  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/simgear
    cd "$CBD"/build/simgear
    rm -f CMakeCache.txt
    cmake -DCMAKE_BUILD_TYPE="Release" \
          -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_SIMGEAR" \
          -DCMAKE_PREFIX_PATH="$INSTALL_DIR_OSG;$INSTALL_DIR_OPENRTI" \
	  $SG_CMAKEARGS \
	  -DENABLE_CURL=1 \
          ../../simgear 2>&1 | tee -a $LOGFILE
  fi
	
  _make simgear
fi

#######################################################
# FGFS
#######################################################
FGFS_INSTALL_DIR=flightgear
INSTALL_DIR_FGFS=$INSTALL_DIR/$FGFS_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGFS"' || "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="DATA"' ]]; then
  echo "****************************************" | tee -a $LOGFILE
  echo "************** FLIGHTGEAR **************" | tee -a $LOGFILE
  echo "****************************************" | tee -a $LOGFILE

  mkdir -p "flightgear"
  cd "$CBD"/flightgear

  if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGFS"' ]]; then
    _gitDownload git://gitorious.org/fg/flightgear-osgearth.git flightgear
    _gitUpdate $FGVERSION

    if [ "$RECONFIGURE" = "y" ]; then
      cd "$CBD"
      mkdir -p build/flightgear
      cd "$CBD"/build/flightgear
      rm -f CMakeCache.txt
      cmake -DCMAKE_BUILD_TYPE="Release" \
            -DENABLE_FLITE=ON \
            -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_FGFS" \
            -DCMAKE_PREFIX_PATH="$INSTALL_DIR_SIMGEAR;$INSTALL_DIR_OSG;$INSTALL_DIR_OPENRTI;$INSTALL_DIR_PLIB" \
            $FG_CMAKEARGS \
            ../../flightgear 2>&1 | tee -a $LOGFILE
    fi

    _make flightgear
  fi

  mkdir -p $INSTALL_DIR_FGFS/fgdata
  cd $INSTALL_DIR_FGFS/fgdata

  if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="DATA"' ]]; then
    echo "****************************************" | tee -a $LOGFILE
    echo "**************** DATA ******************" | tee -a $LOGFILE
    echo "****************************************" | tee -a $LOGFILE

    _gitDownload git://gitorious.org/fg/fgdata-osgearth.git fgdata
    _gitUpdate $FGVERSION
  fi
  cd "$CBD"

  SCRIPT=run_fgfs.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin" >> $SCRIPT
  echo "export LD_LIBRARY_PATH=../../$SIMGEAR_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$OPENRTI_INSTALL_DIR/lib:../../$PLIB_INSTALL_DIR/lib" >> $SCRIPT
  echo "./fgfs --fg-root=\$PWD/../fgdata/ \$@" >> $SCRIPT
  chmod 755 $SCRIPT

  SCRIPT=run_fgfs_debug.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin" >> $SCRIPT
  echo "export LD_LIBRARY_PATH=../../$SIMGEAR_INSTALL_DIR/lib:../../$OSG_INSTALL_DIR/lib:../../$OPENRTI_INSTALL_DIR/lib:../../$PLIB_INSTALL_DIR/lib" >> $SCRIPT
  echo "gdb  --directory="\$P1"/fgfs/source/src/ --args fgfs --fg-root=\$PWD/../fgdata/ \$@" >> $SCRIPT
  chmod 755 $SCRIPT

  SCRIPT=run_fgcom.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR/$FGFS_INSTALL_DIR/bin" >> $SCRIPT
  echo "./fgcom \$@" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# FGRUN
#######################################################
FGRUN_INSTALL_DIR=fgrun
INSTALL_DIR_FGRUN=$INSTALL_DIR/$FGRUN_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGRUN"' ]]; then
  echo "****************************************" | tee -a $LOGFILE
  echo "**************** FGRUN *****************" | tee -a $LOGFILE
  echo "****************************************" | tee -a $LOGFILE

  mkdir -p "fgrun"
  cd "$CBD"/fgrun
  _gitDownload git://gitorious.org/fg/fgrun-osgearth.git fgrun
  _gitUpdate $FGVERSION

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/fgrun
    cd "$CBD"/build/fgrun
    rm -f CMakeCache.txt
    cmake -DCMAKE_BUILD_TYPE="Release" \
          -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_FGRUN" \
          -DCMAKE_PREFIX_PATH="$INSTALL_DIR_SIMGEAR" \
          ../../fgrun/ 2>&1 | tee -a $LOGFILE
  fi
	
  _make fgrun

  cd "$CBD"

  SCRIPT=run_fgrun.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR/$FGRUN_INSTALL_DIR/bin" >> $SCRIPT
  echo "export LD_LIBRARY_PATH=$INSTALL_DIR_SIMGEAR/lib" >> $SCRIPT
  echo "./fgrun --fg-exe=\$PWD/../../$FGFS_INSTALL_DIR/bin/fgfs --fg-root=\$PWD/../../$FGFS_INSTALL_DIR/fgdata   \$@" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# FGO!
#######################################################
FGO_INSTALL_DIR=fgo
INSTALL_DIR_FGO=$INSTALL_DIR/$FGO_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGO"' ]]; then
  echo "****************************************" | tee -a $LOGFILE
  echo "***************** FGO ******************" | tee -a $LOGFILE
  echo "****************************************" | tee -a $LOGFILE

  if [ "$DOWNLOAD" = "y" ]; then
    rm -rf fgo*.tar.gz
    wget https://sites.google.com/site/erobosprojects/flightgear/add-ons/fgo/download/fgo-1.5.5.tar.gz -O fgo.tar.gz
    cd install
    tar -zxvf ../fgo.tar.gz
    cd ..
  fi

  cd "$CBD"

  SCRIPT=run_fgo.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR" >> $SCRIPT
  echo "p=\$(pwd)" >> $SCRIPT
  echo "cd $FGO_INSTALL_DIR" >> $SCRIPT
  echo "python fgo" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# FGx
#######################################################
FGX_INSTALL_DIR=fgx
INSTALL_DIR_FGX=$INSTALL_DIR/$FGX_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="FGX"' ]]; then
  echo "****************************************" | tee -a $LOGFILE
  echo "***************** FGX ******************" | tee -a $LOGFILE
  echo "****************************************" | tee -a $LOGFILE

  mkdir -p "fgx"
  cd "$CBD"/fgx
  _gitDownload https://github.com/fgx/fgx.git
  _gitUpdate master

  cd "$CBD"/fgx/src/
  #Patch in order to pre-setting paths
  cd resources/default/
  cp x_default.ini x_default.ini.orig
  cat x_default.ini | sed s/\\/usr\\/bin\\/fgfs/INSTALL_DIR_FGXMY_SLASH_HERE..MY_SLASH_HEREfgfsMY_SLASH_HEREbinMY_SLASH_HEREfgfs/g > tmp1
  cat tmp1 | sed s/\\/usr\\/share\\/flightgear/INSTALL_DIR_FGXMY_SLASH_HERE..MY_SLASH_HEREfgfsMY_SLASH_HEREfgdata/g > tmp2
  cat tmp2 | sed s/\\/usr\\/bin\\/terrasync/INSTALL_DIR_FGXMY_SLASH_HERE..MY_SLASH_HEREfgfsMY_SLASH_HEREbinMY_SLASH_HEREterrasync/g > tmp3
  cat tmp3 | sed s/\\/usr\\/bin\\/fgcom/INSTALL_DIR_FGXMY_SLASH_HERE..MY_SLASH_HEREfgcomMY_SLASH_HEREbinMY_SLASH_HEREfgcom/g > tmp4
  cat tmp4 | sed s/\\/usr\\/bin\\/js_demo/INSTALL_DIR_FGXMY_SLASH_HERE..MY_SLASH_HEREfgfsMY_SLASH_HEREbinMY_SLASH_HEREjs_demo/g > tmp5
  INSTALL_DIR_FGX_NO_SLASHS=$(echo "$INSTALL_DIR_FGX" | sed -e 's/\//MY_SLASH_HERE/g')
  cat tmp5 | sed s/INSTALL_DIR_FGX/"$INSTALL_DIR_FGX_NO_SLASHS"/g > tmp
  cat tmp | sed s/MY_SLASH_HERE/\\//g > x_default.ini
  rm tmp*

  cd ..
  if [ "$RECONFIGURE" = "y" ]; then
    mkdir -p $INSTALL_DIR_FGX
    cd $INSTALL_DIR_FGX
    qmake ../../fgx/src
  fi

  if [ "$COMPILE" = "y" ]; then
    cd $INSTALL_DIR_FGX
    echo "MAKE AND INSTALL FGX" >> $LOGFILE
    echo "make $JOPTION $OOPTION " >> $LOGFILE
    make $JOPTION $OOPTION | tee -a $LOGFILE
    cd ..
  fi

  cd "$CBD"

  SCRIPT=run_fgx.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $ " >> $SCRIPT
  echo "p=\$(pwd)" >> $SCRIPT
  echo "cd $FGX_INSTALL_DIR" >> $SCRIPT
  echo "./fgx" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# ATC-PIE
#######################################################
ATCPIE_INSTALL_DIR=atc-pie
INSTALL_DIR_ATCPIE=$INSTALL_DIR/$ATCPIE_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="ATCPIE"' ]]; then
  echo "****************************************" | tee -a $LOGFILE
  echo "**************** ATCPIE ***************" | tee -a $LOGFILE
  echo "****************************************" | tee -a $LOGFILE

  mkdir -p "$INSTALL_DIR_ATCPIE"
  cd $INSTALL_DIR_ATCPIE
  _gitDownload git://git.code.sf.net/p/atc-pie/code
  _gitUpdate master

  cd "$CBD"

  SCRIPT=run_atcpie.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd $SUB_INSTALL_DIR/$ATCPIE_INSTALL_DIR" >> $SCRIPT
  echo "./ATC-pie.py \$@" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# OPENRADAR
#######################################################
OR_INSTALL_DIR=openradar
INSTALL_DIR_OR=$INSTALL_DIR/$OR_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="OPENRADAR"' ]]; then
  echo "****************************************" | tee -a $LOGFILE
  echo "************** OPENRADAR ***************" | tee -a $LOGFILE
  echo "****************************************" | tee -a $LOGFILE

  if [ "$DOWNLOAD" = "y" ]; then
    wget http://wagnerw.de/OpenRadar.zip -O OpenRadar.zip
    cd install
    unzip -o ../OpenRadar.zip
    cd ..
  fi

  SCRIPT=run_openradar.sh
  echo "#!/bin/sh" > $SCRIPT
  echo "cd \$(dirname \$0)" >> $SCRIPT
  echo "cd install/OpenRadar" >> $SCRIPT
  echo "java -jar OpenRadar.jar" >> $SCRIPT
  chmod 755 $SCRIPT
fi

#######################################################
# TERRAGEAR
#######################################################

TG_INSTALL_DIR=terragear
INSTALL_DIR_TG=$INSTALL_DIR/$TG_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="TERRAGEAR"' ]]; then
  echo "****************************************" | tee -a $LOGFILE
  echo "*************** TERRAGEAR **************" | tee -a $LOGFILE
  echo "****************************************" | tee -a $LOGFILE

  mkdir -p "terragear"
  cd "$CBD"/terragear
  _gitDownload git://git.code.sf.net/p/flightgear/terragear
  _gitUpdate scenery/ws2.0

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/terragear
    cd "$CBD"/build/terragear
    rm -f CMakeCache.txt
    cmake -DCMAKE_BUILD_TYPE="Debug" \
          -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR_TG" \
          -DCMAKE_PREFIX_PATH="$INSTALL_DIR_SIMGEAR;$INSTALL_DIR_CGAL" \
          ../../terragear/ 2>&1 | tee -a $LOGFILE
  fi

  _make terragear

  cd "$CBD"
  echo "#!/bin/sh" > run_tg-construct.sh
  echo "cd $(dirname $0)" >> run_tg-construct.sh
  echo "cd install/terragear/bin" >> run_tg-construct.sh
  echo "export LD_LIBRARY_PATH=$INSTALL_DIR_SIMGEAR/lib" >> run_tg-construct.sh
  echo "./tg-construct \$@" >> run_tg-construct.sh

  echo "#!/bin/sh" > run_ogr-decode.sh
  echo "cd $(dirname $0)" >> run_ogr-decode.sh
  echo "cd install/terragear/bin" >> run_ogr-decode.sh
  echo "export LD_LIBRARY_PATH=$INSTALL_DIR_SIMGEAR/lib" >> run_ogr-decode.sh
  echo "./ogr-decode \$@" >> run_ogr-decode.sh

  echo "#!/bin/sh" > run_genapts850.sh
  echo "cd $(dirname $0)" >> run_genapts850.sh
  echo "cd install/terragear/bin" >> run_genapts850.sh
  echo "export LD_LIBRARY_PATH=$INSTALL_DIR_SIMGEAR/lib" >> run_genapts850.sh
  echo "./genapts850 \$@" >> run_genapts850.sh
fi
_logSep

#######################################################
# TERRAGEAR GUI
#######################################################

TGGUI_INSTALL_DIR=terrageargui
INSTALL_DIR_TGGUI=$INSTALL_DIR/$TGGUI_INSTALL_DIR
cd "$CBD"
if [[ "$(declare -p WHATTOBUILD)" =~ '['([0-9]+)']="TERRAGEARGUI"' ]]; then
  echo "****************************************" | tee -a $LOGFILE
  echo "************* TERRAGEAR GUI ************" | tee -a $LOGFILE
  echo "****************************************" | tee -a $LOGFILE

  mkdir -p "terrageargui"
  cd "$CBD"/terrageargui
  _gitDownload git://git.code.sf.net/p/flightgear/fgscenery/terrageargui
  _gitUpdate master
	

  if [ "$RECONFIGURE" = "y" ]; then
    cd "$CBD"
    mkdir -p build/terrageargui
    cd "$CBD"/build/terrageargui
    rm -f ../../terrageargui/CMakeCache.txt
    cmake -DCMAKE_BUILD_TYPE="Release" \
          -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR_TGGUI" \
          ../../terrageargui 2>&1 | tee -a $LOGFILE
  fi

  _make terrageargui

  cd "$CBD"
  # Fill TerraGear Root field
  if [ ! -f ~/.config/TerraGear/TerraGearGUI.conf ]; then
    echo "Fill TerraGear Root field" >> $LOGFILE
    echo "[paths]" > TerraGearGUI.conf
    echo "terragear=$INSTALL_DIR_TG/bin" >> TerraGearGUI.conf
    mkdir -p ~/.config/TerraGear
    mv TerraGearGUI.conf ~/.config/TerraGear
  fi

  echo "Create run_terrageargui.sh" >> $LOGFILE
  echo "#!/bin/sh" > run_terrageargui.sh
  echo "cd \$(dirname \$0)" >> run_terrageargui.sh
  echo "cd install/terrageargui/bin" >> run_terrageargui.sh
  echo "export LD_LIBRARY_PATH=$INSTALL_DIR_SIMGEAR/lib" >> run_terrageargui.sh
  echo "./TerraGUI \$@" >> run_terrageargui.sh
fi

echo ""
echo "download_and_compile.sh has finished to work"

cd "$CBD"

