using Plots

x = [100, 1000, 4169, 5000, 6000, 10000]; y = [ 0.536152, 2.870680,  76.700828, 119.475446, 179.492401, (612.383019+689.737006)/2]; # These are the plotting data

plot(x, y, legend=false)
xlabel!("Data points")
ylabel!("Time (s)")
plot!(size=(1000,800))
savefig("times.png")

