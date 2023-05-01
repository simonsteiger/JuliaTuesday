# Data from Portal Project https://portal.weecology.org/

using CSV, Downloads, DataFrames, CategoricalArrays, Pipe, Dates

remotedir = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2023/2023-05-02/"
localdir = "230502/"
names = ["plots", "species", "surveys"]
sfx = ".csv"

# Download data
[Downloads.download(string(remotedir, n, sfx), string(localdir, n, sfx)) for n in names]

# Initialise dictionary
dfs = Dict{Symbol,DataFrame}()

# Read files into dictionary
[dfs[Symbol(n)] = CSV.read(string(localdir, n, sfx), DataFrame) for n in names]

# Spin-off of ethanwhite's cleaning script
# Bottom of page https://github.com/rfordatascience/tidytuesday/tree/master/data/2023/2023-05-02
function cleansurveys!(dfs)
    dfs[:surveys] = @pipe dfs[:surveys] |>
                          # No data older than me!
                          # (and no missings, but ethan removed those already anyway 🤫)
                          filter(:censusdate => x -> x > Date(1995, 03, 19) && !ismissing(x), _) |>
                          transform(
                              _,
                              :plot => categorical => :plot,
                              # Translating ethanwhite's cleaning script involves an anonymous function, verbose in Julia ... 
                              # [:year, :month] => ((y, m) -> Date.(string.(y, "-", m, "-", "01"), dateformat"y-m-d")) => :iso_date,
                              # better do
                              :year => Date -> :iso_date,
                          )
end

cleansurveys!(dfs)
