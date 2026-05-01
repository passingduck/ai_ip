MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K
}

SECTIONS
{
    .text : {
        KEEP(*(.text.start))
        *(.text.trap)
        *(.text*)
        *(.rodata*)
    } > RAM

    .data : {
        __global_pointer$ = . + 0x800;
        *(.sdata*)
        *(.data*)
    } > RAM

    .bss : {
        . = ALIGN(4);
        _sbss = .;
        *(.sbss*)
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > RAM

    . = ORIGIN(RAM) + LENGTH(RAM);
    _stack_top = .;
}
