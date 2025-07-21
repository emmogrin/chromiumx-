# 🚀 ChromiumX — by Saint Khen (@admirkhen)

Run multiple isolated Chromium browser containers (up to 20) on any VPS or PC — secured, containerized, and easily shareable with custom passwords.

---

## 🧠 What is ChromiumX?

ChromiumX is a simple Bash automation that spins up secure browser environments using Docker. Perfect for:

- 📤 Sharing multiple browser instances (with/without passwords)
- 🧪 Running parallel tasks safely
- 🔐 Limiting access via passwords
- ⚡ Quick one-command deployment

---

## 🧾 Features

- ✅ Auto-installs Docker & dependencies
- ✅ Choose how many browser instances (1–20)
- ✅ Option to set same or different passwords per instance
- ✅ Auto-detects and avoids used ports
- ✅ Launches & displays all access URLs

---

## 🚀 One-Click Setup

### 📦 Clone and run:

```bash
git clone https://github.com/emmogrin/chromiumx-.git
cd chromiumx-
chmod +x chromiumx.sh
./chromiumx.sh
```


to remove chromium container
```
chmod +x remove_chromium.sh
./remove_chromium.sh 
```

🔗 Access container 1:
http://your-vps-ip:8085
🔐 Password: yourpassword

Each container runs independently in its own port (e.g. 8080, 8081, etc.).


---

🔧 Requirements

Ubuntu VPS (Contabo, DigitalOcean, etc.) or Local Linux PC

Docker (auto-installed by script)

Recommended: 2GB+ RAM


---

🙌 Credits

Built with ❤️ by @admirkhen
Banner design: Saint Khen Studios™
