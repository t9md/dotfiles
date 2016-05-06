#!/bin/bash

ATOM_DIR=$HOME/.atom
REAL_FILE_DIR=$PWD
cd ${ATOM_DIR}
ln -sf ${REAL_FILE_DIR}/config.cson .
ln -sf ${REAL_FILE_DIR}/init.coffee .
ln -sf ${REAL_FILE_DIR}/keymap.cson .
ln -sf ${REAL_FILE_DIR}/snippets.cson .
ln -sf ${REAL_FILE_DIR}/styles.less .
cd -
