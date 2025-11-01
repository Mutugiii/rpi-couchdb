### [treehouses/couchdb:3.5.0](https://hub.docker.com/r/treehouses/rpi-couchdb/tags)

```bash
docker manifest create treehouses/rpi-couchdb:3.5.0 \
  treehouses/rpi-couchdb:3.5.0 \
  couchdb:3.5.0

docker manifest annotate treehouses/rpi-couchdb:3.5.0 \
  treehouses/rpi-couchdb:3.5.0 \
  --os linux --arch arm

docker manifest push treehouses/rpi-couchdb:3.5.0
```

**Note:** CouchDB 3.x requires admin credentials. The container will fail to start without `COUCHDB_USER` and `COUCHDB_PASSWORD` environment variables.

## Migration from 2.3.1

CouchDB 3.x can read 2.x database files directly. Mount your existing data volume and CouchDB will auto-upgrade

## Environment Variables

- `COUCHDB_USER` - Admin username (required)
- `COUCHDB_PASSWORD` - Admin password (required)
- `COUCHDB_SECRET` - Secret for auth token signing (optional)
- `COUCHDB_ERLANG_COOKIE` - Erlang cookie for clustering (optional)
- `NODENAME` - Node name for clustering (optional)

## Ports

- `5984` - CouchDB HTTP API
- `4369` - Erlang Port Mapper (clustering)
- `9100` - Erlang distribution (clustering)
