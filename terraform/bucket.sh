#!/bin/bash

aws s3 mb s3://$(whoami)-MyAwesomeTestBucket
cat policy.json | sed "s/RESOURCE/arn:aws:s3:::$(whoami)-MyAwesomeTestBucket/g" >| new-policy.json
aws s3api put-bucket-policy --bucket $(whoami)-MyAwesomeTestBucket --policy file://new-policy.json
