set_global_assignment -entity "PLL_test_remake" -library "lib_PLL_test_remake" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "PLL_test_remake" -library "lib_PLL_test_remake" -name IP_TOOL_VERSION "16.0"
set_global_assignment -entity "PLL_test_remake" -library "lib_PLL_test_remake" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_PLL_test_remake" -name SPD_FILE [file join $::quartus(sip_path) "PLL_test_remake.spd"]

set_global_assignment -library "lib_PLL_test_remake" -name MISC_FILE [file join $::quartus(sip_path) "PLL_test_remake_sim/PLL_test_remake.vo"]
