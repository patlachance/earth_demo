#!/bin/sh

TOOLDIR=$HOME/apps/earth_demo/tools

. $TOOLDIR/get_tags.sh

env | grep EARTH_V2 | sort | while read var; do
  echo $var
done
