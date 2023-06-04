using CSV, Downloads # Loading 
using DataFrames, DataFramesMeta
import MultivariateStats as MS
import StatsBase as SB
using StatsPlots, Plots

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
data_cc = @chain dfs["childcare_costs"] begin
                subset(:study_year => x -> x .== 2018)
                subset(All() .=> ByRow(x -> !ismissing(x)))
                innerjoin(_, dfs["counties"], on=:county_fips_code)
                transform(:county_name => ByRow(x -> replace(x, r"\s+County$" => "")) => :county_name)
end

# Join childcare_counties with election results
data_ccele = @chain dfs["us_elections"] begin
                   subset(:party => ByRow(x -> passmissing(occursin)(r"REP|DEM", x)), skipmissing=true)
                   subset(:county => ByRow(x -> !ismissing(x)))
                   groupby(_, [:county, :party])
                   combine(:votes => sum => :sum_votes)
                   unstack(_, :party, :sum_votes)
                   groupby(_, :county)
                   combine([:DEM, :REP] => ByRow((x, y) -> x > y ? "DEM" : "REP") => :winner)
                   innerjoin(_, data_cc, on=:county => :county_name)
                   select(:state_name, Not([:county_fips_code, :study_year, :state_abbreviation]))
end

# Training set
Xtr = @chain Matrix(data_ccele[1:2:end, 4:62])' begin
            convert.(Float64, _) # Must be of type Float64
end

Xtr_labels = Vector(data_ccele[1:2:end, 3])

# Testing set
Xte = @chain Matrix(data_ccele[2:2:end, 4:62])' begin
            convert.(Float64, _) # Must be of type Float64
end

Xte_labels = Vector(data_ccele[2:2:end, 3])

# Z transform and fit PCA
Z = MS.fit(SB.ZScoreTransform, Xtr)
SB.transform!(Z, Xtr)
SB.transform!(Z, Xte)
M = MS.fit(MS.PCA, Xtr, maxoutdim=8)

# Check results
Yte = MS.predict(M, Xte)
Xr = MS.reconstruct(M, Yte)

# Extract values for plotting
DEM = Yte[:,Xte_labels.=="DEM"]
REP = Yte[:,Xte_labels.=="REP"]

p = scatter(REP[1,:],REP[2,:],REP[3,:],marker=:circle, markeralpha=0.35, linewidth=0, label="REP")
scatter!(DEM[1,:],DEM[2,:],DEM[3,:],marker=:circle, markeralpha=0.35, linewidth=0, label="DEM")
plot!(p,xlabel="PC1",ylabel="PC2", zlabel="PC3",camera=[30,30]) # rotate with argument camera=[x::Int64,y::Int64]
