#!/bin/sh

# Protect against buggy runc in docker <20.10.6 causing problems in with Alpine >= 3.14
if [ ! -x /bin/sh ]; then
  echo "Executable test for /bin/sh failed. Your Docker version is too old to run Alpine 3.14+ and Gitea. You must upgrade Docker.";
  exit 1;
fi

GITEA="/app/gitea"
WORK_DIR="/var/lib/gitea"
GITEA_APP_INI="/etc/gitea/app.ini"

# Prepare custom folder
#mkdir -p ${GITEA_CUSTOM} && chmod 0702 ${GITEA_CUSTOM}

# Prepare temp folder
#mkdir -p ${GITEA_TEMP} && chmod 0700 ${GITEA_TEMP}
#if [ ! -w ${GITEA_TEMP} ]; then echo "${GITEA_TEMP} is not writable"; exit 1; fi

#if [ -x /usr/local/bin/gitea-setup.sh ]; then
#    /usr/local/bin/gitea-setup.sh || { echo 'docker setup failed' ; exit 1; }
#fi

ls -la /etc/gitea
ls -la /app/

# Replace app.ini settings with env variables in the form GITEA__SECTION_NAME__KEY_NAME
environment-to-ini --config ${GITEA_APP_INI}

if [ -x ${GITEA} ]; then
        ${GITEA} -c ${GITEA_APP_INI} web || { echo 'gitea run failed' ; exit 1; }
fi

