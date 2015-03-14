
function autoGlitch () {
	var image = pb.dataForType("public.tiff");
	if (image) {
		console.log('image glich');
		pb.clearContents();
		if (!pb.setDataForType(image.replace(/a/g, '0'), "public.tiff")) {
			console.log('error on setDataForType');
		}
	}
}
