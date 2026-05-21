import numpy as np
import Mem_Maker as MifMake
from Constants import *
from Vhdl_Writer import write_configs_to_vhdl


'''
 ==================================
                MAIN
 ==================================
 '''
 
 
# Clear Rom folder from old files
assert ROM_FOLDER_PATH.exists() and ROM_FOLDER_PATH.is_dir()  # Safety check FIRST
for file in ROM_FOLDER_PATH.glob("*.txt"):
    file.unlink()

# Rom files generation
for inst_inx, config in enumerate(CONFIGS_LIST):
    MifMake.create_m_scale_mif(inst_inx)
    MifMake.create_z_scale_mif(inst_inx)
    MifMake.create_bias_mif(inst_inx)
    MifMake.create_weight_mif(inst_inx)
# Optional first layer ROM (For Simulation only)
MifMake.create_flayer_mif(784, 8)

# Update vhdl package file
write_configs_to_vhdl()

# Optional npy file contents print
# MifMake.print_npy_matrix("NN_params/TrainFiles/Bias/I0L0B.npy")


