---
layout: splash
permalink: /
title: "Azure Arc Workshop"
header:
  overlay_color: "#0b3d91"
  overlay_filter: "0.2"
  actions:
    - label: "Start the workshop"
      url: /labs/01-arc-overview/
excerpt: >-
  Learn Azure Arc from the control-plane fundamentals through a guided Windows
  Server and SQL Server onboarding build lab.
---

## Workshop overview

This self-paced workshop teaches how Azure Arc extends Azure management, governance,
security, and data services to infrastructure running outside Azure. You begin with
the control-plane model, connect Azure Arc capabilities to real operational outcomes,
and finish by onboarding Windows Server and SQL Server with repeatable automation.

The content progresses from **L100 fundamentals** to an **L400 build lab**. Complete
the labs in order if you are new to Azure Arc, or use the lab metadata to select the
level that matches your role and experience.

## Workshop objectives

After completing the workshop, you will be able to:

1. Explain how Azure Arc projects external resources into Azure Resource Manager.
2. Map Azure Arc to governance, security, monitoring, patching, and SQL use cases.
3. Onboard a Windows Server with the Azure Connected Machine agent.
4. Register and validate SQL Server enabled by Azure Arc.
5. Run a guarded PowerShell deployment and verify the Arc resources in Azure.
6. Choose an appropriate Arc SQL license type for inventory or advanced capabilities.

## Workshop labs

Four progressive levels (L100 → L400). Beginners can start at L100; experienced
practitioners can jump straight to the L400 build lab.

<div class="lab-cards">
{% assign labs = site.labs | sort: 'nav_order' %}
{% for lab in labs %}
  <a class="lab-card" href="{{ lab.url | relative_url }}">
    <span class="lab-card__level">L{{ lab.level }}</span>
    <div class="lab-card__title">{{ lab.title }}</div>
    <div class="lab-card__desc">{{ lab.excerpt }}</div>
  </a>
{% endfor %}
</div>

## What you will learn

This workshop takes you from zero knowledge to a fully working hands-on lab.

![Azure Arc management control plane](https://learn.microsoft.com/azure/azure-arc/media/overview/azure-arc-control-plane.png)

*The Azure Arc control plane projects resources hosted outside Azure into Azure Resource Manager. Source: Microsoft Learn.*

## Who is this for?

- **IT professionals / infrastructure admins** new to Azure Arc (L100–L200).
- **Cloud engineers and architects** who want a repeatable, scriptable build (L300–L400).

## Prerequisites

- An **Azure subscription** with permission to create resource groups and resources.
- **Owner** or **Contributor** + **User Access Administrator** on the target scope.
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) 2.53+ (or [Azure Cloud Shell](https://shell.azure.com)).
- Basic familiarity with the Azure portal and a terminal.

This workshop targets the **Indonesia Central** (`indonesiacentral`) region so resource
metadata stays in-country. You can substitute any
[supported Arc region](https://learn.microsoft.com/azure/azure-arc/servers/overview#supported-regions).
{: .notice--info}

## Start the workshop

### Step 1 — Clone the repository

```bash
git clone https://github.com/ibranibeny/azure-arc-workshop.git
cd azure-arc-workshop
```

### Step 2 — Sign in and select your subscription

```bash
az login
az account set --subscription "<subscription-id-or-name>"
az account show --output table
```

### Step 3 — Begin with the fundamentals

Open [Lab 01 — Azure Arc Overview]({{ '/labs/01-arc-overview/' | relative_url }}),
then use **Next** at the bottom of each lab to continue through the learning path.

### Step 4 — Run the build lab

When you reach Lab 04, choose the deployment that matches your licensing goal:

| Deployment | Script | Arc SQL license | BPA eligibility |
|------------|--------|-----------------|-----------------|
| Evaluation inventory | `evaluate-arc-on-azure-vm.ps1` | `LicenseOnly` | No |
| Enterprise with qualifying SA/subscription | `deploy-arc-sql-enterprise-lab.ps1` | `Paid` | Yes, after Log Analytics setup |

```powershell
cd scripts

# Evaluation inventory path
./evaluate-arc-on-azure-vm.ps1 -ResourceGroup rg-arc-eval

# OR: Enterprise path covered by qualifying licenses
./deploy-arc-sql-enterprise-lab.ps1 -AcceptUnsupportedLab
```

Both scripts simulate a non-Azure server on an Azure VM. Microsoft supports this only
for evaluating Azure Arc; do not use this topology in production.
{: .notice--warning}

## How Azure Arc works, in one minute

```mermaid
%% Colored per the mermaid-diagrams skill (classDef + subgraph style)
flowchart LR
    subgraph Outside["Outside Azure (on-prem / other cloud / edge)"]
        S[Windows / Linux Server]
        Q[(SQL Server)]
    end
    A[Azure Connected Machine agent] -->|outbound HTTPS 443| ARM
    S --- A
    Q --- A
    subgraph Azure["Microsoft Azure"]
        ARM[Azure Resource Manager<br/>control plane]
        POL[Azure Policy]
        DEF[Defender for Cloud]
        MON[Azure Monitor]
        UPD[Update Manager]
        ARM --- POL & DEF & MON & UPD
    end

    classDef server fill:#107C10,stroke:#0B5A0B,color:#ffffff;
    classDef sql fill:#CC2927,stroke:#8B1A19,color:#ffffff;
    classDef agent fill:#5C2D91,stroke:#3B1C5E,color:#ffffff;
    classDef arm fill:#0078D4,stroke:#004578,color:#ffffff;
    classDef svc fill:#50E6FF,stroke:#0078D4,color:#003350;

    class S server
    class Q sql
    class A agent
    class ARM arm
    class POL,DEF,MON,UPD svc

    style Outside fill:#f3f3f3,stroke:#8A8A8A,color:#333333
    style Azure fill:#eaf3fb,stroke:#0078D4,color:#003350
```

[Begin with Lab 01 → Azure Arc Overview]({{ '/labs/01-arc-overview/' | relative_url }}){: .btn .btn--primary .btn--large}
