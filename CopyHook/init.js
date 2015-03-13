// initial javascript for bridging

var console = {
    log : function (arg) {
        __bridge.log(String(arg) + "\n");
    }
};


var utils = {
    focusedApplicationBundleId : function () {
        return __bridge.focusedApplicationBundleId();
    }
};

var require = function (path) {
    if (__bridge.require(path)) {
        return true;
    } else {
        throw Error(path + " is not located in path");
    }
};

pasteboard.string = function () {
    return pasteboard.stringForType("public.utf8-plain-text");
};

pasteboard.copy = function (str) {
    pasteboard.clearContents();
    pasteboard.setStringForType(str, "public.utf8-plain-text");
};

var pb = pasteboard;
