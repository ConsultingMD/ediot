#!/bin/bash

echo '000 cleaning up 000'
echo '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
rm tmp/*
echo '+++ generating sample data +++'
echo '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
rake sample_data:generate
rake sample_data:generate
rake sample_data:generate
rake sample_data:generate
echo '--- *encrypting ---'
echo '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
gr-encrypt tmp/*
echo '??? renaming ???'
echo '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
TSTAMP=`date +%s`
for file in tmp/*; do echo "moving '${file}' --> 'tmp/x12005010x220a1834out-${TSTAMP}-${file##*/}'"; done
for file in tmp/*; do mv "$file" "tmp/x12005010x220a1834out-${TSTAMP}-${file##*/}"; done
echo '~~~~~~~~~><CHUCKING!!!!'
#export S3_SRC=s3://grnds-development-imports/walmartdemo/dollar/$(date +%s)
export S3_SRC=s3://grnds-development-imports/walmartdemo/dollar/
echo '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$'
echo "...files landed in ${S3_SRC}"
aws s3 cp tmp/ $S3_SRC --recursive
echo 'chucked.'
