#!/bin/bash
set -x
set -v
set -e

sudo echo "hi" > /tmp/test.txt

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
new_hostname="hashistack-$${instance_id}"

# stop consul and nomad so they can be configured correctly
systemctl stop nomad
systemctl stop vault
systemctl stop consul

# clear the consul and nomad data directory ready for a fresh start
rm -rf /opt/consul/data/*
rm -rf /opt/nomad/data/*
rm -rf /opt/vault/data/*

# set the hostname (before starting consul and nomad)
hostnamectl set-hostname "$${new_hostname}"

# ensure dnsmasq is part of name resolution
sudo sed '1 i nameserver 127.0.0.1' -i /etc/resolv.conf

# add the consul group to the config with jq
jq ".retry_join_ec2 += {\"tag_key\": \"Environment-Name\", \"tag_value\": \"${environment_name}\"}" < /etc/consul.d/consul-default.json > /tmp/consul-default.json.tmp
sed -i -e "s/127.0.0.1/$${local_ipv4}/" /tmp/consul-default.json.tmp
mv /tmp/consul-default.json.tmp /etc/consul.d/consul-default.json
chown consul:consul /etc/consul.d/consul-default.json

# remove consul servers specific stuff
rm -f /etc/consul.d/consul-server.json

# start consul once it is configured correctly
systemctl start consul

# currently no additional configuration required for vault
# todo: support TLS in hashistack and pass in {vault_use_tls} once available

# remove this when dan fixes the images
sleep 120

sudo echo "hi2" > /tmp/test.txt

# init Vault
VAULT_HOST=$(curl -s http://127.0.0.1:8500/v1/catalog/service/vault | jq -r '.[0].Address')
curl \
    --silent \
    --request PUT \
    --data '{"secret_shares": 1, "secret_threshold": 1}' \
    http://$${VAULT_HOST}:8200/v1/sys/init | tee \
    >(jq -r .root_token > /tmp/root_token) \
    >(jq -r .keys[0] > /tmp/key)

# unseal Vault
key=$(cat /tmp/key)
for v in $(curl -s http://127.0.0.1:8500/v1/catalog/service/vault | jq -r '.[].Address') ; do
  curl \
       --silent \
       --request PUT \
       --data '{"key": "'"$$key"'"}' \
       http://$${VAULT_HOST}:8200/v1/sys/unseal
done

# wait to ensure leader election complete for an active Vault node
sleep 10

# get active Vault IP via Consul API (cannot use DNS resolution at this stage)
ACTIVE_VAULT_HOST=$(curl -s http://127.0.0.1:8500/v1/catalog/service/vault?tags=active | jq -r '.[0].Address')

# write some secrets
VAULT_TOKEN=$(cat /tmp/root_token)
curl \
    --silent \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data '{"secret":"SUPER_SECRET_PASSWORD"}' \
    http://$${ACTIVE_VAULT_HOST}:8200/v1/secret/foo

#write vault token to Consul for Nomad (DEMO USE ONLY)
ROOT_TOKEN=$(cat /tmp/root_token)
curl \
    --silent \
    --request PUT \
    --data "$${ROOT_TOKEN}" \
    http://127.0.0.1:8500/v1/kv/service/vault/root-token

# write a policy

curl \
    --silent \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data '{"rules":"path \"secret/foo\" {\n capabilities = [\"list\",\"read\"]\n} \npath \"supersecret/*\" {\n capabilities = [\"list\", \"read\"]\n} \npath \"auth/token/lookup-self\" {\n capabilities = [\"read\"]\n}"}' \
    http://$${ACTIVE_VAULT_HOST}:8200/v1/sys/policy/test

####
## Setup AWS authentication
####

# Enable AWS authentication backend
aws_auth_payload=$(cat <<EOF
{
  "type": "aws",
  "description": "AWS authentication setup"
}
EOF
)

curl \
    --silent \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data "$${aws_auth_payload}" \
    http://$${ACTIVE_VAULT_HOST}:8200/v1/sys/auth/aws


# Configure AWS credentials in Vault
curl \
    --silent \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data '{ "access_key": "${aws_access_key}", "secret_key": "${aws_secret_key}"}' \
    http://$${ACTIVE_VAULT_HOST}:8200/v1/auth/aws/config/client

# Configure AWS auth role
test_role_payload=$(cat <<EOF
{
  "auth_type": "ec2",
  "bound_region": "${region}",
  "bound_vpc_id": "${vpc_id}",
  "bound_subnet_id": "${subnet_id}",
  "role_tag": "",
  "policies": "test",
  "max_ttl": 1800000,
  "disallow_reauthentication": false,
  "allow_instance_migration": false
}
EOF
)

curl \
    --silent \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data "$${test_role_payload}" \
    http://$${ACTIVE_VAULT_HOST}:8200/v1/auth/aws/role/test


# Create database table
database_setup() {
  sudo yum install -y mysql
  mysql -h ${db_address} -u ${db_user} -p${db_password} -e 'create database app;'
}

# Setup Vault MySQL database backend
vault_database_setup() {
  database_mount_payload=$(cat <<EOF
  {
    "type": "database"
  }
  EOF
  )

  curl \
      --header "X-Vault-Token: $${VAULT_TOKEN}" \
      --request POST \
      --data '$${database_mount_payload}' \
      http://$${ACTIVE_VAULT_HOST}/v1/sys/mounts/database


  mysql_config_payload=$(cat <<EOF
  {
    "plugin_name": "mysql-database-plugin",
    "allowed_roles": "readonly",
    "connection_url": "${db_user}:${db_password}@tcp(${db_address}:3306)/",
    "max_open_connections": 5,
    "max_connection_lifetime": "5s",
  }
  EOF
  )

  curl \
      --silent \
      --header "X-Vault-Token: $${VAULT_TOKEN}" \
      --request POST \
      --data "$${mysql_config_payload}" \
      http://$${ACTIVE_VAULT_HOST}:8200/v1/database/config/mysql
}

# Setup Nomad Token Role
nomad_token_role_setup() {
  curl -X "PUT" "http://$${ACTIVE_VAULT_HOST}:8200/v1/sys/policy/nomad-server" \
       -H "X-Vault-Token: $${VAULT_TOKEN}" \
       -H "Content-Type: text/plain; charset=utf-8" \
       --data-binary "@files/nomad-server-policy.json"

  curl -X "PUT" "http://$${ACTIVE_VAULT_HOST}:8200/v1/auth/token/roles/nomad-cluster" \
       -H "X-Vault-Token: $${ACTIVE_VAULT_HOST}" \
       -H "Content-Type: text/plain; charset=utf-8" \
       -d '{"disallowed_policies": "nomad-server", "explicit_max_ttl": 0, "name": "nomad-cluster", "orphan": false, "period": 259200, "renewable": true}'

  curl -X "POST" "http://$${ACTIVE_VAULT_HOST}:8200/v1/auth/token/create/nomad-cluster" \
       -H "X-Vault-Token: $${ACTIVE_VAULT_HOST}" \
       -H "Content-Type: text/plain; charset=utf-8" \
       -d '{"policy": "nomad-server", "period": "72h"}'

  # Write Nomad token to Consul
  #export NOMAD_TOKEN=$(vault token-create -policy nomad-server | grep 'token ' | awk '{print $2}')
  #curl -fX PUT 127.0.0.1:8500/v1/kv/service/vault/nomad-token \
  #    -d $NOMAD_TOKEN


}

# Wait for Nomad to Restart, set NOMAD_ADDR?
