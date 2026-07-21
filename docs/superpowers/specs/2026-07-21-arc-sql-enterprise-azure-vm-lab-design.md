# Arc-enabled SQL Server Enterprise on Azure VM lab design

## Status

This design supersedes the Azure-native-only direction in `2026-07-21-azure-native-sql-enterprise-vm-design.md` for the requested workshop deployment.

## Purpose

Deploy a fresh SQL Server 2022 Enterprise Marketplace VM in Azure and immediately onboard the host and SQL instance to Azure Arc for workshop evaluation of best practices assessment (BPA).

This configuration is strictly for lab/evaluation use. Microsoft Learn explicitly lists SQL Server in Azure Virtual Machines as unsupported for SQL Server enabled by Azure Arc. The script must display this limitation before creating resources.

## Licensing

The Marketplace image initially uses SQL Server Enterprise PAYG. The deployment registers or updates the Azure SQL virtual machine resource to `AHUB` before Arc onboarding. The Arc SQL extension uses `Paid`, based on the user's attestation that the workload is covered by qualifying Software Assurance or a SQL Server subscription.

This combination avoids intentionally configuring two PAYG SQL meters. It remains the user's responsibility to ensure sufficient Enterprise core licenses and Software Assurance/subscription coverage. BPA is available with Arc SQL license type `Paid`; it is unavailable with `LicenseOnly`.

## Deployment

Create these resources:

- Resource group `rg-arc-eval-ent` in Indonesia Central.
- VM `arc-sql-ent`, size `Standard_D4s_v5`.
- Marketplace image `MicrosoftSQLServer:sql2022-ws2022:enterprise-gen2:latest`.
- Standard public IP with no inbound NSG rule by default.
- Azure SQL VM registration set to `AHUB`.
- Azure Arc server resource in Southeast Asia.
- Azure extension for SQL Server with `LicenseType=Paid`.
- Resource-group-scoped onboarding service principal `sp-arc-eval-ent`.

The script sets `MSFT_ARC_TEST=true`, disables Azure Guest Agent startup, and blocks `169.254.169.254` and `169.254.169.253` to follow Microsoft's Azure VM Arc-evaluation procedure. It delays the reboot until all guest operations are complete because Azure VM Run Command depends on the Guest Agent.

## Safety

- Use a separate resource group and VM name, preserving the earlier lab.
- Reject any existing VM whose Marketplace image is not the required Enterprise image.
- Require an explicit `-AcceptUnsupportedLab` switch.
- Do not open inbound ports unless `-OpenAllInboundPorts` is explicitly supplied.
- Make cleanup target only `rg-arc-eval-ent` and its onboarding service principal.
- Check each Azure CLI exit code and fail with a task-specific message.
- Avoid writing the service-principal secret to disk except in the short-lived Run Command payload, which is removed locally after invocation.

## Verification

Static tests assert the safety switch, image, AHUB conversion, Arc `Paid` setting, IMDS blocks, and absence of downloaded Evaluation media. PowerShell parsing must pass. Azure preflight must verify authentication, image availability, VM SKU availability, quota headroom, and that the target group does not already exist. After deployment, verify VM power state, Azure SQL VM license type, Arc machine status, Arc SQL extension provisioning state, and discovered SQL Server edition.

## Microsoft Learn baseline

- Evaluate Arc-enabled servers on an Azure VM: https://learn.microsoft.com/azure/azure-arc/servers/plan-evaluate-on-azure-virtual-machine
- SQL Server enabled by Azure Arc support and feature matrices: https://learn.microsoft.com/sql/sql-server/azure-arc/overview
- Configure BPA: https://learn.microsoft.com/sql/sql-server/azure-arc/assess
- Configure Arc SQL licensing: https://learn.microsoft.com/sql/sql-server/azure-arc/manage-configuration
- SQL Server on Azure VM images and licensing: https://learn.microsoft.com/azure/azure-sql/virtual-machines/windows/sql-server-on-azure-vm-iaas-what-is-overview
