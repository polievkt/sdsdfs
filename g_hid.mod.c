#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

MODULE_INFO(vermagic, VERMAGIC_STRING);

struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
 .name = KBUILD_MODNAME,
 .init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
 .exit = cleanup_module,
#endif
 .arch = MODULE_ARCH_INIT,
};

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0xa323b35e, "module_layout" },
	{ 0x487d9343, "param_ops_ushort" },
	{ 0x35b6b772, "param_ops_charp" },
	{ 0x2ab31545, "noop_llseek" },
	{ 0x89cebf27, "platform_device_unregister" },
	{ 0xf2348806, "platform_driver_unregister" },
	{ 0x3e961e9a, "platform_driver_probe" },
	{ 0x1332d16c, "platform_device_register" },
	{ 0x7d9c359e, "class_destroy" },
	{ 0x7485e15e, "unregister_chrdev_region" },
	{ 0x29537c9e, "alloc_chrdev_region" },
	{ 0xd2a02fd1, "__class_create" },
	{ 0xe2fae716, "kmemdup" },
	{ 0x89ff43f6, "init_uts_ns" },
	{ 0x947a3c4c, "device_create_file" },
	{ 0xb81960ca, "snprintf" },
	{ 0xd57c4f56, "device_create" },
	{ 0x6c1c92b9, "cdev_add" },
	{ 0x5af9fe4d, "cdev_init" },
	{ 0x4467122a, "__init_waitqueue_head" },
	{ 0xb04877fb, "__mutex_init" },
	{ 0x12da5bb2, "__kmalloc" },
	{ 0x676bbc0f, "_set_bit" },
	{ 0x803d25b8, "_dev_info" },
	{ 0xe384a102, "usb_speed_string" },
	{ 0x1e047854, "warn_slowpath_fmt" },
	{ 0x20f2bb1a, "usb_gadget_unregister_driver" },
	{ 0x7424f93b, "usb_gadget_probe_driver" },
	{ 0x28a967d3, "dev_warn" },
	{ 0xa675804c, "utf8s_to_utf16s" },
	{ 0x50ca8ce6, "cdev_del" },
	{ 0x568ec4b9, "device_destroy" },
	{ 0x311b7963, "_raw_spin_unlock" },
	{ 0xc2d711e1, "krealloc" },
	{ 0xc2161e33, "_raw_spin_lock" },
	{ 0x98082893, "__copy_to_user" },
	{ 0x32f80ea9, "prepare_to_wait" },
	{ 0xc8b57c27, "autoremove_wake_function" },
	{ 0x17a142df, "__copy_from_user" },
	{ 0xaac275b1, "abort_exclusive_wait" },
	{ 0x1000e51, "schedule" },
	{ 0xf83178bd, "finish_wait" },
	{ 0x264cb558, "prepare_to_wait_exclusive" },
	{ 0x5f754e5a, "memset" },
	{ 0x1883a8d6, "mutex_unlock" },
	{ 0x5f4b4b97, "mutex_lock" },
	{ 0x72542c85, "__wake_up" },
	{ 0x11089ac7, "_ctype" },
	{ 0x20000329, "simple_strtoul" },
	{ 0x97255bdf, "strlen" },
	{ 0x9f984513, "strrchr" },
	{ 0x27e1a049, "printk" },
	{ 0xe2d5255a, "strcmp" },
	{ 0x3b05df25, "malloc_sizes" },
	{ 0x3d22b4f3, "kmem_cache_alloc_trace" },
	{ 0x8ec33771, "dev_err" },
	{ 0x9d669763, "memcpy" },
	{ 0xfa2a45e, "__memzero" },
	{ 0x6cc0821a, "dev_set_drvdata" },
	{ 0xa7431eef, "device_remove_file" },
	{ 0x16305289, "warn_slowpath_null" },
	{ 0x37a0cba, "kfree" },
	{ 0x91715312, "sprintf" },
	{ 0x74c97f9c, "_raw_spin_unlock_irqrestore" },
	{ 0xbd7083bc, "_raw_spin_lock_irqsave" },
	{ 0xc14bed20, "dev_get_drvdata" },
	{ 0x2e5810c6, "__aeabi_unwind_cpp_pr1" },
	{ 0xb1ad28e0, "__gnu_mcount_nc" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=";

