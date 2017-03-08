#!/bin/bash
set -e

# Run confd to render config file(s)
confd -onetime -backend env

# Grant permissions to /dev/stdout for spawned squid process
chown squid:squid /dev/stdout

# Run application
exec "$@"