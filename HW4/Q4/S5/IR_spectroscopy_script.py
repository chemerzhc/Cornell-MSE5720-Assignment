# Pulling in my support script, helpful_support.py
# So you can see the order of what happens here
# But can look in support to see how any one piece works
import helpful_support
import numpy as np

#Smiley Face for good luck
print()
print(":D")
print()

###############################################################
###############################################################

# You have to set these file names!!!!

#Getting the two output files in array form
ph        = helpful_support.reader('CCO.phon.out') #put in the proper path/name
dynmat    = helpful_support.reader('dynmat.out') #put in the proper path/name

###############################################################

#Getting cell volume, we need this to calculate mode effective charge
volume, vol_units= helpful_support.get_volume(ph)


print("Volume is:")
print (str(volume) + " " + str(vol_units))
print()

###############################################################

# Figuring out how many of each atom there is, and their masses
atom_names, atom_counts, masses = helpful_support.atoms(ph)

print("Types of Atoms")
print(atom_names)
print()
print("Number of Each Atom:")
print(atom_counts)
print()
print("Mass of each Atom:")
print(masses)
print()
###############################################################

# Getting the Born effective charge tensor (Need for Mode effective charge)
BEC = helpful_support.get_BEC(ph)

print("BEC (every 3 rows is for 1 atom)")
for x in range(len(BEC)):
	print(BEC[x])
print()

###############################################################

#Getting dynamical frequencies and eigenvectors
Frequencies, vectors= helpful_support.get_DYN(dynmat, sum(atom_counts))


print("Frequencies (cm-1)")
print(Frequencies)
print()

#print("Corresponding Eigenvectors")
#print(vectors)
#print()

# This was me checking how well the phonon eigenvectors were orthogonal with eachother
# Think we were having issues with accoustic modes
#for x in range(len(vectors)):
#	for y in range(len(vectors)):
#
#		if(np.dot(vectors[x], np.transpose(vectors[y])) > 10**-5) and (x>2) and (y>2) and (x!=y):
#			print(x,y)
#			print(np.dot(vectors[x], np.transpose(vectors[y]))  )

###############################################################


# Getting real space phonon displacements (need these for Mode effective charge)
reduced_mass, real_displacements= helpful_support.get_Real_Disp(atom_counts, masses, vectors)

# Each reduced mass corresponds to the column vector of real_displacements
print("Reduced_mass (AMU)")
print(reduced_mass)
print()

#print("Corresponding Eigenvectors")
#for x in range(len(vectors)):
#	print(np.transpose(vectors)[x])

###############################################################

# Calculating Mode Effective Charge as defined in Gonze
# https://journals.aps.org/prb/abstract/10.1103/PhysRevB.55.10355
# It's equation (53)
# Each row here, corresponds to phonons in order they show up in the dynmat
MEC= helpful_support.get_MEC(masses, BEC, real_displacements)
print("MEC")
for x in range(len(MEC)):
	print(MEC[x])

###############################################################

# Generates uniform fake damping parameters
Dampening= helpful_support.get_Damping(atom_counts)

###############################################################

# Writing an input file, called "Input_File"
# dielectric constants are not being read in, set them to zero.
# You can comment out this line if you already have generated an input file
diel_constants=[0,0,0,0,0,0]
helpful_support.write_input(volume, diel_constants, MEC,Frequencies,reduced_mass, Dampening )

###############################################################

# Take that Input file we just made, and read in the variables as inputs
# It is done in this way, so that if you want to modify a parameter you can comment out the 
# write_input line above and it will do the lorentz oscillator model with your inputs
a,b,c,d,e,f,g,h,i,j,k,l= helpful_support.Read_Diel_Input("Input_File.txt")

###############################################################

# Generate the dielectric response as a function of frequency using the Lorentz Oscillator model.
# Section 3 from here seems sufficent:
# https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-007-electromagnetic-energy-from-motors-to-lasers-spring-2011/readings/MIT6_007S11_lorentz.pdf
# Makes a file called diel_output.txt
# Format of the file is:
# There are 14 Columns:
# Frequency, 
# Real part of dielectric function along xx, yy, zz, xy, xz, yz. 
# Imaginary part of dielectric function along the same axes. 
# Finally a Reflection column
#
# Each Row is these values for a given frequency, from the minimum frequency to maximum frequency 

# You can comment this out if you already have made your diel_output.txt file and just want to view the plots at the end
helpful_support.Lorentz_Osc(a,b,c,d,e,f,g,h,i,j,k,l)



###############################################################
# The End
###############################################################
###############################################################



