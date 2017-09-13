
makefile

1. Vault
  - deploy vault (hashistack)
  - Create Vault network

2. RDS
  - create mysql database
    - deploy into Vault network
  - mysql provider create 'demo app' table

3. Admin
  - Deploy admin node into Vault network
  - Setup Vault
  - Configure Token Role
    - write token (for Nomad) to Consul
  - Block for Nomad_addr? Consul template ~/.profile
    - Run consul template? re-template ~/.profile
  - Attach Nomad jobs to this server

4. Nomad
  - setup cluster in Vault network
  - pull token for server config
  - Write Nomad_addr variable to Consul somehow?

Usage:
1. User ssh's into admin node
2. Runs script that sets up NOMAD_ADDR variable (use Consul?)
3. Launches jobs

Features to show off:
- Golang App using native library to pull dynamic mysql creds
- Show nginx/lb using Vault for PKI
- Nomad blue/green/canary deployments
- Consul template example to webserver/library
