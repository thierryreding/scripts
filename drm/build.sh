#!/bin/sh

JOBS=13

x86_options="
  PCI=y AGP=y USB=y VIRTIO_MMIO=y
  DRM=y
  DRM_AMDGPU=y
  DRM_AMDGPU_CIK=y
  DRM_AMDGPU_USERPTR=y
  DRM_AST=y
  DRM_BOCHS=y
  DRM_CIRRUS_QEMU=y
  DRM_GMA500=y
  DRM_GMA600=y
  DRM_GMA3600=y
  DRM_I810=y
  DRM_I915=y
  DRM_I915_PRELIMINARY_HW_SUPPORT=y
  DRM_MGAG200=y
  DRM_MGA=y
  DRM_NOUVEAU=y
  DRM_QXL=y
  DRM_R128=y
  DRM_RADEON=y
  DRM_RADEON_USERPTR=y
  DRM_RADEON_UMS=y
  DRM_SAVAGE=y
  DRM_SIS=y
  DRM_TDFX=y
  DRM_UDL=y
  DRM_VGEM=y
  DRM_VIA=y
  DRM_VIRTIO_GPU=y
  DRM_VMWGFX=y
  DRM_VMWGFX_FBCON=y
  DRM_I2C_ADV7511=y
  DRM_I2C_NXP_TDA998X=y
"

x86_64_options="
  PCI=y AGP=y USB=y VIRTIO_MMIO=y
  DRM=y
  DRM_AMDGPU=y
  DRM_AMDGPU_CIK=y
  DRM_AMDGPU_USERPTR=y
  DRM_AST=y
  DRM_BOCHS=y
  DRM_CIRRUS_QEMU=y
  DRM_GMA500=y
  DRM_GMA600=y
  DRM_GMA3600=y
  DRM_I810=y
  DRM_I915=y
  DRM_I915_PRELIMINARY_HW_SUPPORT=y
  DRM_MGAG200=y
  DRM_MGA=y
  DRM_NOUVEAU=y
  DRM_QXL=y
  DRM_R128=y
  DRM_RADEON=y
  DRM_RADEON_USERPTR=y
  DRM_RADEON_UMS=y
  DRM_SAVAGE=y
  DRM_SIS=y
  DRM_TDFX=y
  DRM_UDL=y
  DRM_VGEM=y
  DRM_VIA=y
  DRM_VIRTIO_GPU=y
  DRM_VMWGFX=y
  DRM_VMWGFX_FBCON=y
  DRM_I2C_ADV7511=y
  DRM_I2C_NXP_TDA998X=y
"

arm_options="
  TICK_CPU_ACCOUNTING=y
  MMU=y
  ARCH_MULTIPLATFORM=y
  ARCH_EXYNOS=y
  ARCH_QCOM=y
  ARCH_ROCKCHIP=y
  ARCH_SHMOBILE=y
  ARCH_TEGRA=y
  ROCKCHIP_IOMMU=y
  OMAP2_DSS=y
  MFD_ATMEL_HLCDC=y
  IMX_IPUV3_CORE=y
  STAGING=y
  DRM=y
  DRM_ARMADA=y
  DRM_ATMEL_HLCDC=y
  DRM_EXYNOS=y
  DRM_EXYNOS_FIMD=y
  DRM_EXYNOS5433_DECON=y
  DRM_EXYNOS7_DECON=y
  DRM_EXYNOS_DPI=y
  DRM_EXYNOS_DSI=y
  DRM_EXYNOS_HDMI=y
  DRM_EXYNOS_VIDI=y
  DRM_EXYNOS_G2D=y
  DRM_EXYNOS_IPP=y
  DRM_EXYNOS_FIMC=y
  DRM_EXYNOS_ROTATOR=y
  DRM_EXYNOS_MIC=y
  DRM_FSL_DCU=y
  DRM_IMX=y
  DRM_IMX_FB_HELPER=y
  DRM_IMX_PARALLEL_DISPLAY=y
  DRM_IMX_TVE=y
  DRM_IMX_LDB=y
  DRM_IMX_HDMI=y
  DRM_MSM=y
  DRM_NOUVEAU=y
  DRM_OMAP=y
  DRM_ROCKCHIP=y
  ROCKCHIP_DW_HDMI=y
  DRM_SHMOBILE=y
  DRM_STI=y
  DRM_STI_FBDEV=y
  DRM_TEGRA=y
  DRM_TEGRA_DEBUG=y
  DRM_TEGRA_STAGING=y
  DRM_TILCDC=y
  DRM_VGEM=y
  DRM_I2C_ADV7511=y
  DRM_I2C_CH7006=y
  DRM_I2C_SIL164=y
  DRM_I2C_NXP_TDA998X=y
  DRM_PANEL_SIMPLE=y
  DRM_PANEL_SAMSUNG_S6E8AA0=y
  DRM_PANEL_SHARP_LQ101R1SX01=y
  DRM_NXP_PTN3460=y
  DRM_PARADE_PS8622=y
"

for config in x86 x86_64 arm; do
	directory="build/drm/$config"
	dotconfig="$directory/.config"

	if ! test -d "$directory"; then
		mkdir -p "$directory"
	fi

	if ! test -f "$dotconfig"; then
		eval "options=${config}_options"
		eval "options=\$${options}"

		make ARCH=$config O="$directory" allnoconfig

		for option in $options; do
			args="--file $dotconfig"
			key=${option%%=*}
			value=${option#*=}

			case $value in
				y)
					args="$args --enable $key"
					;;

				n)
					args="$args --disable $key"
					;;

				m)
					args="$args --module $key"
					;;
			esac

			scripts/config $args
		done

		make ARCH=$config O="$directory" olddefconfig
	fi

	case $config in
		x86)
			CROSS_COMPILE=
			;;

		x86_64)
			CROSS_COMPILE=
			;;

		arm)
			CROSS_COMPILE=armv7l-unknown-linux-gnueabihf-
			;;

		*)
			echo "ERROR: unsupported configuration $config"
			exit 1
			;;
	esac

	make ARCH=$config CROSS_COMPILE=$CROSS_COMPILE O="$directory" -j $JOBS
done

#if ! test -f build/drm/x86/.config; then
#	make ARCH=x86 O=build/drm/x86 allnoconfig
#fi
#
#make ARCH=x86 O=build/drm/x86 -j $JOBS
#
#if ! test -f build/drm/x86_64/.config; then
#	make ARCH=x86 O=build/drm/x86_64 allnoconfig
#fi
#
#make ARCH=x86 O=build/drm/x86_64 -j $JOBS
#
#if ! test -f build/drm/arm/.config; then
#	make ARCH=x86 O=build/drm/arm allnoconfig
#
#	kconfig_enable build/drm/arm TICK_CPU_ACCOUNTING
#fi
#
#make ARCH=arm O=build/drm/arm -j $JOBS
