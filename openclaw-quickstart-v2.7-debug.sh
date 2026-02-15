# THIS IS A PARTIAL FIX - WATSON IS WRITING THE FULL VERSION
# Inserting after line 28 (after set -euo pipefail):

# ERROR TRAPPING - catch silent exits
trap 'echo -e "\n${RED}❌ Script failed at line $LINENO. Last command: $BASH_COMMAND${NC}" >&2' ERR
trap 'echo -e "\n${YELLOW}⚠️  Setup interrupted. Run again to continue.${NC}"' INT TERM

# Rest of script follows...
