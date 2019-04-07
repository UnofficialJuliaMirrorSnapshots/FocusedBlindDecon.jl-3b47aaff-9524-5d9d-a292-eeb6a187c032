module Interferometry

using Conv
import JuMIT.Acquisition
import JuMIT.Data


"""
enhance diffractions in the `TD`

# Keyword Arguments

`λdom::Float64=0.0` : distance between receivers must be greater than twice central wavelength, 2*λdom (Shapiro 2005)
`tlag::Float64=data.tgrid[end]-data.tgrid[1]` : maximum lag time in the output traces 

"""
function TD_virtual_diff(
			 data::Data.TD;
			 λdom::Float64=0.0,
			 tlag::Float64=data.tgrid[end]-data.tgrid[1]
			)

	nr = maximum(data.acqgeom.nr);	nss = data.acqgeom.nss;	nt = length(data.tgrid)
	fields = data.fields;
	# normalize the records in data
	datan = Data.TD_normalize(data,:recrms)


	# get unique receiver postions; a virtual source at each
	urpos = Acquisition.Geom_get([data.acqgeom],:urpos)
	nur = Acquisition.Geom_get([data.acqgeom],:nur)

	# central wavelength (use zero for testing)
	println(string("dominant wavelength in the data:\t",λdom))

	rx = Array{Vector{Float64}}(nur); rz = Array{Vector{Float64}}(nur);
	datmat = zeros(nur, length(fields), 2*nt-1, nur);
	for ifield =1:length(fields)
		# loop over virtual sources
		for irs = 1:nur

			irvec = [];
			# loop over second receiver
			for ir = 1:nur
				rpos = [urpos[1][irs], urpos[2][irs]];
				rpos0 = [urpos[1][ir], urpos[2][ir]];
				δrpos = sqrt((rpos[1] - rpos0[1])^2 + (rpos[2] - rpos0[2])^2)
			
				# the distance between receivers must be greater than 2λdom
				# here λdom is the central wavelength (Shapiro 2005)
				if(δrpos > 2.0*λdom)

					# find sources that shoot at these two receivers
					sson = Acquisition.Geom_find(data.acqgeom; rpos=rpos, rpos0=rpos0)
					nsson = count(x->x!=[0],sson);
					if(nsson!=0)
						push!(irvec, ir)
					end
					# stacking over these sources
					for isson=1:length(sson)
						if(sson[isson] != [0])
							datmat[ir, ifield,:,irs] += 
							-1.0 * xcorr(
							  datan.d[isson,ifield][:, sson[isson][2]], 
							  datan.d[isson,ifield][:, sson[isson][1]])
						end
					end
					# normalize depending on the stack
					nsson != 0 ? datmat[ ir,  ifield, :, irs] /= nsson : nothing
				end
			end
			if(irvec != [])
				rx[irs] = [urpos[2][i] for i in irvec]
				rz[irs] = [urpos[1][i] for i in irvec]
			end
		end
	end
	# virtual source positions 
	sx = [[urpos[2][irs]] for irs in 1:nur];
	sz = [[urpos[1][irs]] for irs in 1:nur];

	# bool array acoording to undef
	ars = [isassigned(rx,irs) ? true : false for irs=1:nur];

	# select only positions that are active
	rx = rx[ars];	rz = rz[ars];
	sx = sx[ars];	sz = sz[ars];
	
	# number of virtual sources
	nvs = length(rx) == length(sx) ? length(sx) : error("some error")

	# geom
	vacqgeom = Acquisition.Geom(sx, sz, rx, rz, nvs, fill(1,nvs), 
			     [length(rx[ir]) for ir=1:length(rx)])

	# tgrid after correlation
	dt = data.tgrid[end]-data.tgrid[1]
	tgridxcorr=range(-dt, stop=+dt, step=step(data.tgrid))
	
	tlag > 0.0 ? tgridcut=range(-tlag,stop=+tlag,step=step(data.tgrid)) : error("tlag < 0")

	return Data.TD_resamp(
		       Data.TD_urpos(datmat,data.fields,tgridxcorr,vacqgeom,nur,urpos), 
		       tgridcut)

end



"""
Correlating noise records with reference records
* `irref` : reference receiver
"""
function TD_noise_corr(data::Data.TD; tlagfrac=0.5, irref=[1],)

	error("fix this")
	# tgrid after correlation
	tt = data.tgrid[end]-data.tgrid[1]
	#tgridc = lag(tlagfrac*tt, step(data.tgrid))

	# allocate TD
	dataout=Data.TD_zeros(data.fields, tgridc[1], data.acqgeom)

	TD_noise_corr!(dataout, data, irref)
end

function TD_noise_corr!(dataout, data, irref)
	nr = data.acqgeom.nr;	nss = data.acqgeom.nss;	
	fields=data.fields
	ntlag=Int((length(dataout.tgrid)-1)/2)

	nto = length(dataout.tgrid);
	isodd(nto) || error("odd samples in output data required")
	for ifield = 1:length(fields), iss = 1:nss
		# need param for each supersource, because of different receivers
		paxcorr=Conv.P_xcorr(length(data.tgrid), nr[iss], 
		   cglags=[ntlag, ntlag], norm_flag=false,cg_indices=irref)
		dd=data.d[iss, ifield]
		ddo=[dataout.d[iss, ifield]]

		Conv.mod!(paxcorr, cg=ddo, g=dd)

	end

	return dataout

end

end # module

