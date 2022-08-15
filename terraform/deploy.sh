#!/bin/bash

rm -rf .terraform
sh bucket.sh
terraform init -backend=true -backend-config=bucket=`whoami`-MyAwesomeTestBucket -backend-config=key=MyState -backend-config=region=us-east-1
terraform apply
