# Data from Portal Project https://portal.weecology.org/

using CSV, Downloads, DataFrames

root = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2023/2023-05-02/"
names = ["plots", "species", "surveys"]
sfx = ".csv"

# Download data
[Downloads.download(string(root, n, sfx), string(n, sfx)) for n in names]

# Initialise dictionary
dfs = Dict{Symbol, DataFrame}()

# Read files into dictionary
[dfs[Symbol(n)] = CSV.read(string(n, sfx), DataFrame) for n in names]
