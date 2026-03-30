@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   RISC-V CPU - 一键设置和运行脚本
echo ========================================
echo.

REM ================================
REM 第一步：检查 iverilog 是否安装
REM ================================
echo [1/4] 检查 iverilog 是否安装...
iverilog -v >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ iverilog 已经安装！
    goto :check_gtkwave
)

echo ❌ iverilog 未安装，开始自动下载安装...
echo.

REM ================================
REM 第二步：下载 iverilog + gtkwave
REM ================================
echo [2/4] 下载 iverilog + gtkwave 安装包...

REM 检查是否有 curl
curl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 没有找到 curl，请手动安装：
    echo 下载地址：http://bleyer.org/icarus/
    echo 下载 iverilog-*-setup.exe 并安装
    pause
    exit /b 1
)

REM 下载 iverilog（这是一个常用的版本）
echo 正在下载 iverilog 安装包...
curl -L -o iverilog-setup.exe http://bleyer.org/icarus/iverilog-12.0-x64_setup.exe
if %errorlevel% neq 0 (
    echo ❌ 下载失败，请手动下载安装：
    echo 下载地址：http://bleyer.org/icarus/
    pause
    exit /b 1
)

echo ✅ 下载成功！
echo.

REM ================================
REM 第三步：安装 iverilog
REM ================================
echo [3/4] 安装 iverilog...
echo ⚠️  请在安装程序中点击 "Next" 完成安装
echo.
echo 安装完成后，按回车键继续...
start /wait iverilog-setup.exe
pause

REM 再次检查是否安装成功
echo 再次检查 iverilog 是否安装...
iverilog -v >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 安装可能没完成，或者需要重启终端
    echo 请手动运行安装程序：iverilog-setup.exe
    pause
    exit /b 1
)

echo ✅ iverilog 安装成功！
echo.

:check_gtkwave
REM ================================
REM 第四步：检查 gtkwave
REM ================================
echo [4/4] 检查 gtkwave...
gtkwave --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ gtkwave 已经安装！
) else (
    echo ⚠️  gtkwave 未安装，稍后运行测试后可以手动下载
    echo 下载地址：http://gtkwave.sourceforge.net/
)
echo.

REM ================================
REM 现在开始运行所有测试！
REM ================================
echo ========================================
echo   开始运行所有测试
echo ========================================
echo.

set TESTS_PASSED=0
set TESTS_FAILED=0

REM 测试 1: 加法测试
echo [1/3] 运行加法测试 (add_test)...
iverilog -o add_test.vvp ^
    ../rtl/pc.v ^
    ../rtl/regfile.v ^
    ../rtl/alu.v ^
    ../rtl/hazard_detect.v ^
    ../rtl/forward.v ^
    ../rtl/decode.v ^
    ../rtl/execute.v ^
    ../rtl/mem_access.v ^
    ../rtl/writeback.v ^
    ../rtl/branch_jump.v ^
    ../rtl/cpu_top.v ^
    add_test.v
if %errorlevel% neq 0 (
    echo ❌ 编译失败！
    set /a TESTS_FAILED+=1
) else (
    echo ✅ 编译成功，运行仿真...
    vvp add_test.vvp
    if exist add_test.vcd (
        echo ✅ 加法测试通过！
        set /a TESTS_PASSED+=1
    ) else (
        echo ❌ 仿真失败！
        set /a TESTS_FAILED+=1
    )
)
echo.

REM 测试 2: lw/sw 测试
echo [2/3] 运行 lw/sw 测试 (lw_sw_test)...
iverilog -o lw_sw_test.vvp ^
    ../rtl/pc.v ^
    ../rtl/regfile.v ^
    ../rtl/alu.v ^
    ../rtl/hazard_detect.v ^
    ../rtl/forward.v ^
    ../rtl/decode.v ^
    ../rtl/execute.v ^
    ../rtl/mem_access.v ^
    ../rtl/writeback.v ^
    ../rtl/branch_jump.v ^
    ../rtl/cpu_top.v ^
    lw_sw_test.v
if %errorlevel% neq 0 (
    echo ❌ 编译失败！
    set /a TESTS_FAILED+=1
) else (
    echo ✅ 编译成功，运行仿真...
    vvp lw_sw_test.vvp
    if exist lw_sw_test.vcd (
        echo ✅ lw/sw 测试通过！
        set /a TESTS_PASSED+=1
    ) else (
        echo ❌ 仿真失败！
        set /a TESTS_FAILED+=1
    )
)
echo.

REM 测试 3: 分支跳转测试
echo [3/3] 运行分支跳转测试 (jump_test_branches)...
iverilog -o jump_test_branches.vvp ^
    ../rtl/pc.v ^
    ../rtl/regfile.v ^
    ../rtl/alu.v ^
    ../rtl/hazard_detect.v ^
    ../rtl/forward.v ^
    ../rtl/decode.v ^
    ../rtl/execute.v ^
    ../rtl/mem_access.v ^
    ../rtl/writeback.v ^
    ../rtl/branch_jump.v ^
    ../rtl/cpu_top.v ^
    jump_test_branches.v
if %errorlevel% neq 0 (
    echo ❌ 编译失败！
    set /a TESTS_FAILED+=1
) else (
    echo ✅ 编译成功，运行仿真...
    vvp jump_test_branches.vvp
    if exist jump_test_branches.vcd (
        echo ✅ 分支跳转测试通过！
        set /a TESTS_PASSED+=1
    ) else (
        echo ❌ 仿真失败！
        set /a TESTS_FAILED+=1
    )
)
echo.

REM ================================
REM 测试总结
REM ================================
echo ========================================
echo   测试总结
echo ========================================
echo.
echo ✅ 通过: %TESTS_PASSED%
echo ❌ 失败: %TESTS_FAILED%
echo.
if %TESTS_FAILED% equ 0 (
    echo ========================================
    echo   🎉 所有测试通过！
    echo ========================================
    echo.
    echo 你可以运行以下命令查看波形：
    echo   gtkwave add_test.vcd
    echo   gtkwave lw_sw_test.vcd
    echo   gtkwave jump_test_branches.vcd
    echo.
    echo 问：是否立即打开波形查看？(y/n)
    set /p OPEN_WAVE=
    if /i "!OPEN_WAVE!"=="y" (
        gtkwave add_test.vcd
    )
) else (
    echo ========================================
    echo   ⚠️  有测试失败！
    echo ========================================
)
echo.

pause
