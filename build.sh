#!/bin/bash
set -euo pipefail
hugo --cleanDestinationDir
gsutil -m rsync -d -r -x '\..*' public gs://www.pete-woods.com

CACHE_CONTROL="Cache-Control:public, max-age=300"
#CACHE_CONTROL="Cache-Control:private, max-age=0, no-transform"

gsutil -m setmeta -h "$CACHE_CONTROL" -r gs://www.pete-woods.com/

