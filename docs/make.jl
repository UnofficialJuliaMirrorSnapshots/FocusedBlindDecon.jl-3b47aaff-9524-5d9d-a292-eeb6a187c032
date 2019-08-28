using Pkg; Pkg.add("Gadfly");

using Documenter, FocusedBlindDecon
using Gadfly

makedocs(
	 format = Documenter.HTML(
		  prettyurls = get(ENV, "CI", nothing) == "true"),
   sitename = "Focused Blind Deconvolution",
   pages = ["Home" => "index.md",
	    "Library" => "library.md",
	    "Tutorial I" => "tut1.md"
	    #"SeisForwExpt" => Any[
			#	  "LBSD" => "lsbd.md",
#				  "Basic usage" => "Fdtd/reuse_expt.md",
#				  "Generate snaps" => "Fdtd/create_snaps.md",
#				  ],
	    ]
#	    "Seismic Born Modeling" => "FWI/born_map.md",
#	    "Seismic Full Waveform Inversion" => "FWI/gradient_accuracy.md",
#    modules = []
)
 
deploydocs(
    repo   = "github.com/pawbz/FocusedBlindDecon.jl.git",
)
