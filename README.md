# Azure Arc Workshop (L100–L500)

A hands-on, self-paced workshop that teaches **Azure Arc** from first principles to a
fully scripted build lab. Published as a static site with GitHub Pages.

🔗 **Live site:** https://ibranibeny.github.io/azure-arc-workshop/

## Labs

| Lab | Level | Topic |
|-----|-------|-------|
| 01 | L100 | Azure Arc Overview |
| 02 | L200 | The Value of Azure Arc |
| 03 | L300 | Onboard Windows Server & SQL Server |
| 04 | L400 | Simulate a Windows + SQL Server VM into Azure Arc (Indonesia Central) |

## Running the L400 lab

The L400 build lab provisions everything with the Azure CLI. See
[`_labs/04-simulate-vm-sql-arc.md`](_labs/04-simulate-vm-sql-arc.md). The in-guest
bootstrap script is provided at [`scripts/bootstrap.ps1`](scripts/bootstrap.ps1).

> ⚠️ The lab uses a **lab-only** technique (blocking the Azure IMDS endpoint) to make an
> Azure VM simulate an on-premises server. Never apply this to a production Azure VM.

## Build locally (optional)

This site uses the [just-the-docs](https://just-the-docs.com/) remote theme and builds
natively on GitHub Pages. To preview locally:

```bash
gem install bundler jekyll
bundle install
bundle exec jekyll serve
```

## Sources & attribution

Technical content is grounded in [Microsoft Learn](https://learn.microsoft.com/azure/azure-arc/).
Architecture diagrams are © Microsoft and linked from Microsoft Learn.

## License

Educational/community content. Verify all commands against current Microsoft
documentation before using in production.
