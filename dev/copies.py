"""Meet hoeveel elke kopie per familie of spel nog verschilt van het gedeelde bestand.

Gebruik: python -I dev/copies.py [repo]
Standaard: deze repo.

Voor elk bestand in een map Classic, Vanilla of TBC zoekt het script het gedeelde bestand
met dezelfde naam (in de bovenliggende map, of in Core, Frames of Tools) en telt het
de verschillende regels, met witruimte en Revision-regels genegeerd. Kleinste eerst;
"-" betekent dat er geen gedeeld bestand is.
"""
import os,sys,difflib
root=sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def lines(p):
    out=[]
    for l in open(p,encoding="utf-8",errors="replace"):
        s="".join(l.split())
        if s and "$Revision" not in l and "$Date" not in l: out.append(s)
    return out
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
        a,bb=lines(s),lines(p); n=0
        for t,i1,i2,j1,j2 in difflib.SequenceMatcher(None,a,bb,autojunk=False).get_opcodes():
            if t!="equal": n+=max(i2-i1,j2-j1)
        rows.append((n,os.path.relpath(p,root),os.path.relpath(s,root)))
for r in sorted(rows): print(*r,sep="\t")
