#!/bin/bash
PORT=8080
PORT=${PORT:-8787}
USER=$(whoami)
PASSWORD=${PASSWORD:-notsafe}
TMPDIR=${TMPDIR:-tmp}
CONTAINER="$RIVER_HOME/.river/images/singularities/images/rstudio-4.4.2.sif"

# Set-up temporary paths
RSTUDIO_TMP="${TMPDIR}/$(echo -n $CONDA_PREFIX | md5sum | awk '{print $1}')"
mkdir -p $RSTUDIO_TMP/{run,var-lib-rstudio-server,local-share-rstudio}

R_BIN=$CONDA_PREFIX/bin/R
PY_BIN=$CONDA_PREFIX/bin/python

if [ ! -f $CONTAINER ]; then
	singularity pull $CONTAINER docker://docker.io/rocker/rstudio-4.4.2
fi

if [ -z "$CONDA_PREFIX" ]; then
  echo "Activate a conda env or specify \$CONDA_PREFIX"
  exit 1
fi

echo "Starting rstudio service on port $PORT ..."
singularity run \
	--bind $RSTUDIO_TMP/run:/run \
	--bind $RSTUDIO_TMP/var-lib-rstudio-server:/var/lib/rstudio-server \
	--bind /sys/fs/cgroup/:/sys/fs/cgroup/:ro \
	--bind database.conf:/etc/rstudio/database.conf \
	--bind rsession.conf:/etc/rstudio/rsession.conf \
	--bind $RSTUDIO_TMP/local-share-rstudio:/home/rstudio/.local/share/rstudio \
	--bind $HOME/.config/rstudio:/home/rstudio/.config/rstudio \
	--env RSTUDIO_WHICH_R=$R_BIN \
	--env RETICULATE_PYTHON=$PY_BIN \
	$CONTAINER \
	rserver \
		--www-address=127.0.0.1 \
		--www-port=$PORT \
		--rsession-which-r=$RSTUDIO_WHICH_R \
		--rsession-ld-library-path=$CONDA_PREFIX/lib \
		--auth-none=1 \
		--server-user $USER	
