### A Pluto.jl notebook ###
# v0.12.10

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 9c8a7e5a-12dd-11eb-1b99-cd1d52aefa1d
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add([
		"Plots",
		"PlutoUI",
		"Images",
		"FileIO",
		"ImageMagick",
		"ImageIO",
		"OffsetArrays",
		"ThreadsX"
	])
	using Statistics
	using Plots
	using PlutoUI
	using Images
	using OffsetArrays
	using ThreadsX
end

# ╔═╡ 67c3dcc0-2c05-11eb-3a84-9dfea24f95a8
md"_homework 10, version 0_"

# ╔═╡ 621230b0-2c05-11eb-2a98-5bd1d7be9038
md"""

# **Homework 10**: _Climate modeling II_
`18.S191`, fall 2020
"""

# ╔═╡ 6cb238d0-2c05-11eb-221e-d5df4c479302
# edit the code below to set your name and kerberos ID (i.e. email without @mit.edu)

student = (name = "Jazzy Doe", kerberos_id = "jazz")

# you might need to wait until all other cells in this notebook have completed running. 
# scroll around the page to see what's up

# ╔═╡ 6a4641e0-2c05-11eb-3430-6f14650c2ad3
md"""

Submission by: **_$(student.name)_** ($(student.kerberos_id)@mit.edu)
"""

# ╔═╡ 70077e50-2c05-11eb-3d83-732b4b780d04
md"_Let's create a package environment:_"

# ╔═╡ ed741ec6-1f75-11eb-03be-ad6284abaab8
html"""
<iframe width="100%" height="300" src="https://www.youtube.com/embed/waOzCGDNPzk" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
"""

# ╔═╡ ac759b96-2114-11eb-24cb-d50b556f4142
md"""
### 1) Background: two-dimensional advection-diffusion

##### 1.1) The two-dimensional advection-diffusion equation
Recall from **Lecture 22** that the one-dimensional advection-diffusion equation is written as

$\frac{\partial T(x,t)}{\partial t} = -U \frac{\partial T}{\partial x} + \kappa \frac{\partial^{2} T}{\partial x^{2}},$

where $T(x, t)$ is the temperature, $U$ is a constant *advective velocity* and $\kappa$ is the *diffusivity*.

The two-dimensional advection diffusion equation adds advection and diffusion operators acting in a *second spatial dimension* $y$ (orthogonal to $x$):

$\frac{\partial T(x,y,t)}{\partial t} = u(x,y) \frac{\partial T}{\partial x} + v(x,y) \frac{\partial T}{\partial y} + \kappa \left( \frac{\partial^{2} T}{\partial x^{2}} + \frac{\partial^{2} T}{\partial y^{2}} \right),$

where $\vec{u}(x,y) = (u, v) = u\,\mathbf{\hat{x}} + v\,\mathbf{\hat{y}}$ is a velocity vector field.

Throughout the rest of the Climate Modelling module, we will consider $x$ to be the *longitundinal* direction (positive from west to east) and $y$ to the be the *latitudinal* direction (positive from south to north).
"""

# ╔═╡ 3a4a1aea-2118-11eb-30a9-57b87f2ddfae
begin
	reviewBox = @bind show_review CheckBox(default=false)
	md"""
	##### 1.2) Review of multivariable calculus identities and notation

	*Check the box for a review* $(reviewBox)
	

	"""
end

# ╔═╡ 023779a0-2a95-11eb-35b5-7be93c43afaf
if show_review
	md"""
	Conventionally, the two-dimensional advection-diffusion equation is written more succintly as

	$\frac{\partial T(x,y,t)}{\partial t} = - \vec{u} \cdot \nabla T + \kappa \nabla^{2} T,$

	using the following shorthand notation.

	The **gradient** operator is defined as 

	$\nabla \equiv (\frac{\partial}{\partial x}, \frac{\partial }{\partial y})$

	such that

	$\nabla T = (\frac{\partial T}{\partial x}, \frac{\partial T}{\partial y})$ and 

	$\vec{u} \cdot \nabla T = (u, v) \cdot (\frac{\partial T}{\partial x}, \frac{\partial T}{\partial y}) = u \frac{\partial T}{\partial x} + v\frac{\partial T}{\partial y}.$

	The **Laplacian** operator $\nabla^{2}$ (sometimes denoted $\Delta$) is defined as 

	$\nabla^{2} = \frac{\partial^{2}}{\partial x^{2}} + \frac{\partial^{2}}{\partial y^{2}}$

	such that

	$\nabla^{2} T = \frac{\partial^{2} T}{\partial x^{2}} + \frac{\partial^{2} T}{\partial y^{2}}.$

	The **divergence** operator is defined as $\nabla \cdot [\quad]$, such that

	$\nabla \cdot \vec{u} = \left(\frac{\partial}{\partial x}, \frac{\partial}{\partial x} \right) \cdot (u,v) = \frac{\partial u}{\partial x} + \frac{\partial v}{\partial y}.$

	**Note:** Since seawater is largely incompressible, we can approximate ocean currents as a *non-divergent flow*, with $\nabla \cdot \vec{u} = \frac{\partial u}{\partial x} + \frac{\partial v}{\partial y} = 0$. Among other implications, this allows us to write:

	\begin{align}
	\vec{u} \cdot \nabla T&=
	u\frac{\partial T(x,y,t)}{\partial x} + v\frac{\partial T(x,y,t)}{\partial y}\newline &=
	u\frac{\partial T}{\partial x} + v\frac{\partial T}{\partial y} + T\left(\frac{\partial u}{\partial x} + \frac{\partial v}{\partial y}\right)\newline &=
	\left( u\frac{\partial T}{\partial x} + T\frac{\partial u}{\partial x} \right) +
	\left( v\frac{\partial T}{\partial y} + \frac{\partial v}{\partial y} \right)
	\newline &=
	\frac{\partial (uT)}{\partial x} + \frac{\partial (vT)}{\partial x}\newline &=
	\nabla \cdot (\vec{u}T)
	\end{align}

	using the product rule (separately in both $x$ and $y$).
	
	##### 1.3) The flux-form two-dimensional advection-diffusion equation

	This lets us finally re-write the two-dimensional advection-diffusion equation as:

	$\frac{\partial T}{\partial t} = - \nabla \cdot (\vec{u}T) + \kappa \nabla^{2} T$

	which is the form we will use in our numerical algorithm below.
	"""
end

# ╔═╡ b1b5625e-211a-11eb-3ee1-3ba9c9cc375a
md"""
### 2) Numerical implementation

##### 2.1) Discretizing advection in two dimensions

In Lecture XX we saw that in one dimension we can discretize a first-partial derivative in space using the *centered finite difference*

$\frac{\partial T(x_{i}, t_{n})}{\partial x} \approx \frac{T_{i+1}^{n} - T_{i-1}^{n}}{2 \Delta x}.$

In two dimensions, we discretize the partial derivative the exact same way, except that we also need to keep track of the cell index $j$ in the $y$ dimension:

$\frac{\partial T(x_{i}, y_{j}, t_{n})}{\partial x} \approx \frac{T_{i+1,\, j}^{n} - T_{i-1,\,j}^{n}}{2 \Delta x}.$

The *x-gradient kernel* below, implemented using the `OffsetArray` type, is shown below, and is reminiscent of the *edge-detection* or *sharpening* kernels used in image processing and machine learning:
"""

# ╔═╡ 3578b158-2a97-11eb-0771-bf6d82d3b6d1
md"""
The first-order partial derivative in $y$ is similarly discretized as:

$\frac{\partial T(x_{i}, y_{j}, t_{n})}{\partial y} \approx \frac{T_{i,\, j+1}^{n} - T_{i,\,j-1}^{n}}{2 \Delta y}.$

Its kernel is shown below.
"""

# ╔═╡ 7f3c9550-2a97-11eb-1549-455009025872
md"""
Now that we have discretized the two derivate terms, we can write out the *advective tendency* for computing $T_{i, j, n+1}$ as

$u\frac{\partial T}{\partial x} + v\frac{\partial T}{\partial y} \approx u_{i,\, j}^{n} \frac{T_{i,\, j+1}^{n} - T_{i,\,j-1}^{n}}{2 \Delta y} + v_{i,\, j}^{n} \frac{T_{i,\, j+1}^{n} - T_{i,\,j-1}^{n}}{2 \Delta y}.$

We implement this in julia as a series of methods for the `advect` function. The first method computes the advective tendency (as a single `Float64` type) for the $(i,j)$ grid cell while the second method returns an array of the tendencies for each grid cell using two nested for loops.
"""

# ╔═╡ 0127bca6-2a99-11eb-16a0-8d7af66694f8
md"""
##### 2.2) Discretizing diffusion in two dimensions

Just as with advection, the process for discretizing the diffusion operators effectively consists of repeating the one-dimensional process for $x$ in a second dimension $y$, separately:

$\kappa \left( \frac{\partial^{2} T}{\partial x^{2}} + \frac{\partial^{2} T}{\partial y^{2}} \right) = \kappa \left(
\frac{T_{i+1,\;j}^{n} - 2T_{i,\;j}^{n} + T_{i-1,\;j}^{n}}{\left( \Delta x \right)^{2}} +
\frac{T_{i,\;j+1}^{n} - 2T_{i,\;j}^{n} + T_{i,\;j-1}^{n}}{\left( \Delta y \right)^{2}}
\right)$

The corresponding $x$ and $y$ second-derivative kernels are shown below:
"""

# ╔═╡ eac507ce-2a99-11eb-3eba-0780a4a7e078
md"""
Just as we did with advection, we implement a `diffuse` function using multiple dispatch:
"""

# ╔═╡ 09f179c0-2a9a-11eb-1d0f-e59012f9e77b
md"""##### 2.3) No-flux boundary conditions

We want to impose the no-flux boundary conditions, which states that

$u\frac{\partial T}{\partial x} = \kappa \frac{\partial T}{\partial x} = 0$ at $x$ boundaries and 

$v\frac{\partial T}{\partial y} = \kappa \frac{\partial T}{\partial y} = 0$ at the $y$ boundaries.

To impose this, we treat $i=1$ and $i=N_{x}$ as *ghost cells*, which do not do anything expect help us impose these boundaries conditions. Discretely, the boundary fluxes between $i=1$ and $i=2$ vanish if

$\dfrac{T_{2,\,j}^{n} -T_{1,\,j}^{n}}{\Delta x} = 0$ or 

$T_{1,\,j}^{n} = T_{2,\,j}^{n}.$

Thus, we can implement the boundary conditions by updating the temperature of the ghost cells to match their interior-point neighbors:
"""

# ╔═╡ 7caca2fa-2a9a-11eb-373f-156a459a1637
function update_ghostcells!(A::Array{Float64,2}; option="no-flux")
	Atmp = @view A[:,:]
	if option=="no-flux"
		A[1, :] = Atmp[2, :]; Atmp[end, :] = Atmp[end-1, :]
		A[:, 1] = Atmp[:, 2]; Atmp[:, end] = Atmp[:, end-1]
	end
end

# ╔═╡ 1f06bc34-2a9b-11eb-1030-ff12d103176c
md"Let's get a feel for what this is actually doing"

# ╔═╡ 2ef2f0cc-2a9b-11eb-03c6-5d8b4c6ae822
begin
	A = rand(Float64, 6,6);
	heatmap(A, size=(200,200))
end |> as_svg

# ╔═╡ 4558d4f8-2a9b-11eb-1f56-416975bcd180
begin
	Acopy = copy(A);
	update_ghostcells!(Acopy)
	heatmap(Acopy, size=(200,200))
end |> as_svg

# ╔═╡ 74aa7512-2a9c-11eb-118c-c7a5b60eac1b
md"""
##### 2.4) Timestepping
"""

# ╔═╡ 13eb3966-2a9a-11eb-086c-05510a3f5b80
md"""
##### 2.5) Data structures
"""

# ╔═╡ cd2ee4ca-2a06-11eb-0e61-e9a2ecf72bd6
begin
	struct Grid
		N::Int64
		L::Float64

		Δx::Float64
		Δy::Float64

		x::Array{Float64, 2}
		y::Array{Float64, 2}

		Nx::Int64
		Ny::Int64

		function Grid(N, L)
			Δx = L/N # [m]
			Δy = L/N # [m]

			x = 0. -Δx/2.:Δx:L +Δx/2.
			x = reshape(x, (1, size(x,1)))
			y = -L -Δy/2.:Δy:L +Δy/2.
			y = reshape(y, (size(y,1), 1))

			Nx, Ny = size(x, 2), size(y, 1)

			return new(N, L, Δx, Δy, x, y, Nx, Ny)
		end
	end

	Base.zeros(G::Grid) = zeros(G.Ny, G.Nx)
end

# ╔═╡ 0d63e6b2-2b49-11eb-3413-43977d299d90
Base.@kwdef struct OceanModelParameters
	κ::Float64=1.e4
end

# ╔═╡ 32663184-2a81-11eb-0dd1-dd1e10ed9ec6
abstract type ClimateModel end

# ╔═╡ d3796644-2a05-11eb-11b8-87b6e8c311f9
begin
	struct OceanModel <: ClimateModel
		G::Grid
		params::OceanModelParameters

		u::Array{Float64, 2}
		v::Array{Float64, 2}
	end

	OceanModel(G::Grid, params::OceanModelParameters) = 
		OceanModel(G, params, zeros(G), zeros(G))
	
	OceanModel(G::Grid) = 
		OceanModel(G, OceanModelParameters(), zeros(G), zeros(G))
end;

# ╔═╡ f92086c4-2a74-11eb-3c72-a1096667183b
begin
	mutable struct ClimateModelSimulation{ModelType<:ClimateModel}
		model::ModelType
		
		T::Array{Float64, 2}
		Δt::Float64
		
		iteration::Int64
	end
	
	ClimateModelSimulation(C::ModelType, T, Δt) where ModelType = 
		ClimateModelSimulation{ModelType}(C, T, Δt, 0)
end

# ╔═╡ 31cb0c2c-2a9a-11eb-10ba-d90a00d8e03a
md"""
##### 3) Simulating heat transport by advective & diffusive ocean currents
"""

# ╔═╡ 9841ff20-2c06-11eb-3c4c-c34e465e1594
default_grid = Grid(10, 6.e6);

# ╔═╡ 981ef38a-2a8b-11eb-08be-b94be2924366
md"**Simulation controls**"

# ╔═╡ d042d25a-2a62-11eb-33fe-65494bb2fad5
begin
	quiverBox = @bind show_quiver CheckBox(default=false)
	anomalyBox = @bind show_anomaly CheckBox(default=false)
	md"""
	*Click to show the velocity field* $(quiverBox) *or to show temperature **anomalies** instead of absolute values* $(anomalyBox)
	"""
end

# ╔═╡ c20b0e00-2a8a-11eb-045d-9db88411746f
begin
	U_ex_Slider = @bind U_ex Slider(-4:1:8, default=0, show_value=false);
	md"""
	$(U_ex_Slider)
	"""
end

# ╔═╡ 6dbc3d34-2a89-11eb-2c80-75459a8e237a
begin
	md"*Vary the current speed U:*  $(2. ^U_ex) [× reference]"
end

# ╔═╡ 933d42fa-2a67-11eb-07de-61cab7567d7d
begin
	κ_ex_Slider = @bind κ_ex Slider(0.:1.e3:1.e5, default=1.e4, show_value=true)
	md"""
	*Vary the diffusivity κ:* $(κ_ex_Slider) [m²/s]
	"""
end

# ╔═╡ c9ea0f72-2a67-11eb-20ba-376ca9c8014f
@bind go_ex Clock(0.1)

# ╔═╡ c3f086f4-2a9a-11eb-0978-27532cbecebf
md"""
**Some unit tests for verification**
"""

# ╔═╡ c0298712-2a88-11eb-09af-bf2c39167aa6
md"""##### Computing the velocity field for a single circular vortex
"""

# ╔═╡ e3ee80c0-12dd-11eb-110a-c336bb978c51
begin
	∂x(ϕ, Δx) = (ϕ[:,2:end] - ϕ[:,1:end-1])/Δx
	∂y(ϕ, Δy) = (ϕ[2:end,:] - ϕ[1:end-1,:])/Δy
	
	xpad(ϕ) = hcat(zeros(size(ϕ,1)), ϕ, zeros(size(ϕ,1)))
	ypad(ϕ) = vcat(zeros(size(ϕ,2))', ϕ, zeros(size(ϕ,2))')
	
	xitp(ϕ) = 0.5*(ϕ[:,2:end]+ϕ[:,1:end-1])
	yitp(ϕ) = 0.5*(ϕ[2:end,:]+ϕ[1:end-1,:])
	
	function diagnose_velocities(ψ, G)
		u = xitp(∂y(ψ, G.Δy/G.L))
		v = yitp(-∂x(ψ, G.Δx/G.L))
		return u,v
	end
end

# ╔═╡ df706ebc-2a63-11eb-0b09-fd9f151cb5a8
function impose_no_flux!(u, v)
	u[1,:] .= 0.; v[1,:] .= 0.;
	u[end,:] .= 0.; v[end,:] .= 0.;
	u[:,1] .= 0.; v[:,1] .= 0.;
	u[:,end] .= 0.; v[:,end] .= 0.;
end

# ╔═╡ e2e4cfac-2a63-11eb-1b7f-9d8d5d304b43
function PointVortex(G; Ω=1., a=0.2, x0=0.5, y0=0.)
	x = reshape(0. -G.Δx/(G.L):G.Δx/G.L:1. +G.Δx/(G.L), (1, G.Nx+1))
	y = reshape(-1. -G.Δy/(G.L):G.Δy/G.L:1. +G.Δy/(G.L), (G.Ny+1, 1))
	
	function ψ̂(x,y)
		r = sqrt.((y .-y0).^2 .+ (x .-x0).^2)
		
		stream = -Ω/4*r.^2
		stream[r .> a] = -Ω*a^2/4*(1. .+ 2*log.(r[r .> a]/a))
		
		return stream
	end
		
	u, v = diagnose_velocities(ψ̂(x, y), G)
	impose_no_flux!(u, v)
	
	return u,v
end

# ╔═╡ 1dd3fc70-2c06-11eb-27fe-f325ca208504
# ocean_velocities = zeros(default_grid), zeros(default_grid);
ocean_velocities = PointVortex(default_grid, Ω=0.5);
# ocean_velocities = DoubleGyre(default_grid);

# ╔═╡ bb084ace-12e2-11eb-2dfc-111e90eabfdd
md"""##### Computing a quasi-realistic ocean velocity field $\vec{u} = (u, v)$
Our velocity field is given by an analytical solution to the classic wind-driven gyre
problem, which is given by solving the fourth-order partial differential equation:

$- \epsilon_{M} \hat{\nabla}^{4} \hat{\Psi} + \frac{\partial \hat{\Psi} }{ \partial \hat{x}} = \nabla \times \hat{\tau} \mathbf{z},$

where the hats denote that all of the variables have been non-dimensionalized and all of their constant coefficients have been bundles into the single parameter $\epsilon_{M} \equiv \dfrac{\nu}{\beta L^3}$.

The solution makes use of an advanced *asymptotic method* (valid in the limit that $\epsilon \ll 1$) known as *boundary layer analysis* (see MIT course 18.305 to learn more). 
"""



# ╔═╡ ecaab27e-2a16-11eb-0e99-87c91e659cf3
function DoubleGyre(G; β=2e-11, τ₀=0.1, ρ₀=1.e3, ν=1.e5, κ=1.e5, H=1000.)
	ϵM = ν/(β*G.L^3)
	ϵ = ϵM^(1/3.)
	x = reshape(0. -G.Δx/(G.L):G.Δx/G.L:1. +G.Δx/(G.L), (1, G.Nx+1))
	y = reshape(-1. -G.Δy/(G.L):G.Δy/G.L:1. +G.Δy/(G.L), (G.Ny+1, 1))
	
	ψ̂(x,y) = π*sin.(π*y) * (
		1 .- x - exp.(-x/(2*ϵ)) .* (
			cos.(√3*x/(2*ϵ)) .+
			(1. /√3)*sin.(√3*x/(2*ϵ))
			)
		.+ ϵ*exp.((x .- 1.)/ϵ)
	)
		
	u, v = (τ₀/ρ₀)/(β*G.L*H) .* diagnose_velocities(ψ̂(x, y), G)
	impose_no_flux!(u, v)
	
	return u, v
end

# ╔═╡ e59d869c-2a88-11eb-2511-5d5b4b380b80
md"""
##### Some simple initial temperature fields
"""

# ╔═╡ 0ae0bb70-2b8f-11eb-0104-93aa0e1c7a72
constantT(G; value) = zeros(G) .+ value

# ╔═╡ c4424838-12e2-11eb-25eb-058344b39c8b
linearT(G; value=50.0) = value*0.5*(1. .+[ -(y/G.L) for y in G.y[:, 1], x in G.x[1, :] ])

# ╔═╡ 3d12c114-2a0a-11eb-131e-d1a39b4f440b
function InitBox(G; value=50., nx=2, ny=2, xspan=false, yspan=false)
	T = zeros(G)
	T[G.Ny÷2-ny:G.Ny÷2+ny, G.Nx÷2-nx:G.Nx÷2+nx] .= value
	if xspan
		T[G.Ny÷2-ny:G.Ny÷2+ny, :] .= value
	end
	if yspan
		T[:, G.Nx÷2-nx:G.Nx÷2+nx] .= value
	end
	return T
end

# ╔═╡ 6f19cd80-2c06-11eb-278d-178c1590856f
# ocean_T_init = InitBox(default_grid; value=40);
ocean_T_init = InitBox(default_grid, value=50, xspan=true);
# ocean_T_init = linearT(default_grid);

# ╔═╡ 863a6330-2a08-11eb-3992-c3db439fb624
ocean_sim = let
	P = OceanModelParameters(κ=κ_ex)
	
	u, v = ocean_velocities
	model = OceanModel(default_grid, P, u*2. ^U_ex, v*2. ^U_ex)
	
	Δt = 12*60*60
	ClimateModelSimulation(model, copy(ocean_T_init), Δt)
end;

# ╔═╡ dc9d12d0-2a9a-11eb-3dae-85b3b6029658
begin
	heat_capacity = 51.
	total_heat_content = sum(heat_capacity*ocean_sim.T*(ocean_sim.model.G.Δx*ocean_sim.model.G.Δy))*1e-15
	mean_temp = mean(ocean_sim.T)
end;

# ╔═╡ bff89550-2a9a-11eb-3038-d70249c96219
begin
	#go_ex
	md"""
	Let's make sure our model conserves energy. We have not added any energy to the system: advection and diffusion just move the energy around. The total heat content is $(round(total_heat_content, digits=3)) peta-Joules and the average temperature is $(round(mean_temp, digits=2)) °C.
	"""
end

# ╔═╡ 6b3b6030-2066-11eb-3343-e19284638efb
plot_kernel(A) = heatmap(
	collect(A),
	color=:bluesreds, clims=(-maximum(abs.(A)), maximum(abs.(A))), colorbar=false,
	xticks=false, yticks=false, size=(30+30*size(A, 2), 30+30*size(A, 1)), xaxis=false, yaxis=false
)

# ╔═╡ 1e8d37ee-2a97-11eb-1d45-6b426b25d4eb
begin
	xgrad_kernel = OffsetArray(reshape([-1., 0, 1.], 1, 3),  0:0, -1:1)
	plot_kernel(xgrad_kernel)
end

# ╔═╡ 682f2530-2a97-11eb-3ee6-99a7c79b3767
begin
	ygrad_kernel = OffsetArray(reshape([-1., 0, 1.], 3, 1),  -1:1, 0:0)
	plot_kernel(ygrad_kernel)
end

# ╔═╡ f4c884fc-2a97-11eb-1ba9-01bf579f8b43
begin
	function advect(T, u, v, Δy, Δx, j, i)
		return .-(
			u[j, i].*sum(xgrad_kernel[0, -1:1].*T[j, i-1:i+1])/(2Δx) .+
			v[j, i].*sum(ygrad_kernel[-1:1, 0].*T[j-1:j+1, i])/(2Δy)
		)
	end
	advect(T, u, v, Δy, Δx) = [
		advect(T, u, v, Δy, Δx, j, i)
		for j=2:size(T, 1)-1, i=2:size(T, 2)-1
	]
	
	advect(T, O::ClimateModel) = advect(T, O.u, O.v, O.G.Δy, O.G.Δx)
end

# ╔═╡ b629d89a-2a95-11eb-2f27-3dfa45789be4
begin
	xdiff_kernel = OffsetArray(reshape([1., -2., 1.], 1, 3),  0:0, -1:1)
	ydiff_kernel = OffsetArray(reshape([1., -2., 1.], 3, 1),  -1:1, 0:0)

	[plot_kernel(xdiff_kernel), plot_kernel(ydiff_kernel)]
end

# ╔═╡ ee6716c8-2a95-11eb-3a00-319ee69dd37f
begin
	function diffuse(T, κ, Δy, Δx, j, i)
		return κ.*(
			sum(xdiff_kernel[0, -1:1].*T[j, i-1:i+1])/(Δx^2) +
			sum(ydiff_kernel[-1:1, 0].*T[j-1:j+1, i])/(Δy^2)
		)
	end
	diffuse(T, κ, Δy, Δx) = [
		diffuse(T, κ, Δy, Δx, j, i) for j=2:size(T, 1)-1, i=2:size(T, 2)-1
	]
	
	diffuse(T, O::ClimateModel) = diffuse(T, O.params.κ, O.G.Δy, O.G.Δx)
end

# ╔═╡ 81bb6a4a-2a9c-11eb-38bb-f7701c79afa2
function timestep!(sim::ClimateModelSimulation{OceanModel})
	update_ghostcells!(sim.T)
	tendencies = advect(sim.T, sim.model) .+ diffuse(sim.T, sim.model)
	sim.T[2:end-1, 2:end-1] .+= sim.Δt*tendencies
	sim.iteration += 1
end;

# ╔═╡ ad7b7ed6-2a9c-11eb-06b7-0f5595167575
function CFL_adv(sim::ClimateModelSimulation)
	maximum(sqrt.(sim.model.u.^2 + sim.model.v.^2)) * sim.Δt / sim.model.G.Δx
end

# ╔═╡ d9e23a5a-2a8b-11eb-23f1-73ff28be9f12
md"**The CFL condition**

The CFL condition is defined by $\text{CFL} = \dfrac{\max\left(\sqrt{u² + v²}\right)Δt}{Δx} =$ $(round(CFL_adv(ocean_sim), digits=2))
"

# ╔═╡ 16905a6a-2a78-11eb-19ea-81adddc21088
Nvec = 1:25

# ╔═╡ 545cf530-2b48-11eb-378c-3f8eeb89bcba
md"""
# Radiation
"""

# ╔═╡ 57535c60-2b49-11eb-07cc-ffc5b4d1f13c
Base.@kwdef struct RadiationOceanModelParameters
	κ::Float64=3.e4
	
	C::Float64=51.0 * 60*60*24*365.25
	
	A::Float64=210
	B::Float64=-1.3
	
	S_mean::Float64 = 1380
	α0::Float64=0.3
	αi::Float64=0.5
	ΔT::Float64=2.0
end

# ╔═╡ de7456c0-2b4b-11eb-13c8-01b196821de4
md"""
## Outgoing radiation
"""

# ╔═╡ 6745f610-2b48-11eb-2f6c-79e0009dc9c3
function outgoing_thermal_radiation(T; A, B)
	A .- B .* (T)
end

# ╔═╡ e80b0532-2b4b-11eb-26fa-cd09eca808bc
md"""
## Incoming radiation
"""

# ╔═╡ 42bb2f70-2b4a-11eb-1637-e50e1fad45f3
function precompute_S(grid::Grid, params::RadiationOceanModelParameters)
	[
		params.S_mean .* (1+0.5*sin((-y / grid.L) * π/2))
		for y in grid.y[:], x in grid.x[:]
	]
end

# ╔═╡ 90e1aa00-2b48-11eb-1a2d-8701a3069e50
begin
	struct RadiationOceanModel <: ClimateModel
		G::Grid
		params::RadiationOceanModelParameters
		
		S::Array{Float64, 2}

		u::Array{Float64, 2}
		v::Array{Float64, 2}
	end

	RadiationOceanModel(G::Grid, P::RadiationOceanModelParameters, u, v) = 
		RadiationOceanModel(G, P, precompute_S(G, P), u, v)
	RadiationOceanModel(G::Grid, P::RadiationOceanModelParameters) = 
		RadiationOceanModel(G, P, zeros(G), zeros(G))
	RadiationOceanModel(G::Grid) = 
		RadiationOceanModel(G, RadiationOceanModelParameters(), zeros(G), zeros(G))
end;

# ╔═╡ a033fa20-2b49-11eb-20e0-5dd968b0c0c6
function outgoing_thermal_radiation(T, model::RadiationOceanModel)
	outgoing_thermal_radiation(T; A=model.params.A, B=model.params.B) ./ model.params.C
end

# ╔═╡ 6c20ca1e-2b48-11eb-1c3c-418118408c4c
plot(
	-10:40, outgoing_thermal_radiation(-10:40, A=11, B=-0.7),
	xlabel="Temperature",
	ylabel="Outgoing radiation",
	label=nothing,
	size=(300,200)
)

# ╔═╡ b99b5b00-2b4b-11eb-260e-21363d1f4a9b
hello = let
	G = Grid(10, 6.e6)
	P = RadiationOceanModelParameters()
	precompute_S(G, P)
end

# ╔═╡ a3e524d0-2b55-11eb-09e2-25a968d79640
plot(hello[:,1])

# ╔═╡ 388898b0-2b56-11eb-2537-c596394b9e20


# ╔═╡ 629454e0-2b48-11eb-2ff0-abed400c49f9
function α(T::Float64; α0, αi, ΔT)
	if T < -ΔT
		return αi
	elseif -ΔT <= T < ΔT
		return αi + (α0-αi)*(T+ΔT)/(2ΔT)
	elseif ΔT <= T
		return α0
	end
end

# ╔═╡ d63c5fe0-2b49-11eb-07fd-a7ec98af3a89
function α(T::Array{Float64,2}, model::RadiationOceanModel)
	α.(T; α0=model.params.α0, αi=model.params.αi, ΔT=model.params.ΔT)
end

# ╔═╡ f2e2f820-2b49-11eb-1c6c-19ae8157b2b9
function absorbed_solar_radiation(T, model::RadiationOceanModel)
	absorption = 1.0 .- α(T, model)
	
	absorption .* model.S ./ 4. ./ model.params.C
end

# ╔═╡ fe492480-2b4b-11eb-050e-9b9b2e2bf50f
md"""
## New timestep method
"""

# ╔═╡ 068795ee-2b4c-11eb-3e58-353eb8978c1c
function timestep!(sim::ClimateModelSimulation{RadiationOceanModel})
	update_ghostcells!(sim.T)
	tendencies = 
		advect(sim.T, sim.model) .+ diffuse(sim.T, sim.model) .+ 
		(@view absorbed_solar_radiation(sim.T, sim.model)[2:end-1, 2:end-1]) .- 
		(@view outgoing_thermal_radiation(sim.T, sim.model)[2:end-1, 2:end-1])
	
	sim.T[2:end-1, 2:end-1] .+= sim.Δt*tendencies
	
	sim.iteration += 1
end;

# ╔═╡ 8346b590-2b41-11eb-0bc1-1ba79bb77dfb
tvec = map(Nvec) do Npower
	G = Grid(8*Npower, 6.e6);
	P = OceanModelParameters(1.e4);

	#u, v = DoubleGyre(G)
	#u, v = PointVortex(G, Ω=0.5)
	u, v = zeros(G), zeros(G)

	model = OceanModel(G, P, u, v)

	IC = InitBox(G)
	#IC = InitBox(G, nx=G.Nx÷2-1)
	#IC = linearT(G)

	Δt = 6*60*60
	S = ClimateModelSimulation(model, copy(IC), Δt)

	return @elapsed timestep!(S)
end

# ╔═╡ 794c2148-2a78-11eb-2756-5bd28b7726fa
begin
	plot(8*Nvec, tvec, xlabel="Number of Grid Cells (in x-direction)", ylabel="elapsed time per timestep [s]")
end |> as_svg

# ╔═╡ ef902590-2bf7-11eb-1eb0-712b3eb3f7c1
let
	G = Grid(10, 6.e6)
	P = RadiationOceanModelParameters()
	
	#u, v = zeros(G), zeros(G)
	# u, v = PointVortex(G, Ω=0.5)
	u, v = DoubleGyre(G)

	# IC = InitBox(G; value=50.)
	# IC = InitBox(G, xspan=true)
	IC = constantT(G; value=14)
	
	model = RadiationOceanModel(G, P, u*2. ^U_ex, v*2. ^U_ex)
	Δt = 400*60*60
	
	sim = ClimateModelSimulation(model, copy(IC), Δt)
	
	while (
			abs(
				mean(absorbed_solar_radiation(sim.T, sim.model)) * sim.model.params.C - 
				mean(outgoing_thermal_radiation(sim.T, sim.model)) * sim.model.params.C
			) > 4.0 || sim.iteration < 1_000) && (
			sim.iteration < 6_000
			)
		for i in 1:500
			timestep!(sim)
		end
	end
	
	mean(sim.T)
end

# ╔═╡ ad95c4e0-2b4a-11eb-3584-dda89970ffdf
md"""
## lets try it out
"""

# ╔═╡ b059c6e0-2b4a-11eb-216a-39bb43c7b423
radiation_sim = let
	G = Grid(10, 6.e6)
	P = RadiationOceanModelParameters(S_mean=1380, A=200, α0=0.3, αi=0.4, κ=2e4)
	
	#u, v = zeros(G), zeros(G)
	# u, v = PointVortex(G, Ω=0.5)
	u, v = DoubleGyre(G)

	# IC = InitBox(G; value=50.)
	# IC = InitBox(G, xspan=true)
	IC = constantT(G; value=0)
	
	model = RadiationOceanModel(G, P, u, v)
	Δt = 400*60*60
	
	ClimateModelSimulation(model, copy(IC), Δt)
end

# ╔═╡ 5fd346d0-2b4d-11eb-066b-9ba9c9d97613
@bind go_radiation Clock(.1)

# ╔═╡ 50c6d850-2b57-11eb-2330-1d1547219b5e
(absorbed_solar_radiation(radiation_sim.T, radiation_sim.model) |> mean) * radiation_sim.model.params.C

# ╔═╡ 57dcf660-2b57-11eb-1518-b7e2e65abfcc
(outgoing_thermal_radiation(radiation_sim.T, radiation_sim.model) |> mean) * radiation_sim.model.params.C

# ╔═╡ f5010a40-2b56-11eb-266a-a71b92692172
mean(radiation_sim.T)

# ╔═╡ ef647620-2c01-11eb-185e-3f36f98fcfaf


# ╔═╡ 127bcb0e-2c0a-11eb-23df-a75767910fcb
md"""
#### Exercise 4.1 - _Equilibrium temperature_
"""

# ╔═╡ c40870d0-2b8e-11eb-0fa6-d7fcb1c6611b
function eq_T(S, T_init)
	G = Grid(10, 6.e6)
	P = RadiationOceanModelParameters(κ=3e4, S_mean=S, αi=.5, A=210)
	
	#u, v = zeros(G), zeros(G)
	# u, v = PointVortex(G, Ω=0.5)
	u, v = DoubleGyre(G)

	# IC = InitBox(G; value=50.)
	# IC = InitBox(G, xspan=true)
	IC = constantT(G; value=T_init)
	
	model = RadiationOceanModel(G, P, u*2. ^U_ex, v*2. ^U_ex)
	Δt = 400*60*60
	
	sim = ClimateModelSimulation(model, copy(IC), Δt)
	
	while (
			abs(
				mean(absorbed_solar_radiation(sim.T, sim.model)) * sim.model.params.C - 
				mean(outgoing_thermal_radiation(sim.T, sim.model)) * sim.model.params.C
			) > 8.0 || sim.iteration < 1_000) && (
			sim.iteration < 6_000
			)
		for i in 1:500
			timestep!(sim)
		end
	end
	
	mean(sim.T)
end

# ╔═╡ ec39a792-2bf7-11eb-11e5-515b39f1adf6


# ╔═╡ 38759600-2b8f-11eb-047d-490b567a2644
# eq_T(1500, -50)

# ╔═╡ 4fd13342-2b8f-11eb-1584-19578501385b
# eq_T(1500, 0)

# ╔═╡ 5300ef60-2b8f-11eb-2433-950848aded8d
# eq_T(1500, 50)

# ╔═╡ 703ebe90-2b8f-11eb-27f7-d7207fb41cda
# eq_T(1900, -50)

# ╔═╡ 75ea0200-2b8f-11eb-000d-f397e04704f2
# eq_T(1700, 50)

# ╔═╡ 7735bbe0-2b8f-11eb-36dc-73439f762444
# eq_T(1300, -50)

# ╔═╡ 7c45829e-2b8f-11eb-15f1-09e84f0e0070
# eq_T(1300, 50)

# ╔═╡ 2495e330-2c0a-11eb-3a10-530f8b87a4eb
md"""
#### Exercise 4.2
"""

# ╔═╡ 59da0470-2b8f-11eb-098c-993effcedecf
# bifurcation_ST = [(S,T) for S in 1350:10:1600 for T in [-50, 0, 50]]

# bifurcation_ST = [(S,T) for S in 1350:10:1600 for T in [-50, 0, 50]]
# bifurcation_ST = [(S,T) for S in 1180:100:1680 for T in [-50, 0, 50]]

# ╔═╡ 9f54c570-2b90-11eb-0e94-07e475a1908f
bifurcation_result = ThreadsX.map(bifurcation_ST) do p
	eq_T(p...)
end

# ╔═╡ b0db7730-2b90-11eb-126b-33b04be4d686
scatter(
	first.(bifurcation_ST), bifurcation_result,
	label=nothing,
	xlabel="Solar insulation",
	ylabel="Equilibrium temperature",
	color=:black,
	) |> as_svg

# ╔═╡ a04d3dee-2a9c-11eb-040e-7bd2facb2eaa
md"""
# Appendix
"""

# ╔═╡ 0a6e6ad2-2c01-11eb-3151-3d58bc09bc69
ice_gradient = PlotUtils.ContinuousColorGradient([
		RGB(0.95, 0.95, 1.0), 
		RGB(0.05, 0.0, 0.3), 
		RGB(0.1, 0.05, 0.4), 
		RGB(0.4, 0.4, 0.5), 
		RGB(0.95, 0.7, 0.4), 
		RGB(1.0, 0.9, 0.3)
	], [0.0, 0.001, 0.2, 0.5, 0.8, 1.0])

# ╔═╡ c0e46442-27fb-11eb-2c94-15edbda3f84d
function plot_state(sim::ClimateModelSimulation; clims=(-1.1,1.1), 
		show_quiver=true, show_anomaly=false, IC=nothing)
	
	model = sim.model
	grid = sim.model.G
	
	
	p = plot(;
		xlabel="longitudinal distance [km]", ylabel="latitudinal distance [km]",
		clabel="Temperature",
		yticks=( (-grid.L:1000e3:grid.L), Int64.(1e-3*(-grid.L:1000e3:grid.L)) ),
		xticks=( (0:1000e3:grid.L), Int64.(1e-3*(0:1000e3:grid.L)) ),
		xlims=(0., grid.L), ylims=(-grid.L, grid.L),
		)
	
	X = repeat(grid.x, grid.Ny, 1)
	Y = repeat(grid.y, 1, grid.Nx)
	if show_anomaly
		arrow_col = :black
		maxdiff = maximum(abs.(sim.T .- IC))
		heatmap!(p, grid.x[:], grid.y[:], sim.T .- IC, clims=(-1.1, 1.1),
			color=:balance, colorbar_title="Temperature anomaly [°C]", linewidth=0.,
			size=(400,530)
		)
	else
		arrow_col = :white
		heatmap!(p, grid.x[:], grid.y[:], sim.T,
			color=ice_gradient, levels=clims[1]:(clims[2]-clims[1])/21.:clims[2],
			colorbar_title="Temperature [°C]", clims=clims,
			linewidth=0., size=(400,520)
		)
	end
	
	annotate!(p,
		50e3, 6170e3,
		text(
			string("t = ", Int64(round(sim.iteration*sim.Δt/(60*60*24))), " days"),
			color=:black, :left, 9
		)
	)
	annotate!(p,
		3000e3, 6170e3,
		text(
			"mean(T) = $(round(mean(sim.T), digits=1)) °C",
			color=:black, :left, 9
		)
	)
	
	if show_quiver
		Nq = grid.N ÷ 5
		quiver!(p,
			X[(Nq+1)÷2:Nq:end], Y[(Nq+1)÷2:Nq:end],
			quiver=grid.L*4 .*(model.u[(Nq+1)÷2:Nq:end], model.v[(Nq+1)÷2:Nq:end]),
			color=arrow_col, alpha=0.7
		)
	end
	
	as_png(p)
end

# ╔═╡ 3b24e1b0-2b46-11eb-383b-c57cbf3e68f1
let
	go_ex
	if ocean_sim.iteration == 0
		timestep!(ocean_sim)
	else
		for i in 1:50
			timestep!(ocean_sim)
		end
	end
	plot_state(ocean_sim, clims=(-10, 40), show_quiver=show_quiver, show_anomaly=show_anomaly, IC=ocean_T_init)
end

# ╔═╡ 6568b850-2b4d-11eb-02e9-696654ac2d37
let
	go_radiation
	for i in 1:100
		timestep!(radiation_sim)
	end
	plot_state(radiation_sim; clims=(-0,40))
end

# ╔═╡ 57b6e7d0-2c07-11eb-16c1-0d058a34c7ee
md"""
## **Exercise XX:** _Lecture transcript_
_(MIT students only)_

Please see the link for hw 9 transcript document on [Canvas](https://canvas.mit.edu/courses/5637).
We want each of you to correct about 500 lines, but don’t spend more than 20 minutes on it.
See the the beginning of the document for more instructions.
:point_right: Please mention the name of the video(s) and the line ranges you edited:
"""

# ╔═╡ 57c0d2e0-2c07-11eb-1091-15fec09c4e8b
lines_i_edited = md"""
Abstraction, lines 1-219; Array Basics, lines 1-137; Course Intro, lines 1-144 (_for example_)
"""

# ╔═╡ 57cdcb30-2c07-11eb-39b2-2f225acf589d
if student.name == "Jazzy Doe" || student.kerberos_id == "jazz"
	md"""
	!!! danger "Before you submit"
	    Remember to fill in your **name** and **Kerberos ID** at the top of this notebook.
	"""
end

# ╔═╡ 57e264a0-2c07-11eb-0e31-2b8fa01be2d1
md"## Function library

Just some helper functions used in the notebook."

# ╔═╡ 57f57770-2c07-11eb-1720-cf00aa7f597b
hint(text) = Markdown.MD(Markdown.Admonition("hint", "Hint", [text]))

# ╔═╡ 58094d90-2c07-11eb-2987-15c068fefd8f
almost(text) = Markdown.MD(Markdown.Admonition("warning", "Almost there!", [text]))

# ╔═╡ 581b9d10-2c07-11eb-1e60-c753aa19f4c3
still_missing(text=md"Replace `missing` with your answer.") = Markdown.MD(Markdown.Admonition("warning", "Here we go!", [text]))

# ╔═╡ 582dc580-2c07-11eb-37e3-c32590a0c325
keep_working(text=md"The answer is not quite right.") = Markdown.MD(Markdown.Admonition("danger", "Keep working on it!", [text]))

# ╔═╡ 58403c10-2c07-11eb-1f4b-f9ecb741d881
yays = [md"Fantastic!", md"Splendid!", md"Great!", md"Yay ❤", md"Great! 🎉", md"Well done!", md"Keep it up!", md"Good job!", md"Awesome!", md"You got the right answer!", md"Let's move on to the next section."]

# ╔═╡ 5853eb20-2c07-11eb-18bf-c14ed22ce153
correct(text=rand(yays)) = Markdown.MD(Markdown.Admonition("correct", "Got it!", [text]))

# ╔═╡ 5867e850-2c07-11eb-17d5-9dac155d381b
not_defined(variable_name) = Markdown.MD(Markdown.Admonition("danger", "Oopsie!", [md"Make sure that you define a variable called **$(Markdown.Code(string(variable_name)))**"]))

# ╔═╡ 587b9760-2c07-11eb-17ff-b9e950aa04ac
todo(text) = HTML("""<div
	style="background: rgb(220, 200, 255); padding: 2em; border-radius: 1em;"
	><h1>TODO</h1>$(repr(MIME"text/html"(), text))</div>""")



#html"<span style='display: inline; font-size: 2em; color: purple; font-weight: 900;'>TODO</span>"

# ╔═╡ b19df5b0-2c05-11eb-0f59-83fa0aa6d0bb
md"""
## **Exercise 1** - _Advection-diffusion_


Goals:

- play with the model, different initial temp conditions
- what is the effect of ...?
  - asdfasdf



- increase Δt for better performance
- increase it too high -- find zebra pattern
- higher N needs smaller Δt 👉 exercise 2

""" |> todo

# ╔═╡ 88c56350-2c08-11eb-14e9-77e71d749e6d
md"""
## **Exercise 2** - _Complexity_

Talk about the theoretical constraints for Δt

This gives us N^3

N^4 for state-of-the-art 3D ocean models

compare to Moore's Law

""" |> todo

# ╔═╡ 4cba7260-2c08-11eb-0a81-abdff2f867de
md"""
## **Exercise 3** - _Radiation_

In Homework 9, we had an EBM with radiation. This week we will do the same, but in 2D instead of 0D.


### What we will give:
- The struct `RadiationOceanModelParameters` below, with our tuned initial values
- The 0D functions for absorbed and outgoing radiation. With demonstrations

### What they will write:
- The 2D methods for absorbed and outgoing radiation, with signature `(T::Array{Float64,2}, model::RadiationOceanModel)`
- The `timestep!(sim::ClimateModelSimulation{RadiationOceanModel})` method
- 



""" |> todo

# ╔═╡ 8b5a22f0-2b8f-11eb-094f-c5ceb1842998
md"""
## **Exercise 4** - _Bifurcation diagram_



""" |> todo

# ╔═╡ Cell order:
# ╟─67c3dcc0-2c05-11eb-3a84-9dfea24f95a8
# ╟─6a4641e0-2c05-11eb-3430-6f14650c2ad3
# ╟─621230b0-2c05-11eb-2a98-5bd1d7be9038
# ╠═6cb238d0-2c05-11eb-221e-d5df4c479302
# ╟─70077e50-2c05-11eb-3d83-732b4b780d04
# ╠═9c8a7e5a-12dd-11eb-1b99-cd1d52aefa1d
# ╟─ed741ec6-1f75-11eb-03be-ad6284abaab8
# ╠═b19df5b0-2c05-11eb-0f59-83fa0aa6d0bb
# ╟─ac759b96-2114-11eb-24cb-d50b556f4142
# ╟─3a4a1aea-2118-11eb-30a9-57b87f2ddfae
# ╟─023779a0-2a95-11eb-35b5-7be93c43afaf
# ╟─b1b5625e-211a-11eb-3ee1-3ba9c9cc375a
# ╠═1e8d37ee-2a97-11eb-1d45-6b426b25d4eb
# ╟─3578b158-2a97-11eb-0771-bf6d82d3b6d1
# ╟─682f2530-2a97-11eb-3ee6-99a7c79b3767
# ╟─7f3c9550-2a97-11eb-1549-455009025872
# ╠═f4c884fc-2a97-11eb-1ba9-01bf579f8b43
# ╟─0127bca6-2a99-11eb-16a0-8d7af66694f8
# ╟─b629d89a-2a95-11eb-2f27-3dfa45789be4
# ╟─eac507ce-2a99-11eb-3eba-0780a4a7e078
# ╠═ee6716c8-2a95-11eb-3a00-319ee69dd37f
# ╟─09f179c0-2a9a-11eb-1d0f-e59012f9e77b
# ╠═7caca2fa-2a9a-11eb-373f-156a459a1637
# ╟─1f06bc34-2a9b-11eb-1030-ff12d103176c
# ╠═2ef2f0cc-2a9b-11eb-03c6-5d8b4c6ae822
# ╠═4558d4f8-2a9b-11eb-1f56-416975bcd180
# ╟─74aa7512-2a9c-11eb-118c-c7a5b60eac1b
# ╠═81bb6a4a-2a9c-11eb-38bb-f7701c79afa2
# ╟─13eb3966-2a9a-11eb-086c-05510a3f5b80
# ╠═cd2ee4ca-2a06-11eb-0e61-e9a2ecf72bd6
# ╠═0d63e6b2-2b49-11eb-3413-43977d299d90
# ╠═32663184-2a81-11eb-0dd1-dd1e10ed9ec6
# ╠═d3796644-2a05-11eb-11b8-87b6e8c311f9
# ╠═f92086c4-2a74-11eb-3c72-a1096667183b
# ╟─31cb0c2c-2a9a-11eb-10ba-d90a00d8e03a
# ╠═9841ff20-2c06-11eb-3c4c-c34e465e1594
# ╠═1dd3fc70-2c06-11eb-27fe-f325ca208504
# ╠═6f19cd80-2c06-11eb-278d-178c1590856f
# ╠═863a6330-2a08-11eb-3992-c3db439fb624
# ╟─981ef38a-2a8b-11eb-08be-b94be2924366
# ╟─d042d25a-2a62-11eb-33fe-65494bb2fad5
# ╟─6dbc3d34-2a89-11eb-2c80-75459a8e237a
# ╟─c20b0e00-2a8a-11eb-045d-9db88411746f
# ╟─933d42fa-2a67-11eb-07de-61cab7567d7d
# ╟─c9ea0f72-2a67-11eb-20ba-376ca9c8014f
# ╠═3b24e1b0-2b46-11eb-383b-c57cbf3e68f1
# ╟─c3f086f4-2a9a-11eb-0978-27532cbecebf
# ╟─bff89550-2a9a-11eb-3038-d70249c96219
# ╟─dc9d12d0-2a9a-11eb-3dae-85b3b6029658
# ╟─c0298712-2a88-11eb-09af-bf2c39167aa6
# ╟─e2e4cfac-2a63-11eb-1b7f-9d8d5d304b43
# ╟─e3ee80c0-12dd-11eb-110a-c336bb978c51
# ╟─df706ebc-2a63-11eb-0b09-fd9f151cb5a8
# ╟─bb084ace-12e2-11eb-2dfc-111e90eabfdd
# ╟─ecaab27e-2a16-11eb-0e99-87c91e659cf3
# ╟─e59d869c-2a88-11eb-2511-5d5b4b380b80
# ╟─0ae0bb70-2b8f-11eb-0104-93aa0e1c7a72
# ╟─c4424838-12e2-11eb-25eb-058344b39c8b
# ╟─3d12c114-2a0a-11eb-131e-d1a39b4f440b
# ╟─6b3b6030-2066-11eb-3343-e19284638efb
# ╠═88c56350-2c08-11eb-14e9-77e71d749e6d
# ╟─d9e23a5a-2a8b-11eb-23f1-73ff28be9f12
# ╠═ad7b7ed6-2a9c-11eb-06b7-0f5595167575
# ╠═16905a6a-2a78-11eb-19ea-81adddc21088
# ╠═8346b590-2b41-11eb-0bc1-1ba79bb77dfb
# ╠═794c2148-2a78-11eb-2756-5bd28b7726fa
# ╠═4cba7260-2c08-11eb-0a81-abdff2f867de
# ╟─545cf530-2b48-11eb-378c-3f8eeb89bcba
# ╠═57535c60-2b49-11eb-07cc-ffc5b4d1f13c
# ╠═ef902590-2bf7-11eb-1eb0-712b3eb3f7c1
# ╠═90e1aa00-2b48-11eb-1a2d-8701a3069e50
# ╟─de7456c0-2b4b-11eb-13c8-01b196821de4
# ╠═6745f610-2b48-11eb-2f6c-79e0009dc9c3
# ╠═a033fa20-2b49-11eb-20e0-5dd968b0c0c6
# ╠═6c20ca1e-2b48-11eb-1c3c-418118408c4c
# ╟─e80b0532-2b4b-11eb-26fa-cd09eca808bc
# ╠═42bb2f70-2b4a-11eb-1637-e50e1fad45f3
# ╠═b99b5b00-2b4b-11eb-260e-21363d1f4a9b
# ╠═a3e524d0-2b55-11eb-09e2-25a968d79640
# ╠═388898b0-2b56-11eb-2537-c596394b9e20
# ╠═629454e0-2b48-11eb-2ff0-abed400c49f9
# ╠═d63c5fe0-2b49-11eb-07fd-a7ec98af3a89
# ╠═f2e2f820-2b49-11eb-1c6c-19ae8157b2b9
# ╟─fe492480-2b4b-11eb-050e-9b9b2e2bf50f
# ╠═068795ee-2b4c-11eb-3e58-353eb8978c1c
# ╟─ad95c4e0-2b4a-11eb-3584-dda89970ffdf
# ╠═b059c6e0-2b4a-11eb-216a-39bb43c7b423
# ╠═5fd346d0-2b4d-11eb-066b-9ba9c9d97613
# ╠═6568b850-2b4d-11eb-02e9-696654ac2d37
# ╠═50c6d850-2b57-11eb-2330-1d1547219b5e
# ╠═57dcf660-2b57-11eb-1518-b7e2e65abfcc
# ╠═f5010a40-2b56-11eb-266a-a71b92692172
# ╠═ef647620-2c01-11eb-185e-3f36f98fcfaf
# ╟─8b5a22f0-2b8f-11eb-094f-c5ceb1842998
# ╟─127bcb0e-2c0a-11eb-23df-a75767910fcb
# ╠═c40870d0-2b8e-11eb-0fa6-d7fcb1c6611b
# ╠═ec39a792-2bf7-11eb-11e5-515b39f1adf6
# ╠═38759600-2b8f-11eb-047d-490b567a2644
# ╠═4fd13342-2b8f-11eb-1584-19578501385b
# ╠═5300ef60-2b8f-11eb-2433-950848aded8d
# ╠═703ebe90-2b8f-11eb-27f7-d7207fb41cda
# ╠═75ea0200-2b8f-11eb-000d-f397e04704f2
# ╠═7735bbe0-2b8f-11eb-36dc-73439f762444
# ╠═7c45829e-2b8f-11eb-15f1-09e84f0e0070
# ╟─2495e330-2c0a-11eb-3a10-530f8b87a4eb
# ╠═59da0470-2b8f-11eb-098c-993effcedecf
# ╠═9f54c570-2b90-11eb-0e94-07e475a1908f
# ╠═b0db7730-2b90-11eb-126b-33b04be4d686
# ╟─a04d3dee-2a9c-11eb-040e-7bd2facb2eaa
# ╠═c0e46442-27fb-11eb-2c94-15edbda3f84d
# ╠═0a6e6ad2-2c01-11eb-3151-3d58bc09bc69
# ╟─57b6e7d0-2c07-11eb-16c1-0d058a34c7ee
# ╠═57c0d2e0-2c07-11eb-1091-15fec09c4e8b
# ╟─57cdcb30-2c07-11eb-39b2-2f225acf589d
# ╟─57e264a0-2c07-11eb-0e31-2b8fa01be2d1
# ╟─57f57770-2c07-11eb-1720-cf00aa7f597b
# ╟─58094d90-2c07-11eb-2987-15c068fefd8f
# ╟─581b9d10-2c07-11eb-1e60-c753aa19f4c3
# ╟─582dc580-2c07-11eb-37e3-c32590a0c325
# ╟─58403c10-2c07-11eb-1f4b-f9ecb741d881
# ╟─5853eb20-2c07-11eb-18bf-c14ed22ce153
# ╟─5867e850-2c07-11eb-17d5-9dac155d381b
# ╠═587b9760-2c07-11eb-17ff-b9e950aa04ac
