import os, sys
import subprocess
import itertools
import multiprocessing as mp
from functools import partial

def proc_fun(var):
    
    s3_folder = 's3://earthlab-modeling-human-ignitions/tiles/x_var'

    tiles = list(range(1,151))
    months = list(range(1,13))
    years = list(range(1992,2016))
    year_month_tile = list(itertools.product(years, months, tiles))
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
        sub_str = f'aws s3 mv {old_fi} {new_fi}'
        #sub_str = 'aws s3 ls'
        subprocess.call(sub_str, shell=True)
        
        #print(sub_str)
        #break
        


#if __name__ == '__main__':
rename_vars = ['aet-95th', 'aet-mean',
               'def-95th', 'def-mean',
               'ffwi-95th', 'ffwi-mean', # did this exist in the first place?
               'fm100-95th', 'fm100-mean', # did this exist in the first place?
               'pdsi-95th', 'pdsi-mean', 
               'pr-95th', 'pr-mean', # did this exist in the first place?
               'vpd-95th', 'vpd-mean',
               'tmmx-95th', 'tmmx-mean', # did this exist in the first place?
               'vs-95th', 'vs-mean' # did this exist in the first place?]

# subset of variables with different names
rename_vars = ['ffwi-numdays95th',
               'fm100-numdays95th',
               'pr-numdays95th',
               'tmmx-numdays95th',
               'vs-numdays95th']

nproc = max(mp.cpu_count(), 2)
pool = mp.Pool(nproc)

vals = pool.map(partial(proc_fun), rename_vars)

# close the pool
pool.close()
pool.join()
