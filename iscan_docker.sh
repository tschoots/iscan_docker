#!/bin/bash


##########################################################################
#
#  Author : Ton Schoots
#  version: 0.1
#
#  This script scans all the containers on a docker host
#  meaning a host able to perform docker commands.
#
#  dependencies:
#       Black Duck hub iscan
#       tar
#       grep
#       awk
#       sort
#       docker
#
#  Status: 29 - 9 - 2015
#  this script is capable to do a i scan of all the images on the machine where it's run
#  it does not however remove the BOM if an image is not there anymore.
##########################################################################

_ISCAN_CLIENT="/Users/tschoots/tmp/scanner/scan.cli-2.2.1.1/bin/scan.cli.sh"
_HOSTNAME=$(hostname)

usage() {
  cat <<EEOPTS
    $(basename $0) -h <hub_hostname> -p <port> -s <scheme [http/https]> -u <username> -w <password> -i <image:tag>
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

if [ "$#" -ne "10" ] && [ "$#" -ne "12" ]; then
   usage
fi

#check input parameters
while getopts "h:p:s:u:w:i:" opt; do
   echo $opt
   case $opt in
      h)
       host=$OPTARG
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
      w)
       password=$OPTARG
       ;;
      i)
       image=$OPTARG
       ;;
      \?)
       usage
       ;;
   esac
done

declare -a images=($(docker images $image | grep -v "REPOSITORY\|<none>" | sort -k 5 -r | awk '{print $1":"$2}'))
if [ "${#images[@]}" -eq "0" ];then 
   echo "no images found"
   exit
fi
for img in "${images[@]}"
do
  mkdir tmp
  cd tmp
  docker save -o dump.tar $img
  tar -xf dump.tar
  rm -rf dump.tar
  find . -name "*.tar" -exec tar -xf {} \;
  find . -name "*.tar" -exec rm -rf {} \;
  cmd="$_ISCAN_CLIENT --host $host --port $port --scheme $scheme --project $(hostname) --release $img --username $username --password $password  -v ."
  echo $cmd
  result=$($cmd)
  cd ..
  chmod -R 777 tmp
  rm -rf tmp
  echo $img
done

