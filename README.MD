# Xavitar

## Introduction

Xavitar is an interactive shell script that, according to your provided parameters and the credentials you fill in, automates the creation of a domain through Laravel Forge, a VCS provider and Cloudflare as CDN.

## Requirements

1. Bash version 4.2+ (associative arrays)
2. JQ (JSON formatting/desctructuring etc.)

## Installation

1. Download the repository and unzip it.
2. Give the main script file the permission to run it:
   ```bash
   chmod +x ~/xavitar.sh
   ```

## What services are being used

### Forge

- Server instance
- MySQL database/user
- Deployment script for push-to-deploy features and composer/npm installations (Laravel Forge)
- Environment variables
- Repository installation and remotes

### Cloudflare

- Site registration
- Default DNS deletion (from domain registar)
- DNS creation from chosen server istance

## What's happening behind the scenes?
