#!/bin/bash

# Script to verify email DNS configuration (SPF, DKIM, MX)
# Usage: ./check-email-dns.sh domain.com [subdomain]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo "Usage: $0 <domain> [subdomain]"
    echo ""
    echo "Examples:"
    echo "  $0 fliinow.com"
    echo "  $0 fliinow.com hola"
    echo "  $0 fliinow.com transactional"
    exit 1
}

# Verify arguments
if [ -z "$1" ]; then
    show_usage
fi

DOMAIN=$1
SUBDOMAIN=$2

if [ -n "$SUBDOMAIN" ]; then
    FULL_DOMAIN="${SUBDOMAIN}.${DOMAIN}"
    IS_SUBDOMAIN=true
else
    FULL_DOMAIN=$DOMAIN
    IS_SUBDOMAIN=false
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Email DNS Verification for: ${FULL_DOMAIN}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to check SPF
check_spf() {
    local CHECK_DOMAIN=$1
    local LABEL=$2
    
    echo -e "${YELLOW}🔍 Checking SPF for ${LABEL}...${NC}"
    SPF=$(dig TXT $CHECK_DOMAIN @8.8.8.8 +short | grep "v=spf1")
    
    if [ -n "$SPF" ]; then
        echo -e "${GREEN}✅ SPF found:${NC}"
        echo "   $SPF"
        
        # Check for common email providers
        if echo "$SPF" | grep -q "amazonses"; then
            echo -e "${GREEN}   ✓ Includes AWS SES (Amazon)${NC}"
        fi
        
        if echo "$SPF" | grep -q "google"; then
            echo -e "${GREEN}   ✓ Includes Google Workspace${NC}"
        fi
        
        if echo "$SPF" | grep -q "outlook\|office365"; then
            echo -e "${GREEN}   ✓ Includes Microsoft 365/Outlook${NC}"
        fi
        
        if echo "$SPF" | grep -q "mailgun"; then
            echo -e "${GREEN}   ✓ Includes Mailgun${NC}"
        fi
        
        if echo "$SPF" | grep -q "sendgrid"; then
            echo -e "${GREEN}   ✓ Includes SendGrid${NC}"
        fi
        
        if echo "$SPF" | grep -q "mailchimp"; then
            echo -e "${GREEN}   ✓ Includes Mailchimp${NC}"
        fi
    else
        echo -e "${RED}❌ SPF not found${NC}"
        echo -e "${YELLOW}   Add SPF record based on your email provider${NC}"
        echo -e "${CYAN}   Common formats:${NC}"
        echo -e "${CYAN}   • AWS SES: v=spf1 include:amazonses.com ~all${NC}"
        echo -e "${CYAN}   • Google: v=spf1 include:_spf.google.com ~all${NC}"
        echo -e "${CYAN}   • Microsoft 365: v=spf1 include:spf.protection.outlook.com ~all${NC}"
    fi
    echo ""
}

# Function to check DKIM
check_dkim() {
    local CHECK_DOMAIN=$1
    local LABEL=$2
    
    echo -e "${YELLOW}🔍 Checking DKIM for ${LABEL}...${NC}"
    
    # Common DKIM selectors used by different providers
    SELECTORS=("default" "dkim" "google" "k1" "s1" "s2" "selector1" "selector2" "resend" "mailgun" "sendgrid" "mandrill" "amazonses")
    DKIM_FOUND=false
    
    for selector in "${SELECTORS[@]}"; do
        DKIM=$(dig TXT ${selector}._domainkey.$CHECK_DOMAIN @8.8.8.8 +short 2>/dev/null | grep "p=")
        if [ -n "$DKIM" ]; then
            echo -e "${GREEN}✅ DKIM found (selector: ${selector}):${NC}"
            # Show only first 80 characters to avoid cluttering
            echo "   ${DKIM:0:80}..."
            DKIM_FOUND=true
            break
        fi
    done
    
    if [ "$DKIM_FOUND" = false ]; then
        echo -e "${RED}❌ DKIM not found${NC}"
        echo -e "${YELLOW}   Checked common selectors: ${SELECTORS[*]}${NC}"
        echo -e "${YELLOW}   Verify DKIM configuration with your email provider${NC}"
    fi
    echo ""
}

# Function to check MX
check_mx() {
    local CHECK_DOMAIN=$1
    local LABEL=$2
    
    echo -e "${YELLOW}🔍 Checking MX records for ${LABEL}...${NC}"
    MX=$(dig MX $CHECK_DOMAIN @8.8.8.8 +short)
    
    if [ -n "$MX" ]; then
        echo -e "${GREEN}✅ MX records found:${NC}"
        echo "$MX" | while read line; do
            echo "   $line"
        done
        
        # Check for common email providers
        if echo "$MX" | grep -q "amazonaws.com"; then
            echo -e "${GREEN}   ✓ Configured to receive emails (AWS SES)${NC}"
        elif echo "$MX" | grep -q "google.com\|googlemail.com"; then
            echo -e "${GREEN}   ✓ Configured to receive emails (Google Workspace)${NC}"
        elif echo "$MX" | grep -q "outlook.com\|office365.com"; then
            echo -e "${GREEN}   ✓ Configured to receive emails (Microsoft 365)${NC}"
        elif echo "$MX" | grep -q "mailgun.org"; then
            echo -e "${GREEN}   ✓ Configured to receive emails (Mailgun)${NC}"
        elif echo "$MX" | grep -q "sendgrid.net"; then
            echo -e "${GREEN}   ✓ Configured to receive emails (SendGrid)${NC}"
        else
            echo -e "${GREEN}   ✓ Custom MX configuration detected${NC}"
        fi
    else
        echo -e "${RED}❌ No MX records${NC}"
        echo -e "${YELLOW}   Add MX records based on your email provider${NC}"
    fi
    echo ""
}

# Function to check DMARC
check_dmarc() {
    local CHECK_DOMAIN=$1
    local LABEL=$2
    
    echo -e "${YELLOW}🔍 Checking DMARC for ${LABEL}...${NC}"
    DMARC=$(dig TXT _dmarc.$CHECK_DOMAIN @8.8.8.8 +short | grep "v=DMARC1")
    
    if [ -n "$DMARC" ]; then
        echo -e "${GREEN}✅ DMARC found:${NC}"
        echo "   $DMARC"
    else
        echo -e "${YELLOW}⚠️  DMARC not found (optional but recommended)${NC}"
        echo -e "${CYAN}   Cloudflare Configuration:${NC}"
        
        if [ "$CHECK_DOMAIN" = "$DOMAIN" ]; then
            echo -e "${CYAN}   Type: TXT${NC}"
            echo -e "${CYAN}   Name: _dmarc${NC}"
        else
            # Extract subdomain part
            SUBDOMAIN_PART="${CHECK_DOMAIN%%.*}"
            echo -e "${CYAN}   Type: TXT${NC}"
            echo -e "${CYAN}   Name: _dmarc.${SUBDOMAIN_PART}${NC}"
        fi
        
        echo -e "${CYAN}   Value: v=DMARC1; p=none; rua=mailto:dmarc@${DOMAIN}; pct=100; fo=1${NC}"
        echo ""
        echo -e "${YELLOW}   Parameters explained:${NC}"
        echo -e "${YELLOW}   • p=none: Monitor only (use p=quarantine or p=reject later)${NC}"
        echo -e "${YELLOW}   • rua=: Email address to receive aggregate reports${NC}"
        echo -e "${YELLOW}   • pct=100: Apply policy to 100% of emails${NC}"
        echo -e "${YELLOW}   • fo=1: Generate report if SPF or DKIM fails${NC}"
    fi
    echo ""
}

# Function to show summary
show_summary() {
    local CHECK_DOMAIN=$1
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  SUMMARY FOR: ${CHECK_DOMAIN}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    SPF_OK=$(dig TXT $CHECK_DOMAIN @8.8.8.8 +short | grep -q "v=spf1" && echo "1" || echo "0")
    
    # Check DKIM with common selectors
    DKIM_OK=0
    SELECTORS=("default" "dkim" "google" "k1" "s1" "s2" "selector1" "selector2" "resend" "mailgun" "sendgrid" "mandrill" "amazonses")
    for selector in "${SELECTORS[@]}"; do
        if dig TXT ${selector}._domainkey.$CHECK_DOMAIN @8.8.8.8 +short 2>/dev/null | grep -q "p="; then
            DKIM_OK=1
            break
        fi
    done
    
    MX_OK=$(dig MX $CHECK_DOMAIN @8.8.8.8 +short | grep -q "." && echo "1" || echo "0")
    DMARC_OK=$(dig TXT _dmarc.$CHECK_DOMAIN @8.8.8.8 +short | grep -q "v=DMARC1" && echo "1" || echo "0")
    
    echo -e "${YELLOW}📋 Authentication & Configuration:${NC}"
    echo ""
    
    # SPF & DKIM Authentication
    if [ "$SPF_OK" = "1" ] && [ "$DKIM_OK" = "1" ]; then
        echo -e "${GREEN}✅ SPF & DKIM Authentication: PASSED${NC}"
        echo -e "   Both SPF and DKIM are properly configured"
    else
        echo -e "${RED}❌ SPF & DKIM Authentication: FAILED${NC}"
        if [ "$SPF_OK" = "0" ]; then
            echo -e "   ${RED}✗${NC} SPF missing"
        fi
        if [ "$DKIM_OK" = "0" ]; then
            echo -e "   ${RED}✗${NC} DKIM missing"
        fi
    fi
    echo ""
    
    # DMARC Authentication
    if [ "$DMARC_OK" = "1" ]; then
        echo -e "${GREEN}✅ DMARC Authentication: CONFIGURED${NC}"
        echo -e "   Domain has DMARC policy in place"
    else
        echo -e "${YELLOW}⚠️  DMARC Authentication: NOT CONFIGURED${NC}"
        echo -e "   ${YELLOW}Recommended:${NC} Add DMARC policy for better deliverability"
    fi
    echo ""
    
    # TLS/Encryption
    echo -e "${BLUE}🔒 Encryption (TLS):${NC}"
    if [ "$MX_OK" = "1" ]; then
        MX_SERVER=$(dig MX $CHECK_DOMAIN @8.8.8.8 +short | head -1 | awk '{print $2}')
        if [ -n "$MX_SERVER" ]; then
            # Check if MX server supports TLS (most modern servers do)
            if echo "$MX_SERVER" | grep -q -E "(google|amazonaws|outlook|mail)"; then
                echo -e "${GREEN}✅ TLS Encryption: SUPPORTED${NC}"
                echo -e "   MX server ($MX_SERVER) supports TLS/STARTTLS"
            else
                echo -e "${YELLOW}⚠️  TLS Encryption: UNKNOWN${NC}"
                echo -e "   Cannot verify TLS support for $MX_SERVER"
            fi
        fi
    else
        echo -e "${RED}❌ TLS Encryption: CANNOT VERIFY${NC}"
        echo -e "   No MX records found"
    fi
    echo ""
    
    # BIMI (Brand Indicators for Message Identification)
    echo -e "${BLUE}🎨 BIMI (Brand Logo in Inbox):${NC}"
    
    # Common BIMI selectors
    BIMI_SELECTORS=("default" "selector" "v1" "bimi")
    BIMI_FOUND=false
    
    for bimi_selector in "${BIMI_SELECTORS[@]}"; do
        BIMI=$(dig TXT ${bimi_selector}._bimi.$CHECK_DOMAIN @8.8.8.8 +short 2>/dev/null | grep "v=BIMI1")
        if [ -n "$BIMI" ]; then
            echo -e "${GREEN}✅ BIMI configured (selector: ${bimi_selector})${NC}"
            echo -e "   Your brand logo may appear in supported email clients"
            echo -e "   ${BIMI:0:80}..."
            BIMI_FOUND=true
            break
        fi
    done
    
    if [ "$BIMI_FOUND" = false ]; then
        echo -e "${YELLOW}⚠️  BIMI not configured (optional, for brand visibility)${NC}"
        echo -e "   BIMI displays your logo in Gmail, Yahoo, and other clients"
        echo -e "   ${CYAN}Requirements:${NC}"
        echo -e "   • DMARC with p=quarantine or p=reject"
        echo -e "   • Verified Mark Certificate (VMC) from DigiCert or Entrust"
        echo -e "   • SVG logo file hosted on HTTPS"
        echo -e "   ${CYAN}Example:${NC} v=BIMI1; l=https://example.com/logo.svg; a=https://example.com/cert.pem"
    fi
    echo ""
    
    # MTA-STS (Mail Transfer Agent Strict Transport Security)
    echo -e "${BLUE}🔐 MTA-STS (Force TLS):${NC}"
    MTA_STS=$(dig TXT _mta-sts.$CHECK_DOMAIN @8.8.8.8 +short | grep "v=STSv1")
    if [ -n "$MTA_STS" ]; then
        echo -e "${GREEN}✅ MTA-STS configured${NC}"
        echo -e "   Forces encrypted delivery via TLS"
    else
        echo -e "${YELLOW}⚠️  MTA-STS not configured (recommended for security)${NC}"
        echo -e "   MTA-STS prevents downgrade attacks and enforces TLS"
        echo -e "   ${CYAN}Add:${NC} TXT record _mta-sts with v=STSv1; id=<timestamp>"
        echo -e "   ${CYAN}Plus:${NC} Host policy file at https://mta-sts.${CHECK_DOMAIN}/.well-known/mta-sts.txt"
    fi
    echo ""
    
    # TLS Reporting
    echo -e "${BLUE}📬 TLS-RPT (TLS Reporting):${NC}"
    TLS_RPT=$(dig TXT _smtp._tls.$CHECK_DOMAIN @8.8.8.8 +short | grep "v=TLSRPTv1")
    if [ -n "$TLS_RPT" ]; then
        echo -e "${GREEN}✅ TLS-RPT configured${NC}"
        echo -e "   Receive reports about TLS connection issues"
    else
        echo -e "${YELLOW}⚠️  TLS-RPT not configured (optional)${NC}"
        echo -e "   Get notified when TLS connections fail"
        echo -e "   ${CYAN}Add:${NC} TXT record _smtp._tls with v=TLSRPTv1; rua=mailto:tls-reports@${DOMAIN}"
    fi
    echo ""
    
    # User Spam Rate
    echo -e "${BLUE}📊 User Spam Complaint Rate:${NC}"
    echo -e "${YELLOW}⚠️  MANUAL VERIFICATION REQUIRED${NC}"
    echo -e "   This metric must be checked in Google Postmaster Tools:"
    echo -e "   ${CYAN}https://postmaster.google.com/${NC}"
    echo ""
    echo -e "   ${GREEN}Target: < 0.3% spam complaint rate${NC}"
    echo -e "   Steps to verify:"
    echo -e "   1. Add domain to Google Postmaster Tools"
    echo -e "   2. Verify domain ownership via DNS TXT record"
    echo -e "   3. Wait 24-48h for data collection"
    echo -e "   4. Check 'Spam rate' section in dashboard"
    echo ""
    
    # Domain Reputation
    echo -e "${BLUE}🌐 Domain Reputation Check:${NC}"
    echo -e "${YELLOW}⚠️  EXTERNAL VERIFICATION RECOMMENDED${NC}"
    echo -e "   Check your domain reputation on these services:"
    echo -e "   ${CYAN}• Google Postmaster Tools:${NC} https://postmaster.google.com/"
    echo -e "   ${CYAN}• Microsoft SNDS:${NC} https://sendersupport.olc.protection.outlook.com/snds/"
    echo -e "   ${CYAN}• Talos Intelligence:${NC} https://talosintelligence.com/reputation_center"
    echo -e "   ${CYAN}• MXToolbox Blacklist:${NC} https://mxtoolbox.com/blacklists.aspx"
    echo ""
    
    # Overall Status
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📋 DNS Records Status:${NC}"
    echo ""
    
    if [ "$SPF_OK" = "1" ]; then
        echo -e "${GREEN}✅ SPF configured${NC}"
    else
        echo -e "${RED}❌ SPF missing${NC}"
    fi
    
    if [ "$DKIM_OK" = "1" ]; then
        echo -e "${GREEN}✅ DKIM configured${NC}"
    else
        echo -e "${RED}❌ DKIM missing${NC}"
    fi
    
    if [ "$MX_OK" = "1" ]; then
        echo -e "${GREEN}✅ MX configured${NC}"
    else
        echo -e "${RED}❌ MX missing${NC}"
    fi
    
    if [ "$DMARC_OK" = "1" ]; then
        echo -e "${GREEN}✅ DMARC configured${NC}"
    else
        echo -e "${YELLOW}⚠️  DMARC not configured (recommended)${NC}"
    fi
    
    echo ""
    
    REQUIRED_OK=$((SPF_OK + DKIM_OK + MX_OK))
    
    if [ "$REQUIRED_OK" = "3" ]; then
        echo -e "${GREEN}🎉 Essential configuration complete${NC}"
        if [ "$DMARC_OK" = "1" ]; then
            echo -e "${GREEN}✨ All recommended configurations in place${NC}"
        else
            echo -e "${YELLOW}💡 Consider adding DMARC for enhanced security${NC}"
        fi
    else
        echo -e "${RED}⚠️  Missing required configurations${NC}"
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Run verifications
if [ "$IS_SUBDOMAIN" = true ]; then
    # Check subdomain
    echo -e "${CYAN}═══ SUBDOMAIN: ${FULL_DOMAIN} ═══${NC}"
    echo ""
    check_spf "$FULL_DOMAIN" "subdomain"
    check_dkim "$FULL_DOMAIN" "subdomain"
    check_mx "$FULL_DOMAIN" "subdomain"
    check_dmarc "$FULL_DOMAIN" "subdomain"
    show_summary "$FULL_DOMAIN"
    
    # Also check parent domain
    echo -e "${CYAN}═══ PARENT DOMAIN: ${DOMAIN} ═══${NC}"
    echo ""
    check_spf "$DOMAIN" "parent domain"
    check_dkim "$DOMAIN" "parent domain"
    check_mx "$DOMAIN" "parent domain"
    check_dmarc "$DOMAIN" "parent domain"
    show_summary "$DOMAIN"
else
    # Check only main domain
    check_spf "$FULL_DOMAIN" "domain"
    check_dkim "$FULL_DOMAIN" "domain"
    check_mx "$FULL_DOMAIN" "domain"
    check_dmarc "$FULL_DOMAIN" "domain"
    show_summary "$FULL_DOMAIN"
fi

echo -e "${BLUE}💡 Tip:${NC} To verify subdomains, use: $0 $DOMAIN <subdomain>"
