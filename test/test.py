
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Iniciando test para ALU")

    # Clock 10us (100kHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut.ena.value = 1
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    # A = 2 (10), B = 1 (01), SEL = 000 (suma)
    A = 0b10
    B = 0b01
    SEL = 0b000
    ui_val = (A << 6) | (B << 4) | (SEL << 1)
    dut.ui_in.value = ui_val

    dut._log.info(f"Probando A={A}, B={B}, SEL={SEL} (suma)")
    await ClockCycles(dut.clk, 1)

    expected = A + B
    assert dut.uo_out.value == expected, f"Esperado {expected}, obtenido {int(dut.uo_out.value)}"

    # Más pruebas: AND
    A = 0b11
    B = 0b01
    SEL = 0b001  # AND
    ui_val = (A << 6) | (B << 4) | (SEL << 1)
    dut.ui_in.value = ui_val
    await ClockCycles(dut.clk, 1)

    expected = A & B
    assert dut.uo_out.value == expected, f"Esperado {expected}, obtenido {int(dut.uo_out.value)}"

    # Más pruebas: shift left
    A = 0b01
    B = 0b00  # No usado
    SEL = 0b011  # shift left
    ui_val = (A << 6) | (B << 4) | (SEL << 1)
    dut.ui_in.value = ui_val
    await ClockCycles(dut.clk, 1)

    expected = (A << 1) & 0xFF
    assert dut.uo_out.value == expected, f"Esperado {expected}, obtenido {int(dut.uo_out.value)}"

    dut._log.info("Todos los tests pasaron correctamente.")
