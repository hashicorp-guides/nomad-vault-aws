# Work In Progress
Unfinished project

Use the makefile to spin up the infrastructure

```
terraform init
terraform apply_vault
terraform apply_rds
terraform apply_admin
terraform apply_nomad
```

These should work, the TODO's left:
1. Setup 'app' db table on rds mysql
2. Configure Vault with Token Role
  a. write token to consul.
  b. Have Nomad pull this token from consul(env var)
  c. start Nomad
3. set NOMAD_ADDR on the admin (pull from consul) or use consul template



# Implementation notes

1. Vault
  - deploy vault (hashistack)
  - Create Vault network

2. RDS
  - create mysql database
    - deploy into Vault network

TODO
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
