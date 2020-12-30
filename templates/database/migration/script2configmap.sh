#!/bin/bash

SQLDIR=$(dirname $0)

# Standard output: convert flyway migration SQL files to configmaps data
for f in `ls ${SQLDIR}/*.sql`; do
    echo "  `basename $f`: |"         # key: SQL filename in flyway style
    cat $f | sed 's/\(.*\)/    \1/'   # value: sql script
done
