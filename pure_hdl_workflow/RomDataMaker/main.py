import numpy as np
import pandas as pd


def int_to_hex(value: int, width_bits: int = 32) -> str:
    if width_bits <= 0:
        raise ValueError("Bit width must be positive")
    hex_chars = (width_bits + 3) // 4  # Round up to full nibbles
    max_val = 1 << width_bits
    mask = max_val - 1
    # Convert to two's complement
    twos_comp = value & mask
    # Format with zero-padding
    return f"{twos_comp:0{hex_chars}X}"


# Pretty printing with aligned format
def print_aligned_table(df, float_format="{: .10f}"):
    headers = df.columns
    rows = [
        [float_format.format(x) if isinstance(x, float) else str(x) for x in row]
        for row in df.values]
    col_widths = [max(len(str(h)), *(len(r[i]) for r in rows)) for i, h in enumerate(headers)]
    header_row = " | ".join(h.ljust(col_widths[i]) for i, h in enumerate(headers))
    separator = "-+-".join('-' * col_widths[i] for i in range(len(headers)))
    print(header_row)
    print(separator)
    for r in rows:
        print(" | ".join(r[i].ljust(col_widths[i]) for i in range(len(r))))


def floats_to_signed_fixed(floats, frac_bits):
    # Converts a list of floats to signed fixed-point format with only fractional bits.
    scale = 2 ** frac_bits
    min_val = -1.0
    max_val = (scale - 1) / scale  # Maximum representable
    rows = []
    for val in floats:
        if not (min_val <= val < 1.0):
            raise ValueError(f"Value {val} out of representable range [-1, 1).")
        fixed_int = int(round(val * scale))
        fixed_int = max(min(fixed_int, scale - 1), -scale)
        fixed_float = fixed_int / scale
        abs_err = abs(val - fixed_float)
        rel_err = abs_err / abs(val) if val != 0 else 0.0
        rows.append({
            'Original': val,
            'Fixed-Point': fixed_float,
            'Abs Error': abs_err,
            'Rel Error': rel_err})
    diff = pd.DataFrame(rows)
    return diff


''' 
 ------------
|    Main    |
 ------------
'''
MAC_CNT = 4
W_WIDTH = 8
B_WIDTH = 32
FRAC_BITS = 8  # Excluding sign
LAYERS = [256, 128, 10]  # Excluding first
if __name__ == "__main__":

    w1 = np.load('quantized_params/layer1_weight.npy')
    print("Shape of layer1 weights:", w1.shape)
    print("First few weights:\n", w1[:10])

    # Brevitas files path and names
    b_file_name = "quantized_params/layer(?)_bias.npy"
    w_file_name = "quantized_params/layer(?)_weight.npy"

    # Scales error check for given number of fraction bits
    print("\nScales fixed point conversion at " + str(FRAC_BITS + 1) + " bits")
    scales = [0.0078125, 0.0078125, 0.00390625]
    df = floats_to_signed_fixed(scales, FRAC_BITS)
    print_aligned_table(df)

    # Bias rom file making
    with open("bias_rom_hex.txt", "w") as f:
        for layer_idx, layer_size in enumerate(LAYERS):
            b_layer = np.load(b_file_name.replace("(?)", str(layer_idx + 1)))
            file_ptr = 0
            remaining = layer_size
            # Process full MAC_CNT chunks
            while remaining >= MAC_CNT:
                for _ in range(MAC_CNT):
                    f.write(f"{int_to_hex(b_layer[file_ptr], B_WIDTH)}\n")
                    file_ptr += 1
                remaining -= MAC_CNT
            # Handle remaining blank mac and padding
            if remaining > 0:
                # Write remaining biases values
                for _ in range(remaining):
                    f.write(f"{int_to_hex(b_layer[file_ptr], B_WIDTH)}\n")
                    file_ptr += 1
                # Fill blanks with zeros
                for _ in range(MAC_CNT - remaining):
                    f.write(f"{int_to_hex(0, B_WIDTH)}\n")

    # Weight rom file making
    with open("weight_rom_hex.txt", "w") as f:
        for layer_idx, layer_size in enumerate(LAYERS):
            w_layer = np.load(w_file_name.replace("(?)", str(layer_idx + 1)))
            weight_ptr = 0
            neuron_ptr = 0
            remaining = w_layer.shape[0]
            # Process full MAC_CNT chunks
            while remaining >= MAC_CNT:
                for _ in range(w_layer.shape[1] - 1):
                    for i in range(MAC_CNT):
                        f.write(f"{int_to_hex(w_layer[neuron_ptr + i][weight_ptr], W_WIDTH)}\n")
                    weight_ptr += 1
                weight_ptr = 0
                neuron_ptr += MAC_CNT
                remaining -= MAC_CNT
            # Handling  last mac pair with some blanks
            if remaining > 0:
                for weight_ptr in range(w_layer.shape[1]):  # For each weight column
                    # Write remaining neurons
                    for i in range(remaining):
                        f.write(f"{int_to_hex(w_layer[neuron_ptr + i][weight_ptr], W_WIDTH)}\n")
                    # Pad with zeros to fill MAC_CNT
                    for _ in range(MAC_CNT - remaining):
                        f.write(f"{int_to_hex(0, W_WIDTH)}\n")
