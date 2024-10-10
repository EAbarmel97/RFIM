include("../src/IMRF.jl")
using .IMRF: plot_trazes, plot_ensamblated_magnetization
using .IMRF: SIMULATIONS_DIR

function __plot(plot_ensamble_magnetization::Bool=false)
  println("plotting trazes, wait ...\n")
  IMRF.plot_trazes()

  if plot_ensamble_magnetization
    ensamblated_magnetization_file_path = first(filter((u) -> endswith(u, "assembled_magnetization.csv"),
      readdir(abspath(IMRF.SIMULATIONS_DIR), join=true)))

    IMRF.plot_ensamblated_magnetization(ensamblated_magnetization_file_path, IMRF.GRAPHS_DIR_SIMULATIONS)
  end
end

function plot(ARGS)
  #ARG[1] = true includes the ensamblated magnetization
  arg = parse(Bool, ARGS[1])

  __plot(arg)
end

plot(ARGS)
