#!/bin/bash

USER=$1
BRANCH=master

if [ -z "$USER" ]; then
  echo "Usage: $0 <bitbucket username>"
  exit 1
fi

rm -rf unit_data
mkdir unit_data
cd unit_data
git init
git remote add -f origin https://${USER}@bitbucket.org/toadchild/infinitydata.git
git checkout $BRANCH
