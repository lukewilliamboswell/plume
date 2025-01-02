#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

rm -f out.html

roc test package/main.roc

roc examples/sankey.roc

open out.html
