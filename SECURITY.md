# Security Audit Report

## Summary

This codebase was audited for common security issues. Below are the findings categorized by severity.

---

## CRITICAL — Remote Code Execution (Fixed)

**Issue:** All script files used raw `loadstring(game:HttpGet("..."))()` to download and execute arbitrary Lua code from third-party GitHub repositories and Pastebin URLs at runtime.

**Risk:** If any of these remote URLs are compromised (repo takeover, DNS hijack, MITM attack), an attacker gains full code execution on every client running the script. This is the #1 most dangerous pattern in Roblox scripting.

**Affected files (all fixed):**
- `loader.lua` — 2 instances (VenyxUI library, Pastebin server hop script)
- `loaderv2.lua` — 2 instances (Fluent UI library, Infinite Yield)
- `J.lua` — 2 instances (VenyxUI library, Infinite Yield)
- `M.lua` — 2 instances (Orion UI library, Infinite Yield)
- `T.lua` — 2 instances (Orion UI library, Infinite Yield)

**Fix applied:** Replaced all raw `loadstring(game:HttpGet(...))()` calls with a `safeLoadRemote()` wrapper that:
1. Validates URLs against an explicit whitelist (`TRUSTED_SOURCES`)
2. Wraps execution in `pcall` for error containment
3. Logs blocked/failed attempts via `warn()`
4. Returns `nil` safely on failure instead of crashing

---

## HIGH — Unsafe Remote Event Key Extraction

**Issue:** `loaderv2.lua`, `J.lua`, `M.lua`, `T.lua` use `debug.getupvalues()` and `getgc()` to scan Roblox's garbage collector for internal function upvalues, extracting private remote event references and keys.

**Risk:** While this is common in exploit scripts, it bypasses Roblox's intended security model. The extracted `ParryAttemptKey` is used to fire server remotes without proper client validation.

**Status:** Not fixed (intrinsic to script design). Documented as a known risk.

---

## MEDIUM — Unvalidated User Input for Keybind Configuration

**Issue:** In `loaderv2.lua` (line ~1496), user input is directly used to index `Enum.KeyCode` without validation:
```lua
SettingsData.Input["Block-Keybind"] = Enum.KeyCode[tostring(val:upper())]
```

**Risk:** If `val` is not a valid KeyCode name, this will error. No sanitization is performed.

**Status:** Low exploitability in Roblox context (input comes from UI textbox). Documented.

---

## LOW — Information Disclosure via Debug Output

**Issue:** `loader.lua` uses `print()` statements that expose internal timing and distance data:
```lua
print(string.format("[SPAM] %.2fs - %d clicks @ %.1f studs", ...))
```

**Risk:** Minimal in Roblox exploit context, but reveals script behavior to anyone monitoring the output console.

**Status:** Informational only.

---

## NOT APPLICABLE to this codebase:
- **SQL Injection** — No database queries exist
- **Insecure Dependencies** — No package manager (npm, pip, etc.) is used; dependencies are loaded via HTTP
- **Overly Permissive CORS** — No web server exists
- **Exposed Debug Endpoints** — No HTTP server/API exists
- **Missing Authentication Checks** — Client-side Roblox script, no server auth to implement
- **Hardcoded API Keys/Secrets** — None found (Discord invite link is not a secret)

---

## Recommendations

1. **Pin remote dependencies by commit hash** instead of loading from `main`/`latest` branches (prevents supply-chain attacks if the upstream repo is compromised)
2. **Consider bundling UI libraries locally** instead of fetching them at runtime
3. **Add integrity checks** (compare SHA256 of downloaded content against known-good hashes) for maximum security
