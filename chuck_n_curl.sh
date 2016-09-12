#!/bin/bash

./chuckit.sh
echo '>>>>> hurling the curl'
curl -v http://localhost:10014/api/v1/jobs/data_source_job
echo -e '\ncurled.'
