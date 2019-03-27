import torch
from torch import nn
import torch.nn.functional as F

import torch
from torch.utils.data import Dataset, DataLoader
import rasterio as rio
from glob import glob
import os, sys
import itertools
import numpy as np

class xymDatasetMultiVar(Dataset):
    """Dataset class for ignition types (Y var)"""
    
    def __init__(self, y_data_dir, x_data_dir, land_mask_dir, y_transform=None, x_transform=None, ig_types=['Arson', 'Campfire'], x_var=['aet-95th'], pad_result=False):
        """ 
        Args:
            data_dir(string): the folder containing the image files
            transform (callable, optional): Optional transform to  be applied to image data
            ig_types (iterable, optional): types of ignition rasters to include
            x_var (iterable, optional): list of predictor variable names
            land_mask (string, optional): defines whether or not to return land mask
        """
        
        # some sanity checks
        assert os.path.exists(y_data_dir)
        assert os.path.exists(x_data_dir)
        assert os.path.exists(land_mask_dir)
        assert len(ig_types) > 1
        assert len(x_var) > 1
        
        val_ig_types = set([os.path.basename(f).split('_')[0] for f in glob(y_data_dir + '/*.tif')])
        for v in ig_types:
            assert v in list(val_ig_types)
            
        val_x_var = set([os.path.basename(f).split('_')[0] for f in glob(x_data_dir + '/*.tif')])
        for v in x_var:
            assert v in list(val_x_var)
        
        # initialize some attributes
        self.y_data_dir = y_data_dir
        self.x_data_dir = x_data_dir
        self.land_mask_dir = land_mask_dir
        
        self.x_transform = x_transform
        self.y_transform = y_transform
        self.pad_result = pad_result
        self.ig_types = ig_types # should have a default...
        self.x_var = x_var
        self.val_months = list(range(1,13))
        
        # the filenaming is not consistent to get the years from the filename :(
        #self.val_years = set([os.path.basename(f).split('_')[-3] for f in y_files if (len(os.path.basename(f).split('_')) > 3)])
        self.val_years = list(range(1992,2016)) # 2015, since it is open-ended on the right
        
        ## y variable assertion
        # get the files for ig_type[0]... need to assert that num_files for each ig_type is equal
        self.files = glob(y_data_dir + "/*{}*.tif".format(ig_types[0]))
        temp_list = []
        for ig_type in ig_types:
            files = glob(y_data_dir + "/{}*.tif".format(ig_type))
            temp_list.append(files)
        
        # this should ensure that the file numbers are equal
        for flist in temp_list[1:]:
            assert len(temp_list[0]) == len(flist)       
            
            
        ## x variable assertion
        
        # get the tile numbers
        self.tile_nums = set([os.path.basename(f).split('_')[-1].split('.tif')[0] for f in files])
        
        # create an iterable for the __getitem__ method
        self.year_month_tile = list(itertools.product(self.val_years, self.val_months, self.tile_nums))
        
    
    def __getitem__(self, idx):
        
        """
            Files are organized as <var_type>_<year>_<month>_t<tileNumber>.tif, e.g., Arson_1992_1_t1
            A single dataset needs to be constructed for a given ignition type, year, month, and tile number
        """
        
        #var, year, month, tile = self.var_year_month_tile[idx]
        year, month, tile = self.year_month_tile[idx]
        y_files = [os.path.join(self.y_data_dir, '{}_{}_{}_{}.tif'.format(var, year, month, tile)) for var in self.ig_types]
        x_files = [os.path.join(self.x_data_dir, '{}_{}_{}_{}.tif'.format(var, year, month, tile)) for var in self.x_var]
        land_mask_file = os.path.join(self.x_data_dir, '{}_{}_{}_{}.tif'.format('land-mask', year, month, tile))
        
        # load y_files
        arrs = []
        valid_thresh = -100000
        for fi in y_files:
            with rio.open(fi) as src:
                arr = src.read(1)
                
                ## any thing matching this condition for X vars replace with mean of valid vals
                # valid Y nodata should be replaced with zeros
                #arr[arr <= -2.4e+38] = arr[arr > valid_thresh].mean()
                arr[arr <= -2.4e+38] = 0
                
                # on the fly padding of data to 448x448
                if self.pad_result:
                    cur_shape = arr.shape
                    temp = np.zeros((448,448), dtype=arr.dtype)
                    temp[:cur_shape[0], :cur_shape[1]] = arr
                    arr = temp
            
            arrs.append(arr)
        y_arr = np.array(arrs)
        
        # load x_files
        arrs = []
        valid_thresh = -100000
        for fi in x_files:
            with rio.open(fi) as src:
                arr = src.read(1)
                
                ## any thing matching this condition for X vars replace with mean of valid vals
                # valid Y nodata should be replaced with zeros
                #arr[arr <= -2.4e+38] = arr[arr > valid_thresh].mean()
                arr[arr <= -2.4e+38] = 0
                
                # on the fly padding of data to 448x448
                if self.pad_result:
                    cur_shape = arr.shape
                    temp = np.zeros((448,448), dtype=arr.dtype)
                    temp[:cur_shape[0], :cur_shape[1]] = arr
                    arr = temp
            
            arrs.append(arr)
        x_arr = np.array(arrs)
        
        # load land_mask
        valid_thresh = -100000
        with rio.open(fi) as src:
            land_mask_arr = src.read()

            ## any thing matching this condition for X vars replace with mean of valid vals
            # valid Y nodata should be replaced with zeros
            #arr[arr <= -2.4e+38] = arr[arr > valid_thresh].mean()
            land_mask_arr[land_mask_arr <= -2.4e+38] = 0

            # on the fly padding of data to 448x448
            if self.pad_result:
                cur_shape = land_mask_arr.shape
                temp = np.zeros((1,448,448), dtype=land_mask_arr.dtype)
                temp[0, :cur_shape[1], :cur_shape[2]] = land_mask_arr
                land_mask_arr = temp
                
        
        if (self.y_transform is not None) and (self.x_transform is not None):
            return (self.y_transform(torch.from_numpy(y_arr)), 
                    self.x_transform(torch.from_numpy(x_arr)), 
                    torch.from_numpy(land_mask_arr))   
        else:
            return (torch.from_numpy(y_arr), torch.from_numpy(x_arr), torch.from_numpy(land_mask_arr)) # return X, Y, Mask (Mask uses LandMask in X-var folder)
        
        
    def __len__(self):
        return len(self.files)

class UNet(nn.Module):
    def __init__(self, in_channels=1, n_classes=2, depth=5, wf=6, padding=False,
                 batch_norm=False, up_mode='upconv'):
        """
        Implementation of
        U-Net: Convolutional Networks for Biomedical Image Segmentation
        (Ronneberger et al., 2015)
        https://arxiv.org/abs/1505.04597
        Using the default arguments will yield the exact version used
        in the original paper
        Args:
            in_channels (int): number of input channels
            n_classes (int): number of output channels
            depth (int): depth of the network
            wf (int): number of filters in the first layer is 2**wf
            padding (bool): if True, apply padding such that the input shape
                            is the same as the output.
                            This may introduce artifacts
            batch_norm (bool): Use BatchNorm after layers with an
                               activation function
            up_mode (str): one of 'upconv' or 'upsample'.
                           'upconv' will use transposed convolutions for
                           learned upsampling.
                           'upsample' will use bilinear upsampling.
        """
        super(UNet, self).__init__()
        assert up_mode in ('upconv', 'upsample')
        self.padding = padding
        self.depth = depth
        prev_channels = in_channels
        self.down_path = nn.ModuleList()
        for i in range(depth):
            self.down_path.append(UNetConvBlock(prev_channels, 2**(wf+i),
                                                padding, batch_norm))
            prev_channels = 2**(wf+i)

        self.up_path = nn.ModuleList()
        for i in reversed(range(depth - 1)):
            self.up_path.append(UNetUpBlock(prev_channels, 2**(wf+i), up_mode,
                                            padding, batch_norm))
            prev_channels = 2**(wf+i)

        self.last = nn.Conv2d(prev_channels, n_classes, kernel_size=1)

    def forward(self, x):
        blocks = []
        for i, down in enumerate(self.down_path):
            x = down(x)
            if i != len(self.down_path)-1:
                blocks.append(x)
                x = F.avg_pool2d(x, 2)

        for i, up in enumerate(self.up_path):
            x = up(x, blocks[-i-1])

        return self.last(x)


class UNetConvBlock(nn.Module):
    def __init__(self, in_size, out_size, padding, batch_norm):
        super(UNetConvBlock, self).__init__()
        block = []

        block.append(nn.Conv2d(in_size, out_size, kernel_size=3,
                               padding=int(padding)))
        block.append(nn.ReLU())
        if batch_norm:
            block.append(nn.BatchNorm2d(out_size))

        block.append(nn.Conv2d(out_size, out_size, kernel_size=3,
                               padding=int(padding)))
        block.append(nn.ReLU())
        if batch_norm:
            block.append(nn.BatchNorm2d(out_size))

        self.block = nn.Sequential(*block)

    def forward(self, x):
        out = self.block(x)
        return out


class UNetUpBlock(nn.Module):
    def __init__(self, in_size, out_size, up_mode, padding, batch_norm):
        super(UNetUpBlock, self).__init__()
        if up_mode == 'upconv':
            self.up = nn.ConvTranspose2d(in_size, out_size, kernel_size=2,
                                         stride=2)
        elif up_mode == 'upsample':
            self.up = nn.Sequential(nn.Upsample(mode='bilinear', scale_factor=2),
                                    nn.Conv2d(in_size, out_size, kernel_size=1))

        self.conv_block = UNetConvBlock(in_size, out_size, padding, batch_norm)

    def center_crop(self, layer, target_size):
        _, _, layer_height, layer_width = layer.size()
        diff_y = (layer_height - target_size[0]) // 2
        diff_x = (layer_width - target_size[1]) // 2
        return layer[:, :, diff_y:(diff_y + target_size[0]), diff_x:(diff_x + target_size[1])]

    def forward(self, x, bridge):
        up = self.up(x)
        crop1 = self.center_crop(bridge, up.shape[2:])
        out = torch.cat([up, crop1], 1)
        out = self.conv_block(out)

        return out