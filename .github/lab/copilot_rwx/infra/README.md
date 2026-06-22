But succinct steps to deploy the VM (Terraform + cloud-init bootstrap):

Prereqs:
- az CLI authenticated (az login) and subscription set
- terraform >= 1.2
- ensure the SSH public key exists locally (default: /home/yves/.ssh/yves@onepoint.pub)

Quickstart:

cd /home/yves/ops/my_git/copilot-ops/.github/lab/copilot_rwx/infra
export TF_VAR_ssh_public_key_path="/home/yves/.ssh/yves@onepoint.pub"    # adjust if different
export TF_VAR_git_repo="https://github.com/youpi-tralala/myownpersonaljesus"
# optionally export TF_VAR_resource_group_name and TF_VAR_location

rtk terraform init
rtk terraform apply -var="ssh_public_key_path=/home/yves/.ssh/yves@onepoint.pub" -auto-approve

# Note: the repo layout may place lab/copilot_rwx under .github/lab/; cloud-init will try both ./lab/... and ./.github/lab/... when cloning the repository.

Notes:
- Provider uses Azure CLI credentials (run: az login)
- If Debian 13 image SKU (debian-13/13) is not available in the subscription/region, edit source_image_reference in main.tf
- After apply, check the public IP and SSH in using the provided output

Cloud-init will clone the repo and attempt to run a bootstrap script or Ansible playbook located under ./lab/copilot_rwx in the repository.
