using Downloads, CSV, DataFrames, DataFramesMeta, Chain
using Plots, StatsBase, GeoMakie, GLMakie

remotedir = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2023/2023-05-16/tornados.csv" 
localdir = "230516/tornados.csv"

Downloads.download(remotedir, localdir)

data = @chain CSV.read(localdir, DataFrame, missingstring = "NA") begin
    @rsubset(_, :yr >= 1980 && :mag >= 4)
end

yearly_fatalities = @chain data begin
    @rsubset(_, !ismissing(:wid) && :yr >= 2010)
    groupby(_, :yr)
    combine(_, nrow => :n)
end

plot(yearly_fatalities.yr, yearly_fatalities.n)


land = GeoMakie.land() # How do we get the US here?
fig = Figure()
ga = GeoAxis(
    fig[1, 1]; # any cell of the figure's layout
    dest = "+proj=natearth", # the CRS in which you want to plot
    coastlines = true # plot coastlines from Natural Earth, as a reference.
)
GeoMakie.poly!(ga, land[22]); datalims!(ga)
#GeoMakie.scatter!(ga, data.elon, data.elat; color = ("blue", 0.05), transparency = true)
#GeoMakie.scatter!(ga, data.slon, data.slat; color = ("red", 0.05), transparency = true)
fig