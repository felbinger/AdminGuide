#!/usr/bin/env sh

IMAGE_NAME="mkdocs-material:local"

docker build -t "${IMAGE_NAME}" .
docker run --rm -p 8000:8000 -v "${PWD}:/docs" "${IMAGE_NAME}"
