
function onCopied (e) {
	log("onCopied");
	log(e.stringForType('public.utf8-plain-text'));
	e.clearContents();
	e.setStringForType(e.focusedApplicationBundleId(), 'public.utf8-plain-text');
}

