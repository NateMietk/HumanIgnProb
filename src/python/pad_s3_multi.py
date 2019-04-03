import os, sys
import subprocess
import itertools
import multiprocessing as mp
from functools import partial
import rasterio as rio
import numpy as np

def download_pad_upload(inputs3, outputs3, rows=448, cols=448, xy=None):

    # download the input file
    sub_str = f'aws s3 cp {inputs3} ./padded/'
    #print(sub_str)
    subprocess.call(sub_str, shell=True)    
    
    infi = f'./padded/{os.path.basename(inputs3)}'
    outfi = f'./padded/{xy}/{os.path.basename(inputs3)}'
    
    print(infi, outfi)
    
    with rio.open(infi) as src:
        arr = src.read()
        meta = src.profile
        
    # pad the array
    cur_shape = arr.shape
    temp = np.zeros((1, 448,448), dtype=arr.dtype)
    temp[0, :cur_shape[1], :cur_shape[2]] = arr
    arr = temp
    
    # update metadata
    meta.update({"height": rows,
                 "width": cols})
                 
    # write out padded array
    with rio.open(outfi, 'w', **meta) as dest:
        dest.write(arr)
        
    # aws call to replace raster
    sub_str = f'aws s3 cp {outfi} {outputs3}'
    subprocess.call(sub_str, shell=True)    

    # clean up
    os.remove(infi)
    os.remove(outfi)
    
    return

def proc_fun(var, xy=None):
    
    # s3_folder_old = 's3://earthlab-modeling-human-ignitions/tiles/x_var'
    # s3_folder_new = 's3://earthlab-modeling-human-ignitions/tiles/padded/x_var'
    
    s3_folder_old = 's3://earthlab-modeling-human-ignitions/tiles/{}'.format(xy)
    s3_folder_new = 's3://earthlab-modeling-human-ignitions/tiles/padded/{}'.format(xy)

    tiles = list(range(1,151)) # all tiles
    bad_tiles = [1, 10, 105, 106, 11, 12, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 13, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 14, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 15, 150, 16, 2, 3, 30, 31, 4, 45, 46, 5, 6, 60, 61, 7, 75, 76, 8, 9, 90, 91]
    months = list(range(1,13))
    years = list(range(1992,2016))
    year_month_tile = list(itertools.product(years, months, tiles))
    for year,month,tile in year_month_tile:

        # construct filename
        fi_name = f'{var}_{year}_{month}_t{tile}.tif'        
        old_fi = s3_folder_old + '/{}'.format(fi_name)
        new_fi = s3_folder_new + '/{}'.format(fi_name)
        
        if tile not in bad_tiles:
            # copy to new tile folder
            sub_str = f'aws s3 cp {old_fi} {new_fi}'
            subprocess.call(sub_str, shell=True)
            
        else:
            # call function to download, pad, and upload
            download_pad_upload(old_fi, new_fi, xy=xy)
            
            
    return

#if __name__ == '__main__':
x_vars = ['aet-95th', 'aet-mean',
               'def-95th', 'def-mean',
               'ffwi-numdays95th', 'ffwi-95th', 'ffwi-mean', # did this exist in the first place?
               'fm100-numdays95th', 'fm100-95th', 'fm100-mean', # did this exist in the first place?
               'pdsi-95th', 'pdsi-mean', 
               'pr-numdays95th', 'pr-95th', 'pr-mean', # did this exist in the first place?
               'vpd-95th', 'vpd-mean',
               'tmmx-numdays95th', 'tmmx-95th', 'tmmx-mean', # did this exist in the first place?
               'vs-numdays95th', 'vs-95th', 'vs-mean', # did this exist in the first place?
               'land-mask']

y_vars = ['Arson', 'Children', 'Campfire', 'Debris-Burning', 'Equipment-Use',
          'Fireworks', 'Lightning', 'Miscellaneous', 'Powerline', 'Railroad', 
          'Smoking', 'Structure', 'Human']

nproc = max(mp.cpu_count(), 2)
pool = mp.Pool(nproc)

# create padded directory
if not os.path.exists('./padded/x_var'):
    os.makedirs('./padded/x_var')
    
if not os.path.exists('./padded/y_var'):
    os.makedirs('./padded/y_var')

for vars, x_or_y in zip((y_vars, x_vars), ('y_var', 'x_var')):
    
    # crush it
    vals = pool.map(partial(proc_fun, xy=x_or_y), vars)

    # close the pool
    pool.close()
    pool.join()
