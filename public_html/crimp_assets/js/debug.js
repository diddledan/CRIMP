function showDebug(){
	crimpDebug = document.getElementById('crimpDebugContainer');

	if (!/[?&]debug=on/.test(window.location)) {
		if (/\?/.test(window.location)) {
			window.location = window.location+'&debug=on';
			return;
		}
		window.location = window.location+'?debug=on';
		return;
	}
	crimpDebug.style.height = doc_height ? doc_height+"px" : "100%";
	crimpDebug.style.width = doc_width ? doc_width+"px" : "100%";
	debugopacity = 0;
	crimpDebug.style.opacity = debugopacity;
	crimpDebug.style.visibility = 'visible';
	showDebug2();

	if (!document.getElementById('closeCrimpDebugButton')) {
		drawCrimpDebugCloseButton();
	}

	closeCrimpDebugButton = document.getElementById('closeCrimpDebugButton');

	resetCrimpDebugCloseButton();
	animateCrimpDebugCloseButton();
}
function showDebug2(){
	if (debugopacity < 0.85) {
		debugopacity += 0.05;
		crimpDebug.style.opacity = debugopacity;
		setTimeout("showDebug2()",3);
	}
}
function hideDebug(){
	crimpDebug.style.visibility = 'hidden';
	closeCrimpDebugButton.style.visibility = 'hidden';
}

function drawCrimpDebugCloseButton(){
	document.write('<div id="closeCrimpDebugButton"><a href="#" onClick="hideDebug(); return false;"><img id="closeCrimpDebugImg" src="/crimp_assets/pics/close.gif" title="close debug view" alt="close debug view" style="border: 0;" /></a></div>');
}
function resetCrimpDebugCloseButton(){
	closeCrimpDebugButton.style.position = "absolute";
	closeCrimpDebugButton.style.top = "45%";
	closeCrimpDebugButtonOpacity = 0;
	closeCrimpDebugButton.style.opacity = closeCrimpDebugButtonOpacity
	closeCrimpDebugButton.style.visibility = 'visible';
}
function animateCrimpDebugCloseButton(){
	if (closeCrimpDebugButtonOpacity < 1) {
		closeCrimpDebugButtonOpacity = closeCrimpDebugButtonOpacity + 0.05;
		closeCrimpDebugButton.style.opacity = closeCrimpDebugButtonOpacity;
		setTimeout("animateCrimpDebugCloseButton()", 1);
	}
}
