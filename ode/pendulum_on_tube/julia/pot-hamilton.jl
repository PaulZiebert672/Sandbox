using Roots
using QuadGK
using DifferentialEquations
using DiffEqPhysics
using Plots
using Statistics

include("pot-config.jl")

# Hamiltonian
H(p, q, rho = 0) = 0.5*(p^2)/(1 + rho*q)^2 + rho*sin(q) + 1 - (1 + rho*q)*cos(q)

e0 = H(u0[2]*(1 + rho*u0[1])^2, u0[1], rho)
println("energy = ", e0)
amplitude = theta -> e0 - H(0, theta, rho)
theta_left = find_zero(amplitude, (-2*pi/3, 0))
theta_right = find_zero(amplitude, (2*pi/3, 0))
println("theta_left = ", theta_left)
println("theta_right = ", theta_right)
kernel = theta -> (1 + rho*theta)/sqrt(amplitude(theta))
result_left, qerror = quadgk(kernel, theta_left, 0)
result_right, qerror = quadgk(kernel, 0, theta_right)
t_period = sqrt(2)*(result_left + result_right)
println("period = ", t_period)

t_step = t_period/N
t_max = K*t_period
prob = HamiltonianProblem(H, u0[2]*(1 + rho*u0[1])^2, u0[1], (0.0, t_max), rho)
sol = solve(prob, Vern7(), adaptive=false, dt=t_step)
data = map(x -> (x[2], x[1]), sol.u)
# display(data)

gr(size = (300, 300))
Plots.scalefontsizes()
Plots.scalefontsizes(0.4)
plotOrbit = scatter(
    data,
    aspect_ratio = 1,
    xlabel = "\\theta",
    ylabel = "p",
    plot_title = "Pendulum on tube - Hamiltonian dynamics",
    markersize = 1.0,
    alpha = 0.25,
    legend = false,
    dpi = 300
)

x_plot_size = xlims(plotOrbit)[2] - xlims(plotOrbit)[1]
y_plot_size = ylims(plotOrbit)[2] - ylims(plotOrbit)[1]
annotate!(
    xlims(plotOrbit)[1] + 0.18*x_plot_size,
    ylims(plotOrbit)[2] - 0.06*y_plot_size,
    text("\$\\mathcal{E}_0 = $(round(e0, digits=4))\$\n\$\\mathrm{T} = $(round(t_period, digits=4))\$", :crimson, :right, 4)
)
annotate!(
    xlims(plotOrbit)[1] + 0.18*x_plot_size,
    ylims(plotOrbit)[2] - 0.92*y_plot_size,
    text("\$\\rho = $(round(rho, digits=4))\$", :slateblue, :right, 4)
)
# gui(), readline()
savefig(plotOrbit, "pot-hamilton-orbit.png")

constant_of_motion = map(H, map(x -> x[2], data), map(x -> x[1], data), map(x -> rho, sol.t))
# display(energy)
println("mean energy = ", mean(constant_of_motion))
println("std energy = ", std(constant_of_motion))

plotError = scatter(
    sol.t, (constant_of_motion .- e0)./e0,
    xlabel = "Time",
    ylabel = "Relative energy error",
    plot_title = "Pendulum on tube - Hamiltonian dynamics",
    markersize = 0.8,
    alpha = 0.15,
    legend = false,
    dpi = 300,
    annotation = (t_max - t_period, 0.0, text("\$\\rho= $(rho)\$\n\$\\mathcal{E}_0 = $(e0)\$", :crimson, :bottom, 4))
)
# gui(), readline()
savefig(plotError, "pot-hamilton-error.png")
