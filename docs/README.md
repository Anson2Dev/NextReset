# Documentation

| Document | Purpose |
| --- | --- |
| [Project README](../README.md) | Installation, quota semantics, privacy, local development |
| [Interface and identity](INTERFACE.md) | Menu bar modes, headroom colors, approved logo and icon generation |
| [Release procedure](RELEASING.md) | Developer ID signing, notarization, release ZIPs and Homebrew |
| [Website deployment](DEPLOYMENT.md) | Worker configuration, authentication, packaging, publishing and checks |
| [v0.2.1 release record](releases/v0.2.1.md) | Source, checksum, notarization and distribution verification |
| [v0.2 release record](releases/v0.2.md) | Published source, artifact checksum, notarization and completed validation |
| [Contribution guide](../CONTRIBUTING.md) | Code boundaries, tests and credential handling |
| [Changelog](../CHANGELOG.md) | Application releases and website changes |
| [Optional CI example](examples/ci.yml) | macOS test/build workflow; not installed in `.github/workflows` |

Current public application release: **v0.2.1**. Website asset query versions such as `0.2.2` are cache keys, not app releases. The website can be deployed independently without changing the app version or notarized archive.
