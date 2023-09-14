# MyUtil
1- After change requires to build
    docker build -t my_docker_project .
2- Run
    docker run my_docker_project

3- Debug go inside image:
    docker run -it my_docker_project /bin/bash

4- run the docker container with a volume to access directory:
    docker run -it -v D:\projects\myUtil\tmp:/app/tmp my_docker_project
