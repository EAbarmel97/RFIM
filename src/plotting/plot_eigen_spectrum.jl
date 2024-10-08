function plot_eigen_spectrum(eigvals::Vector{Float64}, at_temperature::Float64, num_realizations::Int64, dir_to_save::String=".")
  #compute linear fit 
  params = linear_fit_log_eigspectrum(eigvals)
  x = collect(Float64, 1:length(eigvals))
  str_temp = replace(string(round(at_temperature, digits=6)), "." => "_")
  full_file_path = joinpath(dir_to_save, "eigspectrum_magnetization_data_matrix_$(str_temp).pdf")
  #persist graph if doesn't exist
  if !isfile(full_file_path)
    #plot styling
    plt = plot(x, eigvals, label=L"{\lambda}_n", xscale=:log10, yscale=:log10, alpha=0.2)
    #linear fit
    plot!(u -> exp10(params[1] + params[2] * log10(u)), label="linear fit", minimum(x), maximum(x), xscale=:log10, yscale=:log10, lc=:red)

    title!("Eigen spectrum magnetization data matrix at T = $(at_temperature) \n beta_fit = $(round(params[2],digits=4))"; titlefontsize=11)
    xlabel!(L"n")
    ylabel!("Eigen spectrum")

    #file saving
    savefig(plt, full_file_path)
  end
end

function plot_eigen_spectra(r::Int64, temperature_dirs::Vararg{String})
  num_runs = num_runs_rfim_details()
  if r > num_runs
    @error "impossible to plot eigspectra. 
    Magnetization data matrix at fixed temp can not have more than $(num_runs) rows"
  end

  if r < num_runs
    for temperature_dir in collect(temperature_dirs)
      magnetization_data_matrix = ts_data_matrix(temperature_dir, r)
      eigspectum = compute_filtered_eigvals!(magnetization_data_matrix)
      at_temperature = parse(temperature_dir)
      plot_eigen_spectrum(eigspectum, at_temperature, r, GRAPHS_DIR_EIGSPECTRA)
    end
  end
end
