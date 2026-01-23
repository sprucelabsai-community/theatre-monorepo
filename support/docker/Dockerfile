# syntax=docker/dockerfile:1.7

ARG BASE_IMAGE=ubuntu:20.04

FROM ${BASE_IMAGE} AS builder

ARG BLUEPRINT_PATH=blueprint.yml

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.yarn/bin:/root/.config/yarn/global/node_modules/.bin:$PATH"

RUN apt-get update && apt-get install -y \
	ca-certificates \
	curl \
	g++ \
	git \
	jq \
	lsof \
	netcat-openbsd \
	openssh-client \
	procps \
	python3 \
	make \
	gnupg \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
	&& apt-get update \
	&& apt-get install -y nodejs \
	&& npm install -g yarn \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.ssh \
	&& ssh-keyscan github.com >> /root/.ssh/known_hosts

WORKDIR /theatre

COPY . /theatre
COPY ${BLUEPRINT_PATH} /theatre/blueprint.yml

RUN mkdir -p /theatre/packages
RUN yarn rebuild

FROM ${BASE_IMAGE} AS runtime

ARG INSTALL_MONGO=true
ARG INSTALL_CADDY=true

ENV DEBIAN_FRONTEND=noninteractive
ENV INSTALL_MONGO=${INSTALL_MONGO}
ENV INSTALL_CADDY=${INSTALL_CADDY}
ENV PATH="/root/.yarn/bin:/root/.config/yarn/global/node_modules/.bin:$PATH"

RUN apt-get update && apt-get install -y \
	ca-certificates \
	curl \
	git \
	jq \
	lsof \
	netcat-openbsd \
	openssh-client \
	procps \
	gnupg \
	&& rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
	&& apt-get update \
	&& apt-get install -y nodejs \
	&& npm install -g yarn \
	&& rm -rf /var/lib/apt/lists/*

RUN yarn global add @sprucelabs/spruce-cli

RUN if [ "$INSTALL_MONGO" = "true" ]; then \
		apt-get update && \
		apt-get install -y gnupg && \
		rm -f /usr/share/keyrings/mongodb-server-8.0.gpg && \
		curl -fsSL https://pgp.mongodb.com/server-8.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg && \
		echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/8.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-8.0.list && \
		apt-get update && \
		apt-get install -y mongodb-org && \
		mkdir -p /data/db && \
		rm -rf /var/lib/apt/lists/*; \
	fi

RUN if [ "$INSTALL_CADDY" = "true" ]; then \
		apt-get update && \
		apt-get install -y debian-keyring debian-archive-keyring apt-transport-https && \
		curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-archive-keyring.gpg && \
		echo "deb [signed-by=/usr/share/keyrings/caddy-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" > /etc/apt/sources.list.d/caddy-stable.list && \
		apt-get update && \
		apt-get install -y caddy && \
		rm -rf /var/lib/apt/lists/*; \
	fi

WORKDIR /theatre

COPY --from=builder /theatre /theatre
COPY support/docker/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 8080 8081

ENTRYPOINT ["/entrypoint.sh"]
