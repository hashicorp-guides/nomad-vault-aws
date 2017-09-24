
makefile

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
2. Runs script that sets up NOMAD_ADDR variable (use Consul?)
3. Launches jobs

Features to show off:
- Golang App using native library to pull dynamic mysql creds
- Show nginx/lb using Vault for PKI
- Nomad blue/green/canary deployments
- Consul template example to webserver/library
