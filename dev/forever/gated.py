import os, re, collections

BASE = r"D:\Games\World of Warcraft\_forever_\BlizzardInterfaceCode\Interface\AddOns"
ROOT = r"D:\Development\WOW\AddOns\Armory\_archive\_live"
OTHER = {"Cata", "Mists", "Wrath", "TBC", "Vanilla", "Classic", "Standard"}
ALLOW = {"camelot", "forever", "mainline"}


def read(p):
    return open(p, encoding="utf-8", errors="ignore").read()


def strip(t):
    return re.sub(r"--[^\n]*", "", re.sub(r"--\[\[.*?\]\]", "", t, flags=re.S))


loaded, gated, calls = set(), collections.defaultdict(set), set()
gated_addons = []
for addon in os.listdir(BASE):
    d = os.path.join(BASE, addon)
    if not os.path.isdir(d) or addon == "Blizzard_APIDocumentationGenerated":
        continue
    toc = os.path.join(d, addon + ".toc")
    allow = None
    if os.path.exists(toc):
        m = re.search(r"^## AllowLoadGameType:\s*(.*)$", read(toc), re.M)
        if m:
            allow = {x.strip().lower() for x in m.group(1).split(",")}
    excluded = allow is not None and not (allow & ALLOW)
    if excluded:
        gated_addons.append(addon)
    for dp, dn, fns in os.walk(d):
        if set(os.path.relpath(dp, BASE).split(os.sep)) & OTHER:
            continue
        for fn in fns:
            if not fn.endswith(".lua"):
                continue
            t = strip(read(os.path.join(dp, fn)))
            names = set(re.findall(r"^function\s+([A-Za-z_]\w*)\s*\(", t, re.M)) | set(re.findall(r"^\s*([A-Za-z_]\w*)\s*=\s*(?:function|C_)", t, re.M)) | set(re.findall(r"^([A-Za-z_]\w*)\s*=", t, re.M))
            if excluded:
                for n in names:
                    gated[n].add(addon)
            else:
                loaded |= names
                calls |= set(re.findall(r"(?<![\w.:])([A-Za-z_]\w*)\s*\(", t))

print("addons excluded from Forever:", len(gated_addons))
used = collections.defaultdict(set)
for dp, dn, fns in os.walk(ROOT):
    dn[:] = [x for x in dn if x not in {".git", ".tokensave", ".release", ".vscode", "Artwork", "Locales", "Libs"}]
    for fn in fns:
        if fn.endswith(".lua"):
            p = os.path.join(dp, fn)
            c = strip(read(p))
            rel = os.path.relpath(p, ROOT)
            for g in set(re.findall(r"\b_G\.([A-Za-z_]\w*)", c)) | set(re.findall(r"(?<![\w.:\"'])([A-Z][A-Za-z0-9_]+)\s*\(", c)):
                used[g].add(rel)

print("=== _live globals defined only in addons that Forever does not load")
for g in sorted(used):
    if g in gated and g not in loaded:
        print(f"{g}  [{', '.join(sorted(gated[g]))}]  called-by-forever-ui={g in calls}  <- {', '.join(sorted(used[g])[:4])}")

print("=== constants used by talent frame")
for name in ("MAX_TALENT_TIERS", "NUM_TALENT_COLUMNS", "SHOW_TALENT_LEVEL", "TalentTierConstants", "MIN_TALENT_LEVEL"):
    hits = []
    for dp, dn, fns in os.walk(BASE):
        if set(os.path.relpath(dp, BASE).split(os.sep)) & OTHER:
            continue
        for fn in fns:
            if fn.endswith(".lua") and name in read(os.path.join(dp, fn)):
                hits.append(os.path.relpath(os.path.join(dp, fn), BASE))
    print(name, len(hits), hits[:3])
