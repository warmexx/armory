"""Meet hoeveel elke kopie per familie of spel nog verschilt van het gedeelde bestand.

Gebruik: python -I dev/copies.py [repo]
Standaard: deze repo.

Voor elk bestand in een map Classic, Vanilla of TBC zoekt het script het gedeelde bestand
met dezelfde naam (in de bovenliggende map, of in Core, Frames of Tools) en telt het
de verschillende regels, met witruimte en Revision-regels genegeerd. Kleinste eerst;
"-" betekent dat er geen gedeeld bestand is.

Laadt een Classic-client het gedeelde bestand ook (zoals Core\ArmoryStubs.lua naast
Core\Classic\ArmoryStubs.lua), dan is het bestand in de familiemap een aanvulling en geen
kopie. Zulke bestanden staan apart onderaan.
"""
import os,sys,difflib
root=sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def lines(p):
    out=[]
    for l in open(p,encoding="utf-8",errors="replace"):
        s="".join(l.split())
        if s and "$Revision" not in l and "$Date" not in l: out.append(s)
    return out
import re
def loaded(toc):
    """Files a TOC loads, through its XML lists (lowercase, relative to root)."""
    out=set()
    def walk(q):
        q=os.path.normpath(q)
        if q.lower() in out or not os.path.exists(q): return
        out.add(q.lower())
        if q.endswith(".xml"):
            for m in re.finditer(r'<(?:Script|Include)\s+file="([^"]+)"',open(q,encoding="utf-8",errors="replace").read()):
                walk(os.path.join(os.path.dirname(q),m.group(1).replace("\\",os.sep)))
    folder=os.path.dirname(toc)
    if os.path.exists(toc):
        for l in open(toc,encoding="utf-8",errors="replace"):
            l=l.strip()
            if l and not l.startswith("#"): walk(os.path.join(folder,l.replace("\\",os.sep)))
    return out
classic_loads=[loaded(os.path.join(root,t)) for t in ("Armory_Vanilla.toc","Armory_TBC.toc",os.path.join("ArmoryGuildBank","ArmoryGuildBank_TBC.toc"))]
def supplement(p,s):
    return any(p.lower() in l and s.lower() in l for l in classic_loads)
supplements=[]
rows=[]
for d,dn,fn in os.walk(root):
    dn[:]=[x for x in dn if x.lower() not in ("libs","locales","dev","docs",".git")]
    b=os.path.basename(d)
    if b not in ("Classic","Vanilla","TBC"): continue
    parent=os.path.dirname(d)
    for f in fn:
        p=os.path.join(d,f); 
        cands=[os.path.join(parent,f),os.path.join(parent,"Mainline",f)]
        if parent.endswith("Frames") or parent.endswith("Tools") or parent.endswith("Core"):
            cands+= [os.path.join(os.path.dirname(parent),x,f) for x in ("Tools","Frames","Core")]
        s=next((c for c in cands if os.path.exists(c)),None)
        if not s: rows.append((99999,os.path.relpath(p,root),"-")); continue
        if supplement(p,s): supplements.append((os.path.relpath(p,root),os.path.relpath(s,root))); continue
        a,bb=lines(s),lines(p); n=0
        for t,i1,i2,j1,j2 in difflib.SequenceMatcher(None,a,bb,autojunk=False).get_opcodes():
            if t!="equal": n+=max(i2-i1,j2-j1)
        rows.append((n,os.path.relpath(p,root),os.path.relpath(s,root)))
for r in sorted(rows): print(*r,sep="\t")
if supplements:
    print("\nAanvulling naast het gedeelde bestand (geen kopie):")
    for r in sorted(supplements): print(*r,sep="\t")
