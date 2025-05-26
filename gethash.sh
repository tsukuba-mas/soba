#!/bin/bash

git diff --quiet
IS_MODIFIED=$?
if [ ${IS_MODIFIED} -eq 1 ]; then
    MODIFIED_SIGN="+"
else
    MODIFIED_SIGN=""
fi


HASH=$(git rev-parse HEAD)

echo ${HASH}${MODIFIED_SIGN}

