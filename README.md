# nomad-vault-aws

# Initialize Vault

API

```
curl -X "PUT" "http://192.168.33.2:8200/v1/sys/init" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"secret_shares":1, "secret_threshold":1}'
```

CLI

```
vault init -key-shares=1 -key-threshold=1
```

## Unseal Vault

API

```
curl -X "PUT" "http://192.168.33.2:8200/v1/sys/unseal" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{ "key": "KEY"}'
```

CLI

```
vault unseal
```

## Mount the generic backend
curl -X "POST" "http://192.168.33.2:8200/v1/sys/mounts/redis" \
     -H "X-Vault-Token: $VAULT_TOKEN" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d $'{"type": "generic"}'

## Vault: Write secret
curl -X "POST" "http://192.168.33.2:8200/v1/redis/secret1" \
     -H "X-Vault-Token: $VAULT_TOKEN" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"key1": "value1", "key2": "value2"}'

## Vault: Read secret
curl "http://192.168.33.2:8200/v1/redis/secret1" \
     -H "X-Vault-Token: $VAULT_TOKEN"

## Vault: Policy write Redis
curl -X "PUT" "http://192.168.33.2:8200/v1/sys/policy/redis" -H "X-Vault-Token: $VAULT_TOKEN" -H "Content-Type: text/plain; charset=utf-8" --data-binary "@files/redis-policy.json"

## Vault: Policy read Redis
curl "http://192.168.33.2:8200/v1/sys/policy/redis" \
     -H "X-Vault-Token: $VAULT_TOKEN"

## Vault: Policy write Nomad
curl -X "PUT" "http://192.168.33.2:8200/v1/sys/policy/nomad-server" -H "X-Vault-Token: $VAULT_TOKEN" -H "Content-Type: text/plain; charset=utf-8" --data-binary "@files/nomad-server-policy.json"

## Vault: Policy read Nomad
curl "http://192.168.33.2:8200/v1/sys/policy/nomad-server" \
     -H "X-Vault-Token: $VAULT_TOKEN"

## Vault: Role write Nomad
curl -X "PUT" "http://192.168.33.2:8200/v1/auth/token/roles/nomad-cluster" \
     -H "X-Vault-Token: $VAULT_TOKEN" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"disallowed_policies": "nomad-server", "explicit_max_ttl": 0, "name": "nomad-cluster", "orphan": false, "period": 259200, "renewable": true}'

## Vault: Role read Nomad
curl "http://192.168.33.2:8200/v1/auth/token/roles/nomad-cluster" \
     -H "X-Vault-Token: $VAULT_TOKEN"

## Vault: Token create
curl -X "POST" "http://192.168.33.2:8200/v1/auth/token/create/nomad-cluster" \
     -H "X-Vault-Token: $VAULT_TOKEN" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"policy": "nomad-server", "period": "72h"}'
