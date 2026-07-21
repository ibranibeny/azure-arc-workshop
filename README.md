# Azure Arc Workshop (L100–L400)

A hands-on, self-paced workshop that introduces **Azure Arc**, explains its business
and technical value, and guides you through onboarding Windows Server and SQL Server.
The final build lab creates a repeatable Azure-based simulation for learning purposes.

**Live workshop:** https://ibranibeny.github.io/azure-arc-workshop/

## Workshop objectives

By the end of this workshop, you will be able to:

1. Explain how Azure Arc extends Azure Resource Manager beyond Azure.
2. Identify governance, security, monitoring, and operations use cases for Azure Arc.
3. Onboard a Windows Server with the Azure Connected Machine agent.
4. Register SQL Server as a SQL Server enabled by Azure Arc resource.
5. Deploy and validate a repeatable Arc lab with PowerShell and Azure CLI.
6. Distinguish between `LicenseOnly`, `Paid`, and `PAYG` Arc SQL configurations.

## Intended audience

- IT professionals and infrastructure administrators learning Azure Arc.
- Cloud engineers who need a repeatable onboarding workflow.
- Architects evaluating hybrid and multicloud governance with Azure.

## Workshop path

| Lab | Level | Duration | Outcome |
|-----|-------|----------|---------|
| 01 | L100 | 20 min | Explain the Azure Arc control-plane model. |
| 02 | L200 | 25 min | Map Azure Arc capabilities to business and technical outcomes. |
| 03 | L300 | 40 min | Onboard Windows Server and SQL Server manually or with automation. |
| 04 | L400 | 60 min | Build and validate an Azure VM-based Arc simulation. |

## Get started

### 1. Clone the workshop

```bash
git clone https://github.com/ibranibeny/azure-arc-workshop.git
cd azure-arc-workshop
```

### 2. Sign in to Azure

```bash
az login
az account set --subscription "<subscription-id-or-name>"
az account show --output table
```

### 3. Open the workshop

Use the [live workshop](https://ibranibeny.github.io/azure-arc-workshop/) and complete
the labs in order. Start with
[Lab 01 — Azure Arc Overview](https://ibranibeny.github.io/azure-arc-workshop/labs/01-arc-overview/).

### 4. Run an automated build lab

Choose one path:

| Path | Script | SQL licensing | Best Practices Assessment |
|------|--------|---------------|---------------------------|
| Evaluation | `scripts/evaluate-arc-on-azure-vm.ps1` | SQL Evaluation + Arc `LicenseOnly` | Not available with `LicenseOnly` |
| Enterprise | `scripts/deploy-arc-sql-enterprise-lab.ps1` | Azure SQL VM `AHUB` + Arc `Paid` | Eligible after Log Analytics configuration |

Evaluation path:

```powershell
cd scripts
./evaluate-arc-on-azure-vm.ps1 -ResourceGroup rg-arc-eval
```

Enterprise path—only when qualifying SQL Server Enterprise licenses with Software
Assurance or a SQL Server subscription cover the VM:

```powershell
cd scripts
./deploy-arc-sql-enterprise-lab.ps1 -AcceptUnsupportedLab
```

> [!WARNING]
> Both automated paths use Microsoft's **evaluation-only** technique to make an Azure
> VM simulate a non-Azure server. SQL Server in Azure Virtual Machines is not a supported
> production host for SQL Server enabled by Azure Arc. Never apply this design to a
> production Azure VM.

## Prerequisites

- An Azure subscription with permission to create resource groups, VMs, service
  principals, and role assignments.
- Azure CLI 2.53 or later, authenticated with `az login`.
- Windows PowerShell 5.1 or PowerShell 7 or later.
- At least four available vCPUs for the selected VM family and region.
- For the Enterprise path, qualifying SQL Server Enterprise licensing with Software
  Assurance or a SQL Server subscription.

## Build locally (optional)

This site uses the [Minimal Mistakes](https://mmistakes.github.io/minimal-mistakes/)
remote theme and builds
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
