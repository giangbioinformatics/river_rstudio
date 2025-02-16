#!/bin/bash
while IFS== read key value; do
    printf -v "$key" "$value"
done < <(jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' config.json)

PORT=$(python3 -c "import socket; s=socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()")
echo $PORT > $RIVER_HOME/.river/jobs/$uuid_job_id/job.port
echo $(hostname) > $RIVER_HOME/.river/jobs/$uuid_job_id/job.host
echo "$uuid_job_id/" > $RIVER_HOME/.river/jobs/$uuid_job_id/job.proxy_location

USER=$(whoami)
TMPDIR=${TMPDIR:-tmp}
CONTAINER="$RIVER_HOME/.river/images/singularities/images/rstudio-4.4.2.sif"

# Set-up temporary paths
RSTUDIO_TMP="${TMPDIR}/$(echo -n $CONDA_PREFIX | md5sum | awk '{print $1}')"
mkdir -p $RSTUDIO_TMP/{run,var-lib-rstudio-server,local-share-rstudio}

R_BIN=$CONDA_PREFIX/bin/R
PY_BIN=$CONDA_PREFIX/bin/python

if [ ! -f $CONTAINER ]; then
	singularity pull $CONTAINER docker://docker.io/rocker/rstudio:4.4.2
fi

if [ -z "$CONDA_PREFIX" ]; then
  echo "Activate a conda env or specify \$CONDA_PREFIX"
  exit 1
fi

echo "Starting rstudio service on port $PORT ..."
# prepare database and session
rstudio_home=$RIVER_HOME/.river/packages/rstudio 
rstudio_config=$rstudio_home/config
mkdir -p $rstudio_config

session=$rstudio_home/rsession.conf
db=$rstudio_home/database.conf

if [ ! -f $session ]; then
    cp ./analysis/river/rsession.conf $session
fi

if [ ! -f $db ]; then
    cp ./analysis/river/database.conf $db
fi

script -q -c "singularity run \
	--bind $RSTUDIO_TMP/run:/run \
	--bind $RSTUDIO_TMP/var-lib-rstudio-server:/var/lib/rstudio-server \
	--bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \
	--bind $db:/etc/rstudio/database.conf \
	--bind $session:/etc/rstudio/rsession.conf \
	--bind $RSTUDIO_TMP/local-share-rstudio:/home/rstudio/.local/share/rstudio \
	--bind $rstudio_config:/home/rstudio/.config/rstudio \
	--env RSTUDIO_WHICH_R=$R_BIN \
	--env RETICULATE_PYTHON=$PY_BIN \
	$CONTAINER \
	rserver \
		--www-address=0.0.0.0 \
		--www-port=$PORT \
		--rsession-which-r=$R_BIN \
		--rsession-ld-library-path=$CONDA_PREFIX/lib \
        --auth-none=1 \
        --server-user $USER" /dev/null
