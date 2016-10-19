//Variables for songs and features
var dim = 200;
var BeatsPerBlock = 12;
var songfilename1 = "";
var songfilename2 = "";
var tempobias1 = 120;
var tempobias2 = 120;
var MFCCs1 = [[]];
var bts1 = [];
var MFCCs2 = [[]];
var bts2 = [];

//Variables for SSM canvases
var ssm1ctx;
var ssm2ctx;

function getBlockPCAAndSSM(MFCCs, bts, idx) {
    //Step 1: Copy over MFCC windows in this block to a temporary array
    var i1 = bts[idx][0];
    var i2 = bts[idx+BeatsPerBlock][0];
    var i = 0;
    var j = 0;
    var k = 0;
    var N = (i2-i1)+1;
    console.log("N = " + N);
    var K = MFCCs[0].length-1;
    var X = numeric.rep([N, K]);
    for (i = 0; i < N; i++) {
        for (k = 1; k < K+1; k++) {
            X[i][k-1] = MFCCs[i1+i][k];
        }
    }
    
	//Step 2: Compute and subtract off mean
	var mean = numeric.rep([K], 0);
	for (i = 0; i < N; i++) {
		for (k = 0; k < K; k++) {
			mean[k] += X[i][k];
		}
	}
	for (i = 0; i < N; i++) {
		for (k = 0; k < K; k++) {
			X[i][k] -= mean[k]/N;
		}
	}
	
	//Step 3: Scale each row so that it has unit norm
	var rNorm = 1.0;
	for (i = 0; i < N; i++) {
	    rNorm = numeric.norm2(X[i]);
		for (k = 0; k < K; k++) {
			X[i][k] /= rNorm;
		}
	}	
	
/*	//Step 4: Do PCA
	B = numeric.dot(numeric.transpose(X), X);
	E = numeric.eig(B).E.x;
	X = numeric.dot(X, E);
	
	//Step 5: Store the first 3 principal components, and make the 4th
	//component the time of occurrence
	Y = numeric.rep([N, 4], 0);
	for (i = 0; i < N; i++) {
		for (k = 0; k < 3; k++) {
			Y[i][k] = X[i][k];
		}
		Y[i][3] = MFCCs[i1+i];
	}*/
	
	//Step 6: Compute the self-similarity matrix
	var norm = numeric.rep([N], 0);
	for (i = 0; i < N; i++) {
	    norm[i] = numeric.norm2(X[i]);
	    norm[i] = norm[i]*norm[i];
	}
	norm = numeric.rep([N], norm);
	D = numeric.add(norm, numeric.transpose(norm));
	D = numeric.add(D, numeric.mul(-2, numeric.dot(X, numeric.transpose(X))));
	console.log("Finished computing " + D.length + " x " + D[0].length + " SSM");
	return D
}

//TODO: http://stackoverflow.com/questions/24429830/html5-canvas-how-to-change-putimagedata-scale
function makeSSMImage(ctx, D, cmap) {
	console.log("Making SSM image...");
	var H = D.length;
	var W = D[0].length;
	var im = ctx.createImageData(W, H);
	var L = cmap.length/3;
	
	var minV = 0.0;
	var maxV = 10.0;
	//Apply interpolated colormap
	var idx = 0;
	//var ci = numeric.round(numeric.mul((L/maxV), numeric.add(-minV, D)));
	var ci = numeric.round(numeric.mul((255/maxV), numeric.add(-minV, D)));
	for (i = 0; i < H; i++) {
		for (j = 0; j < W; j++) {
			//Linear interpolation for colormap
			im.data[idx] = 255*cmap[ci[i][j]*3]; idx++;//Red
			im.data[idx] = 255*cmap[ci[i][j]*3+1]; idx++;//Green
			im.data[idx] = 255*cmap[ci[i][j]*3+2]; idx++//Blue
			im.data[idx] = 255; idx++;//Alpha
//			im.data[idx] = ci[i][j]; idx++;//Red
//			im.data[idx] = ci[i][j]; idx++;//Green
//			im.data[idx] = ci[i][j]; idx++//Blue
//			im.data[idx] = 255; idx++;//Alpha
		}
	}
	ctx.putImageData(im, 0, 0, 0, 0, 400, 400);
	console.log("Finished making SSM image");
}
