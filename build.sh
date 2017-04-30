#!/bin/bash
set -euo pipefail

# Build the site
hugo --cleanDestinationDir

# Deploy the site
firebase deploy

