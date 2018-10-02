#!/bin/bash

aws --profile stesasso s3 sync ./public/ s3://stefano.dscnet.org/ --delete --acl public-read

