isIE = (document.all) ? 1 : 0;
isMoz = (document.getElementById&&!document.all) ? 1 : 0;

if (isMoz) {
  doc_width = self.innerWidth - 15;
  doc_height = self.innerHeight;
} else if (isIE) {
  doc_width = document.documentElement.clientWidth - 15;
  doc_height = document.documentElement.scrollHeight;
}
