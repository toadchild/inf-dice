#!/bin/bash

USER=$1
BRANCH=jonathan-master

if [ -z "$USER" ]; then
  echo "Usage: $0 <bitbucket username>"
  exit 1
fi

rm -rf mayanet_data
mkdir mayanet_data
cd mayanet_data
git init
git config core.sparseCheckout true
git remote add -f origin https://${USER}@bitbucket.org/paulryanclark/mayanet.git
echo Toolbox/*.json > .git/info/sparse-checkout
git checkout $BRANCH
