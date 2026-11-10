# Finds vanilla recipes that make a splinterable item from fewer splinters' worth of wood than the item gives back.
# Value in splinters: Plank 15 (pressing), Log 45 (3 planks), LargeBranch 15 (1 plank), our items = their splinter count.
# Usage: python -I check_loops.py <vanilla media> <WoodScraps_recipes.txt>
import re,glob,sys
V,R=sys.argv[1],sys.argv[2]
val={"Plank":15,"Log":45,"LargeBranch":15,"Splinters":1,"Twigs":1,"TwigsBundle":12}
for m in re.finditer(r'craftRecipe (WoodScraps_Splinter(\d+)).*?\[([^\]]*)\]',open(R,encoding='utf-8').read(),re.S):
    for it in m.group(3).split(';'): val[it.replace('Base.','')]=int(m.group(2))
bad=0
for f in glob.glob(V+'/scripts/**/*.txt',recursive=True):
    t=open(f,encoding='utf-8',errors='ignore').read()
    for b in re.split(r'\bcraftRecipe\s+',t)[1:]:
        name=b.split()[0]
        i=re.search(r'inputs\s*\{(.*?)\n\s*\}',b,re.S); o=re.search(r'outputs\s*\{(.*?)\n\s*\}',b,re.S)
        if not i or not o: continue
        out=sum(int(n)*val.get(it,0) for n,it in re.findall(r'item (\d+) Base\.(\w+)',o.group(1)))
        if out==0: continue
        inn=0; unknown=[]
        for line in i.group(1).splitlines():
            if 'mode:keep' in line: continue
            mm=re.search(r'item (\d+) \[([^\]]*)\]',line)
            if not mm: continue
            opts=[x.split(':')[-1].replace('Base.','') for x in mm.group(2).split(';')]
            vs=[val.get(x) for x in opts]
            if any(v is None for v in vs): unknown.append(mm.group(2)[:50]); continue
            inn+=int(mm.group(1))*min(vs)
        if out>inn and not unknown:
            bad+=1; print(f"LOOP {name}: in {inn} -> out {out} splinters  ({f.split('scripts')[-1]})")
print("loops:",bad)
