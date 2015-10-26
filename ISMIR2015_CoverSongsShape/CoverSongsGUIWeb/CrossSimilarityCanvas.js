var CSImage = new Image;
var csmctx;
var offset1 = 0;
var offset1idx = 0;
var offset2 = 0;
var offset2idx = 0;
var playing1 = true;
var playIdxCSM = 0;

//Functions to handle mouse motion
function releaseClickCSM(evt) {
	evt.preventDefault();
	console.log("X = " + evt.offsetX + ", Y = " + evt.offsetY);
	offset1 = bts1[evt.offsetY][1];
	offset1idx = evt.offsetY;
	offset2 = bts2[evt.offsetX][1];
	offset2idx = evt.offsetX;
	playing1 = true;
	if (evt.ctrlKey) {
		playing1 = false;
	}
    if (playing) {
        source.stop();
        if (playing1) {
        	playAudio(1);
        }
        else {
        	playAudio(2);
        }
    }
    else {
    	redrawCSMCanvas();
    }
	return false;
}

function makeClickCSM(evt) {
	evt.preventDefault();
	return false;
}

function clickerDraggedCSM(evt) {
	evt.preventDefault();
	return false;
}

function initCanvasHandlers() {
    var canvas = document.getElementById('CrossSimilarityCanvas');
    canvas.addEventListener('mousedown', makeClickCSM);
    canvas.addEventListener('mouseup', releaseClickCSM);
    canvas.addEventListener('mousemove', clickerDraggedCSM);
    
    canvas.addEventListener('touchstart', makeClickCSM);
    canvas.addEventListener('touchend', releaseClickCSM);
    canvas.addEventListener('touchmove', clickerDraggedCSM);
}

function redrawCSMCanvas() {
	csmctx.drawImage(CSImage, 0, 0);
	csmctx.beginPath();
	if (playing1) {
		csmctx.moveTo(0, offset1idx);
		csmctx.lineTo(CSImage.width, offset1idx);
	}
	else {
		csmctx.moveTo(offset2idx, 0);
		csmctx.lineTo(offset2idx, CSImage.height);
	}
	csmctx.strokeStyle = '#ff0000';
	csmctx.stroke();
}

function updateCSMCanvas() {
	var t = context.currentTime - startTime + offsetTime;
	var bts;
	if (playing1) {
		bts = bts1;
	}
	else {
		bts = bts2;
	}
	while (bts[playIdxCSM][1] < t && playIdxCSM < bts.length - 1) {
		playIdxCSM++;
	}
	if (playing1) {
		offset1idx = playIdxCSM;
	}
	else {
		offset2idx = playIdxCSM;
	}
	redrawCSMCanvas();
	if (playing) {
		requestAnimFrame(updateCSMCanvas);
	}
}
