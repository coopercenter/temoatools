import pandas as pd
d = pd.read_excel("BiomassVABioFuel2016Calc.xlsx",sheet_name= None)
sheetnames = d.keys()
#sheetnames = ["Softwood Natural Residue"]
#df = pd.read_excel("BiomassVABioFuel2016Calc.xlsx",sheet_name="Softwood Natural Residue")
results = pd.DataFrame(index = sheetnames, columns=["min","max"],dtype="float")
tot_y_max = 0.0
tot_y_min = 0.0
for s in sheetnames:
    df = pd.read_excel("BiomassVABioFuel2016Calc.xlsx",sheet_name = s)
    counties = df.County.unique()
    for c in counties:
        ind = df.loc[:,"County"]==c
        #Highest Value
        tot_y_max = tot_y_max + df.loc[ind, "Yield"].max()
        results.loc[s,"max"]=tot_y_max
        #Lowest Value
        tot_y_min = tot_y_min + df.loc[ind, "Yield"].min()
        results.loc[s,"min"]=tot_y_min

print(tot_y_max)
print(tot_y_min)

results.to_csv("BiomassPotentialVA.csv")