using CSV, Downloads # loading 
using DataFrames, Pipe, Dates # wrangling

remotedir = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2023/2023-05-09/"
localdir = "230509/"
names = ["childcare_costs", "counties"]
sfx = ".csv"

# Download tidytuesday data
[Downloads.download(string(remotedir, n, sfx), string(localdir, n, sfx)) for n in names]

# Download 2016 election results data
Downloads.download(
    "https://raw.githubusercontent.com/openelections/openelections-data-us/master/2016/20161108__us__general__president__county.csv",
    string(localdir, "us_elections", sfx)
)

# Initialise dictionary
dfs = Dict{String,DataFrame}()

# Read files into dictionary
[dfs[n] = CSV.read(string(localdir, n, sfx), DataFrame) for n in [names..., "us_elections"]]

# we could get 2016 data and see if our childcare values predict election results

x = @pipe dfs["us_elections"] |>
          subset(_, :party => ByRow(x -> passmissing(occursin)(r"REP|DEM", x)), skipmissing=true) |>
          groupby(_, [:state, :party]) |>
          combine(_, :votes => sum => :sum_votes)
