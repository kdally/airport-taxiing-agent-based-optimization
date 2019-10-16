# -*- coding: utf-8 -*-
"""
Created on Tue Oct 15 13:21:22 2019
"""

#INSTRUCTIONS (!!!):
#MEASURE RUNS USING THESE REPORTERS ON BEHAVIORSPACE: link-list

import ast
import pandas as pd
import numpy as np

df = pd.read_csv(r"C:\Users\Bram\Desktop\Master\Agent-Based Modelling\Assignment 2\Behavior space\link-traffic.csv", skiprows = 20)
df.columns = ["to delete", "Link Traffic"]
df = df.drop("to delete", 1)

for i in range(len(df)):
    df.iloc[i][0] = df.iloc[i][0].replace(' ', ',')
    df.iloc[i][0] = ast.literal_eval(df.iloc[i][0])    

lst = []
for i in range(len(df)):
    lst.append(df.iloc[i][0])
toarray = np.array(lst)

df1 = pd.DataFrame(toarray)
df1_mean = df1.mean(axis=0)
df1_mean.columns = ["mean traffic per link"]
df1_std = df1.std(axis=0)

#average traffic per link, and standard deviation
plot = df1_mean.plot.bar(width = 0.3, figsize=(15,6))
plot.set_xlabel("Link")
plot.set_ylabel("Number of aircraft")
fig = plot.get_figure()
#saved in same folder as this file
fig.savefig("Link-traffic.png")

