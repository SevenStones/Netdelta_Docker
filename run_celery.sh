#!/bin/bash
export RABBITMQ_NODE_PORT=8080

service rabbitmq-server start

tail -f /dev/null
