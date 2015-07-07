#define ALTERA_JTAGUART_CONTROL_REG               4
#define ALTERA_JTAGUART_CONTROL_WSPACE_MSK        (0xFFFF0000)
#define ALTERA_JTAGUART_CONTROL_AC_MSK            (0x00000400)

#if defined(CONFIG_EARLY_PRINTK)
void __init prom_putchar(char c)
{
#if defined(UART_BASE)
   volatile short *txdata = (short *)((KSEG1 | UART_BASE) + 0x4);
   volatile short *status = (short *)((KSEG1 | UART_BASE) + 0x8);
   while(!(*status & 0x40));
   *txdata = (short)c;
#elif defined(JTAG_UART_BASE)
   unsigned long *base_reg = (void *)((KSEG1 | JTAG_UART_BASE) + 0);
   unsigned long *control_reg = (void *)((KSEG1 | JTAG_UART_BASE) + ALTERA_JTAGUART_CONTROL_REG);
   unsigned long status = readl(control_reg);
   while((status & ALTERA_JTAGUART_CONTROL_WSPACE_MSK) == 0){
#if defined(CONFIG_SERIAL_ALTERA_JTAGUART_CONSOLE_BYPASS)
      if((status & ALTERA_JTAGUART_CONTROL_AC_MSK) == 0) return;
#endif
      status = readl(control_reg);
   }
   writel(c, base_reg);
#endif
}
#endif
