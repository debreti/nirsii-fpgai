function hB = plugin_board()
% Board definition

% Construct board object
hB = hdlcoder.Board;

hB.BoardName    = 'Xilinx Kintex 7 FPGA KC705';

% FPGA device information
hB.FPGAVendor   = 'Xilinx';
hB.FPGAFamily   = 'Kintex7';
hB.FPGADevice   = 'xc7k325t';
hB.FPGAPackage  = 'ffg900';
hB.FPGASpeed    = '-2';

% Tool information
hB.SupportedTool = {'Xilinx Vivado'};

% FPGA JTAG chain position
hB.JTAGChainPosition = 1;

% Size of external DDR memory in bytes
hB.ExternalMemorySize = 0x40000000; % 1 GB

% Стандарт для "External Port" по умолчанию (опционально)
hB.addExternalPortInterface( ...
    'IOPadConstraint', {'IOSTANDARD = LVCMOS15'});



