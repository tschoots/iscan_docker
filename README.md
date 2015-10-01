# iscan_docker

iscan_docker is a script capable of scanning the images on a machine that can perform docker commands.

in order to function it needs scan.cli.sh
before you start using the script change the _ISCAN_CLIENT parameter on line 25 should be changed to the directory of your iscan.

# dendencies
Run this script in a shell that is capable of running the "docker images" command.

# how to start 
the following command will scan all the docker images where you perform this command
./iscan_docker.sh -h "BlackDuck hub server host" -p 443 -s https -u "username" -w "password"

This command will scan all the versions of the image with name "image name" if the image is
on the machine
./iscan_docker.sh -h "BlackDuck hub servr host" -p 443 -s https -u "username" -w "password" -i "image name"
