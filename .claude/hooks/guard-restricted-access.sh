#!/bin/bash

# Guard hook for Claude Code (PreToolUse)
# Blocks: iMessage/SMS access, CLAUDE.md modifications, blacklisted sites
# Add domains to BLACKLISTED_SITES array to block WebFetch/curl access.

INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
URL=$(echo "$INPUT" | jq -r '.tool_input.url // empty')

# --- Blacklisted sites ---
BLACKLISTED_SITES=(
  # ===================== Financial Institutions =====================

  # -- Banks (Major US) --
  "chase.com"
  "jpmorganchase.com"
  "bankofamerica.com"
  "bofa.com"
  "wellsfargo.com"
  "citibank.com"
  "citi.com"
  "usbank.com"
  "truist.com"
  "pnc.com"
  "capitalone.com"
  "tdbank.com"
  "td.com"
  "fifththird.com"
  "citizensbank.com"
  "regions.com"
  "key.com"
  "keybank.com"
  "huntington.com"
  "mtb.com"
  "bmo.com"
  "bmoharris.com"
  "ally.com"
  "allybank.com"
  "discover.com"
  "discoverbank.com"
  "synchrony.com"
  "synchronybank.com"
  "marcus.com"
  "goldmansachs.com"
  "morganstanley.com"
  "americanexpress.com"
  "amex.com"

  # -- Banks (Online / Neo) --
  "sofi.com"
  "chime.com"
  "current.com"
  "varo.com"
  "varomoney.com"
  "monzo.com"
  "revolut.com"
  "n26.com"

  # -- Credit Unions --
  "navyfederal.org"
  "nfcu.org"
  "penfed.org"
  "alliantcreditunion.org"
  "becu.org"

  # -- Brokerage / Investing --
  "fidelity.com"
  "schwab.com"
  "etrade.com"
  "tdameritrade.com"
  "thinkorswim.com"
  "vanguard.com"
  "robinhood.com"
  "interactivebrokers.com"
  "ibkr.com"
  "merrilledge.com"
  "ml.com"
  "merrilllynch.com"
  "edwardjones.com"
  "scottrade.com"
  "firstrade.com"
  "webull.com"
  "tastyworks.com"
  "tastytrade.com"
  "public.com"
  "m1finance.com"
  "betterment.com"

  # -- Wealth Management / Robo-Advisors --
  "wealthfront.com"
  "personalcapital.com"
  "empower.com"
  "wealthsimple.com"
  "ellevest.com"
  "acorns.com"

  # -- Payroll / HR / Benefits --
  "adp.com"
  "paychex.com"
  "gusto.com"
  "rippling.com"
  "justworks.com"
  "paylocity.com"
  "paycom.com"
  "adpworkforcenow.com"

  # -- Payments / Fintech --
  "paypal.com"
  "venmo.com"
  "zelle.com"
  "stripe.com"
  "square.com"
  "squareup.com"
  "cashapp.com"
  "wise.com"
  "transferwise.com"
  "plaid.com"

  # -- Lending / Mortgage --
  "lendingclub.com"
  "prosper.com"
  "upstart.com"
  "rocketmortgage.com"
  "quickenloans.com"
  "loandepot.com"
  "better.com"
  "figure.com"

  # -- Insurance --
  "geico.com"
  "progressive.com"
  "statefarm.com"
  "allstate.com"
  "usaa.com"
  "lemonade.com"
  "metlife.com"
  "prudential.com"
  "newyorklife.com"
  "northwestern.com"
  "northwesternmutual.com"
  "nationwide.com"
  "libertymutual.com"

  # -- Tax / Accounting --
  "turbotax.com"
  "intuit.com"
  "hrblock.com"
  "taxact.com"
  "freetaxusa.com"

  # -- Crypto Exchanges --
  "coinbase.com"
  "kraken.com"
  "gemini.com"
  "binance.com"
  "binance.us"
  "crypto.com"
  "ftx.com"
  "blockchain.com"

  # -- Credit Reporting --
  "experian.com"
  "equifax.com"
  "transunion.com"
  "annualcreditreport.com"
  "creditkarma.com"
  "myfico.com"

  # ===================== Social Media (except Reddit) =====================
  "facebook.com"
  "fb.com"
  "meta.com"
  "instagram.com"
  "twitter.com"
  "x.com"
  "tiktok.com"
  "snapchat.com"
  "pinterest.com"
  "linkedin.com"
  "tumblr.com"
  "threads.net"
  "mastodon.social"
  "bsky.app"
  "bluesky.com"
  "discord.com"
  "discordapp.com"
  "twitch.tv"
  "youtube.com"
  "youtu.be"
  "whatsapp.com"
  "telegram.org"
  "t.me"
  "signal.org"
  "wechat.com"
  "weibo.com"
  "nextdoor.com"
  "quora.com"
  # reddit.com — ALLOWED
)

# =============================================================================
# 1. Block iMessage / SMS access
# =============================================================================
if [ "$TOOL_NAME" = "Bash" ] && [ -n "$COMMAND" ]; then
  # Block osascript targeting Messages
  if echo "$COMMAND" | grep -qiE 'osascript.*messages|osascript.*imessage|osascript.*sms'; then
    echo "BLOCKED: Access to iMessage/SMS via osascript is not permitted." >&2
    exit 2
  fi

  # Block direct access to Messages database
  if echo "$COMMAND" | grep -qiE 'chat\.db|Library/Messages|imessage'; then
    echo "BLOCKED: Access to the iMessage/SMS database is not permitted." >&2
    exit 2
  fi

  # Block shortcuts that could send messages
  if echo "$COMMAND" | grep -qiE 'shortcuts\s+run.*send.*message'; then
    echo "BLOCKED: Sending messages via Shortcuts is not permitted." >&2
    exit 2
  fi
fi

# =============================================================================
# 2. Block modifications to CLAUDE.md
# =============================================================================
if [ "$TOOL_NAME" = "Edit" ] || [ "$TOOL_NAME" = "Write" ]; then
  if [ -n "$FILE_PATH" ] && echo "$FILE_PATH" | grep -qE '(^|/)CLAUDE\.md$'; then
    echo "BLOCKED: Modifications to CLAUDE.md require explicit user permission.
Ask the user before editing CLAUDE.md." >&2
    exit 2
  fi
fi

# =============================================================================
# 3. Block blacklisted sites (WebFetch and curl/wget in Bash)
# =============================================================================
if [ ${#BLACKLISTED_SITES[@]} -gt 0 ]; then
  # Check WebFetch URLs
  if [ "$TOOL_NAME" = "WebFetch" ] && [ -n "$URL" ]; then
    for domain in "${BLACKLISTED_SITES[@]}"; do
      if echo "$URL" | grep -qiF "$domain"; then
        echo "BLOCKED: Access to $domain is not permitted (blacklisted site)." >&2
        exit 2
      fi
    done
  fi

  # Check curl/wget in Bash commands
  if [ "$TOOL_NAME" = "Bash" ] && [ -n "$COMMAND" ]; then
    if echo "$COMMAND" | grep -qiE 'curl|wget'; then
      for domain in "${BLACKLISTED_SITES[@]}"; do
        if echo "$COMMAND" | grep -qiF "$domain"; then
          echo "BLOCKED: Access to $domain is not permitted (blacklisted site)." >&2
          exit 2
        fi
      done
    fi
  fi
fi

# All checks passed
exit 0
