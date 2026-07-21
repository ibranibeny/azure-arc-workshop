# Azure-native SQL Server Enterprise VM design

## Purpose

Add a safe, repeatable Azure-native deployment path for SQL Server 2022 Enterprise without changing the existing Azure Arc evaluation workflow.

Microsoft Learn establishes these constraints:

- SQL Server 2022 Evaluation supports Azure Arc best practices assessment (BPA), but BPA requires Software Assurance/SQL subscription licensing or Arc pay-as-you-go licensing rather than `LicenseOnly`.
- SQL Server enabled by Azure Arc does not support SQL Server running in Azure Virtual Machines.
- Azure Marketplace SQL Server VMs use the SQL IaaS Agent extension and the image's SQL licensing model.
- The SQL Server 2022 Enterprise on Windows Server 2022 Marketplace image is available in Indonesia Central as `MicrosoftSQLServer:sql2022-ws2022:enterprise-gen2`; the deployment should select `latest` after validating availability.

The new workflow is Azure-native and must not claim to enable Azure Arc SQL BPA.

## Architecture

Create a new PowerShell script alongside the existing Arc evaluation script. The new script creates or checks a dedicated Azure VM named `sql2022-ent` in a dedicated resource group. It uses the SQL Server 2022 Enterprise on Windows Server 2022 Marketplace image and keeps the Azure Guest Agent and Instance Metadata Service enabled.

SQL Server is preinstalled by the Marketplace image. The script does not download SQL Server media, install the Connected Machine agent, create an Arc onboarding service principal, or install the Azure Arc SQL extension.

The script checks for a `Microsoft.SqlVirtualMachine/sqlVirtualMachines` resource and registers the VM with the SQL IaaS Agent extension as `PAYG` when registration is absent. This provides Azure-native SQL VM inventory and management while avoiding duplicate registration.

## Components

### Parameters

Expose parameters for:

- Azure region, defaulting to `indonesiacentral`
- Dedicated resource group
- VM name, defaulting to `sql2022-ent`
- VM size, defaulting to `Standard_D4s_v5`
- Administrator username and optional password
- SQL license type, defaulting to `PAYG` and restricted to supported Azure SQL VM values
- Optional insecure all-inbound NSG rule for controlled workshop use
- Cleanup

### Validation

Before VM creation, the script:

1. Confirms Azure CLI is installed and authenticated.
2. Confirms the SQL Marketplace image is available in the selected region.
3. Fails clearly if an existing VM with the requested name was created from another image rather than attempting an in-place image conversion.
4. Checks native command exit codes and removes temporary files where applicable.

### Deployment flow

1. Create or verify the resource group.
2. Generate and display a strong lab password only when no password is supplied for a new VM.
3. Create the VM from `MicrosoftSQLServer:sql2022-ws2022:enterprise-gen2:latest` with no inbound NSG rule by default.
4. Optionally add the explicit lab-only all-inbound NSG rule.
5. Check SQL VM registration and create it only when absent.
6. Display VM power state, public IP, image identity, SQL VM registration state, edition, and license type.

### Cleanup

Cleanup deletes only the dedicated native SQL VM resource group. It does not delete the existing Arc evaluation resource group or service principal.

## Error handling

Every mutating Azure CLI operation is followed by an exit-code check that terminates with a task-specific error. Image validation happens before VM creation. Existing resources are reused only when their identity matches the requested design.

Registration may take time after VM creation, so the script should report actionable status rather than silently continuing when the SQL VM resource is not ready.

## Security and cost

- No inbound traffic is allowed by default.
- The all-inbound option is labeled insecure and suitable only for an isolated workshop.
- Generated passwords are printed because this is a workshop script; callers can pass their own password to avoid generation.
- Enterprise `PAYG` licensing is included in Azure SQL VM billing and is materially more expensive than a plain Windows VM or SQL Developer image.
- Azure Arc SQL extension installation and Arc `PAYG` configuration are intentionally excluded to avoid unsupported dual management and possible duplicate license reporting.

## Verification

Static verification checks PowerShell parsing and repository diagnostics. Behavioral verification confirms:

- Image discovery resolves the Enterprise Gen2 image in Indonesia Central.
- Existing Arc script remains unchanged.
- A mismatched existing VM is rejected safely.
- Re-running after successful deployment is idempotent.
- Cleanup targets only the native SQL VM resource group.

## Microsoft Learn baseline

- SQL Server on Azure Windows VMs overview: https://learn.microsoft.com/azure/azure-sql/virtual-machines/windows/sql-server-on-azure-vm-iaas-what-is-overview
- SQL Server on Azure VMs pricing guidance: https://learn.microsoft.com/azure/azure-sql/virtual-machines/windows/pricing-guidance
- SQL IaaS Agent automatic registration: https://learn.microsoft.com/azure/azure-sql/virtual-machines/windows/sql-agent-extension-automatic-registration-all-vms
- SQL Server enabled by Azure Arc overview and unsupported configurations: https://learn.microsoft.com/sql/sql-server/azure-arc/overview
- Azure Arc SQL best practices assessment prerequisites: https://learn.microsoft.com/sql/sql-server/azure-arc/assess
