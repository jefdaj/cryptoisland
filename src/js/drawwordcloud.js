// TODO why does the word cloud fail the first load and work after that?

// TODO move to index.html?
function drawLogo(canvas, imagePath, x, y, w, h, coffeeUrl) {
  // draw the coffee cup first (the rest can go over it?)
  ctx2 = canvas[0].getContext('2d');
  coffee = new Image();
  coffee.onload = start;
  function start() {
    // TODO scale to page properly
    ctx2.drawImage(coffee, x, y, w, h);
  };
  coffee.src = imagePath;

  // see https://stackoverflow.com/a/18053642
  // see http://jsfiddle.net/m1erickson/wPMk5/
  function clicked(e) {
    var rect = canvas[0].getBoundingClientRect();
    var clickedX = e.clientX - rect.left;
    var clickedY = e.clientY - rect.top;
    // console.log("x: " + x + " y: " + y);
    if (clickedX>x && clickedX<(x+w) && clickedY>y && clickedY<(y+h)) {
      e.preventDefault();
      location.href = coffeeUrl; // TODO make this go to about.html if clicked from index
      // alert('clicked on coffee');
    }
  }
  canvas[0].addEventListener("mousedown", clicked, false);
};

function drawWordCloud(canvas, wordlist, options, maskPath) {
  var maskCanvas = document.createElement('canvas');
  var img = new Image();
  // img.src = maskPath;

  options.list = wordlist.list;

  // load the local image file, read its pixels and transform it into a B&W mask image on the canvas
  // img.onload = function readPixels() {
  // setTimeout(function() {
  var loadImg = function() {
    // maskCanvas = document.createElement('canvas');
    // img.src = maskPath; // TODO why does this help? shouldn't it be set above already?
    maskCanvas.width = img.width+1; // TODO why +1?
    maskCanvas.height = img.height+1; // TODO why +1?
    var ctx = maskCanvas.getContext('2d');
    ctx.drawImage(img, 0, 0, img.width, img.height); // TODO or is the error here?
    var imageData = ctx.getImageData(0, 0, maskCanvas.width, maskCanvas.height); // TODO fix error here
    var newImageData = ctx.createImageData(imageData);
    for (var i = 0; i < imageData.data.length; i += 4) {
      var tone = imageData.data[i] + imageData.data[i + 1] + imageData.data[i + 2];
      var alpha = imageData.data[i + 3];
      if (alpha < 128 || tone > 128 * 3) {
        // area not to draw
        newImageData.data[i] = newImageData.data[i + 1] = newImageData.data[i + 2] = 255;
        newImageData.data[i + 3] = 0;
      } else {
        // area to draw
        newImageData.data[i] = newImageData.data[i + 1] = newImageData.data[i + 2] = 0;
        newImageData.data[i + 3] = 255;
      }
    }
    ctx.putImageData(newImageData, 0, 0);
  };

  var run = function() {
    // options.clearCanvas = false;
    // Determine bgPixel by creating another canvas and fill the specified background color.
    var bctx = document.createElement('canvas').getContext('2d');
    bctx.fillStyle = options.backgroundColor || '#fff';
    bctx.fillRect(0, 0, 1, 1);
    var bgPixel = bctx.getImageData(0, 0, 1, 1).data;
    var maskCanvasScaled = document.createElement('canvas');
    maskCanvasScaled.width = canvas[0].width;
    maskCanvasScaled.height = canvas[0].height;
    var ctx = maskCanvasScaled.getContext('2d');

    ctx.drawImage(maskCanvas,
      0, 0, maskCanvas.width, maskCanvas.height,
      0, 0, maskCanvasScaled.width, maskCanvasScaled.height);

    var imageData = ctx.getImageData(0, 0, 800, 800);
    var newImageData = ctx.createImageData(imageData);
    for (var i = 0; i < imageData.data.length; i += 4) {
      if (imageData.data[i + 3] > 128) {
        newImageData.data[i] = bgPixel[0];
        newImageData.data[i + 1] = bgPixel[1];
        newImageData.data[i + 2] = bgPixel[2];
        newImageData.data[i + 3] = bgPixel[3];
      } else {
        // This color must not be the same w/ the bgPixel.
        newImageData.data[i] = bgPixel[0];
        newImageData.data[i + 1] = bgPixel[1];
        newImageData.data[i + 2] = bgPixel[2];
	// TODO does removing this hurt anything? lets background image show through
        // newImageData.data[i + 3] = bgPixel[3] ? (bgPixel[3] - 1) : 0;
      }
    }
    ctx.putImageData(newImageData, 0, 0);
    ctx = canvas[0].getContext('2d');
    ctx.drawImage(maskCanvasScaled, 0, 0);
    maskCanvasScaled = ctx = imageData = newImageData = bctx = bgPixel = undefined;
    // TODO add htmlCanvas too for some users?
    // always manually clean up the html output
    // if (!options.clearCanvas) {
      // $htmlCanvas.empty();
      // $htmlCanvas.css('background-color', options.backgroundColor || '#fff');
    // }
    // WordCloud([canvas[0], $htmlCanvas[0]], options);
    // setTimeout(()=>{ WordCloud(canvas[0], options);}, 100)
    WordCloud(canvas[0], options);
  };

  // TODO make this less convoluted
  img.onload = function() { loadImg(); run(); };
  img.src = maskPath;
};
