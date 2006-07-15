function showDebug() {
	debugview.custom(0,0.85);
}
function hideDebug() {
	debugview.custom(0.85,0);
}
function debugInit() {
	debugview = new fx.Opacity('crimpDebugContainer', { duration: 750 } );
	debugview.hide();
}
