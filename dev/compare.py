"""Vergelijkt Lua- en XML-bestanden tussen versiemappen van Armory.

Gebruik: python -I dev/compare.py [map ...]
Standaard: deze repo, _archive/_era en _archive/_bcc.

Per bestand (zonder Libs en Locales) het aantal verschillende regels per paar,
witruimte, regeleinden en Revision-regels genegeerd. Paden worden zonder
hoofdletters vergeleken (ArmoryGuildbank in BCC).
"""
import difflib
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {"libs", "locales", "dev", "docs", ".git", ".release", ".vscode", ".tokensave", ".claude", "_archive"}
EXTS = (".lua", ".xml", ".toc")


def collect(base):
    files = {}
    for dirpath, dirnames, filenames in os.walk(base):
        dirnames[:] = [d for d in dirnames if d.lower() not in SKIP_DIRS]
        for f in filenames:
            if f.lower().endswith(EXTS):
                full = os.path.join(dirpath, f)
                rel = os.path.relpath(full, base).replace("\\", "/")
                files[rel.lower()] = (rel, full)
    return files


def lines(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        out = []
        for line in fh:
            s = "".join(line.split())
            if not s or "$Revision" in line or "$Date" in line:
                continue
            out.append(s)
        return out


def ndiff(a, b):
    n = 0
    for tag, i1, i2, j1, j2 in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes():
        if tag != "equal":
            n += max(i2 - i1, j2 - j1)
    return n


def main():
    names = sys.argv[1:] or [".", "_archive/_era", "_archive/_bcc"]
    trees = [collect(os.path.join(ROOT, n)) for n in names]
    keys = sorted(set().union(*trees))
    pairs = [(i, j) for i in range(len(names)) for j in range(i + 1, len(names))]
    print("file\t" + "\t".join(f"{names[i]}-{names[j]}" for i, j in pairs))
    cache = {}
    for k in keys:
        row = []
        for i, j in pairs:
            a, b = trees[i].get(k), trees[j].get(k)
            if a is None and b is None:
                row.append("")
            elif a is None:
                row.append(f"only {names[j]}")
            elif b is None:
                row.append(f"only {names[i]}")
            else:
                la = cache.setdefault(a[1], lines(a[1]))
                lb = cache.setdefault(b[1], lines(b[1]))
                row.append(str(ndiff(la, lb)))
        rel = next(t[k][0] for t in trees if k in t)
        print(rel + "\t" + "\t".join(row))


if __name__ == "__main__":
    main()
