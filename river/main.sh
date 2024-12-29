# pull singularity if it does not exist
if [ ! -f ~/.river/images/singularities/images/all-spark-notebook_latest.sif ]; then
    singularity pull --dir <<river_home>>/.river/images/singularities/images docker://docker.io/rocker/rstudio:latest 
fi

# overwrite config
echo "www-port=$PORT" >> ./analysis/river/rserver.conf

# run jupyter lab
singularity run --writable --cleanenv --env DISABLE_AUTH=true ./analysis/river/rserver.conf:/etc/rstudio/disable_auth_rserver.conf  <<river_home>>/.river/images/singularities/images/rstudio_latest.sif