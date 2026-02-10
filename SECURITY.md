# Security Policy

## Threat Model

This setup guide helps users configure OpenClaw — an AI agent framework that runs locally on their Mac. The threat model considers:

1. **Local attackers** — Someone with physical access to the machine
2. **Network attackers** — Someone on the same network or internet
3. **Prompt injection** — Malicious instructions embedded in content the agent processes
4. **Supply chain** — Compromised dependencies or skills

### What This Guide Protects Against

| Threat | Protection |
|--------|------------|
| Secrets in plaintext config | Environment variable references (`${VAR}`) |
| Network exposure | Localhost-only binding, mDNS disabled |
| Excessive AI permissions | Access profiles (explorer, admin, default) |
| Shell injection in scripts | Single-quoted heredocs, `sys.argv` for Python |
| Weak gateway tokens | Cryptographically random 64-char hex tokens |

### Known Limitations

**Gateway plaintext rewrite**: OpenClaw's gateway daemon resolves `${VAR}` references and writes the plaintext values back to `openclaw.json` on restart. The LaunchAgent plist is the canonical secret store, but `openclaw.json` may contain resolved secrets after gateway restart. Mitigations:
- File permissions: `chmod 600 ~/.openclaw/openclaw.json`
- Don't commit `openclaw.json` to version control
- Rotate credentials if you suspect exposure

**AI agent autonomy**: Even with restricted access profiles, AI agents can make mistakes. The guide recommends:
- Starting with the `explorer` profile (read-heavy, write-restricted)
- Reviewing agent actions before approving external communications
- Using `requireMention: true` for non-primary Discord channels

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest (main branch) | ✅ |
| Older commits | ❌ |

We recommend always using the latest version of this setup guide, as security improvements are applied incrementally.

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Instead:
1. Email security concerns to the repository maintainer
2. Include steps to reproduce
3. Allow 90 days for a fix before public disclosure

We'll acknowledge receipt within 48 hours and provide a timeline for remediation.

## Security Features in This Guide

### Secrets Architecture
- API keys stored as environment variables in LaunchAgent plist
- Config references variables with `${VAR_NAME}` syntax
- Gateway token auto-generated with `openssl rand -hex 32`

### Network Hardening
- Gateway binds to `127.0.0.1` only (no external access)
- mDNS/Bonjour advertisement disabled
- FileVault disk encryption verified

### Access Control
- Three-tier access profiles with escalating permissions
- `requireMention: true` for non-primary channels
- Browser tool denied in explorer profile

### Script Safety
- All Python code uses `sys.argv` instead of shell variable interpolation
- Single-quoted heredocs (`<< 'PYEOF'`) prevent shell expansion
- Atomic config editing with backup/restore on failure

## Security Checklist for Users

After running the setup scripts, verify:

- [ ] `openclaw.json` has permissions `600` (`ls -la ~/.openclaw/openclaw.json`)
- [ ] LaunchAgent plist contains your secrets (not `openclaw.json`)
- [ ] Gateway token is 64 characters hex
- [ ] mDNS is disabled (`OPENCLAW_DISABLE_BONJOUR=1` in plist)
- [ ] FileVault is enabled (`fdesetup status`)
- [ ] Only primary Discord channel has `requireMention: false`

## CVE References

The security hardening in this guide addresses patterns related to:

| Issue | Description | Mitigation |
|-------|-------------|------------|
| CWE-78 | OS command injection | Single-quoted heredocs, sys.argv |
| CWE-256 | Plaintext storage of credentials | Environment variable references |
| CWE-200 | Information exposure | Localhost binding, mDNS disabled |
| CWE-732 | Incorrect permission assignment | chmod 600 on sensitive files |

## Resources

- [OpenClaw Security Documentation](https://docs.openclaw.ai/security)
- [The Bot Father: Security Lessons](https://steipete.me/posts/the-bot-father) — Article that inspired many of these hardening steps
- [OWASP AI Security Guidelines](https://owasp.org/www-project-ai-security/)

---

Security is a process, not a destination. If you find ways to improve this guide's security posture, please contribute!
