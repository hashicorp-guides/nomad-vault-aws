# Work In Progress
Unfinished project

Use the makefile to spin up the infrastructure

```
terraform init
terraform apply_vault
terraform apply_rds
terraform apply_admin
terraform apply_nomad

ssh ec2-user@ec2-13-56-231-116.us-west-1.compute.amazonaws.com -i vault/nomad-vault-84601057.pem


# Now give it a minute or two for Nomad to join
[ec2-user@hashistack-i-01b913f1d6d78fea3 ~]$ consul members
Node                            Address             Status  Type    Build  Protocol  DC
hashistack-i-01b913f1d6d78fea3  172.19.2.115:8301   alive   client  0.9.2  2         dc1
hashistack-i-07cda7f6c10a23995  172.19.9.221:8301   alive   server  0.9.2  2         dc1
hashistack-i-0d26b4a80eed18e77  172.19.11.123:8301  alive   server  0.9.2  2         dc1
hashistack-i-0e70f956b364b82e9  172.19.26.175:8301  alive   server  0.9.2  2         dc1
nomad-i-01126fea473ae7d80       172.19.25.145:8301  alive   client  0.9.2  2         dc1
nomad-i-04bb00900830859f8       172.19.1.158:8301   alive   client  0.9.2  2         dc1
nomad-i-062c070d6d0f0f935       172.19.5.133:8301   alive   client  0.9.2  2         dc1

```

Above ^ should work, the TODO's left:
1. Setup 'app' db table on rds mysql
2. Configure Vault with Token Role
  - write token to consul.
  - Have Nomad pull this token from consul(env var)
  - start Nomad
3. set NOMAD_ADDR on the admin (pull from consul) or use consul template
4. register mysql/rds as external service in Consul

# Implementation notes

1. Vault
  - deploy vault (hashistack)
  - Create Vault network

2. RDS
  - create mysql database
    - deploy into Vault network

3. Admin
  - Deploy admin node into Vault network
  - Setup Vault
  - Attach Nomad jobs to this server
  - Setup up 'app' table in rds database
  - Configure Token Role
    - write token (for Nomad) to Consul
  - start Blocking script for Nomad_addr?
    - Run consul template? re-template ~/.profile

4. Nomad
  - setup cluster in Vault network
  - pull token for server config
  - Write nomad_addr variable to Consul somehow?

Usage:
1. User ssh's into admin node
2. Runs script that sets up NOMAD_ADDR or have script watch Consul for nomad service
3. Launches jobs

Features to show off:
- Golang App using native library to pull dynamic mysql creds
- Show nginx/lb using Vault for PKI
- Nomad blue/green/canary deployments
- Consul template example to webserver/library
- Fabio

Next Steps:
- add Multi region Vault
- add multi region Nomad
