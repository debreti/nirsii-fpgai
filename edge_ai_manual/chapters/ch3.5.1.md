### **3.5.1 Vivado: инструмент размещения для микросхем Xilinx/AMD** <a name="ch3.5.1"></a>
Vivado Design Suite — основной инструмент для синтеза, размещения и маршрутизации (Place & Route) логики для [FPGA](glossary.md#fpga) семейства Xilinx (ныне AMD Xilinx). Vivado принимает на вход [RTL](glossary.md#rtl) ([VHDL](glossary.md#vhdl)/[Verilog](glossary.md#verilog)) или пользовательские IP-блоки (включая [HLS](glossary.md#hls)-сгенерированные модули) и выполняет полную цепочку до генерации bitstream для целевой платформы.

Основные возможности:
- Синтез и оптимизация RTL с учётом целевой архитектуры (LUT/FF/[DSP](glossary.md#dsp)/[BRAM](glossary.md#bram)).
- Размещение и маршрутизация с отчётами по timing, power и использованию ресурсов.
- Интеграция с Vivado IP Catalog и поддержка интеграции HLS-сгенерированных блоков.
- Средства для статического тайминга (Static Timing Analysis) и проверки ограничений (constraints).

Ресурсы: (Vivado Design Suite documentation: https://www.xilinx.com/products/design-tools/vivado.html).