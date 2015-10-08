#!/bin/bash


##########################################################################
#
#  Author : Ton Schoots
#  version: 0.2
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
#
#  Status: 8 - 10 - 2015
#      The script is now able to interactively give password
##########################################################################

_ISCAN_CLIENT="/Users/tschoots/tmp/scanner/scan.cli-2.2.1.1/bin/scan.cli.sh"
_HOSTNAME=$(hostname)

usage() {
  cat <<EEOPTS
    $(basename $0) -h <hub_hostname> -p <port> -s <scheme [http/https]> -u <username> [-w <password>] [-i <image>]
    Note all parameters are mandatory, except for the -i parameter which gives the opertunity to scan one image!
    and the -w parameter if ommited it will ask for a password interactively
EEOPTS
    exit 1
}


################### MAIN #######################

#check if server is in the output of version then docker is working properly
version=$(docker version | grep Server)
if [ "$version" != "Server:" ]; then
   echo "ERROR : Shell is not in docker context!"
   echo "use the command : eval \"\$(docker-machine env <machine name>)\" , to put it in a context"
   exit
fi

if [ "$#" -ne "8" ] && [ "$#" -ne "12" ] && [ "$#" -ne "10" ] ; then
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

# check if all mandatory fields are there
if [ -z "${host}" ]; then
  echo "ERROR : mandatory field host switch -h missing."
  exit
elif [ -z "${port}" ]; then
  echo "ERROR : mandatory field port switch -p missing."
  exit
elif [ -z "${scheme}" ]; then
  echo "ERROR : mandatory field scheme switch -s missing, options : http/https."
  exit
elif [ -z "${username}" ]; then
  echo "ERROR : mandatory field username swithc -u missing."
  exit
else
  echo "mandatory input parameters checked."
fi


declare -a images=($(docker images $image | grep -v "REPOSITORY\|<none>" | sort -k 5 -r | awk '{print $1":"$2}'))
if [ "${#images[@]}" -eq "0" ];then 
   echo "no images found"
   exit
fi
for img in "${images[@]}"
do
  image_name=$(echo $img | sed 's/:.*$//')
  tag=$(echo $img | sed 's/^.*://')
  project=$(echo "{$(hostname)}$image_name")
  echo "image : $image_name"
  echo "tag : $tag"
  echo "project : $project"
  tmp_dir=$(echo $img | sed 's/:/_/g' | sed 's/\///g')
  echo "creating directory : $tmp_dir"
  mkdir -p tmp/$tmp_dir
  cd tmp/$tmp_dir
  docker save -o dump.tar $img
  tar -xf dump.tar
  rm -rf dump.tar
  find . -name "*.tar" -exec tar -xf {} \;
  find . -name "*.tar" -exec rm -rf {} \;
  if [ -z "${password}" ];then
    cmd="$_ISCAN_CLIENT --host $host --port $port --scheme $scheme --project $project --release $tag --username $username   -v ."
  else
    cmd="$_ISCAN_CLIENT --host $host --port $port --scheme $scheme --project $project --release $tag --username $username --password $password  -v ."
  fi
  echo $cmd
  $cmd
  cd ../..
  chmod -R 777 tmp
  rm -rf tmp
done

