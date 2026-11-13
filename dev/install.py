"""Brings the ArmoryOfa installation in a client up to date with this repo.

The repo is installed as ArmoryOfa and ArmoryGuildBankOfa, next to the released Armory, so
both can be in a client and you switch between them in the addon list. Never enable both:
they share their global names (Armory, ArmoryFrame, ArmoryDB and so on). Each folder has its
own SavedVariables file, so their data stays apart. On install, paths to the addon folder,
the Dependencies and the titles in the TOCs and GetAddOnMetadata("Armory") are rewritten to
the Ofa names.

The first install takes Libs and Locales from the released Armory and ArmoryGuildBank in that
client, and copies their SavedVariables (ArmoryOfa.lua and so on), each only when it is missing.
Copies every file that is new or changed, and removes Lua, XML and TOC files that are
no longer in the repo, so a stale file can never be loaded. Libs and Locales are left
alone: they come from the packager (externals and CurseForge translations).
Revision lines are ignored when comparing, so a packaged file with an expanded
revision counts as unchanged. In TOCs, @project-version@ becomes the newest version in
CHANGELOG.md plus "-dev" (for example v20.0.0-dev), as the packager would fill it in.

Usage: python -I dev/install.py <client> [--dry-run]
  client: retail, era, anniversary or all (Forever follows in phase 3, see docs/CODEBASIS.md)
"""
import filecmp
import glob
import os
import re
import shutil
import sys

WOW = r"D:\Games\World of Warcraft"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLIENTS = {"retail": "_retail_", "era": "_classic_era_", "anniversary": "_anniversary_"}
# Addon folders: (folder in the repo, folder in Interface\AddOns). Every client gets both, like
# the package; a client without a TOC for the guild bank (Era) does not load it.
# The third name is the released addon that the first install takes Libs, Locales and data from.
ADDONS = [("", "ArmoryOfa", "Armory"), ("ArmoryGuildBank", "ArmoryGuildBankOfa", "ArmoryGuildBank")]
SEED_DIRS = ("Libs", "Locales")
SKIP_DIRS = {".git", ".release", ".vscode", ".tokensave", ".claude", "dev", "docs", "Libs", "Locales"}
SKIP_FILES = {".gitignore", ".pkgmeta", ".gitattributes"}
CODE = (".lua", ".xml", ".toc")


def dev_version():
    with open(os.path.join(ROOT, "CHANGELOG.md"), encoding="utf-8") as f:
        m = re.search(r"^## (v[\d.]+)", f.read(), re.M)
    return (m.group(1) if m else "v0") + "-dev"


VERSION = dev_version()


RENAMES = [
    # Interface\AddOns\Armory\... in Lua (double backslash), TOC and XML (single)
    (re.compile(rb"(?i)(AddOns[\x5c]+)(Armory(?:GuildBank)?)(?=[\x5c])"), rb"\1\2Ofa"),
    (re.compile(rb'GetAddOnMetadata\("Armory"'), rb'GetAddOnMetadata("ArmoryOfa"'),
    (re.compile(rb"(?m)^(## Dependencies: )Armory\b"), rb"\1ArmoryOfa"),
    (re.compile(rb"(?m)^(## Title(?:-\w+)?: )(Armory(?:GuildBank)?)\b"), rb"\1\2Ofa"),
]


def content(path):
    """The bytes as they should be installed."""
    with open(path, "rb") as f:
        data = f.read()
    if path.lower().endswith(".toc"):
        data = data.replace(b"@project-version@", VERSION.encode())
    if path.lower().endswith(CODE):
        for rx, to in RENAMES:
            data = rx.sub(to, data)
    return data


def files(base, skip_sub=()):
    out = set()
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


def seed(client, addon, released, dry):
    """Takes Libs, Locales and SavedVariables from the released addon, where missing."""
    base = os.path.join(WOW, CLIENTS[client])
    for sub in SEED_DIRS:
        s = os.path.join(base, "Interface", "AddOns", released, sub)
        d = os.path.join(base, "Interface", "AddOns", addon, sub)
        if os.path.isdir(s) and not os.path.exists(d):
            print(f"  seed   {os.path.join(addon, sub)} from {released}")
            if not dry:
                shutil.copytree(s, d)
    for pattern in ("*", os.path.join("*", "*", "*")):
        for s in glob.glob(os.path.join(base, "WTF", "Account", pattern, "SavedVariables", released + ".lua")):
            d = os.path.join(os.path.dirname(s), addon + ".lua")
            if not os.path.exists(d):
                print(f"  seed   {os.path.relpath(d, base)}")
                if not dry:
                    shutil.copy2(s, d)


def sync(client, dry):
    print(f"== {client}")
    for src_sub, addon, released in ADDONS:
        src = os.path.join(ROOT, src_sub)
        dst = os.path.join(WOW, CLIENTS[client], "Interface", "AddOns", addon)
        if not os.path.isdir(dst):
            print(f"  {addon}: not installed, copying everything")
        seed(client, addon, released, dry)
        skip_sub = {"ArmoryGuildBank"} if src_sub == "" else set()
        # A TOC is named after its folder: Armory_Mainline.toc becomes ArmoryOfa_Mainline.toc
        wanted = {}
        for rel in files(src, skip_sub):
            if rel.lower().endswith(".toc") and rel.startswith(released + "_"):
                wanted[addon + rel[len(released):]] = rel
            else:
                wanted[rel] = rel
        present = files(dst) if os.path.isdir(dst) else set()
        copied = removed = 0
        for rel in sorted(wanted):
            s, d = os.path.join(src, wanted[rel]), os.path.join(dst, rel)
            if os.path.exists(d) and same(s, d):
                continue
            print(f"  copy   {addon}\\{rel}")
            copied += 1
            if not dry:
                os.makedirs(os.path.dirname(d), exist_ok=True)
                with open(d, "wb") as f:
                    f.write(content(s))
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
