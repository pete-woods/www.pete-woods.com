#!/bin/bash
set -euo pipefail
hugo
gsutil -m rsync -d -r -x '\..*' public gs://www.pete-woods.com
