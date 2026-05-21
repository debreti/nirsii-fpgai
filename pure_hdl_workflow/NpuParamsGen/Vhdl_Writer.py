from pathlib import Path
from typing import List, Dict
from Constants import CONFIGS_LIST, PACKAGE_FILE_PATH, ROM_FOLDER_PATH


def gen_layers_map() -> str:
    lines = ["constant LAYERS_MAP : natural_arr := ("]
    for cfg_idx, cfg in enumerate(CONFIGS_LIST):
        last = (cfg_idx == len(CONFIGS_LIST) - 1)
        line = "    " + ", ".join(str(x) for x in cfg["layers"])
        if not last:
            line += ","
        lines.append(line)
    lines.append(");")
    return "\n".join(lines)


def gen_nn_config() -> str:
    lines = ["constant NN_CONFIG : configs_arr := ("]
    for idx, cfg in enumerate(CONFIGS_LIST):
        lines.append(f"    {idx} => (")
        lines.append(f"        Mac_Cnt       => {cfg['mac_count']},")
        lines.append(f"        Layers_Cnt    => {len(cfg['layers'])},")
        lines.append(f"        Weight_Width  => {cfg['weight_width']},")
        lines.append(f"        Bias_Width    => {cfg['bias_width']},")
        lines.append(f"        Z_Scale_Width => {cfg['z_scale_width']},")
        lines.append(f"        M_Scale_Width => {cfg['m_scale_width']},")
        lines.append(f"        Acc_Width     => {cfg['acc_width']},")
        lines.append(f"        Neuron_Width  => {cfg['neuron_width']}")
        # Check if last config
        last = (idx == len(CONFIGS_LIST) - 1)
        lines.append("    )" + ("," if not last else ""))
    lines.append(");")
    return "\n".join(lines)


def replace_vhdl_scalar_constant(text: str, name: str, value: str) -> str:
    key = f"constant {name}"
    start = text.find(key)
    if start == -1:
        raise RuntimeError(f"{name} not found in VHDL file")

    end = text.find(";", start)
    if end == -1:
        raise RuntimeError(f"{name}: ';' not found")
    return (
            text[:start]
            + f'constant {name} : string := {value};'
            + text[end + 1:]
    )


def replace_vhdl_array_constant(text: str, name: str, new_block: str) -> str:
    """
    Replace a VHDL constant definition by name.
    Assumes format:
        constant NAME : <type> := (
            ...
        );
    """
    key = f"constant {name}"
    start = text.find(key)
    if start == -1:
        raise RuntimeError(f"{name} not found in VHDL file")
    assign = text.find(":=", start)
    if assign == -1:
        raise RuntimeError(f"{name}: ':=' not found")
    open_paren = text.find("(", assign)
    if open_paren == -1:
        raise RuntimeError(f"{name}: '(' not found")
    close = text.find(");", open_paren)
    if close == -1:
        raise RuntimeError(f"{name}: ');' not found")
    close += 2  # include ');'
    return text[:start] + new_block + text[close:]


def write_configs_to_vhdl() -> None:
    """
    Update NN_CONFIG and LAYERS_MAP constants in an existing VHDL file.
    Only those two constants are modified. Everything else is preserved.
    """
    # Check path
    if not (PACKAGE_FILE_PATH.exists() and PACKAGE_FILE_PATH.is_file()):
        raise FileNotFoundError(f"VHDL file not found: {PACKAGE_FILE_PATH}")
    # Start file reading
    text = PACKAGE_FILE_PATH.read_text()
    # Replace rom folder path
    text = replace_vhdl_scalar_constant(
        text,
        "MIF_FOLDER_PATH",
        f'"{ROM_FOLDER_PATH.as_posix().rstrip("/") + "/"}"'
    )
    # Replace configs list
    text = replace_vhdl_array_constant(
        text,
        "NN_CONFIG",
        gen_nn_config()
    )
    # Replace layers list
    text = replace_vhdl_array_constant(
        text,
        "LAYERS_MAP",
        gen_layers_map()
    )
    PACKAGE_FILE_PATH.write_text(text)
