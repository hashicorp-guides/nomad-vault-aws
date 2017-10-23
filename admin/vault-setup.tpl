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
ACTIVE_VAULT_HOST=$(curl -s http://127.0.0.1:8500/v1/catalog/service/vault?tags=active | jq -r '.[0].Address')
VAULT_TOKEN=$(cat /tmp/root_token)
database_mount_payload=$(cat <<EOF
{
  "type": "database"
}
EOF
)

curl \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data "$${database_mount_payload}" \
    http://$${ACTIVE_VAULT_HOST}:8200/v1/sys/mounts/database


mysql_config_payload=$(cat <<EOF
{
    "plugin_name": "mysql-rds-database-plugin",
    "allowed_roles": "app",
    "connection_url": "${db_user}:${db_password}@tcp(${db_address}:3306)/"
}
EOF
)

curl \
    --silent \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data "$${mysql_config_payload}" \
    http://$${ACTIVE_VAULT_HOST}:8200/v1/database/config/mysql

mysql_role_payload=$(cat <<EOF
{
    "db_name": "mysql",
    "creation_statements": "CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';",
    "default_ttl": "1h",
    "max_ttl": "24h"
}
EOF
)
curl \
  --silent \
  --header "X-Vault-Token: $${VAULT_TOKEN}" \
  --request POST \
  --data "$${mysql_role_payload}" \
  http://$${ACTIVE_VAULT_HOST}:8200/v1/database/roles/app

}


# Setup Nomad Token Role
nomad_token_role_setup(){

nomad_server_policy=$(cat <<EOF
{"rules": "path \"auth/token/create/nomad-cluster\" {capabilities = [\"update\"]} path \"auth/token/roles/nomad-cluster\" {capabilities = [\"read\"]} path \"database/creds/app\" {capabilities = [\"read\",\"list\"]} path \"secret/app\" {capabilities = [\"read\",\"list\"]}  path \"auth/token/lookup\" {capabilities = [\"update\"]} path \"auth/token/revoke-accessor\" {capabilities = [\"update\"]} path \"/sys/capabilities-self\" {capabilities = [\"update\"]} path \"auth/token/renew-self\" {capabilities = [\"update\"]}"}
EOF
)

curl \
  --header "X-Vault-Token: $${VAULT_TOKEN}" \
  --request PUT \
  --data "$${nomad_server_policy}" \
  http://$${ACTIVE_VAULT_HOST}:8200/v1/sys/policy/nomad-server

curl \
  --header "X-Vault-Token: $${VAULT_TOKEN}" \
  --request PUT \
  --data '{"disallowed_policies": "nomad-server", "explicit_max_ttl": 0, "name": "nomad-cluster", "orphan": false, "period": 259200, "renewable": true}' \
  http://$${ACTIVE_VAULT_HOST}:8200/v1/auth/token/roles/nomad-cluster

curl \
  --header "X-Vault-Token: $${VAULT_TOKEN}" \
  --request "POST" \
  --data '{"policy": "nomad-server", "period": "72h"}' \
  http://$${ACTIVE_VAULT_HOST}:8200/v1/auth/token/create/nomad-cluster | tee \
  >(jq -r .auth.client_token > /tmp/nomad_token)

NOMAD_TOKEN=$(cat /tmp/nomad_token)
curl \
  --silent \
  --request PUT \
  --data "$${NOMAD_TOKEN}" \
  http://127.0.0.1:8500/v1/kv/service/vault/nomad-token

}

database_setup
vault_database_setup
nomad_token_role_setup

#register external database as mysql.service.consul
curl -X PUT \
  -d '{"Datacenter": "dc1", "Node": "mysql", "Address": "${db_address}}", "Service": {"Service": "rds-mysql", "Port": 3306 }}' \
  http://127.0.0.1:8500/v1/catalog/register

#Attach Nomad job files
sudo echo 'job "app" {
  datacenters = ["dc1"]
  type = "service"

  update {
    stagger = "5s"
    max_parallel = 1
  }

  group "app" {
    count = 3

    task "app" {
      driver = "exec"
      config {
        command = "app"
      }

      env {
        VAULT_ADDR = "http://vault.service.consul:8200"
        APP_DB_HOST = "10.103.0.5:3306"
      }

      vault {
        policies = ["nomad-server"]
      }

      artifact {
        source = "https://s3-us-west-1.amazonaws.com/aklaas/app"
      }

      resources {
        cpu = 500
        memory = 64
        network {
          mbits = 1
          port "http" {}
        }
      }

      service {
        name = "app"
        tags = ["urlprefix-app.com/"]
        port = "http"
        check {
          type = "http"
          name = "healthz"
          interval = "15s"
          timeout = "5s"
          path = "/healthz"
        }
      }
    }
  }
}' | tee -a /tmp/app.nomad
sudo chmod 777 /tmp/app.nomad

echo 'job "fabio" {
  datacenters = ["dc1"]
  type = "system"
  update {
    stagger = "5s"
    max_parallel = 1
  }

  group "fabio" {
    task "fabio" {
      driver = "exec"
      config {
        command = "fabio"
      }

      artifact {
        source = "https://s3.amazonaws.com/ak-bucket-1/fabio"
      }

      resources {
        cpu = 500
        memory = 64
        network {
          mbits = 1

          port "http" {
            static = 9999
          }
          port "ui" {
            static = 9998
          }
        }
      }
    }
  }
}' | tee -a /tmp/fabio.nomad
sudo chmod 777 /tmp/fabio.nomad

sudo echo '
job "goapp" {
  datacenters = ["dc1"]
  type = "service"
  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert = false
    canary = 0
  }
  group "goapp" {
    count = 3
    restart {
      # The number of attempts to run the job within the specified interval.
      attempts = 10
      interval = "5m"
      # The "delay" parameter specifies the duration to wait before restarting
      # a task after it has failed.
      delay = "25s"
      mode = "delay"
    }
    ephemeral_disk {
      size = 300
    }
    task "goapp" {
      # The "driver" parameter specifies the task driver that should be used to
      # run the task.
      driver = "docker"
      config {
        image = "aklaas2/test-app"
        port_map {
          http = 8080
        }
      }
      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
        network {
          mbits = 10
          port "http" {
		          static=8080
	        }
        }
      }
      service {
        name = "goapp"
        tags = [ "urlprefix-goapp/"]
        port = "http"
        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
' | tee -a /tmp/goapp.nomad
sudo chmod 777 /tmp/goapp.nomad


# Wait for Nomad to Restart, set NOMAD_ADDR?
# Consul template bashrc .profile
#NOMAD_HOST=$(curl -s http://127.0.0.1:8500/v1/catalog/service/vault | jq -r '.[0].Address')
