#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DEFCONFIG=am335x_the_element_lcd_41_defconfig
CORES=`grep -c ^processor /proc/cpuinfo`

### Make environment ###
export ARCH=arm

#Don't use default compiler 'arm-linux-gnueabihf-' as it is known to miscompile kernels!
export CROSS_COMPILE="$DIR"/linux-devkit/sysroots/x86_64-arago-linux/usr/bin/arm-linux-gnueabihf-

#Default CC value to be used when cross compiling.  This is so that the
#GNU Make default of "cc" is not used to point to the host compiler
export CC="${CROSS_COMPILE}gcc"
export CFLAGS="-march=armv7-a -marm -mthumb-interwork -mfloat-abi=hard -mfpu=neon -mtune=cortex-a8"

#Used for selecting the correct SGX version in the SGX build scripts
export TARGET_PRODUCT=ti335x

function apply_patches {
    echo "applying patches..."
    (cd "$DIR"; patch -Nr - -p0 < "$DIR"/extra_patches/allow-mac-address-to-be-set-in-smsc95xx.patch)
}

function build_kernel {
    echo "#########################"
    echo "Building the Linux Kernel"
    echo "#########################"

    apply_patches
    make "$DEFCONFIG"
    make -j$CORES uImage LOADADDR=0x80008000
    make -j$CORES modules
    build_dtbs
}

function kernel_images {
    echo "##############################################"
    echo "Building the Linux Kernel with existing config"
    echo "##############################################"

    apply_patches
    make -j$CORES uImage LOADADDR=0x80008000
    make -j$CORES modules
    build_dtbs
}

function kernel_defconfig {
    echo "########################################"
    echo "Applying the Element Linux Kernel Config"
    echo "########################################"

    make "$DEFCONFIG"
}

function kernel_savedefconfig {
    echo "########################################"
    echo "Applying the Element Linux Kernel Config"
    echo "########################################"

    make savedefconfig
    cp -v "$DIR/defconfig" "$DIR/arch/arm/configs/am335x_the_element_lcd_41_defconfig"
    rm -v "$DIR/defconfig"
}

function kernel_menuconfig {
    echo "################################"
    echo "Starting Linux Kernel Menuconfig"
    echo "#################################"

    make menuconfig
}

function kernel_modules {
    echo "#################################"
    echo "Building the Linux Kernel Modules"
    echo "#################################"

    apply_patches
    make "$DEFCONFIG"
    make -j$CORES modules
}

function build_dtbs {
    echo "##############################"
    echo "Building the Device Tree Blobs"
    echo "##############################"

    make -j$CORES $(find $DIR/arch/arm/boot/dts -name 'am335x-the-element*.dts' -exec basename \{\} \; | sed 's/.dts/.dtb/g')
}

function build_sgx {
    echo "#######################"
    echo "Building the SGX driver"
    echo "#######################"
    unset  CC
    
    make -C "$DIR"/omap5-sgx-ddk-linux/eurasia_km/eurasiacon/build/linux2/omap_linux CFLAGS="$CFLAGS -Wno-error" KERNELDIR="$DIR" PVR_NULLDRM=1 
}

function install_all {
    if [ -d "$DIR"/out/source ] ; then rm -rf "$DIR"/out/source; fi
    
    install -d "$DIR"/out/source

    echo "###########################"
    echo "Installing the Linux Kernel"
    echo "###########################"

    install -vd "$DIR"/out/source/boot
    install -v "$DIR"/arch/arm/boot/dts/*.dtb "$DIR"/out/source/boot
    install -v "$DIR"/arch/arm/boot/uImage "$DIR"/out/source/boot
    install -v "$DIR"/System.map "$DIR"/out/source/boot
    make INSTALL_MOD_PATH="$DIR"/out/source modules_install
    #make INSTALL_HDR_PATH="$DIR"/out/source headers_install

    echo "#####################"
    echo "Installing SGX driver"
    echo "#####################"

    make SUBDIRS="$DIR"/omap5-sgx-ddk-linux/eurasia_km/eurasiacon/binary2_omap_linux_release/target/kbuild INSTALL_MOD_PATH="$DIR"/out/source modules_install
    echo "Installing usermode SGX driver support libraries"
    export DISCIMAGE="$DIR"/out/source
    make -C "$DIR"/omap5-sgx-ddk-um-linux install

    echo "###########################################"
    echo "Installing wifi and suspend-to-ram firmware"
    echo "###########################################"

    install -d "$DIR"/out/source/lib/firmware/
    cp -vR "$DIR"/extra_firmware/* "$DIR"/out/source/lib/firmware/
    chown -R root:root "$DIR"/out/source/lib/firmware

    echo "############"
    echo "Creating tar"
    echo "############"

    (cd "$DIR"/out/source; tar -czvf "$DIR"/out/kernel+firmware.tar.gz *)
    rm -rf "$DIR"/out/source
}

function kernel_clean {
    echo "###########################"
    echo "Cleaning kernel build files"
    echo "###########################"

    make mrproper
}

function sgx_clean {
    echo "########################"
    echo "Cleaning sgx build files"
    echo "########################"
    unset  CC
    make -C "$DIR"/omap5-sgx-ddk-linux/eurasia_km/eurasiacon/build/linux2/omap_linux KERNELDIR="$DIR" clean
}

#Input parameters parsing
case "$1" in
    kernel) build_kernel;;
    kernel_images) kernel_images;;
    kernel_defconfig) kernel_defconfig;;
    kernel_savedefconfig) kernel_savedefconfig;;
    kernel_menuconfig) kernel_menuconfig;;
    kernel_modules) kernel_modules;;
    dtbs) build_dtbs;;
    sgx) build_sgx;;
    install) install_all;;
    kernel_clean) kernel_clean;;
    sgx_clean) sgx_clean;;
    help) echo "Usage: $0 {kernel|kernel_defconfig|kernel_menuconfig|kernel_images|dtbs|sgx|install|kernel_clean|sgx_clean}";;
    *)
        build_kernel
        build_sgx
        install_all
        ;;
esac
