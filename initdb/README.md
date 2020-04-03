# Dump DB to Docker

Running the `build.sh` command will create a docker image, `pecan/db`, which contains
a full dump of the database in a compressed format. Running this docker container will
restore the database.

The goal of this image is to have a quick way to setup a new machine using a relativly
new dump of the database. The user will only need to dowload a small image with the
full database dump.

## Backup Database

Run `./build.sh`, this will create a new image `pecan/db:latest`. This will create
a docker image with the code to restore the database as well as a full dump of the 
database.

## Restore Database

With the database running (assuming it is running in bety_bety network) you can
restore the database using `docker run --network bety_bety -ti --rm pecan/db`.

## Save/Restore Image

You can save the docker image as a tar file using `docker save -o db.img.tar pecan/db:latest`.
To load the docker image from the tar file use `docker load -i db.img.tar`. 

This will allow you to save the image to a more permanent place.
