# Email Domain Authentication & Deliverability Audit Script

`check-email-dns.sh` is a comprehensive Bash script that audits a domain (and optionally a subdomain) for modern email authentication, security, and brand visibility readiness.

## ✅ What It Checks

| Category | Checks | Details |
|----------|--------|---------|
| SPF | Presence + Providers | Detects inclusion of AWS SES, Google Workspace, Microsoft 365, Mailgun, SendGrid, Mailchimp |
| DKIM | Presence via selectors | Tries common selectors: `default, dkim, google, k1, s1, s2, selector1, selector2, resend, mailgun, sendgrid, mandrill, amazonses` |
| MX | Delivery capability | Lists MX and identifies common providers or custom setup |
| DMARC | Policy + existence | Warns if missing, suggests starter record with explanations |
| TLS | Opportunistic encryption | Infers TLS support based on MX (Google, AWS, Outlook, etc.) |
| BIMI | Brand Indicators | Tries selectors: `default, selector, v1, bimi`; gives requirements if missing |
| MTA-STS | Strict TLS transport | Checks `_mta-sts` TXT presence and policy hosting guidance |
| TLS-RPT | TLS reporting | Checks `_smtp._tls` TXT record for `v=TLSRPTv1` |
| Spam Complaint Rate | Guidance | Links to Google Postmaster (manual metric) |
| Domain Reputation | External | Links to Postmaster, SNDS, Talos, MXToolbox |

## 🧪 Usage

```bash
# Basic (root domain)
./check-email-dns.sh example.com

# Domain + subdomain (checks both)
./check-email-dns.sh example.com mail

# Show help
./check-email-dns.sh
```

If you pass a subdomain (`mail.example.com` style via `example.com mail`), the script:

1. Audits the subdomain
2. Audits the parent domain
3. Shows two separate summaries

## 📥 Installation

```bash
curl -O https://raw.githubusercontent.com/your-org/your-repo/main/check-email-dns.sh
chmod +x check-email-dns.sh
./check-email-dns.sh example.com
```
(Replace repo path after publishing.)

## 🧾 Sample Output (Excerpt)

```text
Email DNS Verification for: example.com

🔍 Checking SPF for domain...
✅ SPF found:
   "v=spf1 include:_spf.google.com include:amazonses.com ~all"
   ✓ Includes Google Workspace
   ✓ Includes AWS SES (Amazon)

🔍 Checking DKIM for domain...
✅ DKIM found (selector: google):
   "v=DKIM1; k=rsa; p=MIIBIjANBg..."

🔍 Checking DMARC for domain...
⚠️  DMARC not found (optional but recommended)
   Cloudflare Configuration:
   Type: TXT
   Name: _dmarc
   Value: v=DMARC1; p=none; rua=mailto:dmarc@example.com; pct=100; fo=1
```


## 🧠 Interpreting Results

| Indicator | Meaning | Action |
|-----------|---------|--------|
| ❌ SPF missing | No sender authorization | Add SPF TXT record |
| ❌ DKIM missing | No cryptographic signing | Enable DKIM in provider panel |
| ⚠️ DMARC not configured | Reduced trust + no reporting | Start with `p=none` then move to `quarantine` / `reject` |
| ⚠️ BIMI not configured | No logo in inbox | Optional; consider when marketing maturity increases |
| ⚠️ MTA-STS missing | TLS downgrade risk | Add `_mta-sts` + host policy file |
| ⚠️ TLS-RPT missing | No TLS failure insights | Add `_smtp._tls` record |
| ❌ MX missing | Cannot receive email | Add provider MX records |

## 🪪 BIMI Requirements (Summary)

1. DMARC with `p=quarantine` or `p=reject`
2. Valid SVG Tiny PS logo (<32KB)
3. (Optional but required for Gmail) VMC (Verified Mark Certificate)
4. DNS TXT: `default._bimi` with `v=BIMI1; l=<logo_url>; a=<vmc_url>`

## 🔐 MTA-STS Quick Start

1. DNS TXT `_mta-sts`: `v=STSv1; id=20250101`
2. Host policy file at: `https://mta-sts.example.com/.well-known/mta-sts.txt`

```text
version: STSv1
mode: enforce
mx: *.example.com
max_age: 86400
```

## 📨 TLS-RPT Record Example

```text
Host: _smtp._tls.example.com
Type: TXT
Value: v=TLSRPTv1; rua=mailto:tls-reports@example.com
```

## 🚦 Roadmap Ideas

- DNS over DoH fallback
- JSON / machine-readable output mode (`--json`)
- Optional live STARTTLS capability probe (via `openssl s_client`)
- DKIM selector enumeration flag (`--all-selectors`)
- Silent / CI mode (`--quiet`)

## ⚠️ Limitations

- Does not perform live SMTP handshakes (heuristic TLS inference)
- Spam complaint & reputation metrics require external consoles
- Cannot verify VMC certificate contents
- Assumes `dig` is installed (install via `bind-utils` / `dnsutils`)

## ✅ Requirements

- Bash 4+
- `dig` available (`apt install dnsutils` / `yum install bind-utils`)

## 🤝 Contributing

1. Fork
2. Create feature branch: `git checkout -b feat/json-output`
3. Commit: `git commit -m "feat: add JSON output mode"`
4. Push & open PR

## 📄 License

MIT (add a `LICENSE` file if distributing publicly).

---
Made to quickly audit email readiness across domains and subdomains. Improve deliverability with confidence.
