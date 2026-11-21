"""Meet hoeveel elke kopie per familie of spel nog verschilt van het bestand dat er het meest op lijkt.

Gebruik: python -I dev/copies.py [repo]
Standaard: deze repo.

Voor elk bestand in een map Classic, Vanilla, TBC, Mainline of Forever zoekt het script alle
bestanden met dezelfde naam: het gedeelde bestand (in de bovenliggende map, of in Core, Frames
of Tools) en dezelfde naam in de andere familie- en spelmappen. Het telt de verschillende regels,
met witruimte en Revision-regels genegeerd, en toont het bestand dat het minst verschilt.
Een paar (zoals Forever en Mainline) staat er één keer in. Kleinste eerst; "-" betekent dat er
geen bestand met dezelfde naam is. De kolom "regels" is de lengte van de kopie: hoe dichter het
verschil daar onder blijft, hoe meer dubbele code.

Laadt een client beide bestanden (zoals Core\ArmoryStubs.lua naast Core\Classic\ArmoryStubs.lua,
of de stats van de paperdoll in Vanilla naast die in Classic, of in Forever naast die van Mainline),
dan is het bestand in de familiemap een aanvulling en geen kopie. Zulke bestanden staan apart onderaan.
"""
import os,sys,difflib
root=sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAMILIES=("Classic","Vanilla","TBC","Mainline","Forever")
GENERAL={"Vanilla":("Classic",),"TBC":("Classic",),"Forever":("Mainline",)}  # a game folder may supplement its family folder
def lines(p):
    out=[]
    for l in open(p,encoding="utf-8",errors="replace"):
        s="".join(l.split())
        if s and "$Revision" not in l and "$Date" not in l: out.append(s)
    return out
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import loadorder
def loaded(client):
    """Files a client loads, through the TOCs with their conditions (lowercase, full paths)."""
    return {os.path.join(root,rel).lower() for _,rel in loadorder.Order(client,root).load().files}
loads=[loaded(c) for c in loadorder.CLIENTS]
def supplement(p,s):
    return any(p.lower() in l and s.lower() in l for l in loads)
def diff(a,b):
    n=0
    for t,i1,i2,j1,j2 in difflib.SequenceMatcher(None,a,b,autojunk=False).get_opcodes():
        if t!="equal": n+=max(i2-i1,j2-j1)
    return n
def rel(p): return os.path.relpath(p,root)
supplements=set()
pairs={}
for d,dn,fn in os.walk(root):
    dn[:]=[x for x in dn if x.lower() not in ("libs","locales","dev","docs",".git",".release",".tokensave","_archive")]
    b=os.path.basename(d)
    if b not in FAMILIES: continue
    parent=os.path.dirname(d)
    bases=[parent]
    if os.path.basename(parent) in ("Core","Frames","Tools"):
        bases+=[os.path.join(os.path.dirname(parent),x) for x in ("Core","Frames","Tools") if x!=os.path.basename(parent)]
    for f in fn:
        p=os.path.join(d,f)
        cands=[]
        for base in bases:
            cands+=[os.path.join(base,f)]+[os.path.join(base,x,f) for x in FAMILIES if x!=b]
        cands=[c for c in cands if os.path.exists(c)]
        co=[c for c in cands if supplement(p,c)]
        sup=[c for c in co if os.path.basename(os.path.dirname(c)) in GENERAL.get(b,())+("Core","Frames","Tools","Shared")
             or os.path.basename(os.path.dirname(c)) not in FAMILIES]
        if sup:
            supplements.add((rel(p),rel(sup[0]))); continue
        cands=[c for c in cands if c not in co]
        a=lines(p)
        if not cands:
            pairs[(rel(p),"-")]=(99999,len(a)); continue
        n,s=min((diff(lines(c),a),c) for c in cands)
        key=tuple(sorted((rel(p),rel(s))))
        if key not in pairs: pairs[(rel(p),rel(s))]=(n,len(a))
rows=sorted((n,size,p,s) for (p,s),(n,size) in pairs.items())
print("verschil\tregels\tkopie\tlijkt het meest op")
for r in rows: print(*r,sep="\t")
if supplements:
    print("\nAanvulling naast een bestand dat de client ook laadt (geen kopie):")
    for r in sorted(supplements): print(*r,sep="\t")
