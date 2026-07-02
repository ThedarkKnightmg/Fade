// Fade out the loading splash once Flutter paints its first frame.
// Kept in an external file so the page's CSP needs no 'unsafe-inline'.
window.addEventListener('flutter-first-frame', function () {
  var l = document.getElementById('loading');
  if (l) {
    l.style.opacity = '0';
    setTimeout(function () { l.remove(); }, 300);
  }
});
