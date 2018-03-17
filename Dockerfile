FROM python:3.5

COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Install Docker client
ENV DOCKER_BUCKET download.docker.com
ENV DOCKER_VERSION 17.12.1-ce

RUN curl -Lo - https://${DOCKER_BUCKET}/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz | \
    tar zxf - --strip-components=1 -C /usr/bin docker/docker
