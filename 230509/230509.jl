using CSV, Downloads # Loading 
using DataFrames, Pipe # Wrangling
using MultivariateStats, StatsBase # PCA

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
[dfs[n] = CSV.read(string(localdir, n, sfx), DataFrame, missingstring="NA") for n in names]
dfs["us_elections"] = CSV.read(string(localdir, "us_elections", sfx), DataFrame)

# Join counties and childcare_costs
data_cc = @pipe dfs["childcare_costs"] |>
                subset(_, :study_year => x -> x .== 2018) |>
                subset(_, All() .=> ByRow(x -> !ismissing(x))) |>
                innerjoin(_, dfs["counties"], on=:county_fips_code) |>
                transform(_, :county_name => ByRow(x -> replace(x, r"\s+County$" => "")) => :county_name)

# Join childcare_counties with election results
data_ccele = @pipe dfs["us_elections"] |>
                   subset(_, :party => ByRow(x -> passmissing(occursin)(r"REP|DEM", x)), skipmissing=true) |>
                   subset(_, :county => ByRow(x -> !ismissing(x))) |>
                   groupby(_, [:county, :party]) |>
                   combine(_, :votes => sum => :sum_votes) |>
                   unstack(_, :party, :sum_votes) |>
                   transform(_, [:DEM, :REP] => ByRow((x, y) -> x / (x + y)) => :ratio_DEM) |>
                   innerjoin(_, data_cc, on=:county => :county_name) |>
                   select(_, Not([:DEM, :REP, :county_fips_code, :study_year, :state_name, :state_abbreviation]))

# Training
Xtr = Matrix(data_ccele[1:2:end, 3:61])'

# Must be of type Float64
Xtr = convert.(Float64, Xtr)

Xtr_labels = Vector(data_ccele[1:2:end, 2])

# Testing
Xte = Matrix(data_ccele[2:2:end, 3:61])'

# Must be of type Float64
Xte = convert.(Float64, Xte)

Xte_labels = Vector(data_ccele[2:2:end, 2])

Z = fit(ZScoreTransform, Xtr)

StatsBase.transform!(Z, Xtr)

M = fit(PCA, Xtr, maxoutdim=5)
