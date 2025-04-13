#!/bin/sh

PE_IMAGE=${PE_IMAGE-platform-engineering}
PE_VERSION=${PE_VERSION-latest}
PE_DEBUG=${PE_DEBUG-0}

image_name="${PE_IMAGE}:${PE_VERSION}"

# check if docker command exists
if ! command -v docker >/dev/null 
then
    echo "docker could not be found, please install docker in order to use platform-engineering image wrapper" >&2
    exit 1
fi

# check if PE_IMAGE is available
if ! docker image inspect ${image_name} >/dev/null 2>/dev/null
then
    echo "platform-engineering docker image ${image_name} not found, please build the image first" >&2
    exit 1
fi

args="--rm -ti -v .:/src -h ${PE_IMAGE}"

if test -z "${SSH_AUTH_SOCK}"
then
    # ssh agent is not running, check if there are any ssh agent sockets in /tmp/ssh-*/agent.*:
    # if there are, set SSH_AUTH_SOCK to the first one found:
    for i in $(ls -1 /tmp/ssh-*/agent.* 2>/dev/null)
    do
        if test -O $i
        then
            # found a socket owned by the current user, set SSH_AUTH_SOCK to it:
            export SSH_AUTH_SOCK=$i
            break
        fi
    done
fi

if ! test -z "${SSH_AUTH_SOCK}" && test -O ${SSH_AUTH_SOCK}
then
    # ssh agent is running, detected via SSH_AUTH_SOCK environment variable:
    # add volume mount for the socket and set the environment variable, so that
    # the container can use the ssh agent
    if test ${PE_DEBUG} -eq 1
    then
        echo "ssh agent socket found: ${SSH_AUTH_SOCK}" >&2
    fi
    args="${args} -v ${SSH_AUTH_SOCK}:${SSH_AUTH_SOCK} -e SSH_AUTH_SOCK=${SSH_AUTH_SOCK}"
fi
awsdir=$(echo ~/.aws)
if test -f "${awsdir}/credentials"
then
    # aws credentials file exists, add volume mount for the directory
    if test ${PE_DEBUG} -eq 1
    then
        echo "using aws credentials directory: $awsdir" >&2
    fi
    args="${args} -v ${awsdir}:/root/.aws:ro"
fi
if ! test -z "${AWS_ACCESS_KEY_ID}"
then
    if test ${PE_DEBUG} -eq 1
    then
        echo "using AWS_ACCESS_KEY_ID envvar"
    fi
    args="${args} -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
fi
if ! test -z "${AWS_SECRET_ACCESS_KEY}"
then
    if test ${PE_DEBUG} -eq 1
    then
        echo "using AWS_SECRET_ACCESS_KEY envvar"
    fi
    args="${args} -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
fi
if ! test -z "${AWS_DEFAULT_REGION}"
then
    if test ${PE_DEBUG} -eq 1
    then
        echo "using AWS_DEFAULT_REGION envvar"
    fi
    args="${args} -e AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
fi

docker run ${args} ${image_name} $@
