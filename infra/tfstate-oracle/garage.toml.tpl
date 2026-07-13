# Standalone single-node Garage for the `oracle` backend's Terraform state.
# Template — scripts/tfstate-oracle-bootstrap.sh substitutes __RPC_SECRET__ and
# __ADMIN_TOKEN__ with freshly generated values before this ships as cloud-init
# user-data. Unlike infra/tfstate/garage.toml (localhost-only, safe to hardcode
# throwaway secrets), this instance has a public IP — never commit real values here.
metadata_dir = "/var/lib/garage/meta"
data_dir     = "/var/lib/garage/data"
db_engine    = "lmdb"

replication_factor = 1

rpc_bind_addr   = "[::]:3901"
rpc_public_addr = "127.0.0.1:3901"
rpc_secret      = "__RPC_SECRET__"

[s3_api]
# Must match the `region` in infra/live/oracle/root.hcl's generated s3 backend block.
s3_region     = "garage"
api_bind_addr = "[::]:3900"
root_domain   = ".s3.tfstate-oracle.local"

[admin]
api_bind_addr = "[::]:3903"
admin_token   = "__ADMIN_TOKEN__"
