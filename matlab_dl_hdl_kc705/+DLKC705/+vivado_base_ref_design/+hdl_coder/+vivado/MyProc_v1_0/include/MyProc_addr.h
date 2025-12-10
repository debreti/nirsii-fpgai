/*
 * File Name:         customProc\ipcore\MyProc_v1_0\include\MyProc_addr.h
 * Description:       C Header File
 * Created:           2025-10-22 15:50:45
*/

#ifndef MYPROC_H_
#define MYPROC_H_

#define  IPCore_Reset_MyProc                              0x0  //write 0x1 to bit 0 to reset IP core
#define  IPCore_Enable_MyProc                             0x4  //enabled (by default) when bit 0 is 0x1
#define  AXI4_Master_Activation_Data_Rd_BaseAddr_MyProc   0x8  //Base Address offset for AXI4 Master Activation Data Read (Default Base Address: hex2dec(0))
#define  AXI4_Master_Activation_Data_Wr_BaseAddr_MyProc   0xC  //Base Address offset for AXI4 Master Activation Data Write (Default Base Address: hex2dec(0))
#define  AXI4_Master_Weight_Data_Rd_BaseAddr_MyProc       0x10  //Base Address offset for AXI4 Master Weight Data Read (Default Base Address: hex2dec(0))
#define  AXI4_Master_Debug_Rd_BaseAddr_MyProc             0x14  //Base Address offset for AXI4 Master Debug Read (Default Base Address: hex2dec(0))
#define  AXI4_Master_Debug_Wr_BaseAddr_MyProc             0x18  //Base Address offset for AXI4 Master Debug Write (Default Base Address: hex2dec(0))
#define  IPCore_Timestamp_MyProc                          0x1C  //contains unique IP timestamp (yymmddHHMM): 2510221549
#define  AXIStreamInData_Data_MyProc                      0x100  //data register for Inport AXIStreamInData. Vector with 4 elements. Register is split across a total of 4 addresses, last address is 0x10C.
#define  AXIStreamInData_Strobe_MyProc                    0x110  //strobe register for port AXIStreamInData
#define  AXIStreamInValid_Data_MyProc                     0x114  //data register for Inport AXIStreamInValid
#define  AXIStreamOutReady_Data_MyProc                    0x118  //data register for Inport AXIStreamOutReady
#define  AXIStreamInReady_Data_MyProc                     0x11C  //data register for Outport AXIStreamInReady
#define  AXIStreamOutData_Data_MyProc                     0x120  //data register for Outport AXIStreamOutData
#define  AXIStreamOutValid_Data_MyProc                    0x124  //data register for Outport AXIStreamOutValid
#define  start_Data_MyProc                                0x138  //data register for Inport start
#define  debugEnable_Data_MyProc                          0x140  //data register for Inport debugEnable
#define  debugDMAEnable_Data_MyProc                       0x144  //data register for Inport debugDMAEnable
#define  debugDMALength_Data_MyProc                       0x148  //data register for Inport debugDMALength
#define  debugSelect_Data_MyProc                          0x14C  //data register for Inport debugSelect
#define  debugDMAWidth_Data_MyProc                        0x150  //data register for Inport debugDMAWidth
#define  debugDMAOffset_Data_MyProc                       0x154  //data register for Inport debugDMAOffset
#define  debugDMADirection_Data_MyProc                    0x158  //data register for Inport debugDMADirection
#define  debugDMAStart_Data_MyProc                        0x15C  //data register for Inport debugDMAStart
#define  image_valid_Data_MyProc                          0x160  //data register for Inport image_valid
#define  image_addr_Data_MyProc                           0x164  //data register for Inport image_addr
#define  image_data_Data_MyProc                           0x168  //data register for Inport image_data
#define  read_addr_Data_MyProc                            0x16C  //data register for Inport read_addr
#define  debug_read_data_Data_MyProc                      0x17C  //data register for Outport debug_read_data
#define  dma_from_ddr4_done_Data_MyProc                   0x184  //data register for Outport dma_from_ddr4_done
#define  dma_to_ddr4_done_Data_MyProc                     0x188  //data register for Outport dma_to_ddr4_done
#define  done_Data_MyProc                                 0x220  //data register for Outport done
#define  inputStart_Data_MyProc                           0x224  //data register for Inport inputStart
#define  preLoadingStart_Data_MyProc                      0x228  //data register for Inport preLoadingStart
#define  FrameCount_Data_MyProc                           0x24C  //data register for Inport FrameCount
#define  fc_weight_ddr_addr_Data_MyProc                   0x294  //data register for Inport fc_weight_ddr_addr
#define  fc_lc_ddr_len_Data_MyProc                        0x298  //data register for Inport fc_lc_ddr_len
#define  fc_lc_ddr_addr_Data_MyProc                       0x29C  //data register for Inport fc_lc_ddr_addr
#define  fc_layerNum_Data_MyProc                          0x300  //data register for Inport fc_layerNum
#define  fc_modeIn_Data_MyProc                            0x304  //data register for Inport fc_modeIn
#define  skd_ddr_addr_Data_MyProc                         0x308  //data register for Inport skd_ddr_addr
#define  skd_ddr_len_Data_MyProc                          0x30C  //data register for Inport skd_ddr_len
#define  add_ip_addr_Data_MyProc                          0x310  //data register for Inport add_ip_addr
#define  add_op_addr_Data_MyProc                          0x314  //data register for Inport add_op_addr
#define  wr_reqCounter_Data_MyProc                        0x318  //data register for Outport wr_reqCounter
#define  nc_LCtotalLength_IP0_Data_MyProc                 0x31C  //data register for Inport nc_LCtotalLength_IP0
#define  nc_LCtotalLength_Conv_Data_MyProc                0x320  //data register for Inport nc_LCtotalLength_Conv
#define  nc_LCtotalLength_OP0_Data_MyProc                 0x324  //data register for Inport nc_LCtotalLength_OP0
#define  nc_LCoffset_IP0_Data_MyProc                      0x328  //data register for Inport nc_LCoffset_IP0
#define  nc_LCoffset_Conv_Data_MyProc                     0x32C  //data register for Inport nc_LCoffset_Conv
#define  nc_LCoffset_OP0_Data_MyProc                      0x330  //data register for Inport nc_LCoffset_OP0
#define  conv_weight_ddr_addr_Data_MyProc                 0x334  //data register for Inport conv_weight_ddr_addr
#define  has_handShaking_Data_MyProc                      0x338  //data register for Inport has_handShaking
#define  hs_ddr_addr_Data_MyProc                          0x33C  //data register for Inport hs_ddr_addr
#define  adder_lc_addr_Data_MyProc                        0x340  //data register for Inport adder_lc_addr
#define  adder_lc_len_Data_MyProc                         0x348  //data register for Inport adder_lc_len
#define  StreamingMode_Data_MyProc                        0x34C  //data register for Inport StreamingMode
#define  InputNext_Data_MyProc                            0x350  //data register for Inport InputNext
#define  InputValid_Data_MyProc                           0x354  //data register for Outport InputValid
#define  InputAddr_Data_MyProc                            0x358  //data register for Outport InputAddr
#define  InputSize_Data_MyProc                            0x35C  //data register for Outport InputSize
#define  OutputNext_Data_MyProc                           0x360  //data register for Inport OutputNext
#define  OutputValid_Data_MyProc                          0x364  //data register for Outport OutputValid
#define  OutputAddr_Data_MyProc                           0x368  //data register for Outport OutputAddr
#define  OutputSize_Data_MyProc                           0x36C  //data register for Outport OutputSize
#define  StreamingDone_Data_MyProc                        0x370  //data register for Outport StreamingDone
#define  InputStop_Data_MyProc                            0x374  //data register for Inport InputStop
#define  PerfCounterOverflow_Data_MyProc                  0x37C  //data register for Outport PerfCounterOverflow
#define  UseCustomBaseAddr_Data_MyProc                    0x380  //data register for Inport UseCustomBaseAddr
#define  InputBaseAddr_Data_MyProc                        0x384  //data register for Inport InputBaseAddr
#define  OutputBaseAddr_Data_MyProc                       0x388  //data register for Inport OutputBaseAddr
#define  ConstrainSchedule_Data_MyProc                    0x38C  //data register for Inport ConstrainSchedule
#define  FCStartCount_Data_MyProc                         0x390  //data register for Outport FCStartCount
#define  FCEndCount_Data_MyProc                           0x394  //data register for Outport FCEndCount
#define  CONVStartCount_Data_MyProc                       0x398  //data register for Outport CONVStartCount
#define  CONVEndCount_Data_MyProc                         0x39C  //data register for Outport CONVEndCount
#define  AXIStreamOutSize_Data_MyProc                     0x3C8  //data register for Inport AXIStreamOutSize
#define  CustomStartCount_Data_MyProc                     0x400  //data register for Outport CustomStartCount
#define  CustomEndCount_Data_MyProc                       0x404  //data register for Outport CustomEndCount
#define  FrameStartCount_Data_MyProc                      0x408  //data register for Outport FrameStartCount
#define  FrameEndCount_Data_MyProc                        0x40C  //data register for Outport FrameEndCount
#define  DLStart_Data_MyProc                              0x410  //data register for Outport DLStart
#define  CONVActive_Data_MyProc                           0x414  //data register for Outport CONVActive
#define  FCActive_Data_MyProc                             0x418  //data register for Outport FCActive
#define  CustomActive_Data_MyProc                         0x41C  //data register for Outport CustomActive

#endif /* MYPROC_H_ */
