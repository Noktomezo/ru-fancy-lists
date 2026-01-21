
# 🛡️ ru-fancy-lists

**Because the "Access Denied" screen is so 2021.** This repository provides curated, auto-updating lists of domains and resources that are currently restricted or throttled in Russia. Perfect for your home-lab, VPN gateway, or custom routing setup.

---

## 📖 TL;DR

Stop manually hunting for IPs. These lists are designed to be fed directly into your routing engines (Clash, Sing-box, Bird, etc.) to keep your traffic flowing where it should.

> [!NOTE]
>
> 🤖 **Automated Updates**: Lists are updated daily at 00:00 UTC via GitHub Actions. Only pushes when lists actually change.

---

## 📊 List Varieties: Choose Your Flavor

Seven shades of blocking: from raw data dumps to laser-focused smart sets. Match your hardware's muscle to the right data diet. Processing pipeline order below (upstream → downstream):

| **List Name**               | **Content Strategy**                                                                                | **Best For**                                                |
| --------------------------------- | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| [**hostlist-full.txt**](./lists/hostlist-full.txt) | Raw merged list from [antifilter](https://antifilter.download), [antifilter community](https://community.antifilter.download), and [Re-filter](https://github.com/1andrevich/Re-filter-lists) sources with deduplication. | Powerful routers (x86), VPS, or local DNS servers (AdGuard Home). |
| [**hostlist-filtered.txt**](./lists/hostlist-filtered.txt) | Filtered version with [illegal chars](./filters/illegal-chars.json), [bad sites](./filters/really-bad-sites.json), and [common patterns](./filters/common.json) removed via JSON filters + [whitelist](./filters/whitelist.txt). | Balanced performance with good coverage. |
| [**data-resolvable.txt**](./lists/data-resolvable.txt) | DNS-resolved domains from filtered list using dnsx:`domain [A] [IP]` format. | Advanced routing setups needing domain-to-IP mapping. |
| [**hostlist-resolvable.txt**](./lists/hostlist-resolvable.txt) | Domain names extracted from resolved data - guaranteed valid DNS resolution. | Most home routers (OpenWrt, Keenetic) with average performance. |
| [**ipset-resolvable.txt**](./lists/ipset-resolvable.txt) | Unique IP addresses parsed from resolved data, deduplicated. Perfect for firewall rules. | Direct IP-based blocking/routing (iptables, nftables). |
| [**hostlist-smart.txt**](./lists/hostlist-smart.txt) | Domain list with subdomains trimmed (sub.example.com → example.com) for optimization. | Resource-constrained devices (Raspberry Pi, mobile routers). |
| [**ipset-smart.txt**](./lists/ipset-smart.txt) | IP ranges optimized with iprange tool, private networks excluded. | Lightweight IP-based filtering for low-power devices. |

---

## 🛠️ How to use

1. **Identify your tool:** Whether it's `sing-box`, `clash-meta` (Mihomo), or just a raw `iptables` script.
2. **Point to the Raw URL:** Copy the link to the version you need.
3. **Automate:** Set your client to pull updates every 24 hours to stay ahead of the ban-hammer.

---

## 🤝 Contributing

Found a site that's missing? Or maybe one that shouldn't be there?

* **Open an Issue:** Use the "It's broken" template.
* **PRs:** Always welcome. Keep them clean, keep them English.

---

## ⚖️ Disclaimer

This project is for educational and research purposes. Use it to keep your dev environment stable and your information access free. Stay safe out there.
