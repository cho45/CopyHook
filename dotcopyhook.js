require("slack.format.js");

function onCopied () {
	// console.log(pb.types());

	console.log(utils.focusedWindowName());

	var bundleId = utils.focusedApplicationBundleId();
	console.log('onCopied: ' + bundleId);
	if (bundleId === "com.apple.Terminal") {
		// clear data without "public.utf8-plain-text"
		pb.copy(pb.string());
	} else
	if (bundleId === "com.tinyspeck.slackmacgap") {
		var text = pb.stringForType("public.utf8-plain-text");
		pb.copy(formatSlack(text));
	}
}

