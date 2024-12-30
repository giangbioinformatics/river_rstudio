# pull singularity if it does not exist
if [ ! -f ~/.river/images/singularities/images/rstudio_latest.sif ]; then
    singularity pull --dir <<river_home>>/.river/images/singularities/images docker://docker.io/rocker/rstudio:latest 
fi

# overwrite config
cp ./analysis/river/rserver.conf ./rserver.conf
echo -e "\nwww-port=$PORT" >> ./rserver.conf


# run jupyter lab
singularity run --fakeroot --writable --cleanenv --env DISABLE_AUTH=true -B ./rserver.conf:/etc/rstudio/disable_auth_rserver.conf  <<river_home>>/.river/images/singularities/images/rstudio_latest.sif