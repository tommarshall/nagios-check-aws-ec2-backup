# !/usr/bin/env bash

load '../vendor/bats-mock/stub'

BASE_DIR=$(dirname $BATS_TEST_DIRNAME)
TMP_DIRECTORY=$(mktemp -d)
AWS_DATE_FORMAT='+%Y-%m-%dT%H:%M:%SZ'

setup() {
  cd $TMP_DIRECTORY
  export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
  export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
}

teardown() {
  unstub aws

  if [ $BATS_TEST_COMPLETED ]; then
    echo "Deleting $TMP_DIRECTORY"
    rm -rf $TMP_DIRECTORY
  else
    echo "** Did not delete $TMP_DIRECTORY, as test failed **"
  fi

  cd $BATS_TEST_DIRNAME
}
