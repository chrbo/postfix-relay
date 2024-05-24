#!/bin/bash

if [ "$1" = 'test.sh' ]; then
  exec "$@"
fi

exec "$@"
