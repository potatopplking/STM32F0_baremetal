#include <interrupt_vectors.h>

typedef unsigned long int uint32_t;

/* symbols defined in linker script */
extern uint32_t _estack;
extern uint32_t _etext;
extern uint32_t _sdata;
extern uint32_t _edata;
extern uint32_t _sbss;
extern uint32_t _ebss;

/* defined in main.c */
void main(void);

/* non-maskable interrupt service routine */
void NMI(void)
{
	while(1) {}
}

/* HardFault interrupt service routine */
void HardFault(void)
{
	/* for real application you would probably want
	 * reset instead of infinite loop */
	while(1) {}
}

void Reset(void)
{
        /* Copy init values from text to data */
        uint32_t *init_values_ptr = &_etext;
        uint32_t *data_ptr = &_sdata;

        for (; data_ptr < &_edata;) {
		*data_ptr++ = *init_values_ptr++;
        }

        /* Clear the zero segment */
        for (uint32_t *bss_ptr = &_sbss; bss_ptr < &_ebss;) {
                *bss_ptr++ = 0;
        }

        /* Branch to main() function */
        main();

        /* infinite loop in case main() returns */
        while (1);
}

/* initial value for stack pointer;
 * stored at 0x00000000 LMA
 * sections are defined in linker script */
__attribute__ ((section(".stack_init_value")))
const uint32_t* stack_initial_value = &_estack;

/* interrupt (exception) vector table follows
 * right after initial stack pointer value */
__attribute__ ((section(".isr_vector_table")))
const InterruptVectors_t InterruptVectors = {
	.Reset_Handler = (void*) Reset,
	.NMI_Handler = (void*) NMI,
	.HardFault_Handler = (void*) HardFault,
};
