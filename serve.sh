#!/usr/bin/env sh

IMAGE_NAME="mkdocs-material:local"

cat <<_EOF > Dockerfile
FROM squidfunk/mkdocs-material

COPY ./requirements.txt .
RUN pip install -r requirements.txt
_EOF

docker build -t "${IMAGE_NAME}" .
docker run --rm -p 8000:8000 -v "${PWD}:/docs" "${IMAGE_NAME}"
rm Dockerfile