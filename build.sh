#!/usr/bin/env sh

docker build --target cppbase -t cppbase:latest .
docker build --target cppedit -t cppedit:latest .
