# Data from Portal Project https://portal.weecology.org/

using CSV, Downloads # loading 
using DataFrames, CategoricalArrays, Pipe, Dates # wrangling
using CairoMakie # plotting
using AlgebraOfGraphics

remotedir = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2023/2023-05-02/"
localdir = "230502/"
names = ["plots", "species", "surveys"]
sfx = ".csv"

# Download data
[Downloads.download(string(remotedir, n, sfx), string(n, sfx)) for n in names]

# Initialise dictionary
dfs = Dict{Symbol,DataFrame}()

# Read files into dictionary
[dfs[Symbol(n)] = CSV.read(string(n, sfx), DataFrame) for n in names]

# Spin-off of ethanwhite's cleaning script
# Bottom of page https://github.com/rfordatascience/tidytuesday/tree/master/data/2023/2023-05-02
function cleansurveys!(dfs)
    dfs[:surveys] = @pipe dfs[:surveys] |>
                          filter(
                              :censusdate => x -> x > Date(1978, 01, 01) && !ismissing(x), _) |>
                          transform(
                              _,
                              :plot => categorical => :plot,
                              :sex => categorical => :sex,
                              :year => (y -> Date.(y)) => :iso_date,
                          )
end

# Translating ethanwhite's cleaning script involves an anonymous function, verbose in Julia ... 
# [:year, :month] => ((y, m) -> Date.(string.(y, "-", m, "-", "01"), dateformat"y-m-d")) => :iso_date,
# Using Date() as above is better

cleansurveys!(dfs)

sex_by_year = @pipe dfs[:surveys] |>
                    filter(:sex => x -> !ismissing(x), _) |>
                    groupby(_, [:year, :sex]) |>
                    combine(_, nrow => :groupsize)

d = (year=sex_by_year.year, groupsize=sex_by_year.groupsize, sex=sex_by_year.sex)
p = data(d) * mapping(:year => "Year", :groupsize => "N", color=:sex => "Sex")
draw(p)