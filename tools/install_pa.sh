#!/bin/sh

TOOLDIR=$HOME/apps/earth_demo/tools

mylog() {
  case $1 in
    'info')
	echo "INFO: $2"
	;;
    'warn')
	echo "WARNING: $2"
	;;
    'error')
	echo "ERROR: $2"
	;;
    *)
	echo "$1: $2"
	;;
  esac
}

mydie() {
  case $1 in
    'no_trig')
	mylog error "No EARTH_V2_TRIGRAMME tag defined on this instance"
	exit 1
	;;
    'no_depot')
	mylog error "No EARTH_V2_DEPLOY_DEPOT tag defined on this instance"
	exit 2
	;;
    'unknown_provider')
	mylog error "Unknown provider defined in EARTH_V2_DEPLOY_DEPOT"
	exit 3
	;;
    'depot_not_found')
	mylog error "Depot defined in EARTH_V2_DEPLOY_DEPOT not found"
	exit 4
	;;
    'free')
	mylog error "$2"
	exit 254
	;;
    *)
	mylog error "Undefined"
	exit 255
	;;
  esac
}


deploy_pkgs_git() {
  DEPOT=$(eval echo $EARTH_V2_DEPLOY_DEPOT | cut -d'=' -f2)

  cd $HOME/apps

  # weak : should improve to handle multiple '/'
  PRJ=$(echo $DEPOT | cut -d'/' -f 2 | cut -d'.' -f 1)
  PRJ=$(echo $DEPOT | awk -F '/' '{print $NF;}' | cut -d'.' -f 1)

  if [ -d $PRJ ]; then
    mylog info "project '$PRJ' already cloned, pulling diffs"
    cd $PRJ
    #GIT_TRACE=1 GIT_SSH="$TOOLDIR/ssh" git pull
    GIT_SSH="$TOOLDIR/ssh" git pull
  else
    mylog info "cloning new project '$PRJ'"
    git clone $DEPOT
  fi

  INSTTIER=$(echo $EARTH_V2_TIER | tr '[:upper:]' '[:lower:]')

  case $INSTTIER in
    'www')
	mylog error "feature not implemented"
	exit 254
	;;
    *)
	mylog error "Undefined"
	exit 255
	;;
  esac
  exit
}


deploy_pkgs_local() {
  DEPOT=$(eval echo $EARTH_V2_DEPLOY_DEPOT | cut -d'=' -f2)
  [ ! -d $DEPOT ] && mydie depot_not_found

  for p in $DEPOT/${EARTH_V2_TRIGRAMME}_*; do
    mylog info "processing package '$p'"
    CURDIR=$(pwd)
    TMPDIR=$(mktemp -d) 
    cd $TMPDIR

    # plug in existing procedure
    sudo mkdir -p /applis/$PDIR
    sudo useradd -m -d /applis/$PDIR/$PUSER $PUSER
    unzip $p
    # no time, quick & dirty hack
    unzip PAAAAEAN_00.00.11.zip > /dev/null
    sudo cp -a TARAPA_00.00.10/NOSUB/TT /applis/$PDIR/apache
    #sudo cp -a TAREXP_00.00.10/NOSUB/TT /applis/$PDIR/
    cd TAREXP_00.00.10/NOSUB/TT && find . -depth | sudo cpio -pdm /applis/$PDIR/ 
    cd ../../../
    sudo cp -a TARPHP_00.00.11/NOSUB/TT /applis/$PDIR/php
    sudo chown -Rh ${PUSER}:${PUSER} /applis/$PDIR
    cd $CURDIR
    rm -rf $TMPDIR
  done
}


deploy_pkgs() {
  # checking mandatory parameters
  [ "x$EARTH_V2_DEPLOY_DEPOT" == "x" ] && mydie no_depot

  echo $EARTH_V2_DEPLOY_DEPOT | grep : > /dev/null
  [ $? != 0 ] && mydie free "Unknown depot format"

  TRI=$(echo $EARTH_V2_TRIGRAMME | tr '[:upper:]' '[:lower:]')
  PDIR=${TRI}d
  PUSER=${TRI}dadm

  PKGPROVIDER=$(echo $EARTH_V2_DEPLOY_DEPOT | cut -d'=' -f1 | tr '[:upper:]' '[:lower:]')
  DEPOT=$(eval echo $EARTH_V2_DEPLOY_DEPOT | cut -d'=' -f2)
  case $PKGPROVIDER in
    'git')
        mylog info "processing '$PKGPROVIDER'"
	deploy_pkgs_git
	;;
    'local')
        mylog info "processing '$PKGPROVIDER'"
	deploy_pkgs_local
	;;
    *)
	mydie unknow_provider
	;;
  esac
  
}


check_tags() {
  # checking mandatory parameters
  [ "x$EARTH_V2_TRIGRAMME" == "x" ] && mydie no_trig
  [ "x$EARTH_V2_DEPLOY_DEPOT" == "x" ] && mydie no_depot
}



### 
# Main logic
###

# Fetching tags from cloud controller
. $TOOLDIR/get_tags.sh

if [ "x$EARTH_V2_AUTO_DEPLOY" != "x" ]; then
  mylog info "Auto-deploy enabled, analyzing..."
  check_tags
  deploy_pkgs
  mylog info "Auto-deploy ... JOB'S DONE !"
else
  mylog info "nothing to do"
fi

