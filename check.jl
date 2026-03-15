using CSV, DataFrames

df = CSV.read("UnicornRawDataRecorder_19_11_2025_10_51_060.csv", DataFrame)
println("Column names:")
for n in names(df)
    println("  ", n)
end
