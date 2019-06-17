#!/bin/bash
#
# This script will perform the installation of the mod_mam2sidekiq ejabberd
# module. It has the same requirements as described on the readme file.  We
# download the module and install it to your systems ejabberd files.
#
# This script was tested on Ubuntu Bionic (18), and works just on
# Ubuntu/Debian.
#
# This script should be called like this:
#
#   $ curl -L 'http://bit.ly/2IVdGJf' | bash
#
# Used Ubuntu packages: wget
#
# @author Hermann Mayer <hermann.mayer92@gmail.com>

# Fail on any errors
set -eE

# Specify the module/ejabberd version
MOD_VERSION=0.1.0
SUPPORTED_EJABBERD_VERSION=18.01

# Check for Debian/Ubuntu, otherwise die
if ! grep -P 'Ubuntu|Debian' /etc/issue >/dev/null 2>&1; then
  echo 'Looks like you are not running Debian/Ubuntu.'
  echo 'This installer is only working for them.'
  echo 'Sorry.'
  exit 1
fi

# Discover the installed ejabberd version
EJABBERD_VERSION=$(dpkg -l ejabberd | grep '^ii' \
  | awk '{print $3}' | cut -d- -f1)

# Check for the ejabberd ebin repository, otherwise die
if [ -z "${EJABBERD_VERSION}" ]; then
  echo 'ejabberd is currently not installed via apt.'
  echo 'Suggestion: sudo apt-get install ejabberd'
  exit 1
fi

# Check for the correct ejabberd version is available
if [ "${EJABBERD_VERSION}" != "${SUPPORTED_EJABBERD_VERSION}" ]; then
  echo "The installed ejabberd version (${EJABBERD_VERSION}) is not supported."
  echo "We just support ejabberd ${SUPPORTED_EJABBERD_VERSION}."
  echo 'Sorry.'
  exit 1
fi

# Discover the ejabberd ebin repository on the system
EBINS_PATH=$(dirname $(dpkg -L ejabberd \
  | grep 'ejabberd.*/ebin/.*\.beam$' | head -n1))

# Check for the ejabberd ebin repository, otherwise die
if [ ! -d "${EBINS_PATH}" ]; then
  echo 'No ejabberd ebin repository path was found.'
  echo 'Sorry.'
  exit 1
fi

# Install the apt Redis dependency
sudo apt-get update -yqqq
sudo apt-get install -y erlang-redis-client

# Download the module binary distribution and install it
URL="https://github.com/hausgold/ejabberd-mam2sidekiq/releases/"
URL+="download/${MOD_VERSION}/ejabberd-mam2sidekiq-${MOD_VERSION}.tar.gz"

cd /tmp
rm -rf ejabberd-mam2sidekiq ejabberd-mam2sidekiq.tar.gz

mkdir ejabberd-mam2sidekiq
wget -O ejabberd-mam2sidekiq.tar.gz "${URL}"
tar xf ejabberd-mam2sidekiq.tar.gz \
  --no-same-owner --no-same-permissions -C ejabberd-mam2sidekiq

echo "Install ejabberd-mam2sidekiq to ${EBINS_PATH} .."
sudo chown root:root ejabberd-mam2sidekiq/ebin/*
sudo chmod 0644 ejabberd-mam2sidekiq/ebin/*
sudo cp -far ejabberd-mam2sidekiq/ebin/* "${EBINS_PATH}"
rm -rf ejabberd-mam2sidekiq ejabberd-mam2sidekiq.tar.gz

echo -e "\n\n"
echo -n 'Take care of the configuration of mod_mam2sidekiq on '
echo '/etc/ejabberd/ejabberd.yml'
echo 'Restart the ejabberd server afterwards.'
echo
echo 'Done.'
