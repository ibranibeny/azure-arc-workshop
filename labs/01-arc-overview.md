---
title: 01 · Azure Arc Overview
layout: default
nav_order: 2
---

# Lab 01 · Azure Arc Overview
{: .no_toc }
{: .fs-7 }

**Level 100 · Concept · ~20 minutes**
{: .fs-4 .fw-300 }

<details open markdown="block">
  <summary>On this page</summary>
  {: .text-delta }
- TOC
{:toc}
</details>

---

## Lab details

| Level | Persona | Duration | Purpose |
|-------|---------|----------|---------|
| 100 | IT pro / architect (new to Arc) | 20 min | After this lab you can explain what Azure Arc is, the problem it solves, and the resource types it can project into Azure. |

## Why this matters

Most organizations no longer run everything in a single place. Workloads are spread
across **on-premises datacenters, multiple public clouds, and edge locations**. Each
environment brings its **own tools**, its own identity model, and its own way of
applying policy and security — which multiplies operational cost and risk.

Common challenges Azure Arc solves:

- *"I have servers in three clouds and on-prem — I need one inventory and one policy engine."*
- *"My auditors want consistent security baselines everywhere, not per-environment scripts."*
- *"I want to use Azure Monitor, Defender for Cloud, and Update Manager on machines that aren't in Azure."*

## Introduction

> Azure Arc simplifies governance and management by delivering a **consistent
> multicloud and on-premises management platform**. — *Microsoft Learn, [Azure Arc overview](https://learn.microsoft.com/azure/azure-arc/overview)*

Azure Arc **extends the Azure control plane** (Azure Resource Manager) to resources
that live outside Azure. Once a resource is *projected* into Azure Resource Manager,
you manage it **the same way you manage a native Azure resource**: it gets an Azure
Resource ID, lives in a resource group, can be tagged, secured with RBAC, and
targeted by Azure Policy.

![Azure Arc management control plane](https://learn.microsoft.com/azure/azure-arc/media/overview/azure-arc-control-plane.png)
*Azure Arc projects non-Azure resources into Azure Resource Manager, giving you a single control plane. Source: Microsoft Learn.*

Azure Arc is a key part of Microsoft's **adaptive cloud** approach: run and manage
apps and services consistently across Azure, other clouds, on-premises, and the edge.

## Core concepts

| Concept | What it means |
|---------|---------------|
| **Control plane** | Azure Resource Manager (ARM) — the API and management layer Azure Arc extends to external resources. |
| **Projection** | Representing a non-Azure resource (server, cluster, database) as a first-class Azure resource with an Azure Resource ID. |
| **Azure Connected Machine agent** (`azcmagent`) | The lightweight agent installed on a Windows/Linux machine that registers it with Azure Arc and enables management. |
| **Hybrid machine** | A physical or virtual server hosted outside Azure that is projected into Azure via Arc. |
| **Extensions** | Add-on capabilities (e.g., the Azure extension for SQL Server, Monitoring agent, Defender) deployed onto Arc-enabled machines. |
| **Custom locations / resource bridge** | An abstraction layer that lets Azure services deploy into on-prem infrastructure (used by VMware, SCVMM, Azure Local). |

## What Azure Arc can manage

Azure Arc lets you manage several resource types hosted **outside** of Azure:

1. **Servers and virtual machines** — Windows and Linux physical servers and VMs, on-prem or in other clouds. *(Focus of this workshop.)*
2. **Kubernetes clusters** — any CNCF-conformant cluster, wherever it runs.
3. **SQL Server** — SQL Server instances *enabled by Azure Arc* (Lab 03 and 04).
4. **Azure data services** — e.g., SQL Managed Instance and PostgreSQL running on Arc-enabled Kubernetes.
5. **VMware vSphere, SCVMM, and Azure Local** — extend Azure to entire virtualization estates via the Arc resource bridge.

{: .note }
> **Azure Arc-enabled servers** is the entry point for machines. When you connect a
> machine, it becomes an Azure resource you can organize into resource groups, apply
> policy to, run scripts on, and tag for search — all from the Azure portal or Azure CLI.

## How connectivity works

The Connected Machine agent only needs **outbound HTTPS (443)** to a defined set of
Azure endpoints. **No inbound ports** are required, which is why Arc works behind
corporate firewalls and NAT. Connectivity can be direct, via a proxy, or through
**Azure Arc gateway / Private Link** for locked-down networks.

![Azure Connected Machine agent architecture](https://learn.microsoft.com/azure/azure-arc/servers/media/agent-overview/connected-machine-agent.png)
*The Connected Machine agent communicates outbound to Azure Resource Manager. Source: Microsoft Learn.*

## Summary of targets

By the end of this lab you should be able to:

- Explain the problem Azure Arc solves (fragmented multicloud/hybrid management).
- Describe the control-plane / projection model.
- List the resource types Azure Arc can manage.
- Describe how the Connected Machine agent connects (outbound-only).

## Test your understanding

1. In one sentence, what does Azure Arc *extend* to resources outside Azure?
2. Which agent do you install on a server to project it into Azure Arc?
3. True or false: Azure Arc requires you to open inbound firewall ports on your servers.
4. Name three Azure capabilities you could apply to an Arc-enabled server.

<details markdown="block">
  <summary>Answers</summary>

1. The **Azure control plane** (Azure Resource Manager) — its management, governance, and security capabilities.
2. The **Azure Connected Machine agent** (`azcmagent`).
3. **False.** Only **outbound HTTPS (443)** is required; no inbound ports.
4. Any three of: Azure Policy, RBAC, tags, Azure Monitor, Defender for Cloud, Update Manager, Run Command, Machine Configuration.

</details>

## Summary of learnings

- Azure Arc **projects** non-Azure resources into Azure Resource Manager.
- You then manage them with **familiar Azure tools** — one pane of glass.
- It is **agent-based and outbound-only**, making it firewall-friendly.
- Arc supports **servers, Kubernetes, SQL Server, data services, and full VM estates**.

---

[⬅ Home](../){: .btn }
[Next: The Value of Azure Arc ➡](02-arc-value){: .btn .btn-primary .float-right }
