#!/bin/bash
# update.sh — Update the AI Earns Its Keep P&L dashboard
# Usage:
#   ./update.sh revenue <product_name> <amount>     # Record new revenue
#   ./update.sh cost <amount>                        # Add to costs
#   ./update.sh status <product_name> <status>       # Update product status
#   ./update.sh publish                              # Push to GitHub Pages
#
# Examples:
#   ./update.sh revenue "Azure Flame" 4.00
#   ./update.sh revenue "Zenn Book" 5.45
#   ./update.sh status "Claude Code Production Guide" live
#   ./update.sh publish

set -e
DATA_FILE="$(dirname "$0")/data.json"

case "$1" in
  revenue)
    PRODUCT="$2"
    AMOUNT="$3"
    if [ -z "$PRODUCT" ] || [ -z "$AMOUNT" ]; then
      echo "Usage: $0 revenue <product_name> <amount>"
      exit 1
    fi
    # Update product revenue and total
    NEW_TOTAL=$(python3 -c "
import json, sys
d = json.load(open('$DATA_FILE'))
for p in d['products']:
    if p['name'] == '$PRODUCT':
        p['revenue_usd'] = round(p['revenue_usd'] + float('$AMOUNT'), 2)
        print(f'Updated {p[\"name\"]}: now \${p[\"revenue_usd\"]}', file=sys.stderr)
d['finances']['total_revenue_usd'] = round(sum(p['revenue_usd'] for p in d['products']), 2)
d['meta']['updated'] = '$(date +%Y-%m-%d)'
print(json.dumps(d, indent=2, ensure_ascii=False))
")
    echo "$NEW_TOTAL" > "$DATA_FILE"
    echo "✓ Revenue updated. New total: \$(python3 -c \"import json; d=json.load(open('$DATA_FILE')); print(d['finances']['total_revenue_usd'])\")"
    ;;
  status)
    PRODUCT="$2"
    STATUS="$3"
    python3 -c "
import json
d = json.load(open('$DATA_FILE'))
for p in d['products']:
    if p['name'] == '$PRODUCT':
        p['status'] = '$STATUS'
        print(f'Updated status of {p[\"name\"]} to $STATUS')
d['meta']['updated'] = '$(date +%Y-%m-%d)'
with open('$DATA_FILE', 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
"
    ;;
  cost)
    AMOUNT="$2"
    python3 -c "
import json
d = json.load(open('$DATA_FILE'))
d['finances']['total_cost_usd'] = round(d['finances']['total_cost_usd'] + float('$AMOUNT'), 2)
d['meta']['updated'] = '$(date +%Y-%m-%d)'
with open('$DATA_FILE', 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
print(f'Total cost now: \${d[\"finances\"][\"total_cost_usd\"]}')
"
    ;;
  publish)
    cd "$(dirname "$0")"
    # Rebuild the HTML with current data
    TOTAL_COST=$(python3 -c "import json; d=json.load(open('data.json')); print(d['finances']['total_cost_usd'])")
    TOTAL_REV=$(python3 -c "import json; d=json.load(open('data.json')); print(d['finances']['total_revenue_usd'])")
    echo "Publishing: Cost=\$$TOTAL_COST, Revenue=\$$TOTAL_REV"
    git add .
    git commit -m "chore: update P&L data (revenue: \$$TOTAL_REV, cost: \$$TOTAL_COST)" || echo "Nothing to commit"
    git push
    echo "✓ Published to https://yurukusa.github.io/ai-earns-its-keep/"
    ;;
  *)
    echo "Usage: $0 {revenue|cost|status|publish} [args]"
    echo "  revenue <product> <amount>  — add revenue to a product"
    echo "  cost <amount>               — add to total cost"
    echo "  status <product> <status>   — update product status (live/free/pending/draft)"
    echo "  publish                     — commit and push to GitHub Pages"
    ;;
esac
