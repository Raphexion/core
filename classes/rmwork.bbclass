#
# Cleanup workdir after build (enabled by default!)
#
# To leave entire workdir after succeussful builds, add the following
# line to conf/local.conf:
#   RMWORK = "0"
# or use --no-rmwork command-line option
#

addtask rmwork after do_package
do_rmwork[dirs] = "${WORKDIR}"
do_rmwork[nohash] = True
do_rmwork[nostamp] = True

python do_rmwork () {
    import os, shutil
    tmp = os.path.basename(d.getVar("T", True))
    for entry in os.listdir("."):
        if os.path.basename(entry) == tmp:
            pass
        else:
            bb.debug(0, "Removing %s"%(entry))
            if os.path.isdir(entry):
                shutil.rmtree(entry)
            else:
                os.remove(entry)

    stampdir = d.getVar("STAMPDIR", True)
    shutil.rmtree(stampdir)
}