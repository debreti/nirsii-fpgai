set_global_assignment -entity "PLL_sdram_test" -library "lib_PLL_sdram_test" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "PLL_sdram_test" -library "lib_PLL_sdram_test" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "PLL_sdram_test" -library "lib_PLL_sdram_test" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_PLL_sdram_test" -name SPD_FILE [file join $::quartus(sip_path) "PLL_sdram_test.spd"]

set_global_assignment -library "lib_PLL_sdram_test" -name MISC_FILE [file join $::quartus(sip_path) "PLL_sdram_test_sim/PLL_sdram_test.vo"]
