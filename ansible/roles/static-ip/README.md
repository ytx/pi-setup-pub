# static-ip

[日本語](README.ja.md)

Gives the Pi a fixed IPv4 address, with NetworkManager (current releases) or
dhcpcd (older ones). The NetworkManager connection on the interface is found
by itself.

A host without `static_ip` is put back on DHCP if its connection is still
set to a manual address, and left alone otherwise, so the role can be in
every playbook and only the hosts that need it get an address.

## Variables

| Variable | Default | |
|---|---|---|
| `static_ip` | (none) | the address, without the prefix (`/24` is added) - usually in `host_vars/<host>.yml` |
| `network_interface` | `wlan0` | the interface (`eth0` for wired) |
| `gateway` | `""` | the router; required with `static_ip` |
| `dns_servers` | `[]` | name servers |

`gateway` and `dns_servers` are usually the same for every host:

```yaml
# inventory/group_vars/all.yml
gateway: 192.168.1.1
dns_servers:
  - 192.168.1.1
  - 1.1.1.1

# inventory/host_vars/raspi-01.yml
static_ip: 192.168.1.50
network_interface: eth0
```

## Notes

- The new address takes effect at the next reboot, not at once, so the SSH
  session running the play is not cut. The reboot at the end of
  [overlay-enable](../overlay-enable/README.md) applies it.
- The prefix is always `/24`.
- Removing `static_ip` from a host puts the connection back on DHCP
  (`ipv4.method auto`) at the next reboot. Hosts that never had it are left alone.

## Tested on

Raspberry Pi OS based on Debian 13 (trixie), with NetworkManager.
