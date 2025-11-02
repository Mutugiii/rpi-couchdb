# The Dockerfile is Licensed under GNU AFFERO GENERAL PUBLIC LICENSE Version 3

FROM debian:bookworm-slim
LABEL maintainer="mutugiii@ole.org,dogi@ole.org"

# Add CouchDB user account
RUN groupadd -r couchdb && useradd -r -d /opt/couchdb -g couchdb couchdb

# Install runtime dependencies (kept in final image)
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    erlang-nox \
    libicu72 \
    libmozjs-102-0 \
    openssl \
    tini \
  && rm -rf /var/lib/apt/lists/*

# Install gosu for step-down from root and tini for signal handling
ENV GOSU_VERSION=1.17
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends wget gnupg dirmngr; \
	rm -rf /var/lib/apt/lists/*; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 || \
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true; \
	apt-get purge -y --auto-remove wget gnupg dirmngr

# CouchDB GPG keys for signature verification
# Key that signed 3.5.0: 0BD7A98499C4AB41C910EE65FC04DFBC9657A78E
ENV GPG_KEYS="0BD7A98499C4AB41C910EE65FC04DFBC9657A78E 390EF70BB1EA12B2773962950EE62FB37A00258D D2B17F9DA23C0A10991AF2E3D9EE01E47852AEE4 2EC788AE3F239FA13E82D215CDE711289384AE37"

ENV COUCHDB_VERSION=3.5.0

# Copy ARM32 compatibility patch
COPY arm32_cfile.patch /tmp/

# Download, verify, build CouchDB, and cleanup in ONE layer (keeps image small)
RUN buildDeps=' \
    build-essential \
    erlang-dev \
    erlang-reltool \
    libcurl4-openssl-dev \
    libicu-dev \
    libmozjs-102-dev \
    pkg-config \
    wget \
    gnupg \
    dirmngr \
  ' \
 && apt-get update -y -qq && apt-get install -y --no-install-recommends $buildDeps \
 && cd /usr/src && mkdir couchdb \
 # Import GPG keys for verification
 && export GNUPGHOME="$(mktemp -d)" \
 && for key in $GPG_KEYS; do \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" || \
    gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || true; \
  done \
 # Download and verify CouchDB source
 && curl -fsSL https://downloads.apache.org/couchdb/source/$COUCHDB_VERSION/apache-couchdb-$COUCHDB_VERSION.tar.gz -o couchdb.tar.gz \
 && curl -fsSL https://downloads.apache.org/couchdb/source/$COUCHDB_VERSION/apache-couchdb-$COUCHDB_VERSION.tar.gz.asc -o couchdb.tar.gz.asc \
 && gpg --batch --verify couchdb.tar.gz.asc couchdb.tar.gz \
 && tar -xzf couchdb.tar.gz -C couchdb --strip-components=1 \
 && cd couchdb \
 # ARM32 Fix: Patch couch_cfile for 32-bit ARM compatibility
 # Part 1: Disables couch_cfile NIF compilation on 32-bit systems (C code)
 # Part 2: Handles missing couch_cfile module gracefully (Erlang code)
 # Source: https://github.com/apache/couchdb/commit/b4dc703dc622bae99ca78c788a7af1f4797f57ee
 # Remove this patch when upgrading to CouchDB 3.5.1+ (if fix included upstream)
 && patch -p1 < /tmp/arm32_cfile.patch \
 # Build and install CouchDB
 && ./configure --disable-docs --spidermonkey-version 102 \
 && make release \
 && mv /usr/src/couchdb/rel/couchdb /opt/ \
 # Cleanup build artifacts and build dependencies
 && apt-get purge -y --auto-remove $buildDeps \
 && rm -rf /var/lib/apt/lists/* /usr/src/couchdb* "$GNUPGHOME" \
 && mkdir /opt/couchdb/data \
 && chown -R couchdb:couchdb /opt/couchdb

# Add configuration
COPY local.ini /opt/couchdb/etc/default.d/
COPY vm.args /opt/couchdb/etc/

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Setup directories and permissions
RUN chown -R couchdb:couchdb /opt/couchdb/etc/default.d/ /opt/couchdb/etc/vm.args

WORKDIR /opt/couchdb
EXPOSE 5984 4369 9100
VOLUME ["/opt/couchdb/data"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["/opt/couchdb/bin/couchdb"]
