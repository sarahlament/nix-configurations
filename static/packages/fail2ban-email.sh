#!/usr/bin/env bash
# fail2ban-email
set -euo pipefail

# set variables from args
jail="$1" ip="$2" timeout="$3"
until=$(date -d "@$(($(date +%s) + timeout))" -Iseconds)

# email needs to know where to go
dest="admin@lament.gay"
sender="system@lament.gay"

# query google if cloudflare's resolver returns nothing
rdns=$(dig +short -x "${ip}" @1.1.1.1 2>/dev/null || true)
rdns="${rdns:-$(dig +short -x "${ip}" @8.8.8.8 2>/dev/null || true)}"
rdns="${rdns:-(no PTR)}"

# I want all log entries regarding this IP over the past hour
logs=$(journalctl --since "1 hour ago" --grep "\\b${ip//./\\.}\\b" -o short-iso --no-pager 2>/dev/null || true)
logs=${logs:-(none found)}

# first we format the message
message=$(cat <<EOF
From: Fail2Ban <${sender}>
To: ${dest}
Subject: [f2b] ${jail} banned ${ip}
X-Notification-Source: fail2ban

${ip} triggered ${jail}'s jail and is banned until ${until}.
rDNS: ${rdns}
Reports:
  - https://www.abuseipdb.com/check/${ip} (abuse history & reports)
  - https://www.shodan.io/host/${ip} (open ports & services)
  - https://bgp.he.net/ip/${ip} (network & ASN info)

---------- recent log lines ----------
${logs}
EOF
)

# then we curl it straight to the server, skipping perms issues
curl --silent --show-error --connect-timeout 5 --max-time 30 \
  --url "smtp://127.0.0.1:25" \
  --mail-from "${sender}" --mail-rcpt "${dest}" --upload-file - <<<"${message}"