#!/bin/sh

OpenFOAM_Version=2.2.2

cp -r /nfs/scratch/OpenFOAM/OpenFOAM-${OpenFOAM_Version}/wmake/rules/linux64Gcc47 /nfs/scratch/OpenFOAM/OpenFOAM-${OpenFOAM_Version}/wmake/rules/linux64Gcc48

module load mpi/openmpi/openmpi-4.1.0rc5 || export PATH=$PATH:/usr/mpi/gcc/openmpi-4.1.0rc5/bin 

echo "export WM_CC='gcc'" >> /nfs/scratch/OpenFOAM/OpenFOAM-${OpenFOAM_Version}/etc/bashrc
echo "export WM_CXX='g++'" >> /nfs/scratch/OpenFOAM/OpenFOAM-${OpenFOAM_Version}/etc/bashrc

export FOAM_INST_DIR=/nfs/scratch/OpenFOAM
foamDotFile=$FOAM_INST_DIR/OpenFOAM-2.2.2/etc/bashrc
[ -f $foamDotFile ] && . $foamDotFile

source $FOAM_INST_DIR/$OpenFOAM_Version/etc/bashrc WM_NCOMPPROCS=36 WM_COMPILER=Gcc48 WM_MPLIB=SYSTEMOPENMPI
