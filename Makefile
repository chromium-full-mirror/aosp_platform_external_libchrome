#
# TODO(b/371112401): Add license information
#
#
include $(TOPDIR)/rules.mk

PKG_NAME:=libchrome
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=gwifi
  CATEGORY:=Nest WiFi Mesh Solutions
  SUBMENU:=Libs
  DEPENDS:=+modp_b64 +protobuf +glib2 +libopenssl +libgcrypt +libdbus +libcurl
  DEPENDS+=+nspr +libevent2 +libnss +abseil-cpp +googletest +double-conversion
  TITLE:=Chrome base/ and dbus/ libraries extracted for use on Chrome OS.
endef

define Package/libchrome/description
  Chrome base/ and dbus/ libraries extracted for use on Chrome OS.
endef

ifeq ($(ARCH),arm)
        ARM_ARCH=true
        X86_ARCH=false
else
        X86_ARCH=true
        ARM_ARCH=false
endif

LIBCHROME_CFLAGS:=["-O2", "-pipe", "-std=gnu11", "-I$(TOOLCHAIN_DIR)/include"]
LIBCHROME_CPPFLAGS:=["-D_LARGEFILE_SOURCE","-D_LARGEFILE64_SOURCE","-DNDEBUG"]
LIBCHROME_CXXFLAGS:=["-Os","-pipe","-Wunused-function","-Wno-error", \
  "-std=c++17","-fno-exceptions","-fno-unwind-tables", \
  "-fno-asynchronous-unwind-tables","-Wno-implicit-fallthrough", \
  "-fpermissive","-fPIC","-DOS_CHROMEOS=1","-I$(BUILD_DIR)/modp_b64", \
  "-I$(STAGING_DIR)/usr/include","-I$(STAGING_DIR)/usr/include/glib-2.0", \
  "-I$(STAGING_DIR)/usr/include/nspr","-I$(STAGING_DIR)/usr/include/nss", \
  "-I$(STAGING_DIR)/usr/include/dbus-1.0", \
  "-I$(STAGING_DIR)/usr/lib/dbus-1.0/include","-D_FILE_OFFSET_BITS=64", \
  "-D_LARGEFILE_SOURCE","-D_LARGEFILE64_SOURCE","-DNDEBUG"]
LIBCHROME_LDFLAGS:=["-Wl,-O2","-Wl,--as-needed","-Wl,-Bdynamic"]

USE_FLAGS:={coverage=false arm=$(ARM_ARCH) abi_x86_64=$(X86_ARCH) \
  amd64=$(X86_ARCH) mojo=false cros_host=true fuzzer=false test=false \
  asan=false dbus=true crypto=true timers=true profiling=false tcmalloc=false}

GN_ARGS:=platform_subdir="libchrome" OS="linux" \
	 platform2_root="$(BUILD_DIR)" \
	 sysroot="$(STAGING_DIR)" \
	 pkg_config="$(STAGING_DIR_HOST)/bin/pkg-config" \
	 cc="$(TARGET_CC)" ar="$(TARGET_AR)" build_root="$(PKG_BUILD_DIR)/"\
	 enable_exceptions=false \
	 libbase_ver="860220" \
	 cxx="$(TARGET_CXX)" \
	 libdir="$(STAGING_DIR_ROOT)/usr/lib" sysroot="$(STAGING_DIR)" \
         external_cxxflags=$(LIBCHROME_CXXFLAGS) \
	 external_cflags=$(LIBCHROME_CFLAGS) \
	 external_cppflags=$(LIBCHROME_CPPFLAGS) \
	 external_ldflags=$(LIBCHROME_LDFLAGS) \
	 use=$(USE_FLAGS)

HEADERS_DIRS:=base base/allocator base/containers base/debug base/files \
  base/hash base/json base/memory base/numerics base/posix base/process \
  base/ranges base/strings base/synchronization base/system base/task \
  base/task/thread_pool base/third_party/nspr base/threading base/time \
  base/timer dbus crypto

define Build/Prepare
	$(CP) $(TOPDIR)/package/gwifi/external/libchrome/ $(BUILD_DIR)/
	$(CP) $(TOPDIR)/package/gwifi/external/platform2/common-mk/ $(BUILD_DIR)/
	$(CP) $(TOPDIR)/package/gwifi/external/platform2/.gn $(BUILD_DIR)/
	$(RM)  $(BUILD_DIR)/libchrome/libchrome_tools/patches/patches
	$(RM)  $(BUILD_DIR)/libchrome/libchrome_tools/patches/show_unused
	$(call PatchDir,$(PKG_BUILD_DIR),$(BUILD_DIR)/libchrome/libchrome_tools/patches, ./)
endef

define Build/Configure/Default
	cd $(PKG_BUILD_DIR) && $(STAGING_DIR_HOSTPKG)/bin/gn gen \
	  '-root=$(BUILD_DIR)' '--args=$(GN_ARGS)' $(PKG_BUILD_DIR)/out/Default
endef

define Build/Compile
	cd $(PKG_BUILD_DIR) && $(STAGING_DIR_HOST)/bin/ninja \
	  -C $(PKG_BUILD_DIR)/out/Default libchrome:all
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib/pkgconfig
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/out/Default/obj/libchrome/*.pc $(1)/usr/lib/pkgconfig
	$(CP) $(PKG_BUILD_DIR)/out/Default/lib/*.so $(1)/usr/lib
	$(foreach header_dir,$(HEADERS_DIRS), \
		$(INSTALL_DIR) $(1)/usr/include/$(header_dir); \
		$(INSTALL_DATA) $(PKG_BUILD_DIR)/$(header_dir)/*.h $(1)/usr/include/$(header_dir)/;)
endef

$(eval $(call BuildPackage,libchrome))
