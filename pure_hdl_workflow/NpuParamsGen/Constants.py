from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parent
VHDL_PROJECT_DIR = BASE_DIR.parent
ROM_FOLDER_PATH = Path(VHDL_PROJECT_DIR, "RomFiles")
PACKAGE_FILE_PATH = Path(VHDL_PROJECT_DIR, "RTL", "NPU_Package.vhd")

'''
 ============================================================
                   USER-DEFINED SETTINGS
       Quantized inference configuration (per instance)
 ============================================================
Fields:
#   mac_count      - number of MAC operations
#   weight_width   - bit width of weights
#   bias_width     - bit width of bias
#   acc_width      - bit width of accumulator of MAC block
#   neuron_width   - bit width of quantized neuron value
#   z_scale_width  - bit width of zero-point scale
#   m_scale_width  - bit width of multiplier scale coefficient  (pure fixed-point I(0).F)
#   layers         - per-instance layer list (unique for each config)
'''

CONFIGS_LIST = [
    {  # MNIST
        "mac_count": 4,
        "weight_width": 8,
        "bias_width": 32,
        "acc_width": 32,
        "neuron_width": 8,
        "z_scale_width": 32,
        "m_scale_width": 32,
        "layers": [784, 128, 10]
    }
]
