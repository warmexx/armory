"""Which Blizzard globals and XML templates does Armory use that a client never loads?

Follows every Blizzard addon TOC file by file, with the game-type conditions per line
([AllowLoadGameType ...], [ExcludeLoadGameType ...]) and the XML <Script>/<Include> tree.
A name counts as missing when it is defined only in Blizzard files that the client does not load.

Armory's own files are followed the same way, through the TOC the client would choose
(Armory_<Suffix>.toc, else Armory.toc) and the one of ArmoryGuildBank, plus Bindings.xml.

Usage: python -I loadcheck.py <client> [armory-source-folder]
  client: retail, forever, era or anniversary
  armory-source-folder: default is the repo this script lives in

Needs a fresh export of Blizzard's code per client (start the client with -console,
then type: exportInterfaceFiles code).
"""
import collections
import os
import re
import sys

WOW = r"D:\Games\World of Warcraft"
DEFAULT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Per client: install folder, game types it loads, what [Family] and [Game] resolve to,
# and the TOC suffixes it tries, in order ("" is the TOC without suffix).
# Measured in phase 0 (see docs/CODEBASIS.md). Retail, Era and Anniversary also load files
# marked camelot or forever (unknown types count as allowed); Blizzard's own code there never
# uses those, so they are left out here.
CLIENTS = {
    "retail": dict(folder="_retail_", types={"mainline", "standard"},
                   family="Mainline", game="Standard", suffixes=["Mainline", ""]),
    "forever": dict(folder="_forever_", types={"mainline", "camelot", "forever"},
                    family="Mainline", game="Camelot", suffixes=["Forever", "Camelot", "Mainline", ""]),
    "era": dict(folder="_classic_era_", types={"classic", "vanilla"},
                family="Classic", game="Vanilla", suffixes=["Vanilla", "Classic", ""]),
    "anniversary": dict(folder="_anniversary_", types={"classic", "tbc"},
                        family="Classic", game="TBC", suffixes=["TBC", "BCC", "Classic", ""]),
}

if len(sys.argv) < 2 or sys.argv[1].lower() not in CLIENTS:
    sys.exit(__doc__)
CLIENT = sys.argv[1].lower()
CFG = CLIENTS[CLIENT]
BASE = os.path.join(WOW, CFG["folder"], "BlizzardInterfaceCode", "Interface", "AddOns")
ROOT = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_ROOT
TYPES = CFG["types"]
SUBST = {"[Family]": CFG["family"], "[Game]": CFG["game"]}

if not os.path.isdir(BASE):
    sys.exit(f"No export of Blizzard's code found in {BASE}")


def read(p):
    with open(p, encoding="utf-8", errors="ignore") as f:
        return f.read()


def strip_lua(t):
    return re.sub(r"--[^\n]*", "", re.sub(r"--\[(=*)\[.*?\]\1\]", "", t, flags=re.S))


def types(spec):
    return {x.strip().lower() for x in spec.split(",") if x.strip()}


def line_allowed(line):
    allow = re.search(r"\[AllowLoadGameType\s+([^\]]+)\]", line, re.I)
    exclude = re.search(r"\[ExcludeLoadGameType\s+([^\]]+)\]", line, re.I)
    if allow and not (types(allow.group(1)) & TYPES):
        return False
    if exclude and (types(exclude.group(1)) & TYPES):
        return False
    return True


def resolve(addon_dir, rel):
    for k, v in SUBST.items():
        rel = rel.replace(k, v)
    rel = rel.replace("\\", os.sep).replace("/", os.sep)
    return os.path.normpath(os.path.join(addon_dir, rel))


def choose_toc(addon_dir, addon):
    """The TOC the client picks: the first suffix that exists, case-insensitive like Windows."""
    present = {fn.lower(): fn for fn in os.listdir(addon_dir) if fn.lower().endswith(".toc")}
    for suffix in CFG["suffixes"]:
        name = (f"{addon}_{suffix}.toc" if suffix else f"{addon}.toc").lower()
        if name in present:
            return os.path.join(addon_dir, present[name])
    return None


def toc_files(addon_dir, toc_path):
    """Return (loaded, skipped) file lists for one TOC."""
    text = read(toc_path)
    addon_ok = True
    m = re.search(r"^## AllowLoadGameType:\s*(.*)$", text, re.M)
    if m and not (types(m.group(1)) & TYPES):
        addon_ok = False
    m = re.search(r"^## AllowLoad:\s*(.*)$", text, re.M)
    if m and types(m.group(1)) == {"glue"}:
        addon_ok = False
    loaded, skipped = [], []
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        name = re.split(r"\s+\[", line)[0].strip()
        if not name.lower().endswith((".lua", ".xml")):
            continue
        path = resolve(addon_dir, name)
        (loaded if addon_ok and line_allowed(line) else skipped).append(path)
    return loaded, skipped


def expand_xml(path, seen):
    """Files reached from an XML file via <Script file> and <Include file>."""
    out = []
    if path in seen or not os.path.exists(path):
        return out
    seen.add(path)
    out.append(path)
    if path.lower().endswith(".xml"):
        base = os.path.dirname(path)
        for m in re.finditer(r"<(?:Script|Include)\s+file=\"([^\"]+)\"", read(path)):
            out += expand_xml(resolve(base, m.group(1)), seen)
    return out


def addon_files(addon_dir, addon):
    """(loaded, skipped) files of one addon, or None when the client has no TOC for it."""
    toc = choose_toc(addon_dir, addon)
    if not toc:
        return None
    loaded, skipped = toc_files(addon_dir, toc)
    out_loaded, out_skipped = set(), set()
    seen = set()
    for p in loaded:
        out_loaded.update(expand_xml(p, seen))
    seen = set()
    for p in skipped:
        out_skipped.update(expand_xml(p, seen))
    return out_loaded, out_skipped - out_loaded, toc


loaded_files, skipped_files = set(), set()
for addon in os.listdir(BASE):
    d = os.path.join(BASE, addon)
    if not os.path.isdir(d) or addon == "Blizzard_APIDocumentationGenerated":
        continue
    result = addon_files(d, addon)
    if result is None:
        # No TOC for this client: none of its files load.
        for dp, _, fns in os.walk(d):
            skipped_files.update(os.path.join(dp, fn) for fn in fns if fn.lower().endswith((".lua", ".xml")))
        continue
    loaded, skipped, _ = result
    loaded_files |= loaded
    skipped_files |= skipped
skipped_files -= loaded_files

FUNC_DEF = re.compile(r"^function\s+([A-Za-z_]\w*)\s*\(", re.M)
GLOBAL_ASSIGN = re.compile(r"^([A-Za-z_]\w*)\s*=", re.M)
TEMPLATE_DEF = re.compile(r"<\w+[^>]*\bname=\"([A-Za-z_]\w*)\"[^>]*\bvirtual=\"true\"", re.S)
TEMPLATE_DEF2 = re.compile(r"<\w+[^>]*\bvirtual=\"true\"[^>]*\bname=\"([A-Za-z_]\w*)\"", re.S)


def definitions(files):
    names, templates = collections.defaultdict(set), collections.defaultdict(set)
    for p in files:
        if not os.path.exists(p):
            continue
        rel = os.path.relpath(p, BASE)
        if p.lower().endswith(".lua"):
            t = strip_lua(read(p))
            for n in set(FUNC_DEF.findall(t)) | set(GLOBAL_ASSIGN.findall(t)):
                names[n].add(rel)
        else:
            t = read(p)
            for n in set(TEMPLATE_DEF.findall(t)) | set(TEMPLATE_DEF2.findall(t)):
                templates[n].add(rel)
    return names, templates


ok_names, ok_templates = definitions(loaded_files)
gone_names, gone_templates = definitions(skipped_files)

# Armory's own files, as this client would load them.
armory_files, armory_tocs = set(), []
for addon, addon_dir in (("Armory", ROOT), ("ArmoryGuildBank", os.path.join(ROOT, "ArmoryGuildBank"))):
    if not os.path.isdir(addon_dir):
        continue
    result = addon_files(addon_dir, addon)
    if result is None:
        armory_tocs.append(f"{addon}: no TOC for {CLIENT}")
        continue
    loaded, _, toc = result
    armory_files |= loaded
    armory_tocs.append(os.path.relpath(toc, ROOT))
    bindings = os.path.join(addon_dir, "Bindings.xml")
    if os.path.exists(bindings):
        armory_files.add(bindings)
armory_files = {p for p in armory_files if os.sep + "Libs" + os.sep not in p and os.sep + "Locales" + os.sep not in p}

used, used_templates = collections.defaultdict(set), collections.defaultdict(set)
own_defs = set()
missing_files = []
for p in sorted(armory_files):
    if not os.path.exists(p):
        missing_files.append(os.path.relpath(p, ROOT))
        continue
    rel = os.path.relpath(p, ROOT)
    if p.lower().endswith(".lua"):
        c = strip_lua(read(p))
        own_defs |= set(FUNC_DEF.findall(c)) | set(GLOBAL_ASSIGN.findall(c))
        own_defs |= set(re.findall(r"^local\s+function\s+([A-Za-z_]\w*)", c, re.M))
        own_defs |= set(re.findall(r"^local\s+([A-Za-z_]\w*)\s*=", c, re.M))
        for g in set(re.findall(r"\b_G\.([A-Za-z_]\w*)", c)) | set(re.findall(r"(?<![\w.:\"'])([A-Za-z_]\w*)", c)):
            used[g].add(rel)
    else:
        c = read(p)
        for t in re.findall(r"\binherits=\"([^\"]+)\"", c):
            for name in t.split(","):
                used_templates[name.strip()].add(rel)
        own_defs |= set(TEMPLATE_DEF.findall(c)) | set(TEMPLATE_DEF2.findall(c))
        # calls inside XML script handlers and bindings
        handlers = re.findall(r">([^<]*)</(?:On\w+|Binding)>", c)
        for g in set(re.findall(r"(?<![\w.:\"'])([A-Za-z_]\w*)\s*\(", " ".join(handlers))):
            used[g].add(rel)

print(f"Client: {CLIENT} (game types {', '.join(sorted(TYPES))}; [Family] = {CFG['family']}, [Game] = {CFG['game']})")
print(f"Blizzard files loaded: {len(loaded_files)}, not loaded: {len(skipped_files)}")
print(f"Armory source: {ROOT}")
print(f"Armory TOCs: {'; '.join(armory_tocs)}  ({len(armory_files)} files)\n")

if missing_files:
    print("=== Files named in Armory's TOC or XML that do not exist")
    for f in missing_files:
        print(f)
    print()

print(f"=== Globals that Armory uses, defined only in files {CLIENT} does not load")
for g in sorted(used):
    if g in gone_names and g not in ok_names and g not in own_defs:
        src = sorted(gone_names[g])[0]
        print(f"{g:45s} only in {src}  <- {', '.join(sorted(used[g])[:3])}")

print(f"\n=== XML templates that Armory inherits, defined only in files {CLIENT} does not load")
for t in sorted(used_templates):
    if t in gone_templates and t not in ok_templates and t not in own_defs:
        src = sorted(gone_templates[t])[0]
        print(f"{t:45s} only in {src}  <- {', '.join(sorted(used_templates[t])[:3])}")
