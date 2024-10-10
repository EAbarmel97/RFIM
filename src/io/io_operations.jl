@enum DIRS dir = 1 sub_dir = 2

function create_dir(dir_name::String, type_of_dict::DIRS, args...)::String
  dir_path::String = ""
  if type_of_dict === dir
    dir_path = string(dir_name, args...)
    return mkdir(dir_path)
  else
    dir_path = string(dir_name, args...)
    return mkpath(dir_path)
  end
end

function create_file(file_name::String, args...)::String
  file_path = joinpath(file_name, args...)
  return touch(file_path)
end

function rfim_info(N_GRID, NUM_RUNS, NUM_GENERATIONS)
  io = create_file(joinpath(SIMULATIONS_DIR, "rfim_details.txt"))
  open(io, "w+") do io
    write(io, "details: ngrid:$N_GRID, nruns:$NUM_RUNS, ngens:$NUM_GENERATIONS")
  end
end

function simulations_dir(dir::String)
  All_SIMULATIONS_DIRS = String[]
  if isequal(abspath(dir), SIMULATIONS_DIR)
    if filter((u) -> endswith(u, ".csv"), readdir(abspath(RFIM.SIMULATIONS_DIR), join=true)) |> length > 0
      All_SIMULATIONS_DIRS = readdir(abspath(RFIM.SIMULATIONS_DIR), join=true)[4:end]
    else
      All_SIMULATIONS_DIRS = readdir(abspath(RFIM.SIMULATIONS_DIR), join=true)[3:end]
    end

    return All_SIMULATIONS_DIRS
  else
    return dir
  end
end

"""
    filter_dir_names_in_dir(dir::String, rgxs::Vararg{Regex})::Vector{String}

Filters and returns a vector of directory names in the specified directory (`dir`) that match any of the given regular expressions (`rgxs`).

# Arguments
- `dir::String`: The path to the directory to search in.
- `rgxs::Vararg{Regex}`: One or more regular expressions to match directory names against.

# Returns
- `Vector{String}`: A vector of directory names that match any of the provided regular expressions.

# Notes
- If `dir` is equal to `SIMULATIONS_DIR`, it first filters out directories containing `.csv` files, and then excludes the first few entries in the list.
- Issues a warning if no directories match a given regular expression.
"""
function filter_dir_names_in_dir(dir::String, rgxs::Vararg{Regex})::Vector{String}
  dir_paths_array = String[]
  dirs_to_search_in = String[]

  if isequal(abspath(dir), SIMULATIONS_DIR)
    if filter((u) -> endswith(u, ".csv"), readdir(abspath(SIMULATIONS_DIR), join=true)) |> length > 0
      dirs_to_search_in = readdir(abspath(SIMULATIONS_DIR), join=true)[4:end]
    else
      dirs_to_search_in = readdir(abspath(SIMULATIONS_DIR), join=true)[3:end]
    end
  else
    dirs_to_search_in = readdir(abspath(dir), join=true)
  end

  for rgx in rgxs
    dir_paths = filter(dir_name -> contains(dir_name, rgx), dirs_to_search_in)
    if isempty(dir_paths)
      @warn "there is no sub dir in $(dir) matching '$(rgx)'"
    else
      first_match = dir_paths |> first
      push!(dir_paths_array, first_match)
    end
  end

  return dir_paths_array
end

function write_to_csv(file_to_write::String, value::Any)
  if !isfile(file_to_write)
    @error "file $file_to_write does not exist"
  end

  CSV.write(file_to_write, DataFrame(col1=[value]); append=true, delim=',')
  return
end

function write_to_csv(file_to_write::String, value::Vector{<:Any})
  if !isfile(file_to_write)
    @error "file $file_to_write does not exist"
  end

  CSV.write(file_to_write, DataFrame(col1=value); append=true, delim=',')
  return
end

function write_rffts(num_runs::Int64)
  #check if assembled_magnetization csv exists
  if filter((u) -> endswith(u, ".csv"), readdir(abspath(SIMULATIONS_DIR), join=true)) |> length > 0
    All_SIMULATIONS_DIRS = readdir(abspath(SIMULATIONS_DIR), join=true)[4:end]
  else
    All_SIMULATIONS_DIRS = readdir(abspath(SIMULATIONS_DIR), join=true)[3:end]
  end

  All_MAGNETIZATION_DIRS = joinpath.(All_SIMULATIONS_DIRS, "magnetization")
  All_FOURIER_DIRS = joinpath.(All_SIMULATIONS_DIRS, "fourier")
  for i in eachindex(All_MAGNETIZATION_DIRS)
    for run in 1:num_runs
      global_magn_ts_path = joinpath(All_MAGNETIZATION_DIRS[i], "global_magnetization_r$run.csv")
      rfft_path = create_file(joinpath(All_FOURIER_DIRS[i], "rfft_global_magnetization_r$run.csv"))
      if isfile(rfft_path)
        rfft_magnetiaztion_ts = FFTW.rfft(global_magn_ts_path)
        write_rfft(rfft_magnetiaztion_ts, rfft_path)
      end
    end
  end
end

function write_rfft(arr::Vector{ComplexF64}, file_path::String)
  write_to_csv(file_path, arr)
end

function write_csv_assembled_magnetization_by_temprature(write_to::String; statistic::Function=mean)
  #this gets an array of dirs with the structure: ../simulations/simulations_T_xy_abcdefg_/
  All_TEMPERATURES_DIRS = readdir(abspath(SIMULATIONS_DIR), join=true)[3:end]
  All_MAGNETIZATION_DIRS = joinpath.(All_TEMPERATURES_DIRS, "magnetization")
  temperatures = Float64[]
  magnetizations = Float64[]

  for i in eachindex(All_MAGNETIZATION_DIRS)
    temperature = parse(Float64,
      replace(
        match(r"[0-9][0-9]_[0-9]+",
          All_MAGNETIZATION_DIRS[i]).match,
        "_" => ".")
    )

    magnetization = sample_magnetization_by_run(All_TEMPERATURES_DIRS[i]; statistic=statistic)
    push!(magnetizations, magnetization)
    push!(temperatures, temperature)
  end

  assembled_magnetization_file_path = create_file(joinpath(write_to, "$(statistic)_assembled_magnetization.csv"))
  CSV.write(assembled_magnetization_file_path, DataFrame(t=temperatures, M_n=magnetizations); append=true, delim=',')
end

function __count_lines_in_csv(file_path::String)
  n::Int64 = 0
  for _ in CSV.Rows(file_path; header=false, reusebuffer=true)
    n += 1
  end

  return n
end

function num_runs_rfim_details()::Int64
  if !isfile(joinpath(SIMULATIONS_DIR), "rfim_details.txt")
    @error "$(SIMULATIONS_DIR)/rfim_details.txt does not exit. Impossible to parse Int64"
  end

  return parse(Int64,
    replace(match(r"nruns:[0-9]+", read(joinpath(SIMULATIONS_DIR, "rfim_details.txt"), String)).match, "nruns:" => ""))
end
