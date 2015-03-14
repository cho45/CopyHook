//#!node

function formatSlack(text) {
	return text.replace(/^(.+)\s(\[\d\d:\d\d( AM|PM)?\])\s*\n(.+)\n*/gm, function (_, name, time, _, text) {
		return time + ' ' + name +  ': ' + text + "\n";
	});
}


if (typeof module != "undefined") {
	var str = require('fs').readFileSync("slack.txt", { encoding: "utf-8" });
	console.log(str);
	console.log(formatSlack(str));
}
