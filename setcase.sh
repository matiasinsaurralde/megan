#!/bin/sh
echo "Setting MGNHOME to $PWD"
export MGNHOME=$PWD

export MGNSRC=$MGNHOME/src
export MGNLIB=$MGNHOME/lib
export MGNEXE=$MGNHOME/bin
export MGNRUN=$MGNHOME/work
export MGNINP=$MGNHOME/Input
export MGNOUT=$MGNHOME/Output
export MGNINT=$MGNHOME/Output/INT
export MGNLOG=$MGNHOME/work/logdir

echo "Creating missing directories"

mkdir -p $MGNINP/MAP
mkdir -p $MGNINP/MGNMET
mkdir -p $MGNINP/PAR

mkdir -p $MGNINT
mkdir -p $MGNLOG