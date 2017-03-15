# nomad-vault-aws

## Vault: Check init status
curl "http://192.168.33.2:8200/v1/sys/init"

## Vault: Init
curl -X "PUT" "http://192.168.33.2:8200/v1/sys/init" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"secret_shares":1, "secret_threshold":1}'

## Vault: Unseal
curl -X "PUT" "http://192.168.33.2:8200/v1/sys/unseal" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{ "key": "24a68ce73eec412061690ba05e917f7c61a5f5cf7c19d8706f32ef81a2b51815"}'

## Vault: Mount generic
curl -X "POST" "http://192.168.33.2:8200/v1/sys/mounts/redis" \
     -H "X-Vault-Token: ed498a61-536c-0f69-e2d7-19fea5ff92a3" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d $'{"type": "generic"}'

## Vault: Write secret
curl -X "POST" "http://192.168.33.2:8200/v1/redis/secret1" \
     -H "X-Vault-Token: ed498a61-536c-0f69-e2d7-19fea5ff92a3" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"key1": "value1", "key2": "value2"}'

## Vault: Read secret
curl "http://192.168.33.2:8200/v1/redis/secret1" \
     -H "X-Vault-Token: ed498a61-536c-0f69-e2d7-19fea5ff92a3"

## Vault: Policy write Redis
curl -X "PUT" "http://192.168.33.2:8200/v1/sys/policy/redis" -H "X-Vault-Token: ed498a61-536c-0f69-e2d7-19fea5ff92a3" -H "Content-Type: text/plain; charset=utf-8" --data-binary "@files/redis-policy.json"

## Vault: Policy read Redis
curl "http://192.168.33.2:8200/v1/sys/policy/redis" \
     -H "X-Vault-Token: ed498a61-536c-0f69-e2d7-19fea5ff92a3"

## Vault: Policy write Nomad
curl -X "PUT" "http://192.168.33.2:8200/v1/sys/policy/nomad-server" -H "X-Vault-Token: ed498a61-536c-0f69-e2d7-19fea5ff92a3" -H "Content-Type: text/plain; charset=utf-8" --data-binary "@files/nomad-server-policy.json"

## Vault: Policy read Nomad
curl "http://192.168.33.2:8200/v1/sys/policy/nomad-server" \
     -H "X-Vault-Token: ed498a61-536c-0f69-e2d7-19fea5ff92a3"

## Vault: Role write Nomad
curl -X "PUT" "http://192.168.33.2:8200/v1/auth/token/roles/nomad-cluster" \
     -H "X-Vault-Token: ed498a61-536c-0f69-e2d7-19fea5ff92a3" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"disallowed_policies": "nomad-server", "explicit_max_ttl": 0, "name": "nomad-cluster", "orphan": false, "period": 259200, "renewable": true}'

## Vault: Role read Nomad
curl "http://192.168.33.2:8200/v1/auth/token/roles/nomad-cluster" \
     -H "X-Vault-Token: ed498a61-536c-0f69-e2d7-19fea5ff92a3"

## Vault: Token create
curl -X "POST" "http://192.168.33.2:8200/v1/auth/token/create/nomad-cluster" \
     -H "X-Vault-Token: ed498a61-536c-0f69-e2d7-19fea5ff92a3" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"policy": "nomad-server", "period": "72h"}'
