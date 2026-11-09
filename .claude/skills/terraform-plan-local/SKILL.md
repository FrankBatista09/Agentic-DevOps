---
name: terraform-plan-local
description: Run terraform init and plan locally for a given environment (devel or stage) using the user's az login, and print the full plan output plus a human summary. Never applies. Use whenever the user wants to see what Terraform would change.
---

# Terraform plan (local)

## Preconditions
1. `az account show` succeeds (the user is logged in) and shows the expected subscription. Never print tokens.
2. Export the subscription for the azurerm provider in the current shell (do not write it to a file):
   - PowerShell: `$env:ARM_SUBSCRIPTION_ID = (az account show --query id -o tsv)`
   - bash: `export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)`
3. Remote state settings (resource group, storage account, container) are provided by the user or by the repository's backend configuration for the environment. Ask if they are missing; never invent them.

## Steps
1. Move to the Terraform directory.
2. `terraform fmt -check -recursive` and `terraform validate` (after init).
3. Initialize for the requested environment, using the backend configuration mechanism the repository defines (for example `-backend-config=<file>` or `-backend-config="key=value"`). Use `-reconfigure` when switching environments.
4. Plan with the environment's variable file and save it:
   `terraform plan -input=false -var-file=<environment tfvars> -out=<env>.tfplan`
5. Print the **complete** human-readable plan to the chat: `terraform show -no-color <env>.tfplan`. Do not truncate it.
6. Summarize: counts of add/change/destroy, every destroy or replace called out explicitly, billable resources, and anything that looks risky.
7. Delete the local plan file afterwards (it can contain sensitive values) and make sure plan/state files are never staged in git.

## Never
- `terraform apply`, `destroy`, `import` or `state` commands without explicit approval for that exact command.
- Printing secrets, access keys or state contents.
