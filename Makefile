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
  DEPENDS+=+re2
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
  "-fpermissive","-fPIC","-I$(STAGING_DIR)/usr/include", "-DOS_CHROMEOS=1", \
  "-D_FILE_OFFSET_BITS=64","-D_LARGEFILE_SOURCE","-D_LARGEFILE64_SOURCE", \
  "-DNDEBUG"]
LIBCHROME_LDFLAGS:=["-Wl,-O2","-Wl,--as-needed","-Wl,-Bdynamic", \
  "-L$(STAGING_DIR_ROOT)/usr/lib"]

USE_FLAGS:={coverage=false arm=$(ARM_ARCH) abi_x86_64=$(X86_ARCH) \
  amd64=$(X86_ARCH) mojo=false cros_host=true fuzzer=false test=false \
  asan=false dbus=true crypto=true timers=true profiling=false tcmalloc=false}

GN_ARGS:=platform_subdir="libchrome" OS="linux" \
	 platform2_root="$(BUILD_DIR)" \
	 build_root="$(PKG_BUILD_DIR)/" \
	 sysroot="$(STAGING_DIR)" \
	 libdir="$(STAGING_DIR_ROOT)/usr/lib" \
	 libbase_ver="860220" \
	 pkg_config="$(STAGING_DIR_HOST)/bin/pkg-config" \
	 cc="$(TARGET_CC)" ar="$(TARGET_AR)" cxx="$(TARGET_CXX)" \
	 enable_exceptions=false \
	 cxx="$(TARGET_CXX)" \
         external_cxxflags=$(LIBCHROME_CXXFLAGS) \
	 external_cflags=$(LIBCHROME_CFLAGS) \
	 external_cppflags=$(LIBCHROME_CPPFLAGS) \
	 external_ldflags=$(LIBCHROME_LDFLAGS) \
	 use=$(USE_FLAGS)

HEADERS_DIRS:=base base/allocator base/containers base/debug base/files \
  base/functional base/hash base/i18n base/json base/memory base/numerics \
  base/posix base/process base/ranges base/strings base/synchronization \
  base/system base/task base/task/common base/task/sequence-manager \
  base/task/thread_pool base/third_party/icu base/third_party/nspr \
  base/third_party/valgrind base/threading base/time base/timer \
  base/trace_event base/trace_event/common base/types \
  base/util/type_safety components/policy components/policy/core/common \
  testing/gmock/include/gmock dbus crypto build \
  third_party/abseil-cpp/absl/types testing/gtest/include/gtest \
  base/message_loop base/metrics \
  third_party/perfetto/include/perfetto/tracing/ \
  third_party/perfetto/include/perfetto/protozero/ \
  third_party/perfetto/protos/perfetto/trace/track_event components/timers

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
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/out/Default/obj/libchrome/*.pc $(1)/usr/lib/pkgconfig
	$(foreach header_dir,$(HEADERS_DIRS), \
		$(INSTALL_DIR) $(1)/usr/include/$(header_dir); \
		$(INSTALL_DATA) $(PKG_BUILD_DIR)/$(header_dir)/*.h $(1)/usr/include/$(header_dir)/;)
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/out/Default/lib/*.so $(1)/usr/lib
endef

$(eval $(call BuildPackage,libchrome))
