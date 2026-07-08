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
  Extend Azure management, governance, and security to servers and SQL Server
  running anywhere — on-premises, at the edge, or in other clouds — with Azure Arc.
---

## Workshop labs

Six progressive levels (L100 → L500). Beginners can start at L100; experienced
practitioners can jump straight to the L400/L500 build labs.

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
