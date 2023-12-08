using DataFrames, DataFramesMeta, CSV, Downloads
using Resample
using StableRNGs: StableRNG

remotedir = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2023/2023-05-23/squirrel_data.csv"
localdir = "230523/squirrels.csv"

# Download data from remote repo
Downloads.download(remotedir, localdir)

# Read data from local directory and assign as data frame
df = CSV.read(localdir, DataFrame)

# Let's see what we can learn about these squirrels
show(DataFrames.names(df))

# Looks like the most fun would be to test if fur color correlates with behavior

# How many individuals are there per fur color?
sum_fur = @chain df begin
    groupby(_, "Primary Fur Color")
    combine(_, nrow => :n)
end

# The data contain squirrel IDs, could it be a multilevel model?
unique(df."Unique Squirrel ID")
# There are almost as many unique measures as there are unique squirrels 
# -> no multilevel model

# We don't want those that have missing Primary Fur Color
subset!(df, "Primary Fur Color" => ByRow(x -> !ismissing(x)))

# We were low on black and cinnamon fur
# Class imbalance may be an issue, so let's upsample
# This requires one-hot encoding of the predictors

# Start by subsetting to the columns we'd like to keep
features = [
    "Running",
    "Chasing",
    "Eating",
    "Foraging",
    "Kuks",
    "Quaas",
    "Moans",
    "Tail flags",
    "Tail twitches",
    "Approaches",
    "Indifferent",
    "Runs from"
]

df = @chain df begin
    select(_, [
        "Primary Fur Color",
        features... 
        # Splat operator ... "unifies" target vector contents with parent vector
        # Try [0, [1, 2, 3]...]
    ])
    transform(_, [f => ByRow(x -> x == false ? 0 : 1) => f for f in features])
    # Have to use ByRow() with ternary operator, can't use dot-syntax
end

# A dict to save results for each category in
up = Dict{String, DataFrame}()

# Upsample the two minority categories
for col in ["Black", "Cinnamon"]
    up[col] = let
        df_sub = @chain df begin
            subset(_, "Primary Fur Color" => ByRow(x -> x == col))
            select(Not("Primary Fur Color"))
        end
        rng = StableRNG(1)
        up = smote(rng, df_sub, 1000)
        DataFrame(up)
    end
end
