set -e
# Check if mkdtimg tool exist
mkdtimg_path="../../../../prebuilts/misc/linux-x86/libufdt"
mkditimg_git_repo="https://github.com/LineageOS/android_prebuilts_tools-lineage.git"
MKDTIMG="../../../../prebuilts/misc/linux-x86/libufdt/mkdtimg"

# Check if the folder exists
if [ -d "$mkdtimg_path" ]; then
    echo "Prebuilt mkdtimg exists. Proceeding to the next step."
else
    echo "Prebuilt mkdtimg does not exist. Cloning Git repository from Lineage OS."
    git clone "$mkditimg_git_repo" ../../../../prebuilts/misc

    # Check if the clone was successful
    if [ $? -eq 0 ]; then
        echo "Git clone successful. Proceeding to the next step."
    else
        echo "Git clone failed. Please check your internet connection and try again."
        exit 1
    fi
fi

cd "$KERNEL_TOP"/kernel

echo "================================================="
echo "Your Environment:"
echo "ANDROID_ROOT: ${ANDROID_ROOT}"
echo "KERNEL_TOP  : ${KERNEL_TOP}"
echo "KERNEL_TMP  : ${KERNEL_TMP}"

for platform in $PLATFORMS; do \

    case $platform in
        yoshino)
            DEVICE=$YOSHINO;
            DTBO="false";;
        nile)
            DEVICE=$NILE;
            DTBO="false";;
        ganges)
            DEVICE=$GANGES;
            DTBO="false";;
        tama)
            DEVICE=$TAMA;
            DTBO="true";;
        kumano)
            DEVICE=$KUMANO;
            DTBO="true";;
        seine)
            DEVICE=$SEINE;
            DTBO="true";;
    esac

    for device in $DEVICE; do \
        (
            if [ ! $only_build_for ] || [ $device = $only_build_for ] ; then
                # Don't override $KERNEL_TMP when set by manually
                [ ! "$build_directory" ] && KERNEL_TMP=$KERNEL_TMP-${device}
                # Keep kernel tmp when building for a specific device or when using keep tmp
                [ ! "$keep_kernel_tmp" ] && [ ! "$only_build_for" ] &&rm -rf "${KERNEL_TMP}"
                mkdir -p "${KERNEL_TMP}"

                echo "================================================="
                echo "Platform -> ${platform} :: Device -> $device"
                make O="$KERNEL_TMP" ARCH=arm64 \
                                          CROSS_COMPILE=aarch64-linux-gnu- \
                                          CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                                          -j$(nproc) ${BUILD_ARGS} \
                                          aosp_${platform}_${device}_defconfig

                echo "The build may take up to 10 minutes. Please be patient ..."
                echo "Building new kernel image ..."
                echo "Logging to $KERNEL_TMP/build.log"
                make O="$KERNEL_TMP" ARCH=arm64 \
                     CROSS_COMPILE=aarch64-linux-gnu- \
                     CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
                     -j$(nproc) ${BUILD_ARGS} \
                     >"$KERNEL_TMP"/build.log 2>&1;

                echo "Copying new kernel image ..."
                cp "$KERNEL_TMP/arch/arm64/boot/Image.gz-dtb" "$KERNEL_TOP/common-kernel/kernel-dtb-$device"
                if [ $DTBO = "true" ]; then
                    # shellcheck disable=SC2046
                    # note: We want wordsplitting in this case.
                    $MKDTIMG create "$KERNEL_TOP"/common-kernel/dtbo-${device}.img $(find "$KERNEL_TMP"/arch/arm64/boot/dts -name "*.dtbo")
                fi

            fi
        )
    done
done


echo "================================================="
echo "Done!"
