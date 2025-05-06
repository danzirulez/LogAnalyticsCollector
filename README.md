# Log Analytics Data Collection Functions - Work in Progress :-)

## Overview

This repository contains a modular set of PowerShell functions designed to collect detailed system information from Windows devices. The collected data needs to be formatted as JSON and can be uploaded to Azure Log Analytics for use in reporting dashboards.

Each function focuses on a specific aspect of the system—such as BIOS versions, driver inventory, installed applications, battery health, and more—making it easy to maintain, extend, and schedule based on reporting needs.

## Features

- Modular PowerShell functions for:
  - BIOS details
  - Driver versions
  - Battery and warranty info
  - Installed software and features
  - Office and Windows Update data
  - Docking stations, disks, network adapters, and more
- JSON output suitable for Log Analytics ingestion
- Supports integration with Intune (Remediations) or scheduled tasks
- Scalable and customizable for enterprise environments

## Use Cases

- Endpoint health monitoring
- Software inventory reporting
- BIOS and driver compliance tracking
- Warranty lifecycle management
- Uptime and reboot tracking
- Custom dashboards in Azure Monitor or Power BI

## Getting Started

1. Clone the repository:
   ```bash

   git clone https://github.com/danzirulez/LogAnalyticsCollector.git
