/**
 * select all link tags and apply an ajax handler to them
 */
function resetAjaxHandlers() {
    var links = $$('a');
    for (i = 0; i < links.length; i++) {
        var el = links[i];
        el.removeEvents('click');
        el.addEvent('click', function(event) {
            href = new String(this.getProperty('href'));
            if (!href.match(/^((((ftps?)|(https?)):\/\/)|(mailto:)|(#))/)) {
                ajaxClickHandler(href);
                (new Event(event)).preventDefault();
            }
        });
    }
}

function ajaxClickHandler(url) {
    $('crimpURL').value = url;
    $('crimp').send({update: $('crimpPageContent'), onComplete: resetAjaxHandlers});
}