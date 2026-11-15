"""In which order does a client load Armory's files, and does that order work?

Follows the TOC the client picks (with the conditions per line, [Family] and [Game]) and the
<Script>/<Include> tree of every XML file, like loadcheck.py, but keeps the order. Reports:
  - files a TOC or XML names that do not exist (in the game: a LUA_WARNING "Error loading");
  - Lua whose main chunk (outside functions) reads a global or a field that only a later file
    writes, found with luac -l (Lua 5.1);
  - XML that inherits from, or names as parent, an Armory frame or template that a later file
    defines.
With --list it also prints the files in load order, so two layouts can be compared with diff.

Usage: python -I dev/loadorder.py <client> [--list] [armory-source-folder]
  client: retail, forever, era, anniversary or all
"""
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

DEFAULT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Per client: game types it loads, what [Family] and [Game] resolve to, and the TOC suffixes
# it tries, in order ("" is the TOC without suffix). Measured in phase 0 and 0b
# (see docs/CODEBASIS.md); the same as in loadcheck.py.
CLIENTS = {
    "retail": dict(types={"mainline", "standard"}, family="Mainline", game="Standard",
                   suffixes=["Standard", "Mainline", ""]),
    "forever": dict(types={"mainline", "camelot", "forever"}, family="Mainline", game="Camelot",
                    suffixes=["Forever", "Camelot", "Mainline", ""]),
    "era": dict(types={"classic", "vanilla"}, family="Classic", game="Vanilla",
                suffixes=["Vanilla", "Classic", ""]),
    "anniversary": dict(types={"classic", "tbc"}, family="Classic", game="TBC",
                        suffixes=["TBC", "BCC", "Classic", ""]),
}
ADDONS = (("Armory", ""), ("ArmoryGuildBank", "ArmoryGuildBank"))


def read(p):
    with open(p, encoding="utf-8-sig", errors="ignore") as f:
        return f.read()


def types(spec):
    return {x.strip().lower() for x in spec.split(",") if x.strip()}


class Order:
    def __init__(self, client, root):
        self.cfg = CLIENTS[client]
        self.root = root
        self.files = []        # (addon, path relative to the root), in load order
        self.missing = []      # (referenced by, path)
        self.tocs = []

    def resolve(self, base, rel):
        rel = rel.replace("[Family]", self.cfg["family"]).replace("[Game]", self.cfg["game"])
        return os.path.normpath(os.path.join(base, rel.replace("\\", os.sep).replace("/", os.sep)))

    def choose_toc(self, addon_dir, addon):
        present = {fn.lower(): fn for fn in os.listdir(addon_dir) if fn.lower().endswith(".toc")}
        for suffix in self.cfg["suffixes"]:
            name = (f"{addon}_{suffix}.toc" if suffix else f"{addon}.toc").lower()
            if name in present:
                return os.path.join(addon_dir, present[name])
        return None

    def allowed(self, line):
        allow = re.search(r"\[AllowLoadGameType\s+([^\]]+)\]", line, re.I)
        exclude = re.search(r"\[ExcludeLoadGameType\s+([^\]]+)\]", line, re.I)
        if allow and not (types(allow.group(1)) & self.cfg["types"]):
            return False
        return not (exclude and (types(exclude.group(1)) & self.cfg["types"]))

    def follow(self, addon, path, by, seen):
        rel = os.path.relpath(path, self.root)
        if not os.path.exists(path):
            # Libs come from the packager (externals) and are not in the repo
            if not rel.lower().startswith("libs" + os.sep):
                self.missing.append((by, rel))
            return
        if path.lower() in seen:
            return
        seen.add(path.lower())
        self.files.append((addon, rel))
        if path.lower().endswith(".xml"):
            text = re.sub(r"<!--.*?-->", "", read(path), flags=re.S)
            for m in re.finditer(r"<(?:Script|Include)\s+file=\"([^\"]+)\"", text):
                self.follow(addon, self.resolve(os.path.dirname(path), m.group(1)), rel, seen)

    def load(self):
        for addon, sub in ADDONS:
            addon_dir = os.path.join(self.root, sub)
            if not os.path.isdir(addon_dir):
                continue
            toc = self.choose_toc(addon_dir, addon)
            if not toc:
                self.tocs.append(f"{addon}: no TOC")
                continue
            text = read(toc)
            m = re.search(r"^## AllowLoadGameType:\s*(.*)$", text, re.M)
            if m and not (types(m.group(1)) & self.cfg["types"]):
                self.tocs.append(f"{os.path.relpath(toc, self.root)}: not for this client")
                continue
            self.tocs.append(os.path.relpath(toc, self.root))
            seen = set()
            for raw in text.splitlines():
                line = raw.strip()
                if not line or line.startswith("#") or not self.allowed(line):
                    continue
                name = re.split(r"\s+\[", line)[0].strip()
                if name.lower().endswith((".lua", ".xml")):
                    self.follow(addon, self.resolve(addon_dir, name), os.path.relpath(toc, self.root), seen)
        return self


def lua_toplevel(path):
    """Globals and string-keyed fields that the main chunk reads and writes."""
    res = subprocess.run(["luac", "-p", "-l", path], capture_output=True, text=True)
    reads, writes = set(), set()
    main = False
    for line in res.stdout.splitlines():
        if line.startswith("main <"):
            main = True
        elif line.startswith("function <"):
            main = False
        elif main:
            m = re.search(r"\b(GETGLOBAL|SETGLOBAL)\b.*; (\S+)", line)
            if m:
                (reads if m.group(1) == "GETGLOBAL" else writes).add(m.group(2))
                continue
            m = re.search(r"\b(GETTABLE|SELF|SETTABLE)\b.*; \"([^\"]+)\"", line)
            if m:
                (writes if m.group(1) == "SETTABLE" else reads).add("." + m.group(2))
    return reads, writes


def xml_names(path):
    """Armory frames and templates an XML file defines, and those it inherits from or parents to.

    Inside a virtual template, inherits and parent are only resolved when the template is used,
    so those do not count."""
    text = re.sub(r"<!--.*?-->", "", read(path), flags=re.S)
    defs = set(re.findall(r"\bname=\"(Armory\w+)\"", text))
    uses = set()
    try:
        tree = ET.fromstring(text)
    except ET.ParseError as e:
        print(f"   XML ERROR {os.path.basename(path)}: {e}")
        return defs, uses

    def walk(el):
        if el.get("virtual", "").lower() == "true":
            return
        for attr in ("inherits", "parent"):
            uses.update(x.strip() for x in el.get(attr, "").split(",") if x.strip().startswith("Armory"))
        for child in el:
            walk(child)

    walk(tree)
    return defs, uses


# Known and harmless: Localization.lua reads ARMORY_CMD_CONFIG as a field of another table
# (the same name happens to be written as a field in ArmoryConfig.lua).
KNOWN = {("Locales" + os.sep + "Localization.lua", ".ARMORY_CMD_CONFIG")}


def problems(order):
    out = []
    paths = [os.path.join(order.root, rel) for _, rel in order.files]
    rels = [rel for _, rel in order.files]
    lua = {p: lua_toplevel(p) for p in paths if p.lower().endswith(".lua")}
    xml = {p: xml_names(p) for p in paths if p.lower().endswith(".xml")}
    written, defined = set(), set()
    for i, p in enumerate(paths):
        if p in lua:
            reads, writes = lua[p]
            for r in sorted(reads - writes):
                later = [rels[j] for j in range(i + 1, len(paths)) if paths[j] in lua and r in lua[paths[j]][1]]
                if later and (rels[i], r) not in KNOWN:
                    # Not written yet, or written again later (then this file keeps the old value)
                    how = "written again later" if r in written else "written later"
                    out.append(f"{rels[i]} reads {r.lstrip('.')} at load, {how} in {later[0]}")
            written |= writes
        else:
            defs, uses = xml[p]
            for u in sorted(uses - defined - defs):
                later = [rels[j] for j in range(i + 1, len(paths)) if paths[j] in xml and u in xml[paths[j]][0]]
                if later:
                    out.append(f"{rels[i]} uses {u}, defined later in {later[0]}")
            defined |= defs
    return out


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    if not args or args[0].lower() not in list(CLIENTS) + ["all"]:
        sys.exit(__doc__)
    root = os.path.abspath(args[1]) if len(args) > 1 else DEFAULT_ROOT
    clients = list(CLIENTS) if args[0].lower() == "all" else [args[0].lower()]
    bad = 0
    for client in clients:
        order = Order(client, root).load()
        found = problems(order)
        print(f"== {client}: {', '.join(order.tocs)}; {len(order.files)} files")
        if "--list" in argv:
            for addon, rel in order.files:
                print(f"   {addon}: {rel}")
        for by, rel in order.missing:
            print(f"   MISSING {rel} (named in {by})")
        for p in found:
            print(f"   ORDER {p}")
        bad += len(order.missing) + len(found)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main(sys.argv[1:])
