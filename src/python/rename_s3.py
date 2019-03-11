import os, sys
import subprocess
import itertools


## extract filename and re-order, e.g., rename all Equipment_Use to EquipmentUse, Debris_Burning to DebrisBurning
s3_folder = 's3://earthlab-modeling-human-ignitions/tiles/x_var'

rename_vars = ['aet-95th', 'aet-mean',
               'def-95th', 'def-mean',
               'ffwi-95th', 'ffwi-mean',
               'fm100-95th', 'fm100-mean',
               'pdsi-95th', 'pdsi-mean',
               'pr-95th', 'pr-mean',
               'vpd-95th', 'vpd-mean',
               'tmmx-95th', 'tmmx-mean',
               'vs-95th', 'vs-mean']

# set up some file path needs
tiles = list(range(1,151))
months = list(range(1,13))
years = list(range(1992,2016))
year_month_tile = list(itertools.product(years, months, tiles))
for var in rename_vars:
    for year,month,tile in year_month_tile:
        
        # construct 'old' filename
        var_split = var.split('-')
        fi_old = f'{var_split[0]}_{year}_{var_split[1]}_{month}_t{tile}.tif'

        # rearrange filename parts
        fname_parts = fi_old.split('_')
        index_correct = [0,2,1,3,4]
        fname_parts_correct = [fname_parts[i] for i in index_correct]
        first_str = fname_parts_correct[0] + '-' + fname_parts_correct[1]
        fname_parts_correct = [first_str] + fname_parts_correct[2:]
        new_fname = '_'.join(fname_parts_correct)
        
        #print(fi_old, ">>>", new_fname)
        
        # construct S3 URIs
        old_fi = s3_folder + '/{}'.format(fi_old)
        new_fi = s3_folder + '/{}'.format(new_fname)
              
        # call aws mv to rename file
        sub_str = f'aws s3 --recursive mv {old_fi} {new_fi}'
        print(f'{old_fi} >>> {new_fi}')
        subprocess.call(sub_str)
        print('done\n')
        