"""Brings the Armory installation in a client up to date with this repo.

Since 2026-11-15 the repo is installed as Armory and ArmoryGuildBank themselves, over the
released addon (before that as ArmoryOfa next to it). Libs and the translations stay as the
release put them there: Libs come from the packager (externals) and are never touched. A file in
Locales without an @localization template, such as Localization.lua, is source code and is
installed like any other file; the released one of Era or BCC lacks globals that the shared code
uses. The translations (the files with a template) come in every client from the released
Armory and ArmoryGuildBank in Retail, since v20 takes all of them from the Retail project on
CurseForge. New English strings that are not on CurseForge yet (dev/strings/<addon>_enUS.lua)
are added to the installed enUS.lua, so they can be tested before the import.
Do not update Armory with the CurseForge app: that puts the old release back.

Copies every file that is new or changed, and removes Lua, XML and TOC files that are
no longer in the repo, so a stale file can never be loaded (also the TOCs with a suffix of the
release, which would win over Armory.toc). Revision lines are ignored when comparing, so a
packaged file with an expanded revision counts as unchanged. In TOCs, @project-version@ becomes
the newest version in CHANGELOG.md plus "-dev" (for example v20.0.0-dev), as the packager
would fill it in.

Usage: python -I dev/install.py <client> [--dry-run]
  client: retail, forever, era, anniversary or all
"""
import filecmp
import glob
import os
import re
import shutil
import sys

WOW = r"D:\Games\World of Warcraft"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLIENTS = {"retail": "_retail_", "forever": "_forever_", "era": "_classic_era_", "anniversary": "_anniversary_"}
# Addon folders: (folder in the repo, folder in Interface\AddOns). Every client gets both, like
# the package; the guild bank's TOC keeps it out of Era (## AllowLoadGameType).
ADDONS = [("", "Armory"), ("ArmoryGuildBank", "ArmoryGuildBank")]
SKIP_DIRS = {".git", ".release", ".vscode", ".tokensave", ".claude", "dev", "docs", "Libs", "Locales"}
SKIP_FILES = {".gitignore", ".pkgmeta", ".gitattributes"}
CODE = (".lua", ".xml", ".toc")
# The translations of every client come from the released addon in Retail (CurseForge project 5195)
TRANSLATIONS = os.path.join(WOW, CLIENTS["retail"], "Interface", "AddOns")


def dev_version():
    with open(os.path.join(ROOT, "CHANGELOG.md"), encoding="utf-8") as f:
        m = re.search(r"^## (v[\d.]+)", f.read(), re.M)
    return (m.group(1) if m else "v0") + "-dev"


VERSION = dev_version()


def content(path):
    """The bytes as they should be installed."""
    with open(path, "rb") as f:
        data = f.read()
    if path.lower().endswith(".toc"):
        data = data.replace(b"@project-version@", VERSION.encode())
    return data


def is_source_locale(path):
    """A file in Locales that is code in the repo, not a template for the CurseForge translations."""
    with open(path, "rb") as f:
        return b"@localization(" not in f.read()


def translations(src, addon):
    """(installed path, Retail file) for each translation that the repo has as a template."""
    out = []
    for p in glob.glob(os.path.join(src, "Locales", "*.lua")):
        if not is_source_locale(p):
            name = os.path.basename(p)
            t = os.path.join(TRANSLATIONS, addon, "Locales", name)
            if os.path.exists(t):
                out.append((os.path.join("Locales", name), t))
    return out


STRINGS = os.path.join(ROOT, "dev", "strings")
KEY = re.compile(rb'^L\["([^"]+)"\]', re.M)


def translation(path, addon, rel):
    """The Retail translation, plus the new English strings in dev/strings that it lacks.

    dev/strings/<addon>_enUS.lua holds the strings that are not on CurseForge yet; adding them
    here lets them be tested before the import. Only for enUS.lua."""
    with open(path, "rb") as f:
        data = f.read()
    pending = os.path.join(STRINGS, f"{addon}_enUS.lua")
    if os.path.basename(rel).lower() != "enus.lua" or not os.path.exists(pending):
        return data
    have = set(KEY.findall(data))
    with open(pending, "rb") as f:
        text = f.read()
    # a statement runs from its key to the next key or comment line (long strings span lines)
    starts = [m.start() for m in KEY.finditer(text)]
    extra = []
    for i, start in enumerate(starts):
        end = starts[i + 1] if i + 1 < len(starts) else len(text)
        stmt = re.split(rb"\r?\n--", text[start:end])[0].rstrip()
        if KEY.match(stmt).group(1) not in have:
            extra.append(stmt)
    if not extra:
        return data
    nl = b"\r\n" if b"\r\n" in data else b"\n"
    return data.rstrip() + nl + nl + b"-- dev/strings: not on CurseForge yet" + nl + nl.join(s.replace(b"\r\n", b"\n").replace(b"\n", nl) for s in extra) + nl


def files(base, skip_sub=(), repo=False):
    out = set()
    if repo:
        for p in glob.glob(os.path.join(base, "Locales", "*.lua")):
            if is_source_locale(p):
                out.add(os.path.relpath(p, base))
    for dp, dns, fns in os.walk(base):
        rel_dir = os.path.relpath(dp, base)
        dns[:] = [d for d in dns if d not in SKIP_DIRS and os.path.normpath(os.path.join(rel_dir, d)) not in skip_sub]
        for fn in fns:
            if fn not in SKIP_FILES:
                out.add(os.path.normpath(os.path.join(rel_dir, fn)))
    return out


def same(a, b):
    if not a.lower().endswith(CODE):
        return filecmp.cmp(a, b, shallow=False)
    with open(b, "rb") as f:
        installed = f.read()
    data = content(a)
    if data == installed:
        return True

    def norm(raw):
        lines = raw.decode("utf-8", errors="replace").splitlines()
        return [l.rstrip() for l in lines if "Revision:" not in l and l.strip()]
    return norm(data) == norm(installed)


def sync(client, dry):
    print(f"== {client}")
    for src_sub, addon in ADDONS:
        src = os.path.join(ROOT, src_sub)
        dst = os.path.join(WOW, CLIENTS[client], "Interface", "AddOns", addon)
        if not os.path.isdir(dst):
            print(f"  {addon}: not installed, copying everything")
        if src_sub == "" and not os.path.isdir(os.path.join(dst, "Libs")):
            print(f"  WARNING {addon} has no Libs: install the release once first")
        skip_sub = {"ArmoryGuildBank"} if src_sub == "" else set()
        wanted = {rel: rel for rel in files(src, skip_sub, repo=True)}
        present = files(dst) if os.path.isdir(dst) else set()
        copied = removed = 0
        for rel in sorted(wanted):
            s, d = os.path.join(src, rel), os.path.join(dst, rel)
            if os.path.exists(d) and same(s, d):
                continue
            print(f"  copy   {addon}\\{rel}")
            copied += 1
            if not dry:
                os.makedirs(os.path.dirname(d), exist_ok=True)
                with open(d, "wb") as f:
                    f.write(content(s))
        for rel, t in translations(src, addon):
            d = os.path.join(dst, rel)
            data = translation(t, addon, rel)
            if os.path.exists(d):
                with open(d, "rb") as f:
                    if f.read() == data:
                        continue
            print(f"  copy   {addon}\\{rel} (Retail translation)")
            copied += 1
            if not dry:
                os.makedirs(os.path.dirname(d), exist_ok=True)
                with open(d, "wb") as f:
                    f.write(data)
        for rel in sorted(present - set(wanted)):
            if rel.lower().endswith(CODE):
                print(f"  remove {addon}\\{rel}")
                removed += 1
                if not dry:
                    os.remove(os.path.join(dst, rel))
        if not dry and os.path.isdir(dst):
            for dp, dns, fns in os.walk(dst, topdown=False):
                if dp != dst and not os.listdir(dp):
                    os.rmdir(dp)
        print(f"  {addon}: {copied} copied, {removed} removed{' (dry run)' if dry else ''}")


args = [a.lower() for a in sys.argv[1:]]
dry = "--dry-run" in args
targets = [a for a in args if a != "--dry-run"]
if len(targets) != 1 or targets[0] not in (*CLIENTS, "all"):
    sys.exit(__doc__)
for c in (CLIENTS if targets[0] == "all" else [targets[0]]):
    sync(c, dry)
