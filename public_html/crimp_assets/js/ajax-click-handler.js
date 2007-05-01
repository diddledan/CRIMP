/**
 * select all link tags
 */
var links = $$('a');
for (i = 0; i < links.length; i++) {
    var el = links[i];
    el.addEvent('click', function(event) {
        href = new String(this.getProperty('href'));
        if (!href.match(/^((((ftps?)|(https?)):\/\/)|(mailto:)|(#))/)) {
            ajaxClickHandler(href);
            (new Event(event)).preventDefault();
        }
    });
}

function ajaxClickHandler(url) {
    $('crimpURL').value = url;
    $('crimp').send({update: $('crimpPageContent'), onComplete: alert(url+": loading complete")});
}