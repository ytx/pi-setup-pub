# pi-setup-pub

Public Ansible roles and playbooks for Raspberry Pi devices, used as teaching
material (lectures, seminars). See README.md for the layout and how it is used
from a private site repository.

## Rules

- **This repository is public.** Nothing personal or site-specific goes in:
  no real domains, host names of real machines, SSIDs, LAN addresses, e-mail
  addresses, passwords, tokens or keys - not in code, comments, examples or
  commit messages. Use `example.com`, `192.168.1.x` and names like `raspi-01`.
- Run `scripts/check-leaks.sh --staged` (the pre-commit hook does) before
  every commit. It reads the maintainer's private patterns from outside the
  repository; never copy that list in here.
- Secrets are read from a directory outside the repository (README.md,
  "Secrets"); roles take them as variables with an empty default.
- Roles here never depend on anything outside this repository (no
  `../other-repo` paths, no private roles).

## Roles

- One role per directory under `ansible/roles/`, with `README.md` (English)
  and `README.ja.md` (Japanese): what it does, the variables it reads with
  their defaults, and what it was tested on.
- Site values belong in the inventory, not in `defaults/`. A default is either
  generic or empty.
- Fully qualified module names (`ansible.builtin.copy`), named tasks.
- `yamllint .` and `ansible-lint` (from `ansible/`) pass.

## Inventory

`ansible/inventory/hosts/*.yml` list groups and hosts only;
`group_vars/<group>.yml` and `host_vars/<host>.yml` hold the variables.
