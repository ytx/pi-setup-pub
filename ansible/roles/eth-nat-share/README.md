# eth-nat-share

[日本語](README.ja.md)

Shares this Pi's Wi-Fi connection with one device plugged into its Ethernet
port: the device gets an address by DHCP and reaches the LAN and the
internet through NAT. A way to bring a device without Wi-Fi (an older Pi, a
microcontroller board) online with one cable.

```
[LAN / internet]
      | Wi-Fi (DHCP)
+-----+-----------------------------+
| this Pi (raspi-01)                |
|  wlan0: DHCP (upstream)           |
|  eth0:  10.42.0.1/30 (shared)     | <- DHCP, DNS and NAT set up by NetworkManager
+-----+-----------------------------+
      | Ethernet cable
+-----+-----------------------------+
| the device (no setup needed)      |
|  eth0: 10.42.0.2 (DHCP)           | <- always this address, whatever its MAC
+-----------------------------------+
```

## How it works

- NetworkManager's `ipv4.method shared`. NetworkManager starts dnsmasq (DHCP
  server and DNS forwarder), turns on IP forwarding and adds the NAT
  (masquerade) rules itself - no dnsmasq or iptables of your own.
- A **/30** subnet leaves exactly one address to hand out, so the device
  **always gets the same address, whatever its MAC** (`10.42.0.1/30`: this
  Pi `.1`, the device `.2`).
- With a pool of one, the lease of a device plugged in before could block
  the next one; `dhcp-authoritative` (in
  `/etc/NetworkManager/dnsmasq-shared.d/`) hands the address out at once
  anyway.
- The NetworkManager connection the interface had before (a fixed address,
  say) is set to `autoconnect no`.
- Nothing is switched over live - the SSH session running the play may be on
  that interface. **It starts at the next reboot** (the one at the end of
  [overlay-enable](../overlay-enable/README.md) will do).

## Variables

| Variable | Default | |
|---|---|---|
| `share_interface` | `eth0` | the interface shared (downstream) |
| `share_connection_name` | `{{ share_interface }}-shared` | the NetworkManager connection's name |
| `share_ip` | `10.42.0.1/30` | this Pi's address on it (CIDR); a /30 fixes the device's address. Pick a subnet your LAN does not use |

## Example

```yaml
roles:
  - static-ip        # nothing without static_ip
  - keep-wifi
  - wifi-fallback
  - eth-nat-share

post_tasks:
  - name: Enable the overlay filesystem
    ansible.builtin.include_role:
      name: overlay-enable
```

To reach the device over SSH, through this Pi:

```
# ~/.ssh/config
Host raspi-01-device
  HostName 10.42.0.2
  User pi
  ProxyJump raspi-01
```

## Checking, after the reboot

```sh
# On this Pi
nmcli connection show            # eth0-shared active
ip addr show eth0                # 10.42.0.1/30
ps aux | grep dnsmasq            # NetworkManager's dnsmasq with --dhcp-range=10.42.0.2,10.42.0.2
ip route                         # the default route still via wlan0

# On the device, once plugged in
ip addr show eth0                # 10.42.0.2
ping -c1 1.1.1.1                 # out through the NAT
```

## Notes

1. **The Wi-Fi must work first.** Afterwards the Ethernet port only serves
   the device, so SSH to this Pi goes over Wi-Fi. Check that it connects to
   your access point before applying (with keep-wifi and wifi-fallback).
   If the host has `static_ip` on `share_interface`, remove it from the
   inventory - it would fight with static-ip.
2. **Shared mode on a /30 may depend on the NetworkManager version.** The first
   time, check that dnsmasq's `--dhcp-range` is `.2,.2`. If it misbehaves,
   your own dnsmasq with a fixed `dhcp-range` is the way out (not part of
   this role).
3. **One device only.** A /30 has room for one. To connect several through a
   switch, widen `share_ip` (say to a /24) - the addresses are then no longer
   fixed.
4. **The device needs no setup.** If it runs a DHCP client (Raspberry Pi OS
   does), plugging it in gives it an address, DNS and a default route.

## Tested on

Raspberry Pi OS based on Debian 13 (trixie), on a Pi 4B.
