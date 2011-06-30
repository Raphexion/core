RECIPE_TYPE			 = "canadian-cross"
#
RECIPE_ARCH			 = "canadian/${SDK_ARCH}--${MACHINE_ARCH}"
RECIPE_ARCH_MACHINE		 = "canadian/${SDK_ARCH}--${MACHINE}"

PACKAGES_append		+= "${SYSROOT_PACKAGES}"
SYSROOT_PACKAGES	?= ""

# Get both sdk and machine cross toolchains and sysroots
DEFAULT_DEPENDS += "${TARGET_ARCH}/toolchain ${TARGET_ARCH}/sysroot-dev"

# Set host=sdk for architecture triplet build/sdk/target
HOST_ARCH		= "${SDK_ARCH}"
HOST_CFLAGS		= "${SDK_CFLAGS}"
HOST_CPPFLAGS		= "${SDK_CPPFLAGS}"
HOST_OPTIMIZATION	= "${SDK_OPTIMIZATION}"
HOST_CFLAGS		= "${SDK_CFLAGS}"
HOST_CXXFLAGS		= "${SDK_CXXFLAGS}"
HOST_LDFLAGS		= "${SDK_LDFLAGS}"

# Arch tuple arguments for configure (oe_runconf in autotools.bbclass)
OECONF_ARCHTUPLE = "--build=${BUILD_ARCH} --host=${HOST_ARCH} --target=${TARGET_ARCH}"

# Need to have both host and target cross as well as native dirs in path
PATH_prepend = "\
${STAGE_DIR}/target/cross${stage_bindir}:\
${STAGE_DIR}/host/cross${stage_bindir}:\
${STAGE_DIR}/native${stage_bindir}:\
"
LD_LIBRARY_PATH = "\
${STAGE_DIR}/target/cross${stage_libdir}:\
${STAGE_DIR}/host/cross${stage_libdir}:\
${STAGE_DIR}/native${stage_libdir}\
"

MACHINE_SYSROOT	 = "${STAGE_DIR}/target/sysroot"
SDK_SYSROOT	 = "${STAGE_DIR}/host/sysroot"

# Use sdk_* path variables for host paths
base_prefix		= "${sdk_base_prefix}"
prefix			= "${sdk_prefix}"
exec_prefix		= "${sdk_exec_prefix}"
base_bindir		= "${sdk_base_bindir}"
base_sbindir		= "${sdk_base_sbindir}"
base_libexecdir		= "${sdk_base_libexecdir}"
base_libdir		= "${sdk_base_libdir}"
base_includecdir	= "${sdk_base_includedir}"
datadir			= "${sdk_datadir}"
sysconfdir		= "${sdk_sysconfdir}"
servicedir		= "${sdk_servicedir}"
sharedstatedir		= "${sdk_sharedstatedir}"
localstatedir		= "${sdk_localstatedir}"
runitservicedir		= "${sdk_runitservicedir}"
infodir			= "${sdk_infodir}"
mandir			= "${sdk_mandir}"
docdir			= "${sdk_docdir}"
bindir			= "${sdk_bindir}"
sbindir			= "${sdk_sbindir}"
libexecdir		= "${sdk_libexecdir}"
libdir			= "${sdk_libdir}"
includedir		= "${sdk_includedir}"

# Override the stage to handle host/target split of stage dir
#python do_stage () {
#    import bb, os
#    recdepends = bb.data.getVar('RECDEPENDS', d, True).split()
#    bb.debug(1, 'stage: RECDEPENDS=%s'%recdepends)
#    for dir in ('target', 'host'):
#        os.mkdir(dir)
#    for dep in recdepends:
#        # Get complete specification of package that provides 'dep', in
#        # the form PACKAGE_ARCH/PACKAGE-PV-PR
#        pkg = bb.data.getVar('PKGPROVIDER_%s'%dep, d, 0)
#        if not pkg:
#            bb.error('PKGPROVIDER_%s not defined!'%dep)
#            continue
#    
#        host_arch = bb.data.getVar('HOST_ARCH', d, True)
#        if pkg.startswith('native/'):
#            subdir = ''
#        elif pkg.startswith('cross/%s/'%host_arch):
#            subdir = 'host'
#        elif pkg.startswith('sysroot/%s/'%host_arch):
#            subdir = 'host'
#        elif pkg.startswith('sysroot/%s--'%host_arch):
#            subdir = 'host'
#        else:
#            subdir = 'target'
#    
#        filename = os.path.join(bb.data.getVar('STAGE_DEPLOY_DIR', d, True), pkg + '.tar')
#        if not os.path.isfile(filename):
#            bb.error('could not find %s to satisfy %s'%(filename, dep))
#            continue
#    
#        bb.note('unpacking %s to %s'%(filename, os.path.join(os.getcwd(), subdir)))
#    
#        # FIXME: do error handling on tar command
#        cmd = 'tar xpf %s'%filename
#        if subdir:
#            cmd = 'cd %s;%s'%(subdir, cmd)
#        os.system(cmd)
#}


FIXUP_PACKAGE_ARCH = canadian_fixup_package_arch
def canadian_fixup_package_arch(d):
    arch = bb.data.getVar('RECIPE_ARCH', d, True).partition('canadian/')
    sdk_arch = None
    if not arch[0] and arch[1]:
        # take part after / of RECIPE_ARCH if it begins with $RECIPE_TYPE/
        # and split at the double dash
        arch = arch[2].partition('--')
        if arch[0] and arch[1] and arch[2]:
            sdk_arch = arch[0]
            machine_arch = arch[2]
    if not sdk_arch:
        sdk_arch = '${SDK_ARCH}'
        machine_arch = '${MACHINE_ARCH}'
    packages = bb.data.getVar('PACKAGES', d, True).split()
    sysroot_packages = bb.data.getVar('SYSROOT_PACKAGES', d, True).split()
    for pkg in packages:
        if not bb.data.getVar('PACKAGE_ARCH_'+pkg, d, False):
            if pkg in sysroot_packages:
                pkg_arch = 'sysroot/'+machine_arch
            else:
                pkg_arch = 'sysroot/%s--%s'%(sdk_arch, machine_arch)
            bb.data.setVar('PACKAGE_ARCH_'+pkg, pkg_arch, d)

REBUILDALL_SKIP = "1"
RELAXED = "1"
