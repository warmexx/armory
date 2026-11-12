"""Cross-reference Forever's paperdoll stat code with Armory's stubs.

For every stat that Forever's PAPERDOLL_STATCATEGORIES shows, follow the update
function through Blizzard's Lua (last definition wins, in TOC load order) and
collect every external call. Then report which of those Armory caches.
"""
import re
from pathlib import Path

UI = Path(r"D:\Games\World of Warcraft\_forever_\BlizzardInterfaceCode\Interface\AddOns")
GAME = UI / "Blizzard_UIPanels_Game"
LOAD_ORDER = [
    GAME / "Camelot" / "PaperDollFrameConstants.lua",
    GAME / "Camelot" / "PaperDollFrame.lua",
    GAME / "Vanilla" / "PaperDollFrameStats.lua",
    GAME / "Cata" / "PaperDollFrameStats.lua",
    GAME / "Camelot" / "PaperDollFrameStats.lua",
]
ARMORY = Path(r"D:\Development\WOW\AddOns\Armory\_forever")

FUNC_RE = re.compile(r"^(local\s+)?function\s+([A-Za-z_][\w.:]*)\s*\(", re.M)
CALL_RE = re.compile(r"(?<![\w.:])([A-Za-z_][\w]*(?:\.[A-Za-z_]\w*)?)\s*\(")
LUA_KEYWORDS = {"if", "elseif", "while", "for", "return", "and", "or", "not", "function", "local", "until", "in"}
LUA_BUILTINS = {
    "format", "max", "min", "floor", "ceil", "abs", "tostring", "tonumber", "type", "select", "pairs", "ipairs",
    "next", "unpack", "strupper", "strlower", "strsub", "strlen", "tinsert", "tremove", "wipe", "print", "error",
    "assert", "pcall", "securecall", "rawget", "setmetatable", "getmetatable", "math.max", "math.min", "math.floor",
    "math.ceil", "math.abs", "string.format", "table.insert", "table.wipe", "table.remove", "string.find",
    "string.match", "string.gsub", "_G", "issecretvalue", "hasanysecretvalues",
}


def extract_functions(path):
    text = path.read_text(encoding="utf-8", errors="replace")
    funcs = {}
    matches = list(FUNC_RE.finditer(text))
    for i, m in enumerate(matches):
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        body = text[start:end]
        # cut at first top-level "end"
        cut = re.search(r"^end\b", body, re.M)
        if cut:
            body = body[: cut.end()]
        funcs[m.group(2)] = (path.name, path.parent.name, body)
    return funcs, text


defs = {}
statinfo_text = ""
for p in LOAD_ORDER:
    f, text = extract_functions(p)
    defs.update(f)
    if "PAPERDOLL_STATINFO = {" in text:
        statinfo_text = text

# stat -> update function
statinfo = {}
for m in re.finditer(r'\["([A-Z_]+)"\]\s*=\s*\{\s*(?:--[^\n]*\n\s*)?updateFunc\s*=\s*function\([^)]*\)\s*return\s+([A-Za-z_]\w*)\(([^)]*)\)', statinfo_text):
    statinfo[m.group(1)] = (m.group(2), m.group(3))

consts = (GAME / "Camelot" / "PaperDollFrameConstants.lua").read_text(encoding="utf-8")
shown = []
for cat in re.finditer(r"categoryName\s*=\s*(\w+),\s*unit\s*=\s*\"(\w+)\",\s*stats\s*=\s*\{(.*?)\n\t\t\},", consts, re.S):
    for s in re.findall(r'stat\s*=\s*"([A-Z_]+)"', cat.group(3)):
        shown.append((cat.group(1), cat.group(2), s))

# Armory stubs
armory_methods = set()
for lua in ARMORY.rglob("*.lua"):
    for m in re.finditer(r"^function\s+Armory:(\w+)\s*\(", lua.read_text(encoding="utf-8", errors="replace"), re.M):
        armory_methods.add(m.group(1))


def walk(name, seen, calls):
    if name in seen or name not in defs:
        return
    seen.add(name)
    body = defs[name][2]
    body = re.sub(r"--[^\n]*", "", body)
    first = True
    for m in CALL_RE.finditer(body):
        callee = m.group(1)
        if first:  # skip the function's own name in its header
            first = False
            if callee == name.split(".")[-1] or callee == name:
                continue
        if callee in LUA_KEYWORDS or callee in LUA_BUILTINS:
            continue
        if callee in defs:
            walk(callee, seen, calls)
        else:
            calls.setdefault(callee, set()).add(name)


API_HINT = re.compile(r"^(C_\w+\.\w+|Unit\w+|Get\w+|Is\w+|Has\w+|ComputePetBonus|BreakUpLargeNumbers)$")

all_external = {}
print("=== Forever stats per category, with the functions they reach and external calls\n")
for cat, unit, stat in shown:
    func = statinfo.get(stat, ("?", ""))[0]
    seen, calls = set(), {}
    walk(func, seen, calls)
    apis = sorted(c for c in calls if API_HINT.match(c) and not c.startswith("PaperDoll"))
    for a in apis:
        all_external.setdefault(a, set()).add(f"{stat}({unit})")
    where = defs.get(func, ("MISSING", "", ""))
    print(f"[{cat} / {unit}] {stat} -> {func}  ({where[1]}\\{where[0]})")
    print("    API: " + ", ".join(apis))

print("\n=== API calls and whether Armory has a method with the same name\n")
for api in sorted(all_external):
    short = api.split(".")[-1]
    has = "yes" if short in armory_methods else "NO "
    print(f"{has}  {api:45s} <- {', '.join(sorted(all_external[api]))}")
