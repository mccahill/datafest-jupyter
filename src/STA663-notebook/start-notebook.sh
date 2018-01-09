#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e

#
# start the notebook via xvfb-run so graphics work
# 
start.sh jupyter notebook $*

# we can run in JupyterLab mode by stating the notebook server as shown below:
#start.sh jupyter lab $*

