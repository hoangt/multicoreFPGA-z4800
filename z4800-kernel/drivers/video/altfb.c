/*
 *  altfb.c -- Altera framebuffer driver
 *
 *  Based on vfb.c -- Virtual frame buffer device
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/dma-mapping.h>
#include <linux/platform_device.h>
#include <linux/fb.h>
#include <linux/init.h>

#define VGA_CONTROLLER_0_BASE 0x1fd00010

#define VGABASE VGA_CONTROLLER_0_BASE	/* Altera VGA controller */
#define XRES 640
#define YRES 480
#define BPX  16

/*
 *  RAM we reserve for the frame buffer. This defines the maximum screen
 *  size
 *
 *  The default can be overridden if the driver is compiled as a module
 */

#define VIDEOMEMSIZE	(XRES * YRES * (BPX>>3))

static struct fb_var_screeninfo altfb_default __initdata = {
	.xres = XRES,
	.yres = YRES,
	.xres_virtual = XRES,
	.yres_virtual = YRES,
	.bits_per_pixel = BPX,
#if (BPX == 16)
	.red = {11, 5, 0},
	.green = {5, 6, 0},
	.blue = {0, 5, 0},
#elif (BPX == 32)
	.red = {16, 8, 0},
	.green = {8, 8, 0},
	.blue = {0, 8, 0},
#elif (BPX == 8)
	.red = {6, 2, 0},
	.green = {2, 3, 0},
	.blue = {0, 2, 0},
#else
#error Unknown BPX value
#endif
	.activate = FB_ACTIVATE_NOW,
	.height = -1,
	.width = -1,
	.vmode = FB_VMODE_NONINTERLACED,
};

static struct fb_fix_screeninfo altfb_fix __initdata = {
	.id = "altfb",
	.type = FB_TYPE_PACKED_PIXELS,
	.visual = FB_VISUAL_TRUECOLOR,
	.line_length = (XRES * (BPX >> 3)),
	.accel = FB_ACCEL_NONE,
};

static int altfb_setcolreg(unsigned regno, unsigned red, unsigned green,
			   unsigned blue, unsigned transp, struct fb_info *info)
{
	/*
	 *  Set a single color register. The values supplied have a 32/16 bit
	 *  magnitude.
	 *  Return != 0 for invalid regno.
	 */

	if (regno > 255)
		return 1;
#if (BPX == 16)
	red >>= 11;
	green >>= 10;
	blue >>= 11;

	if (regno < 255) {
		((u32 *) info->pseudo_palette)[regno] = ((red & 31) << 11) |
		    ((green & 63) << 5) | (blue & 31);
	}
#elif (BPX == 32)
	red >>= 8;
	green >>= 8;
	blue >>= 8;

	if (regno < 255) {
		((u32 *) info->pseudo_palette)[regno] = ((red & 255) << 16) |
		    ((green & 255) << 8) | (blue & 255);
	}
#elif (BPX == 8)
	red >>= 13;
	green >>= 12;
	blue >>= 13;

	if (regno < 255) {
		((u32 *) info->pseudo_palette)[regno] = ((red & 3) << 6) |
		    ((green & 7) << 2) | (blue & 3);
	}
#else
#error Unknown BPX value
#endif
	return 0;
}

static struct fb_ops altfb_ops = {
	.owner = THIS_MODULE,
	.fb_fillrect = cfb_fillrect,
	.fb_copyarea = cfb_copyarea,
	.fb_imageblit = cfb_imageblit,
	.fb_setcolreg = altfb_setcolreg,
};

/*
 *  Initialization
 */

static int __init altfb_dma_start(unsigned long start, unsigned long len,
				  void *descp)
{
	unsigned long base = ioremap(VGABASE, 16);
	writel(0x0, base + 0);	/* Reset the VGA controller */
	writel(start, base + 4);	/* Where our frame buffer starts */
	writel(len, base + 8);	/* buffer size */
	writel(0x1, base + 0);	/* Set the go bit */
	return 0;
}

static int __init altfb_probe(struct platform_device *dev)
{
	struct fb_info *info;
	int retval = -ENOMEM;
	void *fbmem_virt;
	u8 *desc_virt;

	/* sgdma descriptor table is located at the end of display memory */
	fbmem_virt = dma_alloc_coherent(NULL,
					VIDEOMEMSIZE,
					(void *)&altfb_fix.smem_start,
					GFP_KERNEL);
	if (!fbmem_virt) {
		printk(KERN_ERR "altfb: unable to allocate %ld Bytes fb memory\n",
		       VIDEOMEMSIZE);
		return -ENOMEM;
	}
	altfb_fix.smem_len = VIDEOMEMSIZE;

	info = framebuffer_alloc(sizeof(u32) * 256, &dev->dev);
	if (!info)
		goto err;

	info->screen_base = fbmem_virt;
	info->fbops = &altfb_ops;
	info->var = altfb_default;
	info->fix = altfb_fix;
	info->pseudo_palette = info->par;
	info->par = NULL;
	info->flags = FBINFO_FLAG_DEFAULT;

	retval = fb_alloc_cmap(&info->cmap, 256, 0);
	if (retval < 0)
		goto err1;

	retval = register_framebuffer(info);
	if (retval < 0)
		goto err2;
	platform_set_drvdata(dev, info);

	desc_virt = fbmem_virt;
	desc_virt += altfb_fix.smem_len;
	if (altfb_dma_start
	    (altfb_fix.smem_start, altfb_fix.smem_len, desc_virt))
		goto err2;

	printk(KERN_INFO "fb%d: %s frame buffer device at 0x%x+0x%x\n",
	       info->node, info->fix.id, (unsigned)altfb_fix.smem_start,
	       altfb_fix.smem_len);
	return 0;
err2:
	fb_dealloc_cmap(&info->cmap);
err1:
	framebuffer_release(info);
err:
	dma_free_coherent(NULL, altfb_fix.smem_len, fbmem_virt,
			  altfb_fix.smem_start);
	return retval;
}

static int altfb_remove(struct platform_device *dev)
{
	struct fb_info *info = platform_get_drvdata(dev);

	if (info) {
		unregister_framebuffer(info);
		dma_free_coherent(NULL, info->fix.smem_len, info->screen_base,
				  info->fix.smem_start);
		framebuffer_release(info);
	}
	return 0;
}

static struct platform_driver altfb_driver = {
	.probe = altfb_probe,
	.remove = altfb_remove,
	.driver = {
		   .name = "altfb",
		   },
};

static struct platform_device altfb_device = {
	.name = "altfb",
	.id = 0,
};

static int __init altfb_init(void)
{
	int ret = 0;

	ret = platform_driver_register(&altfb_driver);

	if (!ret) {
		ret = platform_device_register(&altfb_device);
		if (ret)
			platform_driver_unregister(&altfb_driver);
	}
	return ret;
}

static void __exit altfb_exit(void)
{
	platform_device_unregister(&altfb_device);
	platform_driver_unregister(&altfb_driver);
}

module_init(altfb_init);
module_exit(altfb_exit);

MODULE_DESCRIPTION("Altera framebuffer driver");
MODULE_AUTHOR("Thomas Chou <thomas@wytron.com.tw>");
MODULE_LICENSE("GPL");
