# 🛡️ Russia Fancy Lists

This repository provides curated, auto-updating lists of domains and resources that are currently restricted or throttled in Russia. Perfect for your home-lab, VPN gateway, or custom routing setup.

> [!IMPORTANT]
> This project is for educational and research purposes. Use it to keep your dev environment stable and your information access free. Stay safe out there.

## 📊 List Varieties: Choose Your Flavor

Seven shades of blocking: from raw data dumps to laser-focused smart sets. Match your hardware's muscle to the right data diet. Processing pipeline order below (upstream → downstream):

| **List Name**                                                  | **Content Strategy**                                                                                                                                                                                                             |
| -------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**hostlist-full.txt**](./lists/hostlist-full.txt)             | Raw merged list from [antifilter](https://antifilter.download), [antifilter community](https://community.antifilter.download), and [Re-filter](https://github.com/1andrevich/Re-filter-lists) sources with deduplication.        |
| [**hostlist-filtered.txt**](./lists/hostlist-filtered.txt)     | Filtered version with [illegal chars](./filters/illegal-chars.json), [bad sites](./filters/really-bad-sites.json), and [common patterns](./filters/common.json) removed via JSON filters + [whitelist](./filters/whitelist.txt). |
| [**data-resolvable.txt**](./lists/data-resolvable.txt)         | DNS-resolved domains from filtered list using dnsx:`domain [A] [IP]` format.                                                                                                                                                     |
| [**hostlist-resolvable.txt**](./lists/hostlist-resolvable.txt) | Domain names extracted from [**data-resolvable.txt**](./lists/data-resolvable.txt) - guaranteed valid DNS resolution.                                                                                                            |
| [**ipset-resolvable.txt**](./lists/ipset-resolvable.txt)       | Unique IP addresses parsed from [**data-resolvable.txt**](./lists/data-resolvable.txt).                                                                                                                                          |
| [**hostlist-smart.txt**](./lists/hostlist-smart.txt)           | Domain list with subdomains trimmed (sub.example.com → example.com).                                                                                                                                                             |
| [**ipset-smart.txt**](./lists/ipset-smart.txt)                 | IP ranges optimized with iprange tool, private networks excluded.                                                                                                                                                                |

> [!NOTE]
> 🤖 **Automated Updates**: Lists are updated daily at 00:00 UTC via GitHub Actions. Only pushes when lists actually change.

&nbsp;

<div align="center">
  <img src="./assets/heartbeat.svg" alt="heartbeat" width="600px">
  <p>Made with 💜. Published under <a href="LICENSE">MIT license</a>.</p>
</div>
