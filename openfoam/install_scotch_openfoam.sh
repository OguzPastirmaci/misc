#!/bin/sh

SCOTCH_VERSION=scotch_6.0.9

wget https://gforge.inria.fr/frs/download.php/file/38187/scotch_6.0.9.tar.gz

tar xf scotch_6.0.9.tar.gz

cd $SCOTCH_VERSION

build_dir=/nfs/scratch/OpenFOAM/ThirdParty-2.2.2/$SCOTCH_VERSION

export SCOTCH_VERSION=scotch_6.0.9
install_dir=$WM_THIRD_PARTY_DIR/platforms/$WM_ARCH$WM_COMPILER/$SCOTCH_VERSION
mkdir -p $install_dir

cd src/
cp Make.inc/Makefile.inc.x86-64_pc_linux2 Makefile.inc
sed -i "s/gcc/mpicc/g" Makefile.inc
prefix=$build_dir make scotch ptscotch

prefix=$install_dir make install

export SCOTCH_VERSION=scotch_6.0.9
export SCOTCH_ARCH_PATH=$WM_THIRD_PARTY_DIR/platforms/$WM_ARCH$WM_COMPILER/$SCOTCH_VERSION

cd $WM_THIRD_PARTY_DIR
./Allwmake

cd $FOAM_SRC/parallel/decompose
./Allwmake
