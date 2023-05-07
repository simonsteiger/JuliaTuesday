using CSV, Downloads # loading 
using DataFrames, CategoricalArrays, Pipe, Dates # wrangling
using CairoMakie # plotting
using AlgebraOfGraphics

remotedir = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2023/2023-05-09/"
localdir = "230509/"
names = ["childcare_costs", "counties"]
sfx = ".csv"

# Download data
[Downloads.download(string(remotedir, n, sfx), string(localdir, n, sfx)) for n in names]

# Initialise dictionary
dfs = Dict{String, DataFrame}()

# Read files into dictionary
[dfs[n] = CSV.read(string(localdir, n, sfx), DataFrame) for n in names]