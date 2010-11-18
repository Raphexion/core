inherit binconfig-install
addtask stage before do_fetch
addtask stage_fixup after do_stage

do_stage[cleandirs] =	"${STAGE_DIR}"
do_stage[dirs] =	"${STAGE_DIR}"
do_stage[recdeptask] =	"do_package"

python do_stage () {
    import bb

    recdepends = bb.data.getVar('RECDEPENDS', d, True).split()
    bb.debug('stage: RECDEPENDS=%s'%recdepends)
    for dep in recdepends:
	stage_add(dep, d)
}

def stage_add(dep, d):
    bb.debug(2, 'adding build dependency %s to stage'%dep)

    # FIXME: we should find a way to avoid building recipes needed for
    # stage packages which is present (pre-baked) in deploy/stage dir.
    # perhaps we can dynamically add stage_packages to ASSUME_PROVIDED
    # in base_after_parse() based on the findings in deploy/stage
    # based on exploded DEPENDS???

    # Get complete specification of package that provides 'dep', in
    # the form PACKAGE_ARCH/PACKAGE-PV-PR
    pkg = bb.data.getVar('PKGPROVIDER_%s'%dep, d, 0)
    if not pkg:
	bb.error('PKGPROVIDER_%s not defined!'%dep)
	return

    filename = os.path.join(bb.data.getVar('STAGE_DEPLOY_DIR', d, True), pkg + '.tar')
    if not os.path.isfile(filename):
	bb.error('could not find %s to satisfy %s'%(filename, dep))
	return

    bb.note('unpacking %s to %s'%(filename, os.getcwd()))

    unpack(d, filename)

    
def unpack(d, filename):
    import tempfile

    dest = os.getcwd()
    tempdir = tempfile.mkdtemp(dir=dest)
    os.chdir(tempdir)
    bb.data.setVar('TEMP_STAGE_DIR', tempdir, d)
    # FIXME: do error handling on tar command
    os.system('tar xpf %s'%filename)

    for f in (bb.data.getVar('STAGE_FIXUP_FUNCS', d, 1) or '').split():
        bb.build.exec_func(f, d)

    for root, dirs, files in os.walk("."):
        for f in files:
            file = os.path.join(root, f)
            if os.path.exists(dest+"/"+file):
                bb.error("file exist in stage: %s" % dest+"/"+file)
            os.renames(file, dest+"/"+file)
    os.chdir(dest)

    return

STAGE_FIXUP_FUNCS += " \
"
