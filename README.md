# Nagios check_aws_ec2_backup

[![Build Status](https://travis-ci.org/tommarshall/nagios-check-aws-ec2-backup.svg?branch=master)](https://travis-ci.org/tommarshall/nagios-check-aws-ec2-backup)

Nagios plugin for monitoring AWS EC2 EBS snapshot creation via [AWS CLI](https://aws.amazon.com/cli/).

## Installation

[Install the AWS CLI](http://docs.aws.amazon.com/cli/latest/userguide/installing.html).

[Configure the AWS CLI credentials](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) for the Nagios service's user.

Download the [check_aws_ec2_backup](https://cdn.rawgit.com/tommarshall/nagios-check-aws-ec2-backup/v0.1.0/check_aws_ec2_backup) script and make it executable.

Define a new `command` in the Nagios config, e.g.

```
define command {
    command_name    check_aws_ec2_backup
    command_line    $USER1$/check_aws_ec2_backup -r eu-west-1 -v vol-123abcd0
}
```

## Usage

```
Usage: ./check_aws_ec2_backup -r <region> -v <volume-id> [options]
```

### Examples

```sh
# exit WARNING the if most recent snapshot older than 24hrs 15mins, CRITICAL if older than 48hrs 15mins
./check_aws_ec2_backup -r eu-west-1 -v vol-123abcd0

# exit WARNING the if most recent snapshot older than 24hrs, CRITICAL if older than 1 week
./check_aws_ec2_backup -r eu-west-1 -v vol-123abcd0 -c 604800

# exit WARNING the if most recent snapshot older than 1 week, CRITICAL if older than 2 weeks
./check_aws_ec2_backup -r eu-west-1 -v vol-123abcd0 -w 604800 -c 1209600

# set an AWS CLI config profile
./check_aws_ec2_backup -r eu-west-1 -v vol-123abcd0 -p foo-profile

# set full path to AWS CLI
./check_aws_ec2_backup -r eu-west-1 -v vol-123abcd0 -a /usr/local/bin/aws
```

### Options

```
-r, --region <region>       AWS region to use
-v, --volume-id <volume-id> AWS volume ID to check
-p, --profile <profile>     AWS CLI config profile to use
-w, --warning <seconds>     snapshot age in seconds to treat as WARNING
-c, --critical <seconds>    snapshot age in seconds to treat as CRITICAL
-a, --aws-cli-path <path>   set path to AWS CLI, if not on $PATH
-V, --version               output version
-h, --help                  output help information
```

## Dependencies

* bash
* [AWS CLI](https://aws.amazon.com/cli/)
