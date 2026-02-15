# Bash 3.2 Compatibility Checklist

**Target:** openclaw-quickstart-v2.sh  
**macOS Default Bash:** 3.2.57 (all versions: Ventura, Sonoma, Sequoia)

---

## ✅ Compatible Features (Safe to Use)

These features work in bash 3.2 and are used correctly in the script:

- [x] `set -euo pipefail` (strict error handling)
- [x] `[[ ... ]]` tests (conditional expressions)
- [x] `read -r` (read without backslash interpretation)
- [x] Heredocs (`<< EOF` and `<< 'EOF'`)
- [x] Process substitution (`<(command)`)
- [x] Command substitution (`$(command)`)
- [x] `local` keyword (function-local variables)
- [x] Indexed arrays (`array=(item1 item2)`)
- [x] `printf` for formatting
- [x] `trap` for error handling
- [x] Parameter expansion (`${var:-default}`, `${var#pattern}`)
- [x] Case statements
- [x] While/for loops
- [x] Functions

---

## ⚠️ Use With Caution (Works But Unclear)

These patterns work in bash 3.2 but may confuse readers or behave unexpectedly:

### 1. `[[ ... ]] && command` with `set -e`

**Current usage:** Lines 1114-1116, 1742, 1818

```bash
[[ "$use_case_input" == *"1"* ]] && has_content=true
```

**Status:** ✅ **WORKS** — bash 3.2 doesn't treat this as a `set -e` termination

**Issue:** Not obvious to readers that it's safe

**Better alternative:**
```bash
if [[ "$use_case_input" == *"1"* ]]; then
    has_content=true
fi
```

**Recommendation:** OPTIONAL refactor for clarity (not a bug)

---

### 2. `read -ra` without explicit IFS save/restore

**Current usage:** Lines 384, 1742, 1818

```bash
IFS=',' read -ra NUMS <<< "$input"
```

**Status:** ✅ **WORKS** — IFS change is scoped to that line

**Issue:** Not immediately clear that IFS is restored

**Better alternative:**
```bash
OLD_IFS="$IFS"
IFS=','
read -ra NUMS <<< "$input"
IFS="$OLD_IFS"
```

**Recommendation:** OPTIONAL for explicitness

---

### 3. `((arithmetic)) || true` pattern

**Current usage:** Line 212

```bash
((attempt++)) || true
```

**Status:** ✅ **CORRECT** — prevents `set -e` exit on arithmetic errors

**No change needed** — this is the right pattern

---

## ❌ Incompatible Features (Bash 4+)

These features DO NOT work in bash 3.2. The script correctly avoids them:

- [ ] Associative arrays (`declare -A array`)
  - **Used in script?** ❌ No (uses case statements instead)
  
- [ ] `&>>` redirect (redirect both stdout and stderr)
  - **Workaround:** `2>&1` or `&>/dev/null`
  - **Used in script?** ✅ Correctly uses `&>/dev/null`

- [ ] `**` globstar (recursive glob)
  - **Used in script?** ❌ No

- [ ] `read -i` (default value in prompt)
  - **Workaround:** Implement default logic manually
  - **Used in script?** ✅ Correctly implements defaults without `-i`

- [ ] Brace expansion with variables: `{$start..$end}`
  - **Used in script?** ❌ No

- [ ] `|&` (pipe stderr and stdout)
  - **Workaround:** `2>&1 |`
  - **Used in script?** ✅ Correctly uses `2>&1 |` or `&>/dev/null`

---

## Current Script Analysis

### Bash 3.2 Compliance: ✅ PASS

**No blocking incompatibilities found.**

The script uses bash 3.2 compatible syntax throughout. All modern bash features (associative arrays, etc.) are correctly avoided.

---

## Style Improvements (Optional)

These are NOT bugs, just clarity improvements:

### 1. Make `[[ ... ]] && command` more explicit

**Current:**
```bash
[[ "$use_case_input" == *"1"* ]] && has_content=true
[[ "$use_case_input" == *"2"* ]] && has_workflow=true
```

**Clearer:**
```bash
if [[ "$use_case_input" == *"1"* ]]; then has_content=true; fi
if [[ "$use_case_input" == *"2"* ]]; then has_workflow=true; fi
```

**Even clearer (multi-line):**
```bash
if [[ "$use_case_input" == *"1"* ]]; then
    has_content=true
fi
```

---

### 2. Explicit IFS handling

**Current:**
```bash
IFS=',' read -ra NUMS <<< "$input"
```

**More explicit:**
```bash
OLD_IFS="$IFS"
IFS=','
read -ra NUMS <<< "$input"
IFS="$OLD_IFS"
```

---

### 3. Add comments where bash 3.2 limits apply

Example:
```bash
# Bash 3.2 note: Using case statement instead of associative array
get_template_checksum() {
    case "$template_path" in
        "templates/AGENTS.md") echo "abc123..." ;;
        # ...
    esac
}
```

---

## Verification Steps

### 1. Confirm bash version
```bash
bash --version
# Expected: GNU bash, version 3.2.57(1)-release
```

### 2. Syntax check
```bash
bash -n openclaw-quickstart-v2.sh
# Expected: No output (silent = success)
```

### 3. Run with strict bash 3.2
```bash
/bin/bash openclaw-quickstart-v2.sh
# /bin/bash on macOS is always 3.2.57
```

### 4. ShellCheck (if available)
```bash
shellcheck -s bash openclaw-quickstart-v2.sh
# May warn about style, but should show no bash 4+ features
```

---

## Common Bash 3.2 Gotchas (Not in This Script)

For future reference, these are common mistakes when targeting bash 3.2:

### ❌ Associative arrays
```bash
# WRONG (bash 4+):
declare -A config
config[key]="value"

# RIGHT (bash 3.2):
case "$key" in
    "key1") value="value1" ;;
    "key2") value="value2" ;;
esac
```

### ❌ `read -i` for default values
```bash
# WRONG (bash 4+):
read -i "$default" -p "Enter: " value

# RIGHT (bash 3.2):
echo -n "Enter [$default]: "
read value
value="${value:-$default}"
```

### ❌ `&>>` redirect
```bash
# WRONG (bash 4+):
command &>> logfile

# RIGHT (bash 3.2):
command >> logfile 2>&1
```

---

## Testing Matrix

| Test | Command | Expected Result |
|------|---------|----------------|
| **Syntax** | `bash -n script.sh` | No errors |
| **Direct exec** | `bash script.sh` | Runs successfully |
| **Piped exec** | `cat script.sh \| bash` | Runs successfully |
| **Bash 3.2** | `/bin/bash script.sh` | Runs successfully |
| **ShellCheck** | `shellcheck script.sh` | No bash 4+ warnings |

---

## Conclusion

**Status:** ✅ **FULLY COMPATIBLE** with bash 3.2

The script correctly avoids all bash 4+ features and uses only bash 3.2 compatible syntax. The identified patterns (`[[ ... ]] && command`, `read -ra`) are **style issues**, not compatibility bugs.

**No changes required for bash 3.2 compatibility.**

**Optional:** Refactor style issues for clarity (cosmetic improvements only).
