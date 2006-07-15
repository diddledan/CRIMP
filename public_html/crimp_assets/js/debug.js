function showDebug() {
	if (document.getElementById('crimpDebugContainer')) {
		debugview.custom(0,0.85);
	} else {
		alert('This feature requires the server to be configured to always send the debug messages. This usually means adding "debug = on" to the crimp.ini file.');
	}
}
function hideDebug() {
	debugview.custom(0.85,0);
}
function debugInit() {
	debugview = new fx.Opacity('crimpDebugContainer', { duration: 750 } );
	debugview.hide();
}
