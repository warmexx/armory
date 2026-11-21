import os, re, collections

WOW = r"D:\Games\World of Warcraft"
ARMORY = r"D:\Development\WOW\AddOns\Armory\_archive"
OTHER = {"Cata", "Mists", "Wrath", "TBC", "Vanilla", "Classic", "Standard"}
SKIP = {".git", "Locales", "Libs", "libs", ".tokensave", ".release", ".vscode", "Artwork"}


def read(p):
    return open(p, encoding="utf-8", errors="ignore").read()


def strip(code):
    code = re.sub(r"--\[\[.*?\]\]", "", code, flags=re.S)
    return re.sub(r"--[^\n]*", "", code)


def blizz(client, drop_other):
    base = os.path.join(WOW, client, "BlizzardInterfaceCode", "Interface", "AddOns")
    defs, calls, cnames, xmln = set(), set(), set(), set()
    for dp, dn, fns in os.walk(base):
        rel = os.path.relpath(dp, base)
        if "Blizzard_APIDocumentationGenerated" in rel:
            continue
        if drop_other and set(rel.split(os.sep)) & OTHER:
            continue
        for fn in fns:
            p = os.path.join(dp, fn)
            if fn.endswith(".lua"):
                t = strip(read(p))
                defs |= set(re.findall(r"^function\s+([A-Za-z_]\w*)\s*\(", t, re.M))
                defs |= set(re.findall(r"^([A-Za-z_]\w*)\s*=", t, re.M))
                calls |= set(re.findall(r"(?<![\w.:])([A-Za-z_]\w*)\s*\(", t))
                calls |= set(re.findall(r"=\s*([A-Z][A-Za-z_0-9]+)\s*[;\n]", t))
                cnames |= set(re.findall(r"\b(C_[A-Za-z0-9]+\.[A-Za-z0-9_]+)", t))
            elif fn.endswith(".xml"):
                xmln |= set(re.findall(r'\bname="([^"$]+)"', read(p)))
    return defs, calls, cnames, xmln


def docs(client):
    base = os.path.join(WOW, client, "BlizzardInterfaceCode", "Interface", "AddOns", "Blizzard_APIDocumentationGenerated")
    out = set()
    for fn in os.listdir(base):
        if fn.endswith(".lua"):
            t = read(os.path.join(base, fn))
            m = re.search(r'Namespace\s*=\s*"([^"]+)"', t)
            ns = m.group(1) if m else None
            for n in re.findall(r'Name\s*=\s*"([A-Za-z0-9_]+)",\s*\n\s*Type\s*=\s*"Function"', t):
                out.add(f"{ns}.{n}" if ns else n)
    return out


fd, fc, fcn, fx = blizz("_forever_", True)
rd, rc, rcn, rx = blizz("_retail_", False)
ed, ec, ecn, ex = blizz("_classic_era_", False)
fdoc, rdoc, edoc = docs("_forever_"), docs("_retail_"), docs("_classic_era_")

BUILTIN = set("""assert collectgarbage date error getfenv getmetatable ipairs load loadstring next pairs pcall print rawequal rawget rawset require select
setfenv setmetatable tonumber tostring type unpack xpcall CreateFrame GetTime""".split())


def scan(folder):
    root = os.path.join(ARMORY, folder)
    per = collections.defaultdict(lambda: {"g": set(), "c": set(), "inh": set()})
    own = set()
    for dp, dn, fns in os.walk(root):
        dn[:] = [d for d in dn if d not in {".git", ".tokensave", ".release", ".vscode", "Artwork"}]
        for fn in fns:
            p = os.path.join(dp, fn)
            if fn.endswith(".lua"):
                t = read(p)
                own |= set(re.findall(r"^function\s+([A-Za-z_]\w*)\s*\(", t, re.M))
                own |= set(re.findall(r"^([A-Za-z_]\w*)\s*=", t, re.M))
            elif fn.endswith(".xml"):
                own |= set(re.findall(r'name="([^"]+)"', read(p)))
    for dp, dn, fns in os.walk(root):
        dn[:] = [d for d in dn if d not in SKIP]
        for fn in fns:
            p = os.path.join(dp, fn)
            rel = os.path.relpath(p, root)
            if fn.endswith(".lua"):
                code = strip(read(p))
                locs = set(re.findall(r"local\s+function\s+(\w+)", code))
                for m in re.findall(r"local\s+([\w, ]+?)\s*(?:=|\n)", code):
                    locs.update(x.strip() for x in m.split(","))
                for m in re.findall(r"function\s*[\w.:]*\(([^)]*)\)", code):
                    locs.update(x.strip() for x in m.split(","))
                per[rel]["c"] |= set(re.findall(r"\b(C_[A-Za-z0-9]+\.[A-Za-z0-9_]+)", code))
                per[rel]["g"] |= set(re.findall(r"\b_G\.([A-Za-z_]\w*)", code))
                per[rel]["g"] |= {b for b in re.findall(r"(?<![\w.:\"'])([A-Z][A-Za-z0-9_]+)\s*\(", code) if b not in locs}
            elif fn.endswith(".xml"):
                t = read(p)
                per[rel]["inh"] |= {x.strip() for s in re.findall(r'inherits="([^"]+)"', t) for x in s.split(",")}
    return per, own


def classify_g(g):
    if g in fd or g in fdoc:
        return "ok"
    if g in fc:
        return "called-by-forever-ui"
    if g in rd or g in rdoc or g in rc:
        return "RETAIL-ONLY"
    if g in ed or g in edoc or g in ec:
        return "ERA-ONLY"
    return "unknown"


def classify_c(c):
    if c in fdoc:
        return "ok"
    if c in fcn:
        return "called-by-forever-ui"
    if c in rdoc or c in rcn:
        return "RETAIL-ONLY"
    if c in edoc or c in ecn:
        return "ERA-ONLY"
    return "unknown"


for folder in ("_live", "_era"):
    per, own = scan(folder)
    print("########", folder)
    tot = collections.Counter()
    for rel in sorted(per):
        r = per[rel]
        gb = collections.defaultdict(list)
        for g in sorted(r["g"]):
            if g in BUILTIN or g in own:
                continue
            k = classify_g(g)
            tot[k] += 1
            if k not in ("ok", "called-by-forever-ui"):
                gb[k].append(g)
        for c in sorted(r["c"]):
            k = classify_c(c)
            tot[k] += 1
            if k not in ("ok", "called-by-forever-ui"):
                gb[k].append(c)
        tm = sorted(i for i in r["inh"] if i not in fx and i not in own)
        if gb or tm:
            print("---", rel)
            for k in gb:
                print("   ", k + ":", ", ".join(gb[k]))
            if tm:
                print("    templates missing:", ", ".join(tm))
    print("totals:", dict(tot))
    print()
