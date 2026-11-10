# Generates WoodScraps recipe script: wooden items -> splinters (count = weight/0.2, floor, min 1), splinters -> plank.
import re,glob,os,sys,collections
V=sys.argv[1]; OUT=sys.argv[2]
items={}
for f in glob.glob(V+'/scripts/generated/items/*.txt'):
    t=open(f,encoding='utf-8',errors='ignore').read()
    for m in re.finditer(r'^\s*item (\w+)\s*\{(.*?)^\s*\}',t,re.S|re.M):
        w=re.search(r'Weight\s*=\s*([\d.]+)',m.group(2)); items[m.group(1)]=float(w.group(1)) if w else None
# pure-wood items that are not raw building materials (see _devnotes/WoodScraps/README.md)
TOOL=["Dice_Wood","WoodenFork","WoodenSpoon","Chopsticks","SkewersWooden","SmokingPipe","ClayTool_Carved",
 "KnittingNeedles_Wood","WoodenBarCastMold","WoodenBenchAnvilMold","WoodenBlacksmithAnvilMold","WoodenBlockAnvilMold",
 "WoodenBrickMold","WoodenCrudeBenchVisePartsMold","WoodenIngotCastMold","WoodenShingleMold","WoodenTileMold",
 "Goblet_Wood","MasonsTrowel_Wood","SmallHandle","Stake","Drumstick",
 "UnusableWood","Plank_Broken","CuttingBoardWooden","CrudeWoodenTongs","Handle","WoodenStick_Broken","LongHandle_Broken",
 "Branch_Broken","ShortBat","WoodenMallet","GardenToolHandle_Broken","LongStick_Broken","BaseballBat_Broken",
 "FieldHockeyStick_Broken","FieldHockeyStick","IceHockeyStick",
 "BaseballBat","BaseballBat_Crafted","SpadeWood","SpearCrafted","SpearCraftedFireHardened","LongHandle"]
# caps where vanilla makes several from one plank (tools/check_loops.py): 6 Handle or 12 SmallHandle per plank
CAP={"Handle":2,"SmallHandle":1}
groups=collections.defaultdict(list)
for k in TOOL:
    w=items[k]; n=min(CAP.get(k,99),max(1,int(round(w/0.2,6)//1)))  # floor of weight/0.2, min 1
    groups[n].append(k)
L=["module Base","{"]
def rec(name,time,action,cat,tags,inputs,outputs,xp=None,skill=None):
    L.append(f"    craftRecipe {name}"); L.append("    {")
    L.append(f"        timedAction = {action},"); L.append(f"        time = {time},")
    L.append(f"        Tags = {tags},"); L.append(f"        category = {cat},")
    if skill: L.append(f"        SkillRequired = {skill},")
    if xp: L.append(f"        xpAward = {xp},")
    L.append("        inputs"); L.append("        {")
    for i in inputs: L.append("            "+i+",")
    L.append("        }"); L.append("        outputs"); L.append("        {")
    for o in outputs: L.append("            "+o+",")
    L.append("        }"); L.append("    }"); L.append("")
CUT="item 1 tags[base:sharpknife;base:choptree;base:saw;base:crudesaw] mode:keep flags[MayDegradeLight;Prop1]"
# twigs by hand
rec("WoodScraps_BreakTwigs",10,"Making","Carpentry","InHandCraft;CanBeDoneFromFloor",
    ["item 1 [Base.Twigs] flags[Prop2]"],["item 1 Base.Splinters"])
rec("WoodScraps_BreakTwigsBundle",60,"Making","Carpentry","InHandCraft;CanBeDoneFromFloor",
    ["item 1 [Base.TwigsBundle] flags[Prop2]"],["item 12 Base.Splinters"])
for n in sorted(groups):
    lst=";".join("Base."+k for k in sorted(groups[n]))
    t=30+10*n  # vanilla ChopLog 60 for 6 firewood, ChopLargeBranch 40
    rec(f"WoodScraps_Splinter{n}",t,"SharpenStakeWood","Carpentry","InHandCraft;CanBeDoneFromFloor",
        [f"item 1 [{lst}] flags[Prop2;AllowDestroyedItem]",CUT],[f"item {n} Base.Splinters"])
rec("WoodScraps_PressPlank",120,"MakingHammer_Surface","Carpentry","InHandCraft;CanBeDoneFromFloor",
    ["item 15 [Base.Splinters] flags[Prop2]",
     "item 1 tags[base:hammer;base:clubhammer;base:mallet] mode:keep flags[MayDegradeLight;Prop1]"],
    ["item 1 Base.Plank"],xp="Woodwork:5",skill="Woodwork:5")
L.append("}")
os.makedirs(os.path.dirname(OUT),exist_ok=True)
open(OUT,'w',encoding='utf-8',newline='\n').write("\n".join(L)+"\n")
for n in sorted(groups): print(n, groups[n])
