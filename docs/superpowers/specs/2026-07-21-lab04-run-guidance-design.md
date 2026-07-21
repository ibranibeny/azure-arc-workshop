# Lab 04 run guidance design

## Problem

The Lab 04 execution instructions exist under **Get the script**, after introductory content. A learner opening the lab cannot immediately see how to clone the repository, authenticate, run a deployment, verify it, and clean it up.

## Goal

Make the executable workshop path visible near the top of Lab 04 and understandable without reading the block-by-block script explanation first.

## Page structure

Immediately after **Lab details**, add a primary **Run this lab** section containing:

1. Clone the repository and enter its scripts directory.
2. Sign in to Azure and select the intended subscription.
3. Choose exactly one deployment path:
   - Evaluation inventory with `evaluate-arc-on-azure-vm.ps1`.
   - Enterprise/BPA-eligible with `deploy-arc-sql-enterprise-lab.ps1`, restricted to participants with qualifying Enterprise licensing.
4. Verify the VM, Arc machine, and Arc SQL resources with Azure CLI.
5. Run the matching cleanup command.

Add a prominent **Run the lab** button near the beginning of the page that links to the new section. Keep the architecture, prerequisites, warnings, and detailed code walkthrough below the quick-start.

## Command design

Commands must be complete, copyable PowerShell sequences. The clone step includes the repository URL and `Set-Location`. Authentication includes `az login`, subscription selection, and account verification. Deployment commands must not enable the insecure allow-all inbound option by default.

The Enterprise path must retain these constraints:

- Require `-AcceptUnsupportedLab`.
- State that Azure SQL VM uses `AHUB` and Arc SQL uses `Paid`.
- Require qualifying SQL Server Enterprise licenses with Software Assurance or a SQL Server subscription.
- State that the Azure VM Arc topology is evaluation-only and unsupported for production.

## Verification

The quick-start verifies:

- Azure VM provisioning and power state.
- Azure Arc machine connection status.
- `WindowsAgent.SqlServer` extension provisioning state.
- Discovered Arc SQL Server edition, license type, and connection status.

The page must not imply that BPA is automatically enabled. It remains eligible only after a Log Analytics workspace and BPA configuration are added.

## Publication validation

Before publishing:

- Check Markdown/Jekyll diagnostics and whitespace.
- Confirm PowerShell scripts still parse and contract tests pass.
- Build through GitHub Pages.
- Open the rendered Lab 04 page and confirm **Run this lab**, clone, deployment, verification, and cleanup instructions are visible and correctly ordered.
