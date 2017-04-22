#!/bin/bash
set -euo pipefail

# Config
BUCKET="gs://www.pete-woods.com"
CACHE_CONTROL="Cache-Control:public, max-age=300"
#CACHE_CONTROL="Cache-Control:private, max-age=0, no-transform"

# Build the site
hugo --cleanDestinationDir

# Sync the files
gsutil -m rsync -d -r -x '\..*|.*\/\..*' public "$BUCKET"

# Set cache control headers
gsutil -m setmeta -h "$CACHE_CONTROL" -r "$BUCKET"
for var in images img downloads
	do
	gsutil -m setmeta -h "Cache-Control" -r "$BUCKET/$var"
done
