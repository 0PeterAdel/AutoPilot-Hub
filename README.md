<div align="center">

# 🤖 AutoPilot-Hub

### AI-Powered Personal DevOps Ecosystem

[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://python.org)
[![Docker](https://img.shields.io/badge/Docker-24+-blue.svg)](https://docker.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-In%20Development-yellow.svg)]()

*A self-hosted microservices platform that automates your developer 
workflow using local LLMs and intelligent agents.*

</div>

---

## 🎯 Overview

AutoPilot-Hub is a personal AI-powered automation system built on 
microservices architecture. It acts as your virtual team, handling:

- 🏢 **Freelance Management** — Auto-monitor خمسات & مستقل, 
  reply to clients, discover & apply for projects
- 📧 **Email Management** — Read, summarize, classify, and 
  respond to Gmail messages
- 🛠️ **Dev Environments** — One-command setup for any 
  development stack
- 🔍 **Bug Hunting** — Automated recon, scanning, and 
  AI-powered vulnerability analysis
- 📊 **Smart Reports** — Daily digests delivered via Telegram

<p align="center">
  <img src="https://media2.giphy.com/media/v1.Y2lkPTc5MGI3NjExd3M3ZW0xYmE3OTQyMngzNTg0YWUwanozZ2gyNnI5NTlxb3Uxc2x3dSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/1nR6fu93A17vWZbO9c/giphy.gif" alt="AutoPilot Animation" />
</p>


## 🏗️ Architecture

```text
┌──────────────┐
│  Telegram Bot │──┐
│  Dashboard    │  │
└──────────────┘  │
                   ▼
            ┌──────────┐
            │Main Agent│ (Orchestrator)
            └────┬─────┘
      ┌──────┬───┴───┬──────┐
      ▼      ▼       ▼      ▼
  Freelancer Email  DevEnv BugHunter
  Service   Service Service Service
```

## 🚀 Quick Start

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/AutoPilot-Hub.git
cd AutoPilot-Hub

# Configure
cp .env.example .env
# Edit .env with your settings

# Launch
make setup
make up

# Check status
make status
```

## 📋 Services

| Service | Port | Description |
|---------|------|-------------|
| Main Agent | 8000 | Orchestrator & API Gateway |
| Freelancer | 8001 | خمسات & مستقل automation |
| Email | 8002 | Gmail management |
| DevEnv | 8003 | Dev environment generator |
| BugHunter | 8004 | Bug hunting automation |
| Telegram Bot | - | Command interface |
| Dashboard | 8080 | Web UI |
| Grafana | 3000 | Monitoring |

## 🛠️ Tech Stack

- **Language:** Python 3.11+
- **AI:** Ollama (Local LLM), LangChain, CrewAI
- **API:** FastAPI
- **Browser:** Playwright
- **Queue:** RabbitMQ
- **Database:** PostgreSQL + Redis
- **Container:** Docker + Docker Compose
- **Monitoring:** Prometheus + Grafana

## 📖 Documentation

- [Software Requirements Specification](docs/SRS.md)
- [Architecture Guide](docs/ARCHITECTURE.md)
- [Setup Guide](docs/SETUP.md)

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE)



<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&height=65&section=footer"/>
</p>
