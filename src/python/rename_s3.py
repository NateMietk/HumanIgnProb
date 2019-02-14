import os, sys
import subprocess

## extract filename and re-order, e.g., rename all Equipment_Use to EquipmentUse, Debris_Burning to DebrisBurning
x_var_dir = '../../../data/x_tiles'

aet = glob(x_var_dir + "/{}*.tif".format('aet'))
landmask = glob(x_var_dir + "/{}*.tif".format('land-mask'))

f=aet[0]
bname = os.path.basename(f)
dname = os.path.dirname(f)

fname_parts = bname.split('_')
print(fname_parts)
index_correct = [0,2,1,3,4]
fname_parts_correct = [fname_parts[i] for i in index_correct]
print(fname_parts_correct)
# the first two items should be concatenated
print(fname_parts_correct[2:])
first_str = fname_parts_correct[0] + '-' + fname_parts_correct[1]
fname_parts_correct = [first_str] + fname_parts_correct[2:]
print(fname_parts_correct)
new_fname = '_'.join(fname_parts_correct)
print(new_fname)

# rename
for f in aet:
    bname = os.path.basename(f)
    dname = os.path.dirname(f)
    
    fname_parts = bname.split('_')
    index_correct = [0,2,1,3,4]
    fname_parts_correct = [fname_parts[i] for i in index_correct]
    
    # the first two items should be concatenated
    first_str = fname_parts_correct[0] + '-' + fname_parts_correct[1]
    fname_parts_correct = [first_str] + fname_parts_correct[2:]
    new_fname = '_'.join(fname_parts_correct)
    
    os.rename(f, os.path.join(dname,new_fname))
    
## set up some parameters
s3_folder = 's3://earthlab-modeling-human-ignitions/<folder>'
old_fi = s3_folder + '/{}'.format(old_file)
new_fi = s3_folder + '/{}'.format(new_file)

## produce cmd string and use subprocess to call it
#sub_str = 'aws s3 --recursive mv {old_fi} {new_fi}'
#subprocess.call(sub_str)