#!/bin/sh

PE_DEBUG=${PE_DEBUG-0}
LOG_P="[\033[1;32m$(hostname)-container\033[0m] "

ensure_group() {
    group_id=$1
    group_name="grp_${group_id}"

    if ! getent group "${group_id}" >/dev/null 2>&1
    then
        [ "${PE_DEBUG}" = 1 ] && echo "${LOG_P}Creating group ${group_name} with GID ${group_id}"
        groupadd -g "${group_id}" "${group_name}"
    else
        [ "${PE_DEBUG}" = 1 ] && echo "${LOG_P}Group ${group_name} already exists"
    fi
}

ensure_user() {
    user_name="$1"
    user_id="$2"
    group_ids="$3"

    if ! getent passwd "${user_id}" >/dev/null 2>&1
    then
        [ "${PE_DEBUG}" = 1 ] && echo "${LOG_P}Creating user ${user_name} with UID ${user_id} and GID(s) ${group_ids}"
        chown "${user_id}" /pe-user
        chgrp "${group_ids%%,*}" /pe-user
        chmod 700 /pe-user
        useradd -u "${user_id}" -g "${group_ids%%,*}" -G "${group_ids#*,}" -d /pe-user "${user_name}"
    else
        [ "${PE_DEBUG}" = 1 ] && echo "${LOG_P}User id ${user_id} already exists"
    fi
}


# Check if the script is running in a Docker container
if ! [ -f /.dockerenv ]; then
    echo "${LOG_P}$0 script must run inside a Docker container"
    exit 1
fi

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "${LOG_P}$0 script must be run as root"
    exit 1
fi

if [ -z "${PE_USER}" ]; then
    echo "${LOG_P}PE_USER environment variable is not set"
    exit 1
fi
if [ -z "${PE_GROUPS}" ]; then
    echo "${LOG_P}PE_GROUP environment variable is not set"
    exit 1
fi
if [ -z "${PE_USER_ID}" ]; then
    echo "${LOG_P}PE_USER_ID environment variable is not set"
    exit 1
fi

for group_id in $(echo "${PE_GROUPS}" | tr ',' ' ')
do
    ensure_group ${group_id}
done
ensure_user "${PE_USER}" "${PE_USER_ID}" "${PE_GROUPS}"

if [ "${user_id}" = 0 ]; then
    if [ -z "$*" ]; then
        [ "${PE_DEBUG}" = 1 ] && echo "${LOG_P}entering interactive shell as root user"
        bash -i
    else
        [ "${PE_DEBUG}" = 1 ] && echo "${LOG_P}executing payload as user root user: $*"
        $@
    fi
else
    if [ -z "$*" ]; then
        [ "${PE_DEBUG}" = 1 ] && echo "${LOG_P}dropping to user ${user_name} (interactive shell)"
        su "${PE_USER}" -P -c bash -i
    else
        [ "${PE_DEBUG}" = 1 ] && echo "${LOG_P}executing payload as user ${user_name}: $*"
        su "${PE_USER}" -P -c "$*" 
    fi
fi
