import numpy as np
import os
import matplotlib.pyplot as plt

# Allows for changing how numpy handles printing to screen
# A WORD OF WARNING: the precision you set here will also be the precision numpy uses in calculations
np.set_printoptions(precision=20 , threshold=100000, linewidth=1000000, suppress=True)

##############################################################################################################################

# Going to read in the Output files
# Return an Array, where each element of the array is a line of the file
def reader(file_name):
	
	# Throwing an error, and quitting if it cannot find the file
	try:
		f1=open(file_name, 'r')
	except:
		print("Error could not find file: " + str(file_name) + " with given name")
		os._exit(0)

	# Copy each line of the file into an array
	file1=[]
	for line in f1:
		file1.append(line)
	f1.close()

	
	return file1

##############################################################################################################################

# Pulling cell volume from the .ph file, need it to calculate oscillator strength
# Hoping Volume is in units of A^3
# Returns volume (float), and units (string)
def get_volume(file):
	volume=0
	units=""
	for line in file:
		if 'unit-cell volume' in line:
			volume= float(line.split()[3])
			units= str(line.split()[4])

	# Error test incase volume is missing, don't want it to be zero
	if volume==0:
		print("Unable to find volume in .ph file, that seems peculiar")
		os._exit(0)

	# (scalar, string)
	return volume, units

##############################################################################################################################

#Getting atomic masses and number of atoms from .ph file
# Returns a list of atom names (string array), atom counts (int array), and masses (float array)
def atoms(file):
	atom_names=[]
	atom_counts=[]
	masses=[]
	counter=0
	line=file[counter]

	# Searching for "site n." because atoms are listed directly after
	for counter in range(len(file)):
		if 'site n.' in line:
			counter+=1
			line=file[counter]
			atom_counts.append(1)
			atom_names.append(str(line.split()[1]))
			masses.append(float(line.split()[2]))
			break
		
		line=file[counter]

	# Once it finds "site n." it will add lines until it reaches an empty line,
	# Indicating it has read all of the atoms + masses

	# If an atom we don't have indexed appears, we add it to the list and keep track of it. 
	while( len(line.split()) >0):
		if str(line.split()[1]) not in atom_names:
			atom_counts.append(1)
			atom_names.append(str(line.split()[1]))
			masses.append(float(line.split()[2]))
		else:
			atom_counts[-1]+=1
			masses.append(float(line.split()[2]))
		counter+=1
		line=file[counter]

	# Error test
	if len(atom_counts)==0:
		print("Could not find atoms in .ph file, abandon ship")
		os._exit(0)

	return atom_names, atom_counts, masses

##############################################################################################################################

# Getting Effective cahrges from .ph file
# Returns a (3*N x 3) array of effective charges (units of e?)
# Every set of 3 rows is for 1 atom
def get_BEC(file):
	BEC=[]
	counter=0

	# Parse file until it finds line indicating effective charges are there
	for line in file:
		if 'Effective charges' in line:
			counter+=2
			line=file[counter]
			break
		counter+=1

	# Reads effective charges until line is blank
	while(len(line.split())>1):
		if 'atom' not in line:
			#print(line.split()[2:-1]) 
			BEC.append([float(y) for y in (line.split())[2:-1]  ] )
		counter+=1
		line=file[counter]

	if len(BEC)==0:
		print("Could not find Effective Charges in .ph file, there are no mistakes just happy accidents")

	return BEC

##############################################################################################################################

# Reads the dynmat file, and uses the number of atoms from the .ph file
# To get the normalized eigenvectors and eigenvalues from dynmat
# Returns 3N float array of frequencies (cm-1), and a 3N X 3N float array of eigenvectors  

# My code only reads the first, third and fifth columns for the  dynamical eigenvectors (assumes only real)
def get_DYN(file, atom_count):
	frequencies=[]
	DYN_matrix= np.zeros((atom_count*3,atom_count*3))
	#print(DYN_matrix)
	mode=0
	counter=0
	line=file[counter]
	
	# Sifts through file, pulling frequencies and eigenvectors
	while(counter< len(file)-1):
		counter+=1
		line=file[counter]

		if 'cm-1' in line:
			frequencies.append(float(line.split('=')[2].split()[0]))
			for x in range(atom_count):
				counter +=1
				line=file[counter]
				DYN_matrix[mode][3*x]= float(line.split()[1])
				DYN_matrix[mode][3*x+1]= float(line.split()[3])
				DYN_matrix[mode][3*x+2]= float(line.split()[5])

			mode+=1
			#print(DYN_matrix)

	vectors=DYN_matrix
	# Normalizing eigenvectors
	for x in range(len(vectors)):
		vectors[x]= vectors[x]/np.linalg.norm(vectors[x])

	# Throw error
	if len(frequencies)==0:
		print("Dynamat file empty?")
		os._exit(0)


	return frequencies, vectors



##############################################################################################################################

# Using information from .ph and dynmat files, we can calculate real space phonon distortions
# returns a 3N array of floats for reduced mass, and a 3N x 3N matrix of real space phonon displacement eigenvectors each column is an eigenvector 
def get_Real_Disp(atom_counts, masses, DYN_vectors):
	
	# Generating an inverted mass matrix, in order to calculate real space displacements
	inv_mass_matrix=[]
	for x in range(len(masses)):
		for y in range(3):
			inv_mass_matrix.append(1/masses[x])

	inv_mass_matrix=np.diag(inv_mass_matrix)
	real_disp= np.dot(DYN_vectors, inv_mass_matrix**.5)
	real_disp=np.transpose(real_disp)

	# Getting reduced mass
	reduced_mass=[]
	for x in range(len(real_disp)):
		reduced_mass.append(np.dot(np.transpose(real_disp)[x] , np.transpose(real_disp)[x])**-1)
		np.transpose(real_disp)[x]= np.transpose(real_disp)[x]/ np.linalg.norm(np.transpose(real_disp)[x])



	return reduced_mass, real_disp


##############################################################################################################################

# Calculating the mode effective charge, as defined in this paper:
# https://journals.aps.org/prb/abstract/10.1103/PhysRevB.55.10355
# It's equation (53)
# Units probably won't be accurate since I'm unfamiliar with QE, but we care about relative scales
def get_MEC(masses, BEC, real_disp):
	MEC_list=[]
	for n in range(len(real_disp)):
		MEC_list.append([])
		U=np.transpose(real_disp)[n]
		for alpha in range(3):
			MEC=0
			norm=0

			for x in range(len(masses)):
				for y in range(3):
					MEC+= U[x*3+y] * BEC[x*3+alpha][y]
					norm+= U[x*3+y] * U[x*3+y]
			

			#This if statement is to supress noise, keeping results looking clean
			# checks that the length of the mode effective charge vector is less than 10^-10
			if (abs(MEC/(norm**.5)) < 10**(-3) ):
				MEC=0
			MEC_list[n].append(MEC/(norm**.5))



	return MEC_list


##############################################################################################################################

# Fixing in a damping parameter for phonons, for now it is 1.7 cm-1 for all of them. 
def get_Damping(atoms):
	damp=[]
	for x in range(3*sum(atoms)):
		damp.append(1.7)
	return damp


##############################################################################################################################

# Writing an Input file for the Lorentz oscillator
def write_input(vol, DIEL , charges,freq, mass, damping ):
	# Opens file
	f=open('Input_File.txt','w' )
	
	# Setting up the, minimum and maximum frequencies (cm-1)
	f.write("Freq_Min(cm-1)= 0 \n")
	f.write("Freq_Max(cm-1)= " + str(1.5*freq[-1]) + "\n")

	# Number of steps you want within the frequency range
	f.write("Number_Of_Steps= 10000 \n")

	# Beta is a constant for units, but doesn't really matter here since I'm unsure of QE
	# Multiplied my normal beta by 33.333 so that values scale better due to cm-1
	f.write("Beta(ps^-1)= 58197148.327 \n")

	# Volume
	f.write("Vol(Angstrom^3)= " + str(vol)+ "\n")
	
	# Option for linear vs angular frequency units 
	f.write("Out_Units(freq)= 1 (0=anglar freq, 1= linear freq) \n")

	# Dielectric constants
	f.write("DE_Inf= xx, yy, zz, xy, xz, yz \n")
	f.write( str(DIEL[0]) + '\t' +   str(DIEL[1]) + '\t' +str(DIEL[2]) + '\t' +str(DIEL[3]) + '\t' +str(DIEL[4]) + '\t' +str(DIEL[5]) + '\t' +  "\n")
	#f.write( '0' + '\t' +   '0' + '\t' + '0' + '\t' + '0' + '\t' + '0' + '\t' + '0' + '\t' +  "\n")
	# Keeping track of number of modes we have to try
	f.write("Number_of_Oscillators= "  + str(len(freq)) + " \n")
	
	# Writing down the mode effective charge for each mode
	f.write("Mode_Effective_Charge(e): 3*N \n")
	f.write("Example N: x y z \n")
	for x in range(len(freq)):
		# Forcing Accoustic phonon MEC to be zero
		if freq[x] <=0:
			f.write( str(x+1) + "\t" + str(0) + "\t" + str(0)+ "\t" + str(0)+ "\n")
		else:
			f.write( str(x+1) + "\t" + str(charges[x][0]) + "\t" + str(charges[x][1])+ "\t" + str(charges[x][2])+ "\n")

	# Writing frequencies of each mode
	f.write("Res_Freq(cm-1)= N \n")
	for x in range(len(freq)):
		f.write( str(x+1) + "\t" + str(freq[x]) + "\n")

	# Reduced masses
	f.write("Mass(amu)= N \n")
	for x in range(len(freq)):
		f.write( str(x+1) + "\t" + str(mass[x]) + "\n")

	# Damping parameter
	f.write("Damping(cm-1)= N \n")
	for x in range(len(freq)):
		f.write( str(x+1) + "\t" + str(damping[x]) + "\n")


	# Done, pizza is finished
	f.close()




##############################################################################################################################

# Reading in the inputs from the input file, should be fairly self contained
def Read_Diel_Input(Filename):
	
	f = open(Filename,'r')

	#Freq_Min(cm-1)
	line=f.readline()
	row=line.split()
	Freq_Min= float(row[1])
	
	#Freq_Max(cm-1)
	line=f.readline()
	row=line.split()
	Freq_Max=float(row[1])	
		
	#Number_Of_Steps
	line=f.readline()
	row=line.split()
	Freq_step=int(row[1])	
		
	#Beta(ps^-1) 
	line=f.readline()
	row=line.split()
	Beta=float(row[1])	
	
	#Vol(Angstrom^3)= 1
	line=f.readline()
	row=line.split()
	Vol=float(row[1])	   
	
	#Out_Units(freq)= 0 (0=anglar freq, 1= linear freq)
	line=f.readline()
	row=line.split()
	Out=int(row[1])
	
	#DE_inf
	line=f.readline()
	line=f.readline()
	row=line.split()
	DE_inf=row
	if len(DE_inf)!=6:
		print("Not a proper amount of given high frequency Dielectric Constants ")
	for x in range(0,len(DE_inf),1):
		DE_inf[x]= float(DE_inf[x])
		
	#Num Osc
	line=f.readline()
	row= line.split()
	Num_Osc= int(row[1])
	
	#Mode Charge
	Mode_Charge =[]
	n=0
	line=f.readline()
	line=f.readline()
	line=f.readline()
	
	while 'Res_Freq'  not in line :
		Mode_Charge.append([])
		row=line.split()
		Mode_Charge[n].append(float(row[1]))
		Mode_Charge[n].append(float(row[2]))
		Mode_Charge[n].append(float(row[3]))
		
		n=n+1
		line=f.readline()
	
	if len(Mode_Charge) != Num_Osc:
		print("Number of Oscillators not equal to number of given modes")
		
	#Res_Freq(cm-1)
	line=f.readline()
	
	Res_freq = []

	
	while 'Mass'  not in line :
		
		row=line.split()
		Res_freq.append(float(row[1]))
  
		line=f.readline()		
		
		
	if len(Res_freq) != Num_Osc:
		print("Number of Oscillators not equal to number of given Resonate modes")		
		
	#Mass(amu)= N
	line=f.readline()
	
	Mass = []
	
	while 'Damping'  not in line :
		
		row=line.split()
		Mass.append(float(row[1]))
		
		line=f.readline()		
		
		
	if n != Num_Osc:
		print("Number of Oscillators not equal to number of given number of Masses")		  
	

	#Damping(cm-1)
	line=f.readline()
	
	Damping= []
 
	while len(line) !=0 :
		
		row=line.split()
		Damping.append(float(row[1]))
 
		line=f.readline()		
		
		
	if len(Damping) != Num_Osc:
		print("Number of Oscillators not equal to number of given Damping modes")	 


	f.close()
	return DE_inf, Num_Osc, Mode_Charge, Res_freq, Damping, Freq_Min, Freq_Max, Freq_step, Beta, Mass, Vol, Out




##############################################################################################################################

# If you are curious how this is being calculated, I think you can just google it.
# Section 3 from here seems sufficent:
# https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-007-electromagnetic-energy-from-motors-to-lasers-spring-2011/readings/MIT6_007S11_lorentz.pdf
def Lorentz_Osc(DE_inf,  Num_Osc,Mode_Charge, Res_freq, Damping, Freq_min, Freq_max, Freq_steps,Beta,Mass, Vol, Out_Unit):
	#Calculates real and imaginary parts of the dielectric as a function of frequency. Based on the lorentz oscillator model. Also the reflectivity maybe. 


	#Inputs (in order of the call input):
	#Deilectric for infinite frequency
	#Number of Oscillators
	#Plasma Frequency
	#Resonate Frequency
	#Dampening constant
	#Initial frequency
	#Final Frequency
	#Number of frequencies in-between
	#Beta is a predetermined unit constant
	#Mass
	#volume of unit cell
	#output units
	
	
	#initialize lists
	Damping_squared= [0 for k in range(Num_Osc)]
	Res_squared= [0 for k in range(Num_Osc)]
	Mode_Charge_squared =[[0 for j in range(6) ]  for k in range(Num_Osc)]
	#Plasma_freq_squared[n][0] would give the xx component of the nth oscillator
	

	
	
	#Squaring constants here so we don't constnatly re-calculate them in the main for-loop
	for y in range(0, Num_Osc,1):	 
		Damping_squared[y] =(Damping[y]*Damping[y])
		Res_squared[y]=(Res_freq[y]*Res_freq[y])
		
		#Plasma Frequency[n][x], for x== 0 is xx, 1 is yy, 2 is zz, 3 is xy, 4 is xz, 5 is yz
		Mode_Charge_squared[y][0]=( Mode_Charge[y][0]*Mode_Charge[y][0])
		Mode_Charge_squared[y][1]=( Mode_Charge[y][1]*Mode_Charge[y][1])
		Mode_Charge_squared[y][2]=( Mode_Charge[y][2]*Mode_Charge[y][2])
		Mode_Charge_squared[y][3]=( Mode_Charge[y][0]*Mode_Charge[y][1])
		Mode_Charge_squared[y][4]=( Mode_Charge[y][0]*Mode_Charge[y][2])
		Mode_Charge_squared[y][5]=( Mode_Charge[y][1]*Mode_Charge[y][2])
		
		
		
		
		
	
	#calculates the frequency step size
	Step_size=((Freq_max - Freq_min)/float(Freq_steps))
	
	
	#calculating unit constant so we don't do it each time
	Vol= float(Vol)
	
	if(Out_Unit==0):
		delta=1
	elif(Out_Unit==1):
		delta=2*np.pi
		
		
		
	Unit_Constant= Beta/(Vol*delta**2)
	
	#creates a new text file puts in the header columns
	file = open('diel_output.txt','w') 
	if delta==1:
		file.write( 'w' +"(2pi_cm-1)" + ", " )
	else:
		file.write( 'w' +"(cm-1)" + ", " )
	file.write( 'RE(w)_11' + "," )
	file.write( 'RE(w)_22' + "," ) 
	file.write( 'RE(w)_33' + "," )
	file.write( 'RE(w)_12' + "," )
	file.write( 'RE(w)_13' + "," )
	file.write( 'RE(w)_23' + "," ) 
	file.write( 'IM(w)_xx' + "," ) 
	file.write( 'IM(w)_yy' + "," ) 
	file.write( 'IM(w)_zz' + "," ) 
	file.write( 'IM(w)_xy' + "," ) 
	file.write( 'IM(w)_xz' + "," )
	file.write( 'IM(w)_yz' + "," )
	file.write( 'IM(w)_23' + "," )
	file.write( 'Reflectance(w)' + "	\n" )
	
	#q is a variable to keep track of the current frequency
	q= Freq_min 
 
	
	
	DE_real=[0 for k in range(6)]
	DE_img=[0 for k in range(6)]
	Reflectivity=[0 for k in range(6)]
	#just a for loop to iterate over the frequencies 
	for x in range(0, Freq_steps+1,1):
		Avg_Reflectivity=0
		#iterate over the cordinate products (xx, yy,zz, xy, xz, yz)
		for y in range(0,6,1):
			DE_real[y]=0
			DE_img[y]=0
			
			#add up the contributions from each oscillator
			for z in range(0,Num_Osc,1):
			#calculates the real part of the Dielectric function based on the lorentz oscillator model
				#DE_real[y] = DE_real[y] +  (Mode_Charge_squared[z][y]*(1/Mass[z]) *( Res_squared[z] - (q*q))/(( Res_squared[z] - q*q )**2 + Damping_squared[z]*q*q)) 
	
			#calculates the imginary part of the Dielectric function based on the lorentz oscillator model
				DE_img[y] = DE_img[y] +  (Mode_Charge_squared[z][y]*(1/Mass[z])*(Damping[z])*q)/(( Res_squared[z] - q*q )**2 + Damping_squared[z]*q*q)
			
			
			
			
			#DE_real[y]=   Unit_Constant*DE_real[y]+ DE_inf[y]
			DE_img[y] = Unit_Constant*DE_img[y]
			DE_img[y] = complex(0,DE_img[y])
		
		
			#Reflectivity[y] = ( ((DE_real[y]-DE_img[y])**.5 -1)/( (DE_real[y]-DE_img[y])**.5 +1 ) )**2
			#Reflectivity[y] = ( Reflectivity[y].real*Reflectivity[y].real + Reflectivity[y].imag*Reflectivity[y].imag )	#I think we only want the real part of the reflectivity?		
			#Avg_Reflectivity+= Reflectivity[y]
		
	
		#Avg_Reflectivity= Avg_Reflectivity/(6.0)
		#writes the values to a text file
		file.write( str(q) ) 
		#for j in range(6):
		#	file.write(str(DE_real[j]) + "	" ) 
			
		for j in range(6):
			file.write(", "+str(DE_img[j].imag) )
		file.write("\n") 
		#file.write(str(Avg_Reflectivity) + "	\n" )

		
		#iterates to the next frequency
		q=q+Step_size
		
		
		

	file.close()	

##############################################################################################################################
######################################################### THE END ############################################################
##############################################################################################################################