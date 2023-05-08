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

# Join counties and childcare_costs
data_cc = @pipe dfs["childcare_costs"] |>
                subset(_, :study_year => x -> x .== 2018) |>
                innerjoin(_, dfs["counties"], on=:county_fips_code) |>
                transform(_, :county_name => ByRow(x -> replace(x, r"\s+County$" => "")) => :county_name)




data_ccele = @pipe dfs["us_elections"] |>
                   subset(_, :party => ByRow(x -> passmissing(occursin)(r"REP|DEM", x)), skipmissing=true) |>
                   subset(_, :county => ByRow(x -> !ismissing(x))) |>
                   groupby(_, [:county, :party]) |>
                   combine(_, :votes => sum => :sum_votes) |>
                   innerjoin(_, data_cc, on=:county => :county_name)
