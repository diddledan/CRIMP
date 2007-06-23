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
            if (!href.match(/^(((ftp)|(http))s?:\/\/)|(mailto:)|(#)/)) {
                ajaxClickHandler(href);
                (new Event(event)).preventDefault();
            }
        });
    }
}

function ajaxClickHandler(url) {
    url = new String(url);
    var re = /^.*\?crimpq=(.+)[&;]?.*$/;
    var matches = re.exec(url);
    url = new String(matches[1]);
    $('crimpURL').value = url;
    $('crimp').send({update: $('crimpPageContent'), onComplete: resetAjaxHandlers});
}