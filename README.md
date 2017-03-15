# nomad-vault-aws

## Initialize Vault

API

```
curl -X "PUT" "http://[IP]:8200/v1/sys/init" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"secret_shares":1, "secret_threshold":1}'
export VAULT_TOKEN=[TOKEN]
```

CLI

```
vault init -key-shares=1 -key-threshold=1
export VAULT_TOKEN=[TOKEN]
```

## Unseal Vault

API

```
curl -X "PUT" "http://[IP]:8200/v1/sys/unseal" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{ "key": "KEY"}'
```

CLI

```
vault unseal
```

## Mount the generic backend

API

```
curl -X "POST" "http://[IP]:8200/v1/sys/mounts/redis" \
     -H "X-Vault-Token: $VAULT_TOKEN" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d $'{"type": "generic"}'
```

```
vault mount -path=redis generic
```

## Write a secret

API

```
curl -X "POST" "http://[IP]:8200/v1/redis/secret1" \
     -H "X-Vault-Token: $VAULT_TOKEN" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"key1": "value1", "key2": "value2"}'
```

CLI

```
vault write redis/secret1 key1=value1 key2=value2
```

## Read the secret

API

```
curl "http://[IP]:8200/v1/redis/secret1" \
     -H "X-Vault-Token: $VAULT_TOKEN"
```

CLI

```
vault read redis/secret1
```


## Create a policy for your job

API

```
curl -X "PUT" "http://[IP]:8200/v1/sys/policy/redis" -H "X-Vault-Token: $VAULT_TOKEN" -H "Content-Type: text/plain; charset=utf-8" --data-binary "@files/redis-policy.json"
curl "http://192.168.33.2:8200/v1/sys/policy/redis" -H "X-Vault-Token: $VAULT_TOKEN"
```

CLI

```
vault policy-write redis files/redis-policy.hcl
vault read redis/secret1
```

## Create the master Nomad server policy

API

```
curl -X "PUT" "http://[IP]:8200/v1/sys/policy/nomad-server" -H "X-Vault-Token: $VAULT_TOKEN" -H "Content-Type: text/plain; charset=utf-8" --data-binary "@files/nomad-server-policy.json"
curl "http://192.168.33.2:8200/v1/sys/policy/nomad-server" -H "X-Vault-Token: $VAULT_TOKEN"
```

CLI

```
vault policy-write nomad-server nomad-server-policy.hcl
vault policies nomad-server
```

## Create the Nomad role

API

```
curl -X "PUT" "http://[IP]:8200/v1/auth/token/roles/nomad-cluster" \
     -H "X-Vault-Token: $VAULT_TOKEN" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"disallowed_policies": "nomad-server", "explicit_max_ttl": 0, "name": "nomad-cluster", "orphan": false, "period": 259200, "renewable": true}'
curl "http://192.168.33.2:8200/v1/auth/token/roles/nomad-cluster" \
     -H "X-Vault-Token: $VAULT_TOKEN"
```

CLI

```
vault write /auth/token/roles/nomad-cluster @nomad-cluster-role.json
vault read /auth/token/roles/nomad-cluster
```


## Create the master Nomad token

API

```
curl -X "POST" "http://[IP]:8200/v1/auth/token/create/nomad-cluster" \
     -H "X-Vault-Token: $VAULT_TOKEN" \
     -H "Content-Type: text/plain; charset=utf-8" \
     -d '{"policy": "nomad-server", "period": "72h"}'
```

CLI

```
vault token-create -policy nomad-server -period 72h
```

## Enable Nomad / Vault integration

```
sudo vi /etc/nomad.d/nomad.hcl (enable & set token)
sudo service nomad restart
```

## Run the job

```
nomad run files/redis.nomad
nomad alloc-status
nomad node-status NODE_ID
```

## Validate

ssh to the appropriate client (from node-status above)

```
sudo docker ps
sudo docker exec -i -t [CONTAINER_ID] /bin/bash
echo $VAULT_TOKEN
wget --header "X-Vault-Token: $VAULT_TOKEN" http://[IP]:8200/v1/redis/secret1
```
