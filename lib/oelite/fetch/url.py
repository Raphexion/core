import oelite.fetch
import bb.utils
import os
import urlgrabber
import urlgrabber.progress
import hashlib

class UrlFetcher():

    SUPPORTED_SCHEMES = ("http", "https", "ftp")

    def __init__(self, uri, d):
        if not uri.scheme in self.SUPPORTED_SCHEMES:
            raise Exception(
                "Scheme %s not supported by oelite.fetch.UrlFetcher"%(
                    uri.scheme))
        self.url = "%s://%s"%(uri.scheme, uri.location)
        try:
            isubdir = uri.params["isubdir"]
        except KeyError:
            isubdir = uri.isubdir
        self.localname = os.path.basename(uri.location)
        self.localpath = os.path.join(uri.ingredients, isubdir, self.localname)
        self.signatures = d.get("FILE") + ".sig"
        self.uri = uri
        self.fetch_signatures = d["__fetch_signatures"]
        return

    def signature(self):
        try:
            self._signature = self.fetch_signatures[self.localname]
            return self._signature
        except KeyError:
            raise oelite.fetch.NoSignature(self.uri, "signature unknown")

    def grab(self, url, timeout=120, retry=5):
        print "grabbing %s"%(url)
        def grab_fail_callback(data):
            "Only print debug here when non fatal retries, debug in other cases is already printed"
            if (data.exception.errno in retrycodes) and (data.tries != data.retry):
                print "grabbing retry %d/%d, self.exception %s" %(data.tries,data.retry,data.exception)
        try:
            retrycodes = urlgrabber.grabber.URLGrabberOptions().retrycodes
            if 12 not in retrycodes:
                retrycodes.append(12)
            return urlgrabber.urlgrab(url, self.localpath,timeout=timeout,retry=retry,
                                      retrycodes=retrycodes,
                                      progress_obj=SimpleProgress(),
                                      failure_callback=grab_fail_callback)
        except urlgrabber.grabber.URLGrabError as e:
            print 'URLGrabError %i: %s' % (e.errno, e.strerror)
            if os.path.exists(self.localpath):
                os.unlink(self.localpath)
        return None

    def fetch(self):
        localdir = os.path.dirname(self.localpath)
        if not os.path.exists(localdir):
            bb.utils.mkdirhier(localdir)
        url = self.url
        while url:
            if os.path.exists(self.localpath):
                if "_signature" in dir(self):
                    m = hashlib.sha1()
                    m.update(open(self.localpath, "r").read())
                    if self._signature == m.hexdigest():
                        return True
                    else:
                        print "Expected signature: %s"%self._signature
                        print "Obtained signature: %s"%m.hexdigest()
                        raise Exception("Signature mismatch")
                os.unlink(self.localpath)
            f = self.grab(url)
            if f:
                break
            url = self.uri.alternative_mirror()
        if not f or f != self.localpath:
            return False
        m = hashlib.sha1()
        m.update(open(self.localpath, "r").read())
        signature = m.hexdigest()
        if not "_signature" in dir(self):
            return (self.localname, signature)
        return signature == self._signature


class SimpleProgress(urlgrabber.progress.BaseMeter):
    def _do_end(self, amount_read, now=None):
        print "grabbed %d bytes in %.2f seconds" %(amount_read,self.re.elapsed_time())
