#!/bin/bash
set -euo pipefail

DOCKER_IMAGE="buildkite/agent:latest"
DOCKER_SOCKET_PATH="/var/run/docker.sock"
EXPOSE_DOCKER_SOCKET=false

# Path to where the source will be checked out for the build
readonly build_dir="${BUILDKITE_BUILD_PATH}/${BUILDKITE_AGENT_NAME}/${BUILDKITE_ORGANIZATION_SLUG}/${BUILDKITE_PIPELINE_SLUG}"

# Build an array of params to pass to docker run
args=(
  --env BUILDKITE_AGENT_ACCESS_TOKEN
  --env "BUILDKITE_BUILD_PATH=$BUILDKITE_BUILD_PATH"
  --rm
  --volume "${build_dir}:${build_dir}"
)

# On linux, we can match the userid and groupid to the container and host
if [[ ! "$OSTYPE" =~ ^(darwin|win32) ]] ; then
  args+=(
    --volume /etc/group:/etc/group:ro
    --volume /etc/passwd:/etc/passwd:ro
    --user "$( id -u "$USER" ):$( id -g "$USER" )"

    # https://www.projectatomic.io/blog/2016/03/no-new-privs-docker/
    "--security-opt=no-new-privileges"
  )
fi

# Optionally expose the docker socket for builds
if [[ "$EXPOSE_DOCKER_SOCKET" =~ ^(true|1|on)$ ]] ; then
  args+=(--volume "${DOCKER_SOCKET_PATH}:/var/run/docker.sock")
fi

# Read in the env file and convert to --env params for docker
while read -r var; do
  args+=( --env "${var%%=*}" )
done < "$BUILDKITE_ENV_FILE"

# Invoke the bootstrap in a docker container
echo "~~~ Build running in :docker: ${DOCKER_IMAGE}"
docker run "${args[@]}" "$DOCKER_IMAGE" bootstrap "$@"
