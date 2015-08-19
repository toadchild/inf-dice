#!/bin/bash

BRANCH=jonathan-master

rm -rf mayanet_data
mkdir mayanet_data
cd mayanet_data
git init
git config core.sparseCheckout true
git remote add -f origin git@bitbucket.org:paulryanclark/mayanet.git
echo Toolbox/*.json > .git/info/sparse-checkout
git checkout $BRANCH
