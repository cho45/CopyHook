require("slack.format.js");

function onCopied () {
	// console.log(pb.types());

	/*
	pb.clearContents();
	pb.setStringForType("foo<b>bar</b>", "public.html");
	*/

	/*
	if (pb.string().match(/(https?:.+\.(gif|jpg|png))/)) {
		console.log('Download ' + RegExp.$1);
		var ret = utils.system('cd ~/Downloads && curl -O "' + RegExp.$1 + '" &');
		console.log(ret);
	}
	*/

	var bundleId = utils.focusedApplicationBundleId();
	var name = utils.focusedWindowName();
	console.log('onCopied: ' + bundleId + " (" + name + ")");
	if (bundleId === "com.apple.Terminal") {
		// clear data without "public.utf8-plain-text"
		pb.copy(pb.string());
	} else
	if (bundleId === "com.tinyspeck.slackmacgap") {
		var text = pb.stringForType("public.utf8-plain-text");
		pb.copy(formatSlack(text));
	}
}

