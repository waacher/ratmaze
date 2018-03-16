@echo off
set xv_path=C:\\Xilinx\\Vivado\\2017.2\\bin
call %xv_path%/xelab  -wto 4d692f9ee56e44cca7f2c621856fd5e0 -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L secureip --snapshot testbench_behav xil_defaultlib.testbench -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
