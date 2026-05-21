# Реализация нейронных сетей на FPGA с помощью MATLAB: подробный разбор с двумя примерами реализации

## 1. Введение

Этот гайд описывает практический workflow разработки компактной нейронной сети в MATLAB и ее последующей реализации на [FPGA](glossary.md#fpga) с помощью Deep Learning HDL Toolbox. Основной фокус сосредоточен на:

- подготовке простой [CNN](glossary.md#cnn)-модели в MATLAB;
- проверке и квантовании модели перед аппаратной реализацией;
- быстром сценарие запуска на поддерживаемой плате на примере Xilinx Zynq-7000 ZC706;
- сценарие custom board на примере проекта `matlab_dl_hdl_kc705` и платы Xilinx Kintex-7 KC705.

![Структура MATLAB-инструментов для разработки и имплементации нейронной сети на FPGA](matlab_structure.png)

## 2. Инструменты MATLAB

Для реализации нейронных сетей на ПЛИС необходим следующий набор MATLAB-компонентов.

**Deep Learning Toolbox** используется для создания, обучения, анализа и валидации нейронных сетей. На этом уровне проектируется архитектура сети, выбираются слои, выполняется обучение и проверяется точность модели.

**Deep Learning HDL Toolbox** отвечает за аппаратно-ориентированный workflow: проверку поддерживаемых слоев, компиляцию сети, генерацию инструкций для deep learning processor, сборку кастомного процессора, оценку ресурсов/производительности и запуск инференса на FPGA.

**HDL Coder** нужен для генерации HDL/IP и регистрации custom board/reference design. В сценарии custom board именно HDL Coder связывает MATLAB-описание платы, reference design и Vivado/Quartus-проект.

**HDL Verifier** используется для JTAG AXI Manager. Через него MATLAB получает доступ к регистрам управления и внешней памяти платы при прототипировании.

**Vivado или Quartus** нужны как проприетарные инструменты, вызываемые MATLAB для прошивки платы. Для Xilinx-плат используется Vivado, при этом, необходимо отметить, что версия должна соответствовать версии reference design.

## 3. Практические сценарии внедрения на FPGA

В DL HDL workflow удобно выделить три сценария имплементации по уровню сложности их реализации.

**Сценарий 1. Поддерживаемая плата.**  
Плата уже поддержана MathWorks, а для нее есть готовые bitstream-файлы. Разработчик работает в основном с сетью и MATLAB-объектами `dlhdl.Target` и `dlhdl.Workflow`. Поддерживаемые MATLAB платы: Xilinx Zynq-7000 ZC706, Xilinx Zynq UltraScale+ MPSoC ZCU102, Intel Arria 10 [SoC](glossary.md#soc).

**Сценарий 2. Custom board с vendor board part/reference design.**  
Плата не входит в список штатно поддерживаемых DL HDL Toolbox, но ее можно описать для HDL Coder: создать board plugin, reference design, block design Tcl, AXI-интерфейсы, memory map и затем собрать deep learning processor под эту плату. Пример этого сценария реализован в проекте: `matlab_dl_hdl_kc705`.

**Сценарий 3. Полностью новая/нестандартная плата.**  
Нужно готовить не только MATLAB board plugin и reference design, но и низкоуровневые board part/constraints/vendor-пакеты, DDR/MIG-конфигурацию и проверять совместимость JTAG/Ethernet канала. Этот сценарий выходит за рамки данного гайда.

## 4. Создание простой CNN в MATLAB

В качестве базового примера используем классификацию рукописных цифр из встроенного датасета `DigitDataset`. Цель не в максимальной точности, а в получении небольшой CNN, которую затем можно передать в DL HDL workflow.

### 4.1. Загрузка и подготовка данных

```matlab
clear; clc;

rng(1);

digitDatasetPath = fullfile(matlabroot, "toolbox", "nnet", ...
    "nndemos", "nndatasets", "DigitDataset");

imds = imageDatastore(digitDatasetPath, ...
    "IncludeSubfolders", true, ...
    "LabelSource", "foldernames");

imds.ReadFcn = @(f) im2gray(imresize(imread(f), [28 28]));

[imdsTrain, imdsVal] = splitEachLabel(imds, 0.8, "randomized");
```

`imageDatastore` хранит пути к изображениям и метки классов. `ReadFcn` приводит все входы к формату `28 x 28 x 1`, поэтому входной слой сети должен иметь ровно такой размер.

### 4.2. Архитектура сети

```matlab
layers = [
    imageInputLayer([28 28 1], "Normalization", "zscore", "Name", "input")

    convolution2dLayer(3, 8, "Padding", "same", "Name", "conv1")
    batchNormalizationLayer("Name", "bn1")
    reluLayer("Name", "relu1")
    maxPooling2dLayer(2, "Stride", 2, "Name", "pool1")

    convolution2dLayer(3, 16, "Padding", "same", "Name", "conv2")
    batchNormalizationLayer("Name", "bn2")
    reluLayer("Name", "relu2")

    fullyConnectedLayer(10, "Name", "fc")
    softmaxLayer("Name", "softmax")
    classificationLayer("Name", "output")
];

analyzeNetwork(layers);
```

Для FPGA важно заранее проверять, что выбранные слои поддерживаются Deep Learning HDL Toolbox. Часть слоев может быть реализована аппаратно, а часть, например нормализация входа, softmax или classification output, может быть обработана на процессорной стороне. Поэтому после изменения архитектуры важно проверять сеть через `analyzeNetwork`, `compile` и таблицу supported layers из документации MathWorks.

### 4.3. Обучение

```matlab
opts = trainingOptions("adam", ...
    "InitialLearnRate", 1e-3, ...
    "L2Regularization", 1e-4, ...
    "MaxEpochs", 10, ...
    "MiniBatchSize", 128, ...
    "Shuffle", "every-epoch", ...
    "ValidationData", imdsVal, ...
    "ValidationFrequency", 30, ...
    "ExecutionEnvironment", "auto", ...
    "Verbose", true, ...
    "Plots", "training-progress");

net = trainNetwork(imdsTrain, layers, opts);
```

На практике архитектура и параметры обучения подбираются итерационно. Для аппаратной реализации особенно важны:

- малое число слоев и каналов;
- отсутствие неподдерживаемых custom-операций;
- возможности оптимизации без сильной потери точности (например, с помощью квантования, прунинга или дистилляции).

### 4.4. Проверка точности FP32 модели

```matlab
predVal = classify(net, imdsVal, "MiniBatchSize", 256);
acc_fp32 = mean(predVal == imdsVal.Labels);

fprintf("Baseline accuracy (FP32): %.2f%%\n", 100 * acc_fp32);
```

### 4.5. Post-training квантование

Для FPGA более выгоден `int8` формат представления чисел: ниже расход памяти, выше плотность вычислений, проще уложиться в ресурсы. Квантование нужно выполнять на репрезентативной калибровочной выборке.

```matlab
[imdsCal, imdsTest] = splitEachLabel(imdsVal, 0.5, "randomized");

q = dlquantizer(net, "ExecutionEnvironment", "FPGA");

calResults = calibrate(q, imdsCal);
valResults = validate(q, imdsTest);

disp(calResults);
disp(valResults.MetricResults);
```

Если падение точности после квантования неприемлемо, нужно вернуться к архитектуре, обучению, объему калибровочной выборки или использовать другой режим чисел. Для дальнейших действий модель можно сохранить.

```matlab
save("digits_cnn_fp32.mat", "net");
save("digits_cnn_int8_quantizer.mat", "q");
```

## 5. Как DL HDL Toolbox исполняет сеть на FPGA

Deep Learning HDL Toolbox не генерирует отдельную уникальную [RTL](glossary.md#rtl)-схему для каждого слоя сети. Основная идея другая: на FPGA размещается настраиваемый deep learning processor, а сеть компилируется в набор инструкций, весов, смещений и memory map для этого процессора.

![MATLAB-controlled deep learning processor](ml_controlled_dl_processor.png)

На схеме показана типовая архитектура MATLAB-controlled deep learning processor. MATLAB на хост-компьютере выступает управляющей средой: компилирует сеть, загружает bitstream, передает инструкции, веса и входные данные, а затем считывает результаты инференса и данные профайлера. Связь с платой обычно выполняется через JTAG AXI Manager или Ethernet-интерфейс.

Внутри FPGA размещается deep learning processor IP. Его центральный элемент - scheduler, который читает скомпилированные инструкции сети и координирует работу вычислительных модулей. Convolution kernel выполняет операции свертки и связанные с ними слои, FC kernel обслуживает полносвязные слои, custom kernel используется для поддерживаемых дополнительных операций. Memory modules и DDR-интерфейс обеспечивают обмен активациями, весами и промежуточными результатами с внешней памятью. Отдельные AXI master interfaces обычно разделяют трафик активаций, весов и отладочных/профилировочных данных, а управляющий AXI slave/register interface используется MATLAB для запуска, остановки и контроля состояния процессора.

Типовой путь имплементации:

1. Создать или загрузить обученную сеть.
2. Создать объект `dlhdl.Target`, который описывает vendor и канал связи с платой.
3. Создать `dlhdl.Workflow`, передав сеть, bitstream и target.
4. Выполнить `compile`, чтобы сеть была преобразована в аппаратно-ориентированное представление.
5. Выполнить `deploy`, чтобы загрузить bitstream и данные сети.
6. Выполнить `predict`, чтобы получить результат инференса.

Deep learning processor обычно имеет:

- AXI4-Lite или AXI4 slave/register interface для управления;
- AXI4 Master Activation Data для чтения/записи активаций;
- AXI4 Master Weight Data для весов;
- AXI4 Master Debug для профайлера и отладки;
- доступ к внешней DDR/[BRAM](glossary.md#bram) memory map;
- clock/reset интерфейсы из reference design.

## 6. Сценарий 1: поддерживаемая плата Xilinx Zynq-7000 ZC706

Xilinx Zynq-7000 ZC706 является штатно поддерживаемой платой Deep Learning HDL Toolbox. Для нее доступны готовые bitstream names, например:

- `zc706_single` для `single`;
- `zc706_int8` для `int8`;
- `zc706_lstm_single` для [LSTM](glossary.md#lstm)-сценариев.

### 6.1. Предварительные действия

1. Установить MATLAB, Deep Learning Toolbox, Deep Learning HDL Toolbox.
2. Установить Deep Learning HDL Toolbox Support Package for Xilinx FPGA and SoC Devices.
3. Подключить ZC706 к хосту.
4. Настроить JTAG или Ethernet-интерфейс.
5. Если используется JTAG через Vivado, настроить путь к Vivado:

```matlab
hdlsetuptoolpath("ToolName", "Xilinx Vivado", ...
    "ToolPath", "C:\Xilinx\Vivado\2024.1\bin\vivado.bat");
```

Версию Vivado подбирайте под установленный MATLAB release и support package.

### 6.2. Запуск FP32-сети на ZC706

```matlab
load("digits_cnn_fp32.mat", "net");

hTarget = dlhdl.Target("Xilinx", "Interface", "JTAG");

hW = dlhdl.Workflow( ...
    "Network", net, ...
    "Bitstream", "zc706_single", ...
    "Target", hTarget);

compile(hW);
deploy(hW);

img = readimage(imdsVal, 1);
[result, speed] = predict(hW, single(img), "Profile", "on");

[~, idx] = max(result);
disp(idx);
disp(speed);
```

На выходе `predict` возвращает численный результат последнего аппаратно значимого слоя. Для классификации индекс класса нужно сопоставить с `net.Layers(end).Classes` или с категориями исходного datastore.

### 6.3. Запуск квантованной сети на ZC706

```matlab
load("digits_cnn_int8_quantizer.mat", "q");

hTarget = dlhdl.Target("Xilinx", "Interface", "JTAG");

hW = dlhdl.Workflow( ...
    "Network", q, ...
    "Bitstream", "zc706_int8", ...
    "Target", hTarget);

compile(hW);
deploy(hW);

img = readimage(imdsTest, 1);
[result, speed] = predict(hW, img, "Profile", "on");

[~, idx] = max(result);
disp(idx);
disp(speed);
```

Если `compile` сообщает о неподдерживаемом слое, нужно изменить архитектуру сети или сгенерировать custom processor с нужными блоками.

## 7. Сценарий 2: custom board на примере Xilinx Kintex-7 KC705

Плата KC705 не является штатной DL HDL board уровня `zc706_single`/`zcu102_single`. Для нее нужно зарегистрировать custom board и custom reference design, а затем сгенерировать bitstream под deep learning processor.

В проекте есть минимальная структура:

```text
for_git/matlab_dl_hdl_kc705/
  main.mlx
  hdlcoder_board_customization.m
  +DLKC705/
    plugin_board.m
    hdlcoder_ref_design_customization.m
    +vivado_base_ref_design/
      plugin_rd.m
      design_1.tcl
      +hdl_coder/+vivado/
        hdlcoder_proc_iplist.m
        MyProc_v1_0/
```

Пройдёмся кратко по содержанию файлов:

- `hdlcoder_board_customization.m` регистрирует board plugin в MATLAB path и указывает workflow `hdlcoder.Workflow.DeepLearningProcessor`;
- `+DLKC705/plugin_board.m` описывает плату: имя, FPGA, корпус, speed grade, toolchain, JTAG chain, объем DDR;
- `+DLKC705/hdlcoder_ref_design_customization.m` связывает плату с одним или несколькими reference designs;
- `+DLKC705/+vivado_base_ref_design/plugin_rd.m` описывает Vivado reference design, AXI-интерфейсы, clock/reset, memory map и target interface;
- `design_1.tcl` восстанавливает Vivado block design;
- `+hdl_coder/+vivado/hdlcoder_proc_iplist.m` сообщает Vivado/MATLAB, какие пользовательские IP лежат в локальном IP repository;
- `MyProc_v1_0` содержит сгенерированный generic deep learning processor IP.

### 7.1. Как выполнять настройку проекта

Для `plugin_board.m` нужны аппаратные параметры платы:

- FPGA vendor/family/device/package/speed;
- JTAG chain position;
- объем внешней DDR;
- I/O standard для external ports;
- при необходимости списки внешних I/O: LEDs, buttons, FMC, clocks.

В проекте для KC705, например:

```matlab
hB.BoardName    = 'Xilinx Kintex 7 FPGA KC705';
hB.FPGAVendor   = 'Xilinx';
hB.FPGAFamily   = 'Kintex7';
hB.FPGADevice   = 'xc7k325t';
hB.FPGAPackage  = 'ffg900';
hB.FPGASpeed    = '-2';
hB.SupportedTool = {'Xilinx Vivado'};
hB.JTAGChainPosition = 1;
hB.ExternalMemorySize = 0x40000000; % 1 GB
```

Эти значения берутся из документации платы KC705, Vivado board part и Xilinx reference designs.

### 7.2. Регистрация board plugin

Файл `hdlcoder_board_customization.m` должен лежать в папке, добавленной в MATLAB path:

```matlab
function [boardList, workflow] = hdlcoder_board_customization
boardList = { ...
    'DLKC705.plugin_board', ...
};
workflow = hdlcoder.Workflow.DeepLearningProcessor;
end
```

Ключевой момент: второй выход `workflow`. Без него HDL Coder может зарегистрировать плату для обычных HDL workflows, но не для DL processor workflow.

### 7.3. Описание платы `plugin_board.m`

Минимальная конфигурация файла:

```matlab
function hB = plugin_board()
hB = hdlcoder.Board;

hB.BoardName    = 'Xilinx Kintex 7 FPGA KC705';
hB.FPGAVendor   = 'Xilinx';
hB.FPGAFamily   = 'Kintex7';
hB.FPGADevice   = 'xc7k325t';
hB.FPGAPackage  = 'ffg900';
hB.FPGASpeed    = '-2';

hB.SupportedTool = {'Xilinx Vivado'};
hB.JTAGChainPosition = 1;
hB.ExternalMemorySize = 0x40000000; % 1 GB

hB.addExternalPortInterface( ...
    'IOPadConstraint', {'IOSTANDARD = LVCMOS15'});
end
```

Если плата использует дополнительные внешние сигналы, их нужно добавить через `addExternalIOInterface`. Для DL processor минимально критичны корректные FPGA-параметры и `ExternalMemorySize`.

### 7.4. Подготовка generic deep learning processor IP

В custom board workflow сначала удобно собрать generic processor IP, который затем будет подключен к Vivado reference design.

Пример из `main.mlx`:

```matlab
hdlsetuptoolpath('ToolName', 'Xilinx Vivado', ...
    'ToolPath', 'C:\Xilinx\Vivado\2020.2\bin\vivado.bat');

hPC = dlhdl.ProcessorConfig;

hPC.TargetFrequency = 100;
hPC.ProcessorDataType = 'int8';

hPC.setModuleProperty('adder', 'ModuleGeneration', 'off');

hPC.setModuleProperty('conv', 'ConvThreadNumber', 4);
hPC.setModuleProperty('conv', 'InputMemorySize', [28 28 1]);
hPC.setModuleProperty('conv', 'OutputMemorySize', [28 28 1]);
hPC.setModuleProperty('conv', 'FeatureSizeLimit', 16);

hPC.estimateResources;

hPC.TargetPlatform = 'Generic Deep Learning Processor';

dlhdl.buildProcessor(hPC, ...
    'ProjectFolder', 'customProc', ...
    'ProcessorName', 'MyProc', ...
    'HDLCoderConfig', {'TargetLanguage', '[VHDL](glossary.md#vhdl)'});
```

После сборки в `customProc` появляется Vivado IP repository с `MyProc_v1_0`. Этот IP нужно положить туда, откуда reference design сможет его добавить в IP catalog. В рассматриваемом проекте это:

```text
+DLKC705/+vivado_base_ref_design/+hdl_coder/+vivado/MyProc_v1_0
```

А файл `hdlcoder_proc_iplist.m` должен вернуть имя IP:

```matlab
function [ipList] = hdlcoder_proc_iplist()
ipList = {'MyProc_v1_0'};
end
```

### 7.5. Создание Vivado block design

`design_1.tcl` должен восстанавливать block design с инфраструктурой, к которой MATLAB позже подключит deep learning processor.

![Reference design Vivado, подготовленный под интеграцию DL processor](design_3.png)


На рисунке показан reference design из Vivado, который экспортируется в Tcl и затем подключается в `plugin_rd.m` через `addCustomVivadoDesign`. Этот дизайн еще не является специализированным neural-network bitstream: он задает аппаратную инфраструктуру, в которую HDL Coder встраивает сгенерированный deep learning processor. В нем должны быть уже подготовлены DDR/MIG, clock/reset blocks, AXI interconnect, JTAG AXI Manager и свободные AXI-подключения под управляющий интерфейс, активации, веса и debug/profiler.

Для KC705 в design Tcl присутствуют:

- Vivado project part `xc7k325tffg900-2`;
- board part `xilinx.com:kc705:part0:1.6`;
- `mig_7series` для DDR3;
- clock wizard;
- processor system reset;
- `hdlverifier_axi_manager`;
- AXI interconnect с master/slave ports под control, activation, weight и debug interfaces;
- адресный сегмент DDR с base `0x80000000` и размером `0x40000000`.

Практический порядок подготовки:

1. Создать Vivado-проект под KC705.
2. Выбрать board part KC705, если он установлен.
3. Настроить MIG по документации KC705 и Xilinx reference design.
4. Добавить JTAG AXI Manager IP из HDL Verifier repository.
5. Добавить AXI interconnect и clock/reset blocks.
6. Проверить address editor: DDR segment должен совпадать с тем, что будет указан в `plugin_rd.m`.
7. Выполнить `validate_bd_design`.
8. Экспортировать block design:

```tcl
write_bd_tcl -force design_1.tcl
```

Важно: Tcl, экспортированный из Vivado, жестко привязан к версии IP. Если открываете его в другой версии Vivado, обновите IP и заново экспортируйте Tcl.

### 7.6. Регистрация reference design

Файл `+DLKC705/hdlcoder_ref_design_customization.m`:

```matlab
function [rd, boardName] = hdlcoder_ref_design_customization
rd = { ...
    'DLKC705.vivado_base_ref_design.plugin_rd', ...
};

boardName = 'Xilinx Kintex 7 FPGA KC705';
end
```

`boardName` должен дословно совпадать с `hB.BoardName` из `plugin_board.m`.

### 7.7. Описание reference design `plugin_rd.m`

Файл `plugin_rd.m` создает объект `hdlcoder.ReferenceDesign` и связывает MATLAB с Vivado block design:

```matlab
function hRD = plugin_rd()
hRD = hdlcoder.ReferenceDesign('SynthesisTool', 'Xilinx Vivado');

hRD.ReferenceDesignName = 'AXI-Stream DDR Memory Access : 3-AXIM';
hRD.BoardName = 'Xilinx Kintex 7 FPGA KC705';
hRD.SupportedToolVersion = {'2020.2'};

hRD.addCustomVivadoDesign( ...
    'CustomBlockDesignTcl', 'design_1.tcl', ...
    'VivadoBoardPart', 'xilinx.com:kc705:part0:1.6');

hRD.addIPRepository( ...
    'IPListFunction', 'hdlverifier.fpga.vivado.iplist', ...
    'NotExistMessage', 'IP Repository not found.');

hRD.addIPRepository( ...
    'IPListFunction', ...
    'DLKC705.vivado_base_ref_design.hdl_coder.vivado.hdlcoder_proc_iplist', ...
    'NotExistMessage', 'IP Repository not found.');
```

Далее описывается clock/reset:

```matlab
hRD.addClockInterface( ...
    'ClockConnection', 'system_0/clk_out1_0', ...
    'ResetConnection', 'system_0/peripheral_aresetn_0', ...
    'DefaultFrequencyMHz', 200, ...
    'MinFrequencyMHz', 10, ...
    'MaxFrequencyMHz', 250, ...
    'ClockNumber', 1, ...
    'ClockModuleInstance', 'system_0/clk_wiz_0');
```

Затем control/register interface. В проекте KC705 используется `addAXI4SlaveInterface`; в новых примерах MathWorks часто используется `addRegisterInterface`. Смысл одинаковый: это управляющий AXI-интерфейс между MATLAB/JTAG AXI Manager и DL processor.

```matlab
hRD.addAXI4SlaveInterface( ...
    'InterfaceConnection', 'system_0/M00_AXI_0', ...
    'BaseAddress', '0x44A00000', ...
    'MasterAddressSpace', 'system_0/hdlverifier_axi_mana_0/axi4m', ...
    'InterfaceType', 'AXI4');
```

Для DL processor обязательно описать три AXI4 Master interfaces. Их `InterfaceID` должны совпадать с ожидаемыми именами DL HDL Toolbox:

```matlab
hRD.addAXI4MasterInterface( ...
    'InterfaceID', 'AXI4 Master Activation Data', ...
    'ReadSupport', true, ...
    'WriteSupport', true, ...
    'MaxDataWidth', 512, ...
    'AddrWidth', 32, ...
    'InterfaceConnection', 'axi_interconnect_0/S01_AXI', ...
    'TargetAddressSegments', ...
        {{'mig_7series_0/memmap/memaddr', hex2dec('80000000'), hex2dec('40000000')}});

hRD.addAXI4MasterInterface( ...
    'InterfaceID', 'AXI4 Master Weight Data', ...
    'ReadSupport', true, ...
    'WriteSupport', true, ...
    'MaxDataWidth', 512, ...
    'AddrWidth', 32, ...
    'InterfaceConnection', 'axi_interconnect_0/S02_AXI', ...
    'TargetAddressSegments', ...
        {{'mig_7series_0/memmap/memaddr', hex2dec('80000000'), hex2dec('40000000')}});

hRD.addAXI4MasterInterface( ...
    'InterfaceID', 'AXI4 Master Debug', ...
    'ReadSupport', true, ...
    'WriteSupport', true, ...
    'MaxDataWidth', 512, ...
    'AddrWidth', 32, ...
    'InterfaceConnection', 'axi_interconnect_0/S03_AXI', ...
    'TargetAddressSegments', ...
        {{'mig_7series_0/memmap/memaddr', hex2dec('80000000'), hex2dec('40000000')}});
```

В конце указываются DL-specific properties:

```matlab
hRD.registerDeepLearningTargetInterface("JTAG");
hRD.registerDeepLearningMemoryAddressSpace(0x80000000, 0x40000000);

hRD.ResourcesUsed.LogicElements = 30500;
hRD.ResourcesUsed.[DSP](glossary.md#dsp) = 3;
hRD.ResourcesUsed.RAM = 26.5;
end
```

`registerDeepLearningMemoryAddressSpace` должен совпадать с DDR segment в Vivado. `ResourcesUsed` описывает ресурсы самого reference design без deep learning processor; эти числа используются при оценке ресурсов.

### 7.8. Проверка регистрации в MATLAB

В MATLAB:

```matlab
projectRoot = "C:\Users\anton\OneDrive\Рабочий стол\НИЦ СФ\Matlab_FPGA\for_git\matlab_dl_hdl_kc705";
addpath(genpath(projectRoot));

hPC = dlhdl.ProcessorConfig;
hPC.TargetPlatform = 'Xilinx Kintex 7 FPGA KC705';

disp(hPC);
```

### 7.9. Сборка calibration bitstream

Калибровочный bitstream нужен для измерения задержек доступа к внешней памяти на конкретной плате. Эти данные повышают точность `estimatePerformance`.

```matlab
hdlsetuptoolpath('ToolName', 'Xilinx Vivado', ...
    'ToolPath', 'C:\Xilinx\Vivado\2020.2\bin\vivado.bat');

hPC = dlhdl.ProcessorConfig;
hPC.TargetPlatform = 'Xilinx Kintex 7 FPGA KC705';
hPC.TargetFrequency = 100;
hPC.ProcessorDataType = 'int8';

hPC.setModuleProperty('adder', 'ModuleGeneration', 'off');
hPC.setModuleProperty('conv', 'ConvThreadNumber', 4);
hPC.setModuleProperty('conv', 'InputMemorySize', [28 28 1]);
hPC.setModuleProperty('conv', 'OutputMemorySize', [28 28 1]);
hPC.setModuleProperty('conv', 'FeatureSizeLimit', 16);

bitstreamPath = buildCalibrationBitstream(hPC);
```

После сборки bitstream загружается на плату:

```matlab
deployCalibrationBitstream(hPC, bitstreamPath);
```

В результате MATLAB сохраняет calibration data в `hPC.CalibrationData` и файл `calibrationData.mat`. Для повторного запуска:

```matlab
load("calibrationData.mat", "calData");
hPC.CalibrationData = calData;
```

### 7.10. Оценка производительности и ресурсов

```matlab
load("digits_cnn_fp32.mat", "net");

estimatePerformance(hPC, net);
estimateResources(hPC);
```

Если ресурсы превышают возможности KC705, уменьшайте:

- `ConvThreadNumber`;
- `FCThreadNumber`;
- `InputMemorySize`/`OutputMemorySize`;
- `FeatureSizeLimit`;
- число каналов в CNN;
- включенные processing modules.

Для небольшой сети `28 x 28 x 1` в примере KC705 уже уменьшены convolution threads и feature memory limits.

### 7.11. Сборка custom bitstream под KC705

```matlab
dlhdl.buildProcessor(hPC, ...
    'ProjectFolder', 'kc705_dlhdl_prj', ...
    'ProcessorName', 'dlprocessor', ...
    'HDLCoderConfig', {'TargetLanguage', 'VHDL'});
```

Результат появляется в папке проекта сборки. Для DL HDL deployment нужны:

- `.bit` файл bitstream;
- `.mat` файл с описанием процессора/конфигурации.

В стандартном workflow MathWorks они называются `dlprocessor.bit` и `dlprocessor.mat` и лежат в `dlhdl_prj` или указанном `ProjectFolder`.

### 7.12. Deploy и inference на KC705

```matlab
load("digits_cnn_fp32.mat", "net");

hTarget = dlhdl.Target("Xilinx", "Interface", "JTAG");

hW = dlhdl.Workflow( ...
    "Network", net, ...
    "Bitstream", "dlprocessor.bit", ...
    "Target", hTarget);

compile(hW);
deploy(hW);

img = readimage(imdsVal, 1);
[result, speed] = predict(hW, single(img), "Profile", "on");

disp(result);
disp(speed);
```

Если используется `int8`-процессор, передавайте `dlquantizer`-объект и bitstream, собранный с `hPC.ProcessorDataType = 'int8'`.


## 8. Источники и полезные ссылки

- MathWorks: [Supported Networks, Boards, and Tools](https://www.mathworks.com/help/deep-learning-hdl/ug/supported-network-boards-and-tools.html)
- MathWorks: [Use Deep Learning on FPGA Bitstreams](https://www.mathworks.com/help/deep-learning-hdl/gs/use-deep-learning-on-fpga-bitstreams.html)
- MathWorks: [dlhdl.ProcessorConfig](https://www.mathworks.com/help/deep-learning-hdl/ref/dlhdl.processorconfig-class.html)
- MathWorks: [Generate Custom Processor IP](https://www.mathworks.com/help/deep-learning-hdl/ug/generate-custom-processor-ip.html)
- MathWorks: [Deep Learning Processor IP Core Generation for Custom Board](https://www.mathworks.com/help/deep-learning-hdl/ug/define-custom-board-and-reference-design-for-dl-ip-core-workflow.html)
- Локальный пример custom board: `for_git/matlab_dl_hdl_kc705`
