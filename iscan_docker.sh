#!/bin/bash

_ISCAN_CLIENT="/Users/tschoots/tmp/scanner/scan.cli-2.2.1.1/bin/scan.cli.sh"
_HOSTNAME=$(hostname)

usage() {
  cat <<EEOPTS
    $(basename $0) -h <hub_hostname> -p <port> -s <scheme [http/https]> -u <username> -p <password> -i <image:tag>
    Note all parameters are mandatory, except for the -i parameter which gives the opertunity to scan one image!
EEOPTS
    exit 1
}


################### MAIN #######################

#check if server is in the output of version then docker is working properly
version=$(docker version | grep Server)
if [ "$version" != "Server:" ]; then
   exit
fi

#check input parameters
while getopts ":h:p:s:u:p:" opt; do
   case $opt in
      h)
       host=$OPTARGA
       ;;
      p)
       port=$OPTARG
       ;;
      s)
       scheme=$OPTARG
       ;;
      u)
       username=$OPTARG
       ;;
      p)
       password=$OPTARG
       ;;
      \?)
       usage
       ;;
   esac
done

mkdir tmp
cd tmp
# get all the images sorted on size so the smallest will go first to avoid long waiting time in case of wrong parameters.
declare -a images=($(docker images | grep -v "REPOSITORY\|<none>" | sort -k 5 -r | awk '{print $1":"$2}'))
for img in "${images[@]}"
do
  docker save -o dump.tar $img
  tar -xvf dump.tar
  rm -rf dump.tar
  find . -name "*.tar" -exec tar -xvf {} \;
  find . -name "*.tar" -exec rm -rf {} \;
  result=$($_ISCAN_CLIENT $@ .)
  echo $img
done

cmd="$_ISCAN_CLIENT --dryRunReadFile prr  $@"
$cmd 
