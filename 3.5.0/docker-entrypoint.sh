#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

set -e

# first arg is `-something` or `+something`
if [ "${1#-}" != "$1" ] || [ "${1#+}" != "$1" ]; then
	set -- /opt/couchdb/bin/couchdb "$@"
fi

# first arg is the bare word `couchdb`
if [ "$1" = 'couchdb' ]; then
	shift
	set -- /opt/couchdb/bin/couchdb "$@"
fi

if [ "$1" = '/opt/couchdb/bin/couchdb' ]; then
	# Fix permissions for Docker volume mounts (mounted as root by default)
	chown -R couchdb:couchdb /opt/couchdb

	chmod -R 0770 /opt/couchdb/data

	chmod 664 /opt/couchdb/etc/*.ini 2>/dev/null || true
	chmod 664 /opt/couchdb/etc/default.d/*.ini 2>/dev/null || true
	chmod 775 /opt/couchdb/etc/*.d 2>/dev/null || true

	# Handle NODENAME env for clustering
	if [ ! -z "$NODENAME" ] && ! grep -q "couchdb@" /opt/couchdb/etc/vm.args; then
		echo "-name couchdb@$NODENAME" >> /opt/couchdb/etc/vm.args
	fi

	# Ensure writable overlay for runtime config
	mkdir -p /opt/couchdb/etc/local.d
	touch /opt/couchdb/etc/local.d/docker.ini

	# CouchDB 3.x requires admin credentials
	if [ "$COUCHDB_USER" ] && [ "$COUCHDB_PASS" ]; then
		# Create admin
		printf "[admins]\n%s = %s\n" "$COUCHDB_USER" "$COUCHDB_PASS" > /opt/couchdb/etc/local.d/docker.ini
		chown couchdb:couchdb /opt/couchdb/etc/local.d/docker.ini
	fi

	# Optional: set secret for auth token signing
	if [ "$COUCHDB_SECRET" ]; then
		printf "[couch_httpd_auth]\nsecret = %s\n" "$COUCHDB_SECRET" >> /opt/couchdb/etc/local.d/docker.ini
		chown couchdb:couchdb /opt/couchdb/etc/local.d/docker.ini
	fi

	# Optional: set Erlang cookie for clustering
	if [ -n "${COUCHDB_ERLANG_COOKIE:-}" ] && ! grep -q '^-setcookie' /opt/couchdb/etc/vm.args; then
		echo "-setcookie ${COUCHDB_ERLANG_COOKIE}" >> /opt/couchdb/etc/vm.args
	fi

	# Warn if no admin is configured (3.x will refuse to start without admin)
	if ! grep -Pzoqr '\[admins\]\n[^;]\w+' /opt/couchdb/etc/default.d/*.ini /opt/couchdb/etc/local.d/*.ini 2>/dev/null; then
		cat >&2 <<-'EOWARN'
			****************************************************
			WARNING: CouchDB 3.x requires admin credentials.
			         Set them using environment variables:
			         -e COUCHDB_USER=admin -e COUCHDB_PASS=password

			         CouchDB will fail to start without credentials.
			****************************************************
		EOWARN
	fi

	# Step down from root to couchdb user
	exec gosu couchdb "$@"
fi

exec "$@"
