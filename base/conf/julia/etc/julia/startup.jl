# This file should contain site-specific commands to be executed on Julia startup;
# Users may store their own personal commands in `~/.julia/config/startup.jl`.

println("Executing site-specific startup file (", @__FILE__, ")...")

using Pkg
