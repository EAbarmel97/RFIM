# About this repo:
parallel Julia implementation of the 2D Ising Model. 

# To use it without the REPL
 1. Clone the repo.

 2. Instantiante the julia-project running `make instantiante`.

 3. Given `NGRID`: size of the spin lattice, `NUM_RUNS`: number of runs and `NUM_GENS`: number of generations. Run `make simulate ngrid=NGRID runs=NUM_RUNS gens=NUM_GENS`. 
 
 4. Run `make plot_trazes assembled_magn=true`. If "true" the plot of the assembled magnetization is saved under graphs/simulations

 5. Run `make plot_psd` to save all the average PSD by run at each fixed temperature.

 6. Given `r`: number of realization and an array of patterns (suppose those are `pattern1, pattern2, pattern3`). Run `make plot_eigspectra realizations=r patterns="pattern1 pattern2 pattern3"`

 7. To clean the "workspace" run `make cleanup`. This will delete all the simulations info and graphs persisted under the dirs 
 "simulations" and graphs". If instead you want to just delete all the persisted simulations, run:`make cleanup_simulations` else
 if you want to delete the plots saved in the "graphs" dir run `make cleanup_graphs`.
