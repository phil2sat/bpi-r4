split() {
    local in="$1"
    local model="${2:-bpi-r4}"
    local base="$(basename "${in}" .img)"
    dd "if=${in}" bs=1024 count=17 "of=${base}-gpt.img"
    dd "if=${in}" bs=1024 skip=6656 count=$((1024*44-6656)) "of=${base}-uboot-recovery.img"
    dd "if=${in}" bs=1048576 skip=45 count=$((51-45)) "of=${base}-uboot-snand.img"
    dd "if=${in}" bs=1048576 skip=52 "of=${base}-rest.img"
    
    cp -f "${model}_sdmmc_8GB_bl2.img" "${base}-sdmmc-bl2.img"
    dd "if=/dev/zero" "of=${base}-sdmmc-bl2.img" seek=$(((6656-17)*1024-1)) bs=1 count=1
    cp -f "${model}_spim-nand_ubi_8GB_bl2.img" "${base}-spim-nand-bl2.img"
    dd "if=/dev/zero" "of=${base}-spim-nand-bl2.img" seek=$((1024*1024-1)) bs=1 count=1
    cp -f "${model}_emmc_8GB_bl2.img" "${base}-emmc-bl2.img"
    dd "if=/dev/zero" "of=${base}-emmc-bl2.img" seek=$((1024*1024-1)) bs=1 count=1
    rm -f "${base}-new.img"
    cat "${base}-"{gpt,sdmmc-bl2,uboot-recovery,spim-nand-bl2,uboot-snand,emmc-bl2,rest}".img" > "${base}-8GB.img"
    rm "${base}-"{gpt,sdmmc-bl2,uboot-recovery,spim-nand-bl2,uboot-snand,emmc-bl2,rest}".img"
}

gunzip -k "openwrt-mediatek-filogic-bananapi_bpi-r4-sdcard.img.gz"
gunzip -k "openwrt-mediatek-filogic-bananapi_bpi-r4-poe-sdcard.img.gz"
split "openwrt-mediatek-filogic-bananapi_bpi-r4-sdcard.img"
split "openwrt-mediatek-filogic-bananapi_bpi-r4-poe-sdcard.img"
gzip -9 "openwrt-mediatek-filogic-bananapi_bpi-r4-sdcard-8GB.img"
gzip -9 "openwrt-mediatek-filogic-bananapi_bpi-r4-poe-sdcard-8GB.img"
rm "openwrt-mediatek-filogic-bananapi_bpi-r4-sdcard.img"
rm "openwrt-mediatek-filogic-bananapi_bpi-r4-poe-sdcard.img"