//#!node

function formatSlack(text) {
	return text.replace(/^(.+)\s(\[\d\d:\d\d\])\s*\n(.+)\n*/gm, function (_, name, time, text) {
		return time + ' ' + name +  ': ' + text + "\n";
	});
}


/*
var str = require('fs').readFileSync("slack.txt", { encoding: "utf-8" });
console.log(str);
console.log(formatSlack(str));
*/
