import math
import numpy as np
from pyfi import fi
from Constants import *


# Function to print npy data and its type (Useful before mif making)
def print_npy_matrix(filepath):
    data = np.load(filepath)
    flat = data.flatten()
    n = math.ceil(math.sqrt(len(flat)))
    max_len = max(len(f"{x:.4g}") for x in flat)
    print(f"Данные из файла {filepath} — {flat.size} записей типа {data.dtype}")
    for i in range(n):
        row = flat[i * n:(i + 1) * n]
        print("  ".join(f"{x:>{max_len}.4g}" for x in row))


def write_mem_hex(values, bit_width, output_file):
    hex_digits = bit_width // 4
    max_value = 1 << bit_width
    with open(output_file, "w") as f:
        for val in values:
            unsigned_val = int(val) % max_value
            f.write(f"{unsigned_val:0{hex_digits}X}\n")


def create_flayer_mif(segment_length=784, word_len=8):
    with open("NN_params/inputs.txt", 'r') as f:
        numbers = [int(x) for x in f.read().split()]
    num_segments = (len(numbers) + segment_length - 1) // segment_length
    for n in range(num_segments):
        segment = numbers[n * segment_length:(n + 1) * segment_length]
        depth = len(segment)
        output_mem = Path(ROM_FOLDER_PATH, f"FirstLayer{n}.txt")
        write_mem_hex(segment, word_len, output_mem)
        print(f"MIF '{output_mem}' создан! Глубина: {depth}, Ширина: {word_len}")


def create_weight_mif(inst_inx):
    layers = CONFIGS_LIST[inst_inx]["layers"]
    mac_count = CONFIGS_LIST[inst_inx]["mac_count"]
    weight_width = CONFIGS_LIST[inst_inx]["weight_width"]
    mac_data = [[] for _ in range(mac_count)]
    for i in range(1, len(layers)):  # Excluding first layer
        input_size = layers[i - 1]
        output_size = layers[i]
        input_file = f"NN_params/TrainFiles/Weight/I{inst_inx}L{i - 1}W.npy"
        weight_matrix = np.load(input_file, allow_pickle=True).astype(np.int64)
        weight_matrix = weight_matrix.reshape(output_size, input_size)
        for neuron_idx in range(output_size):
            mac_idx = neuron_idx % mac_count
            mac_data[mac_idx].extend(weight_matrix[neuron_idx].tolist())
        remainder = output_size % mac_count
        if remainder != 0:
            pad_neurons = mac_count - remainder
            for m in range(remainder, remainder + pad_neurons):
                dead_mac = m % mac_count
                mac_data[dead_mac].extend([0] * input_size)
    for mac_idx in range(mac_count):
        values = mac_data[mac_idx]
        depth = len(values)
        output_file = Path(ROM_FOLDER_PATH, f"I{inst_inx:02d}W{mac_idx:03d}.txt")
        write_mem_hex(values, weight_width, output_file)
        print(f"MIF-файл '{output_file}' создан! Глубина: {depth}, Ширина: {weight_width}")


def create_bias_mif(inst_inx):
    mac_count = CONFIGS_LIST[inst_inx]["mac_count"]
    bias_width = CONFIGS_LIST[inst_inx]["bias_width"]
    b_layers = CONFIGS_LIST[inst_inx]["layers"].copy()
    b_layers.pop(0)  # Remove first layer
    mac_memories = [[] for _ in range(mac_count)]
    for layer_idx, neuron_count in enumerate(b_layers):
        input_file = f"NN_params/TrainFiles/Bias/I{inst_inx}L{layer_idx}B.npy"
        bias_values = np.load(input_file, allow_pickle=True).flatten().astype(np.int64)
        if len(bias_values) != neuron_count:
            raise ValueError
        for i, val in enumerate(bias_values):
            mac_idx = i % mac_count
            mac_memories[mac_idx].append(val)
        remainder = neuron_count % mac_count
        if remainder != 0:
            for mac_idx in range(remainder, mac_count):
                mac_memories[mac_idx].append(0)
    for mac_idx in range(mac_count):
        data = mac_memories[mac_idx]
        depth = len(data)
        output_file = Path(ROM_FOLDER_PATH, f"I{inst_inx:02d}B{mac_idx:03d}.txt")
        write_mem_hex(data, bias_width, output_file)
        print(f"MIF-файл '{output_file}' создан! Глубина: {depth}, Ширина: {bias_width}")


def create_z_scale_mif(inst_inx):
    memory_int = []
    num_layers = len(CONFIGS_LIST[inst_inx]["layers"])
    z_width = CONFIGS_LIST[inst_inx]["z_scale_width"]
    for i in range(num_layers - 2):  # Excluding first and last layer
        input_file = f"NN_params/TrainFiles/Z_Scale/I{inst_inx}L{i}Z.npy"
        int_array = np.load(input_file).flatten().astype(np.int64)
        memory_int.extend(int_array)
    depth = len(memory_int)
    output_file = Path(ROM_FOLDER_PATH, f"I{inst_inx:02d}Z.txt")
    write_mem_hex(memory_int, z_width, output_file)
    print(f"MIF-файл '{output_file}' создан! Глубина: {depth}, Ширина: {z_width}")


def create_m_scale_mif(inst_inx):
    memory_int = []
    word_len = CONFIGS_LIST[inst_inx]["m_scale_width"]
    num_layers = len(CONFIGS_LIST[inst_inx]["layers"])
    fi_obj = fi(word_len=word_len, frac_len=word_len, signed=False, fixed=True, return_val=True)
    for i in range(num_layers - 1):  # Excluding first layer
        input_file = f"NN_params/TrainFiles/M_Scale/I{inst_inx}L{i}M.npy"
        float_array = np.load(input_file)
        hex_strings = [fi_obj(float(val)) for val in float_array.flatten()]
        layer_memory = [int(h.replace('0x', ''), 16) for h in hex_strings]
        memory_int.extend(layer_memory)
    depth = len(memory_int)
    output_file = Path(ROM_FOLDER_PATH, f"I{inst_inx:02d}M.txt")
    write_mem_hex(memory_int, word_len, output_file)
    print(f"MIF-файл '{output_file}' создан успешно! Глубина: {depth}, Ширина: {word_len}")
