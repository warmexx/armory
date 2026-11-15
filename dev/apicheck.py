"""Which global functions, events and Enum values does Armory use that a client does not know at all?

Enum values are checked against the generated API documentation; Classic names some of them
differently (Enum.ItemQuality.Standard where Mainline has Common).

loadcheck.py finds names that Blizzard defines only in files a client does not load.
This script finds names that are defined nowhere: not in Blizzard's Lua or XML code
(loaded or not), not in the generated API documentation, and not in Armory or its libs.
A name counts as known when Blizzard's code defines or calls it, or the API documentation
names it. Typical hits are removed APIs (ChatFrame_OnHyperlinkShow, GuildRoster) and removed
events (LEARNED_SPELL_IN_TAB). Expect some noise: C functions that Blizzard never calls, and
optional functions of other addons.

It also lists methods (":Name(" or "Armory.Name(") that a loaded file calls, but that are
defined only in Armory files this client does not load, for example a function that only
exists in the copy of the other family.

Usage: python -I dev/apicheck.py <client> [armory-source-folder]
  client: retail, forever, era or anniversary
"""
import os
import re
import sys

WOW = r"D:\Games\World of Warcraft"
FOLDERS = {"retail": "_retail_", "forever": "_forever_", "era": "_classic_era_", "anniversary": "_anniversary_"}
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import loadorder  # noqa: E402  (which Armory files a client loads)

if len(sys.argv) < 2 or sys.argv[1].lower() not in FOLDERS:
    sys.exit(__doc__)
CLIENT = sys.argv[1].lower()
ROOT = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE = os.path.join(WOW, FOLDERS[CLIENT], "BlizzardInterfaceCode", "Interface")

LUA_GLOBALS = set("""assert collectgarbage error getfenv getmetatable ipairs load loadstring next pairs pcall
print rawequal rawget rawset select setfenv setmetatable tonumber tostring type unpack xpcall require
format strsplit strjoin strtrim strlower strupper strlen strsub strfind strmatch strrep strbyte strchar
gsub gmatch tinsert tremove wipe sort floor ceil abs max min mod sqrt random date time debugstack
geterrorhandler seterrorhandler securecall issecure hooksecurefunc getglobal setglobal tostringall
strconcat strcmputf8i debugprofilestop bit math string table coroutine""".split())


def read(p):
    with open(p, encoding="utf-8", errors="ignore") as f:
        return f.read()


def strip_lua(t):
    t = re.sub(r"--\[(=*)\[.*?\]\1\]", "", t, flags=re.S)
    t = re.sub(r"--[^\n]*", "", t)
    return re.sub(r"\"(?:\\.|[^\"\\\n])*\"|'(?:\\.|[^'\\\n])*'", "\"\"", t)


known = set(LUA_GLOBALS)
events = set()
enums = {}
blizzard_methods = set()  # widget and mixin methods Blizzard's code calls
for dp, _, fns in os.walk(BASE):
    for fn in fns:
        p = os.path.join(dp, fn)
        if fn.endswith(".lua"):
            t = read(p)
            if "APIDocumentation" in dp:
                for m in re.finditer(r'Name\s*=\s*"(\w+)",\s*Type\s*=\s*"Enumeration".*?Fields\s*=\s*\{(.*?)\n\t*\},', t, re.S):
                    enums.setdefault(m.group(1), set()).update(re.findall(r'Name\s*=\s*"(\w+)"', m.group(2)))
            known |= set(re.findall(r"\bfunction\s+([A-Za-z_]\w*)\s*\(", t))
            known |= set(re.findall(r"^\s*([A-Za-z_]\w*)\s*=", t, re.M))
            known |= set(re.findall(r"^\s*(?:local\s+)?([A-Za-z_]\w*)\s*=", t, re.M))
            known |= set(re.findall(r"^\t+([A-Za-z_]\w*)\s*=\s*function", t, re.M))
            if "APIDocumentation" in dp:
                known |= set(re.findall(r'Name\s*=\s*"(\w+)"', t))
                events |= set(re.findall(r'LiteralName\s*=\s*"(\w+)"', t))
            events |= set(re.findall(r'RegisterEvent\(\s*"(\w+)"', t))
            # whatever Blizzard's own code calls, the client has (C functions without documentation)
            known |= set(re.findall(r"(?<![\w.:])([A-Za-z_]\w*)\s*\(", strip_lua(t)))
            blizzard_methods |= set(re.findall(r"[:.]([A-Za-z_]\w*)\s*\(", strip_lua(t)))
        elif fn.endswith(".xml"):
            known |= set(re.findall(r'name="([A-Za-z_]\w*)"', read(p)))

# Armory's own files (all of them, any client) and its libs
own_files = []
for dp, dns, fns in os.walk(ROOT):
    dns[:] = [d for d in dns if d not in (".git", "dev", "docs")]
    own_files += [os.path.join(dp, fn) for fn in fns if fn.endswith((".lua", ".xml"))]
for p in own_files:
    t = read(p)
    if p.endswith(".lua"):
        c = strip_lua(t)
        known |= set(re.findall(r"\bfunction\s+([A-Za-z_]\w*)\s*\(", c))
        known |= set(re.findall(r"(?:^|[\s;])([A-Za-z_]\w*)\s*=[^=]", c, re.M))
        known |= set(re.findall(r"\b_G\.([A-Za-z_]\w*)\s*=[^=]", c))
    else:
        known |= set(re.findall(r'name="([A-Za-z_]\w*)"', t))

# Armory's files that this client loads, through the TOC with its conditions (loadorder.py),
# plus Bindings.xml of each addon the client loads (no guild bank in Era)
def toc_files():
    order = loadorder.Order(CLIENT, ROOT).load()
    out = [os.path.join(ROOT, rel) for _, rel in order.files]
    for addon, sub in loadorder.ADDONS:
        bindings = os.path.join(ROOT, sub, "Bindings.xml")
        if any(a == addon for a, _ in order.files) and os.path.exists(bindings):
            out.append(bindings)
    return out


hits, ev_hits, enum_hits = {}, {}, {}
for p in toc_files():
    rel = os.path.relpath(p, ROOT)
    t = read(p)
    if p.endswith(".xml"):
        t = " ".join(re.findall(r">([^<]*)</(?:On\w+|Binding)>", t))
    raw = t
    t = strip_lua(t)
    for n in re.findall(r"(?<![\w.:])(?:_G\.)?([A-Za-z_]\w*)\s*\(", t):
        if n not in known and n not in ("function", "if", "elseif", "while", "and", "or", "not", "return", "until"):
            hits.setdefault(n, set()).add(rel)
    for n in re.findall(r"\b_G\.([A-Za-z_]\w*)", t):
        if n not in known:
            hits.setdefault(n, set()).add(rel)
    for n in re.findall(r'RegisterEvent\(\s*"(\w+)"', raw):
        if n not in events:
            ev_hits.setdefault(n, set()).add(rel)
    # Enum.X.Y with a field this client does not have (Classic: ItemQuality.Standard, not Common);
    # "Enum.X.Y or ..." and "... or Enum.X.Y" are a fallback or a branch per version, and do not count
    for m in re.finditer(r"(?<!\bor )\bEnum\.(\w+)\.(\w+)\b(?!\s+or\b)", t):
        e, v = m.groups()
        if e not in enums or v not in enums[e]:
            enum_hits.setdefault(f"Enum.{e}.{v}", set()).add(rel)

# Methods that a loaded file calls, defined only in Armory files this client does not load
METHOD_DEF = re.compile(r"function\s+[\w.]+[:.]([A-Za-z_]\w*)\s*\(|[\w\])]\.([A-Za-z_]\w*)\s*=(?!=)|^\s*([A-Za-z_]\w*)\s*=\s*function\b", re.M)


def method_defs(paths):
    out = set()
    for q in paths:
        for m in METHOD_DEF.finditer(strip_lua(read(q))):
            out.add(m.group(1) or m.group(2) or m.group(3))
    return out


loaded = [q for q in toc_files() if q.endswith(".lua")]
repo = []
for d, dn, fn in os.walk(ROOT):
    dn[:] = [x for x in dn if x.lower() not in ("libs", "dev", "docs", ".git")]
    repo += [os.path.join(d, f) for f in fn if f.endswith(".lua")]
loaded_defs = method_defs(loaded)
other_defs = method_defs([q for q in repo if q not in set(loaded)]) - loaded_defs
method_hits = {}
for q in loaded:
    for n in re.findall(r"(?::|\bArmory\.)([A-Za-z_]\w*)\s*\(", strip_lua(read(q))):
        if n in other_defs and n not in blizzard_methods:
            method_hits.setdefault(n, set()).add(os.path.relpath(q, ROOT))

print(f"Client: {CLIENT}, Armory source: {ROOT}\n")
print("=== Global functions used by Armory that this client does not define")
for n in sorted(hits):
    print(f"{n:45s} <- {', '.join(sorted(hits[n])[:3])}")
print("\n=== Events registered by Armory that this client does not know")
for n in sorted(ev_hits):
    print(f"{n:45s} <- {', '.join(sorted(ev_hits[n])[:3])}")
print("\n=== Enum values used by Armory that this client does not have")
for n in sorted(enum_hits):
    print(f"{n:45s} <- {', '.join(sorted(enum_hits[n])[:3])}")
print("\n=== Methods called by Armory, defined only in Armory files this client does not load")
for n in sorted(method_hits):
    print(f"{n:45s} <- {', '.join(sorted(method_hits[n])[:3])}")
