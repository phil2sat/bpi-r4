#!/bin/bash

# 🎨 Color Palette
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# 📌 Status Functions
info() { echo -e "${CYAN}ℹ️  [INFO]${NC} $1"; }
progress() { echo -e "${BLUE}⌛ [WORKING]${NC} $1..."; }
success() { echo -e "${GREEN}✅ [SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}⚠️  [WARNING]${NC} $1"; }
fail() { 
    echo -e "${RED}❌ [FAILURE]${NC} $1"
    echo -e "${YELLOW}💡 Tip:${NC} $2"
    exit 1
}

# 🔍 Pre-Flight Checks
check_dependencies() {
    local missing=()
    for cmd in dd gunzip gzip cp rm; do
        if ! command -v $cmd &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    [ ${#missing[@]} -gt 0 ] && \
        fail "Missing tools: ${missing[*]}" "Install required packages first"
}

check_source_files() {
    local std_image="bpi-r4-std/openwrt-mediatek-filogic-bananapi_bpi-r4-sdcard.img.gz"
    local poe_image="bpi-r4-poe/openwrt-mediatek-filogic-bananapi_bpi-r4-poe-sdcard.img.gz"
    
    for file in "$std_image" "$poe_image"; do
        if [ ! -f "$file" ]; then
            fail "Missing source file: $file" "Download from official OpenWRT releases"
        fi
        
        if ! gunzip -t "$file" 2>/dev/null; then
            fail "Corrupted file: $file" "Redownload the image, checksum failed"
        fi
    done
}

check_bl2_files() {
    local bl2_files=(
        "u-boot/bpi-r4_sdmmc_8GB_bl2.img"
        "u-boot/bpi-r4_spim-nand_ubi_8GB_bl2.img" 
        "u-boot/bpi-r4_emmc_8GB_bl2.img"
    )
    
    local missing_bl2=()
    for file in "${bl2_files[@]}"; do
        [ ! -f "$file" ] && missing_bl2+=("$file")
    done
    
    [ ${#missing_bl2[@]} -gt 0 ] && \
        fail "Missing BL2 files: ${missing_bl2[*]}" "Download from: https://github.com/frank-w/u-boot/releases"
}

# 🔇 Silent Operations
safe_dd() {
    local params="$1"
    local label="$2"
    
    progress "$label"
    if ! dd $params status=none >/dev/null 2>&1; then
        fail "Operation failed: $label" "Check disk space and permissions"
    fi
    success "$label"
}

# 🖼️ Image Processing
process_image() {
    local source_dir="$1"
    local variant="$2"  # "" or "poe"
    local model="bpi-r4"
    local source_gz="${source_dir}/openwrt-mediatek-filogic-bananapi_${model}${variant:+-${variant}}-sdcard.img.gz"
    local base="openwrt-mediatek-filogic-bananapi_${model}${variant:+-${variant}}-sdcard"
    
    echo -e "\n${MAGENTA}🖼️  Processing: ${source_gz}${NC}"
    
    # Decompress in source directory
    progress "Decompressing source image"
    if ! gunzip -kf "$source_gz"; then
        fail "Decompression failed" "File might be corrupted"
    fi
    
    local source_img="${source_dir}/${base}.img"
    
    # 1. Partition Extraction
    safe_dd "if=${source_img} bs=1024 count=17 of=${source_dir}/${base}-gpt.img" "Extracting GPT header"
    safe_dd "if=${source_img} bs=1024 skip=6656 count=$((1024*44-6656)) of=${source_dir}/${base}-uboot-recovery.img" "Extracting U-Boot recovery"
    safe_dd "if=${source_img} bs=1048576 skip=45 count=$((51-45)) of=${source_dir}/${base}-uboot-snand.img" "Extracting U-Boot snand"
    safe_dd "if=${source_img} bs=1048576 skip=52 of=${source_dir}/${base}-rest.img" "Extracting remaining partitions"

    # 2. BL2 Preparation
    prepare_bl2() {
        local type=$1
        local seek=$2
        
        if ! cp -f "u-boot/${model}_${type}_8GB_bl2.img" "${source_dir}/${base}-${type}-bl2.img"; then
            fail "Copy failed for ${type}" "Verify file permissions"
        fi
        
        if ! dd if=/dev/zero of="${source_dir}/${base}-${type}-bl2.img" seek=$seek bs=1 count=1 conv=notrunc status=none; then
            fail "Modification failed for ${type}" "Check filesystem integrity"
        fi
    }
    
    progress "Preparing BL2 components"
    prepare_bl2 "sdmmc" $(((6656-17)*1024-1))
    prepare_bl2 "spim-nand" $((1024*1024-1))
    prepare_bl2 "emmc" $((1024*1024-1))

    # 3. Image Assembly
    progress "Building final image"
    local output_img="${source_dir}/${base}-8GB.img"
    rm -f "$output_img"
    if ! cat "${source_dir}/${base}-"{gpt,sdmmc-bl2,uboot-recovery,spim-nand-bl2,uboot-snand,emmc-bl2,rest}".img" > "$output_img"; then
        fail "Image assembly failed" "Check available disk space"
    fi

    # 4. Cleanup
    progress "Removing temporary files"
    rm -f "${source_dir}/${base}-"{gpt,sdmmc-bl2,uboot-recovery,spim-nand-bl2,uboot-snand,emmc-bl2,rest}".img"
    rm -f "$source_img"
    
    # 5. Compress final image
    progress "Compressing final image"
    gzip -9f "$output_img" || warning "Final compression had issues"
    
    success "Created: ${output_img}.gz"
}

# ======= MAIN =======
echo -e "${YELLOW}
╔══════════════════════════════╗
║   BPI-R4 8GB Image Generator ║
╚══════════════════════════════╝${NC}"

# 🛡️ Pre-Flight Checks
check_dependencies
check_source_files
check_bl2_files

# 🚀 Process Images
process_image "bpi-r4-std" ""
process_image "bpi-r4-poe" "poe"

echo -e "\n${GREEN}
╔══════════════════════════════╗
║   Process completed! 🎉      ║
╚══════════════════════════════╝${NC}"