#!/bin/bash
set -euo pipefail
hugo --cleanDestinationDir
gsutil -m rsync -d -r -x '\..*' public gs://www.pete-woods.com
gsutil -m setmeta -h "Cache-Control:private, max-age=0, no-transform" -r gs://www.pete-woods.com/
