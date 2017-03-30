#!/usr/bin/env bats

load '../vendor/bats-support/load'
load '../vendor/bats-assert/load'
load 'test_helper'

# Validation
# ------------------------------------------------------------------------------
@test "exits UNKNOWN if unrecognised option provided" {
  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo --not-an-arg

  assert_failure 3
  assert_line "UNKNOWN: Unrecognised argument: --not-an-arg"
  assert_line --partial "Usage:"
}

@test "exits UNKNOWN if --region/-r not provided" {
  run $BASE_DIR/check_aws_ec2_backup --volume-id foo

  assert_failure 3
  assert_output "UNKNOWN: --region/-r not set"
}

@test "exits UNKNOWN if --volume-id/-v not provided" {
  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1

  assert_failure 3
  assert_output "UNKNOWN: --volume-id/-v not set"
}

@test "exits UNKNOWN if AWS CLI is missing" {
  PATH='/bin:/usr/bin'
  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo

  assert_failure 3
  assert_output "UNKNOWN: Unable to find AWS CLI"
}

@test "exits UNKNOWN if GNU date is missing" {
  skip
  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo

  assert_failure 3
  assert_output "UNKNOWN: Unable to find GNU date"
}

@test "exits UNKNOWN if AWS CLI access key is missing" {
  unset AWS_ACCESS_KEY_ID
  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo

  assert_failure 3
  assert_output "UNKNOWN: Unable to find AWS CLI access key"
}

@test "exits UNKNOWN if AWS CLI secret key is missing" {
  unset AWS_SECRET_ACCESS_KEY
  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo

  assert_failure 3
  assert_output "UNKNOWN: Unable to find AWS CLI secret key"
}

@test "exits UNKNOWN if AWS CLI credentials are set, but invalid" {
  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo

  assert_failure 3
  assert_output "UNKNOWN: Unable to fetch snapshots via AWS CLI"
}

# Defaults
# ------------------------------------------------------------------------------
@test "exits OK if snapshot created within the OK threshold" {
  SNAPSHOT_DATETIME_24_HOURS_AGO="$(date -u -d '-24 hours' $AWS_DATE_FORMAT)"
  SNAPSHOT_DATETIME_99_HOURS_AGO="$(date -u -d '-99 hours' $AWS_DATE_FORMAT)"
  AWS_CLI_RESPONSE="${SNAPSHOT_DATETIME_24_HOURS_AGO}\n${SNAPSHOT_DATETIME_99_HOURS_AGO}"
  stub aws \
    "configure list" \
    "ec2 describe-snapshots --region eu-west-1 --filters Name=volume-id,Values=foo --output text --query Snapshots[*].{Time:StartTime} : echo -e '${AWS_CLI_RESPONSE}'"

  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo

  assert_success
  assert_output "OK: Snapshot created ${SNAPSHOT_DATETIME_24_HOURS_AGO}"
}

@test "exits WARNING if snapshot created between the warning and critical thresholds" {
  SNAPSHOT_DATETIME_25_HOURS_AGO="$(date -u -d '-25 hours' $AWS_DATE_FORMAT)"
  SNAPSHOT_DATETIME_99_HOURS_AGO="$(date -u -d '-99 hours' $AWS_DATE_FORMAT)"
  AWS_CLI_RESPONSE="${SNAPSHOT_DATETIME_25_HOURS_AGO}\n${SNAPSHOT_DATETIME_99_HOURS_AGO}"
  stub aws \
    "configure list" \
    "ec2 describe-snapshots --region eu-west-1 --filters Name=volume-id,Values=foo --output text --query Snapshots[*].{Time:StartTime} : echo -e '${AWS_CLI_RESPONSE}'"

  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo

  assert_failure 1
  assert_output "WARNING: Snapshot created ${SNAPSHOT_DATETIME_25_HOURS_AGO}"
}

@test "exits CRITICAL if snapshot created beyond the WARNING threshold" {
  SNAPSHOT_DATETIME_99_HOURS_AGO="$(date -u -d '-99 hours' $AWS_DATE_FORMAT)"
  AWS_CLI_RESPONSE="${SNAPSHOT_DATETIME_99_HOURS_AGO}"
  stub aws \
    "configure list" \
    "ec2 describe-snapshots --region eu-west-1 --filters Name=volume-id,Values=foo --output text --query Snapshots[*].{Time:StartTime} : echo -e '${AWS_CLI_RESPONSE}'"

  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo

  assert_failure 2
  assert_output "CRITICAL: Snapshot created ${SNAPSHOT_DATETIME_99_HOURS_AGO}"
}

@test "exits CRITICAL if no snapshots exist" {
  AWS_CLI_RESPONSE=""
  stub aws \
    "configure list" \
    "ec2 describe-snapshots --region eu-west-1 --filters Name=volume-id,Values=foo --output text --query Snapshots[*].{Time:StartTime} : echo -e '${AWS_CLI_RESPONSE}'"

  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo

  assert_failure 2
  assert_output "CRITICAL: No snapshots found for volume-id 'foo'"
}

# @test "exits UNKNOWN if the volume ID cannot be found" {
#   skip "unimplemented"
#   run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo
#   assert_failure 3
#   assert_output "UNKNOWN: Unrecognised volume-id 'foo'"
# }

# --region
# ------------------------------------------------------------------------------
@test "-r is an alias for --region" {
  AWS_CLI_RESPONSE="$(date -u $AWS_DATE_FORMAT)"
  stub aws \
    "configure list" \
    "ec2 describe-snapshots --region us-east-1 --filters Name=volume-id,Values=foo --output text --query Snapshots[*].{Time:StartTime} : echo -e '${AWS_CLI_RESPONSE}'"

  run $BASE_DIR/check_aws_ec2_backup -r us-east-1 --volume-id foo

  assert_success
  assert_output "OK: Snapshot created ${AWS_CLI_RESPONSE}"
}

# --volume-id
# ------------------------------------------------------------------------------
@test "-v is an alias for --volume-id" {
  AWS_CLI_RESPONSE="$(date -u $AWS_DATE_FORMAT)"
  stub aws \
    "configure list" \
    "ec2 describe-snapshots --region eu-west-1 --filters Name=volume-id,Values=bar --output text --query Snapshots[*].{Time:StartTime} : echo -e '${AWS_CLI_RESPONSE}'"

  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id bar

  assert_success
  assert_output "OK: Snapshot created ${AWS_CLI_RESPONSE}"
}

# --critical
# ------------------------------------------------------------------------------
@test "--critical takes prescence over warning and ok" {
  SNAPSHOT_DATETIME_2_HOURS_AGO="$(date -u -d '-2 hours' $AWS_DATE_FORMAT)"
  AWS_CLI_RESPONSE="${SNAPSHOT_DATETIME_2_HOURS_AGO}"
  stub aws \
    "configure list" \
    "ec2 describe-snapshots --region eu-west-1 --filters Name=volume-id,Values=foo --output text --query Snapshots[*].{Time:StartTime} : echo -e '${AWS_CLI_RESPONSE}'"

  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo --critical 3600

  assert_failure 2
  assert_output "CRITICAL: Snapshot created ${SNAPSHOT_DATETIME_2_HOURS_AGO}"
}

@test "--critical overrides default" {
  SNAPSHOT_DATETIME_99_HOURS_AGO="$(date -u -d '-99 hours' $AWS_DATE_FORMAT)"
  AWS_CLI_RESPONSE="${SNAPSHOT_DATETIME_99_HOURS_AGO}"
  stub aws \
    "configure list" \
    "ec2 describe-snapshots --region eu-west-1 --filters Name=volume-id,Values=foo --output text --query Snapshots[*].{Time:StartTime} : echo -e '${AWS_CLI_RESPONSE}'"

  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo --critical 604800

  assert_failure 1
  assert_output "WARNING: Snapshot created ${SNAPSHOT_DATETIME_99_HOURS_AGO}"
}

@test "-c is an alias for --critical" {
  SNAPSHOT_DATETIME_99_HOURS_AGO="$(date -u -d '-99 hours' $AWS_DATE_FORMAT)"
  AWS_CLI_RESPONSE="${SNAPSHOT_DATETIME_99_HOURS_AGO}"
  stub aws \
    "configure list" \
    "ec2 describe-snapshots --region eu-west-1 --filters Name=volume-id,Values=foo --output text --query Snapshots[*].{Time:StartTime} : echo -e '${AWS_CLI_RESPONSE}'"

  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo -c 604800

  assert_failure 1
  assert_output "WARNING: Snapshot created ${SNAPSHOT_DATETIME_99_HOURS_AGO}"
}

# --warning
# ------------------------------------------------------------------------------
@test "--warning overrides default" {
  SNAPSHOT_DATETIME_25_HOURS_AGO="$(date -u -d '-25 hours' $AWS_DATE_FORMAT)"
  AWS_CLI_RESPONSE="${SNAPSHOT_DATETIME_25_HOURS_AGO}"
  stub aws \
    "configure list" \
    "ec2 describe-snapshots --region eu-west-1 --filters Name=volume-id,Values=foo --output text --query Snapshots[*].{Time:StartTime} : echo -e '${AWS_CLI_RESPONSE}'"

  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo --warning 129600

  assert_failure 1
  assert_output "WARNING: Snapshot created ${SNAPSHOT_DATETIME_25_HOURS_AGO}"
}

@test "-w is an alias for --warning" {
  SNAPSHOT_DATETIME_25_HOURS_AGO="$(date -u -d '-25 hours' $AWS_DATE_FORMAT)"
  AWS_CLI_RESPONSE="${SNAPSHOT_DATETIME_25_HOURS_AGO}"
  stub aws \
    "configure list" \
    "ec2 describe-snapshots --region eu-west-1 --filters Name=volume-id,Values=foo --output text --query Snapshots[*].{Time:StartTime} : echo -e '${AWS_CLI_RESPONSE}'"

  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo -w 129600

  assert_failure 1
  assert_output "WARNING: Snapshot created ${SNAPSHOT_DATETIME_25_HOURS_AGO}"
}

# --aws-cli-path
# ------------------------------------------------------------------------------

@test "--aws-cli-path overrides default" {
  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo --aws-cli-path /not-a-path

  assert_failure 3
  assert_output "UNKNOWN: Unable to find AWS CLI"
}

@test "-a is an alias for --aws-cli-path" {
  run $BASE_DIR/check_aws_ec2_backup --region eu-west-1 --volume-id foo -a /not-a-path

  assert_failure 3
  assert_output "UNKNOWN: Unable to find AWS CLI"
}

# --version
# ------------------------------------------------------------------------------
@test "--version prints the version" {
  run $BASE_DIR/check_aws_ec2_backup --version
  assert_success
  [[ "$output" == "check_aws_ec2_backup "?.?.? ]]
}

@test "-V is an alias for --version" {
  run $BASE_DIR/check_aws_ec2_backup -V
  assert_success
  [[ "$output" == "check_aws_ec2_backup "?.?.? ]]
}

# --help
# ------------------------------------------------------------------------------
@test "--help prints the usage" {
  run $BASE_DIR/check_aws_ec2_backup --help
  assert_success
  assert_line --partial "Usage: ./check_aws_ec2_backup -r <region> -v <volume-id> [options]"
}

@test "-h is an alias for --help" {
  run $BASE_DIR/check_aws_ec2_backup -h
  assert_success
  assert_line --partial "Usage: ./check_aws_ec2_backup -r <region> -v <volume-id> [options]"
}
