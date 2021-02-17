---
title: About
---

<script src="/js/jquery.min.js"></script>
<script>
// TODO how to move this to a script?
// aeson-encoded wordlist goes here:
var wordlist = [];
var options = {
	gridSize: 5,
	clearCanvas: false, // automatic when using a mask
	// drawOutOfBound: true,
	// drawMask: true,
	weightFactor: 10,
	fontFamily: 'sans-serif',
	// color: 'random-light',
	// color: '#c1c1c1',
	color: function (word, weight) {
		return (word === 'codeis.land' || word === 'about' || word === 'resume') ? '#000' : '#c3c3c3';
	},
	hover: window.drawBox,
	click: function(item) {
		if (item[0] === 'codeis.land') {
			location.href = "";
		} else {
			location.href = "/tags/" + item[0] + ".html";
		}
	},
	backgroundColor: '#fff'
}
$(document).ready(function() {
  var canvas = $('#canvas');
  setTimeout(
    drawLogo(canvas, '/about/pic.png', 0, 0, 100, 150, ''),
    500);
});
</script>

Hi. I'm Code and this is my island! Sort of. You know what I mean.
