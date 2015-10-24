var gl;
var glcanvas;

var LOOP_DITTY_CURVE = [[0,0,0,1],[0.172811,0.0691244,0,2],[0.403226,0.241935,0,3],[0.564516,0.581797,0,4],[0.679724,1.05127,0,5],[0.679724,1.37817,0,6],[0.564516,1.61074,0,7],[0.380184,1.70399,0,8],[0.264977,1.56628,0,9],[0.218894,1.12849,0,10],[0.288018,0.805912,0,11],[0.380184,0.460289,0,12],[0.587558,0.137709,0,13],[0.771889,0.0225014,0,14],[1.0023,0.0916259,0,15],[1.07143,0.252916,0,16],[1.11751,0.552455,0,17],[1.2788,0.78287,0,18],[1.46313,0.828953,0,19],[1.62442,0.78287,0,20],[1.73963,0.483331,0,21],[1.71659,0.229875,0,22],[1.53226,0.137709,0,23],[1.20968,0.0916259,0,24],[1.44009,0.0685844,0,25],[1.78571,0.0455429,0,26],[1.99309,0.114667,0,27],[2.17742,0.322041,0,28],[2.26959,0.713746,0,29],[2.43088,0.805912,0,30],[2.73041,0.828953,0,31],[2.93779,0.690704,0,32],[2.93779,0.322041,0,33],[2.82258,0.0455429,0,34],[2.36175,0.114667,0,35],[2.56912,-0.0235815,0,36],[3.09908,-0.0353723,0,37],[3.37558,0.0508983,0,38],[3.49078,0.327396,0,39],[3.51382,0.649977,0,40],[3.55991,0.834308,0,41],[3.7212,0.880391,0,42],[3.92857,0.834308,0,43],[4.06682,0.719101,0,44],[4.1129,0.442603,0,45],[4.08986,0.23523,0,46],[3.95161,0.0969812,0,47],[3.69816,0.00481531,0,48],[3.49078,-0.0412676,0,49],[3.49078,-0.320713,0,50],[3.47531,-0.489134,0,51],[3.51756,-0.739214,0,52],[3.51756,-1.04532,0,53],[3.51756,-1.51522,0,54],[3.5402,-1.29752,0,55],[3.5402,-0.890136,0,56],[3.5402,-0.595912,0,57],[3.5402,-0.369586,0,58],[3.69862,-0.211157,0,59],[4.06075,-0.165892,0,60],[4.26444,-0.165892,0,61],[4.46813,-0.165892,0,62],[4.67183,-0.165892,0,63],[4.85289,-0.143259,0,64],[5.10185,-0.143259,0,65],[5.10185,0.0604343,0,66],[5.19238,0.309393,0,67],[5.23764,0.558352,0,68],[5.4866,0.648883,0,69],[5.6903,0.694148,0,70],[5.89399,0.62625,0,71],[6.05242,0.377291,0,72],[6.05242,0.1057,0,73],[6.02978,-0.0753615,0,74],[5.75819,-0.143259,0,75],[5.37344,-0.120627,0,76],[5.89399,-0.143259,0,77],[6.16558,-0.0979941,0,78],[6.16558,0.377291,0,79],[6.16558,0.762046,0,80],[6.18821,1.03364,0,81],[6.21085,1.46366,0,82],[6.18821,1.84841,0,83],[6.27874,1.5585,0,84],[6.32401,1.24164,0,85],[6.27874,0.76636,0,86],[6.30138,0.381605,0,87],[6.30138,0.0194828,0,88],[6.4598,-0.161578,0,89],[6.6635,-0.161578,0,90],[6.77666,-0.0257825,0,91],[6.82193,0.33634,0,92],[6.84456,0.585299,0,93],[6.86719,0.811625,0,94],[6.95772,0.653196,0,95],[6.95772,0.358972,0,96],[7.00299,0.110013,0,97],[7.04825,-0.0484151,0,98],[7.18405,-0.184211,0,99],[7.31984,-0.138946,0,100],[7.45564,0.0194828,0,101],[7.50091,0.404237,0,102],[7.52354,0.76636,0,103],[7.52354,1.15111,0,104],[7.5688,1.5585,0,105],[7.5688,1.98852,0,106],[7.5688,1.83225,0,107],[7.54617,1.3796,0,108],[7.38774,1.3796,0,109],[7.04825,1.3796,0,110],[7.27458,1.40223,0,111],[7.5688,1.3796,0,112],[7.72723,1.3796,0,113],[7.97619,1.3796,0,114],[7.88566,1.3796,0,115],[7.68197,1.40223,0,116],[7.5688,1.28907,0,117],[7.59144,1.06274,0,118],[7.59144,0.745884,0,119],[7.59144,0.361129,0,120],[7.6367,0.0442722,0,121],[7.68197,-0.159421,0,122],[7.81776,-0.249952,0,123],[8.02146,-0.249952,0,124],[8.20252,-0.249952,0,125],[8.38358,-0.182054,0,126],[8.47411,0.0669049,0,127],[8.51937,0.315864,0,128],[8.58727,0.632721,0,129],[8.6099,1.01748,0,130],[8.6099,1.2438,0,131],[8.6099,1.53803,0,132],[8.63254,1.74172,0,133],[8.65517,2.01331,0,134],[8.65517,1.79938,0,135],[8.65517,1.57305,0,136],[8.49674,1.48252,0,137],[8.24778,1.45989,0,138],[8.40621,1.50516,0,139],[8.6778,1.45989,0,140],[8.8815,1.45989,0,141],[9.10782,1.43726,0,142],[8.97203,1.43726,0,143],[8.72307,1.48252,0,144],[8.6778,1.2562,0,145],[8.70044,0.961972,0,146],[8.65517,0.59985,0,147],[8.6778,0.282993,0,148],[8.6778,0.0340343,0,149],[8.72307,-0.169659,0,150],[8.8136,-0.237557,0,151],[9.03992,-0.282823,0,152],[9.13046,-0.0564962,0,153],[9.15309,0.305626,0,154],[9.17572,0.577218,0,155],[9.26625,0.667748,0,156],[9.35678,0.622483,0,157],[9.37941,0.237728,0,158],[9.40205,0.056667,0,159],[9.42468,-0.237557,0,160],[9.58311,-0.328088,0,161],[9.89996,-0.328088,0,162],[9.99539,-0.221002,0,163],[10.106,0.055496,0,164],[10.106,0.387293,0,165],[10.1613,0.691441,0,166],[10.2442,0.580842,0,167],[10.2995,0.110795,0,168],[10.3272,-0.193352,0,169],[10.3272,-0.580449,0,170],[10.3272,-1.02285,0,171],[10.2719,-1.27169,0,172],[10.106,-1.52054,0,173],[9.96774,-1.55085,0,174],[9.80184,-1.59365,0,175],[9.80184,-1.42151,0,176],[9.91244,-1.17266,0,177],[10.106,-1.03441,0,178],[10.2719,-0.813213,0,179],[10.5207,-0.702614,0,180],[10.8249,-0.536715,0,181],[11.129,-0.343167,0,182]];

var LOADING_CURVE = [[0,0,0,1],[0.346052,0.123809,0,2],[0.771862,0.53719,0,3],[0.989135,1.31422,0,4],[1.09777,2.27308,0,5],[1.07061,3.26853,0,6],[0.85334,3.84774,0,7],[0.52743,3.94723,0,8],[0.473111,3.42663,0,9],[0.50027,2.77481,0,10],[0.608907,2.04151,0,11],[0.690385,1.33537,0,12],[0.771862,0.737872,0,13],[1.09777,0.276166,0,14],[1.39652,0.113211,0,15],[1.69527,0.14037,0,16],[1.77675,0.357643,0,17],[1.83107,0.79219,0,18],[2.18414,1.14526,0,19],[2.45573,1.03662,0,20],[2.64584,0.79219,0,21],[2.673,0.384803,0,22],[2.51005,0.249007,0,23],[2.0755,0.194688,0,24],[1.80391,0.221848,0,25],[2.18414,0.113211,0,26],[2.64584,0.276166,0,27],[3.05323,0.411962,0,28],[3.18903,0.79219,0,29],[3.32482,0.982304,0,30],[3.56926,1.00946,0,31],[3.86801,0.955145,0,32],[3.97664,0.79219,0,33],[4.0038,0.493439,0,34],[3.94948,0.276166,0,35],[3.51494,0.0317335,0,36],[3.10755,0.113211,0,37],[3.4063,0.113211,0,38],[3.89517,0.0860518,0,39],[3.94948,0.0860518,0,40],[4.03096,0.0317335,0,41],[4.16676,-0.0769031,0,42],[4.49267,-0.0610364,0,43],[4.68278,0.0476002,0,44],[4.7371,0.427828,0,45],[4.79142,0.916693,0,46],[5.17165,1.05249,0,47],[5.36176,0.971012,0,48],[5.57903,0.69942,0,49],[5.66051,0.536465,0,50],[5.52471,0.0747594,0,51],[4.92721,-0.00671808,0,52],[4.7371,-0.00671808,0,53],[5.60619,-0.0610364,0,54],[5.76915,0.0476002,0,55],[5.9321,0.37351,0,56],[5.98642,1.05249,0,57],[5.95926,1.92158,0,58],[6.01358,2.98079,0,59],[5.95926,3.49681,0,60],[5.82347,3.84988,0,61],[5.74199,3.38818,0,62],[5.85062,1.35124,0,63],[5.90494,0.590783,0,64],[5.98642,0.346351,0,65],[6.0679,0.183396,0,66],[6.25801,0.183396,0,67],[6.50244,0.292033,0,68],[6.69256,0.672261,0,69],[6.69256,0.916693,0,70],[6.74688,1.32408,0,71],[6.74688,1.32408,0,72],[6.77404,0.672261,0,73],[6.85551,0.346351,0,74],[6.90983,0.156237,0,75],[7.20858,0.156237,0,76],[7.3987,0.237714,0,77],[7.53449,0.617943,0,78],[7.64313,1.35124,0,79],[7.80608,1.35124,0,80],[8.07724,1.31612,0,81],[8.13199,1.29692,0,82],[8.26779,1.18828,0,83],[8.29495,0.943852,0,84],[8.29495,0.617943,0,85],[8.24063,0.210555,0,86],[8.43074,-0.0610364,0,87],[8.70234,0.0747594,0,88],[9.00109,0.590783,0,89],[9.16404,0.862375,0,90],[9.51711,1.18828,0,91],[9.68007,1.21544,0,92],[10.006,1.05249,0,93],[10.2232,0.563624,0,94],[10.3047,-0.0338772,0,95],[10.3047,-0.223991,0,96],[10.2776,0.109852,0,97],[10.1689,0.924627,0,98],[9.84302,1.03326,0,99],[9.54427,1.0061,0,100],[9.08256,0.625876,0,101],[8.94677,0.109852,0,102],[8.94677,-0.324695,0,103],[9.40847,-0.456524,0,104],[9.84302,-0.413802,0,105],[10.1418,-0.332324,0,106],[10.4405,-0.196528,0,107],[10.4405,-0.196528,0,108],[10.4677,-0.46812,0,109],[10.4405,-1.0171,0,110],[10.3862,-1.86193,0,111],[10.1146,-2.61026,0,112],[9.68007,-3.0659,0,113],[9.29984,-3.34804,0,114],[8.97393,-3.32615,0,115],[8.97393,-2.86445,0,116],[9.35416,-2.23979,0,117],[9.62575,-1.80524,0,118],[10.0331,-1.47933,0,119],[10.4677,-1.15342,0,120],[10.7936,-0.88183,0,121],[11.1195,-0.637398,0,122],[11.3368,-0.501602,0,123],[11.6084,-0.257169,0,124]];

var COLORMAP_JET = [0, 0, 0.5625, 0, 0, 0.625, 0, 0, 0.6875, 0, 0, 0.75, 0, 0, 0.8125, 0, 0, 0.875, 0, 0, 0.9375, 0, 0, 1, 0, 0.0625, 1, 0, 0.125, 1, 0, 0.1875, 1, 0, 0.25, 1, 0, 0.3125, 1, 0, 0.375, 1, 0, 0.4375, 1, 0, 0.5, 1, 0, 0.5625, 1, 0, 0.625, 1, 0, 0.6875, 1, 0, 0.75, 1, 0, 0.8125, 1, 0, 0.875, 1, 0, 0.9375, 1, 0, 1, 1, 0.0625, 1, 0.9375, 0.125, 1, 0.875, 0.1875, 1, 0.8125, 0.25, 1, 0.75, 0.3125, 1, 0.6875, 0.375, 1, 0.625, 0.4375, 1, 0.5625, 0.5, 1, 0.5, 0.5625, 1, 0.4375, 0.625, 1, 0.375, 0.6875, 1, 0.3125, 0.75, 1, 0.25, 0.8125, 1, 0.1875, 0.875, 1, 0.125, 0.9375, 1, 0.0625, 1, 1, 0, 1, 0.9375, 0, 1, 0.875, 0, 1, 0.8125, 0, 1, 0.75, 0, 1, 0.6875, 0, 1, 0.625, 0, 1, 0.5625, 0, 1, 0.5, 0, 1, 0.4375, 0, 1, 0.375, 0, 1, 0.3125, 0, 1, 0.25, 0, 1, 0.1875, 0, 1, 0.125, 0, 1, 0.0625, 0, 1, 0, 0, 0.9375, 0, 0, 0.875, 0, 0, 0.8125, 0, 0, 0.75, 0, 0, 0.6875, 0, 0, 0.625, 0, 0, 0.5625, 0, 0, 0.5, 0, 0];

var DelaySeries = [ [] ];

//Playing information
var playIdx = 0;
var playTime = 0;
var startTime = 0;
var offsetTime = 0;
var playing = false;

function initGL(canvas) {
    try {
        gl = canvas.getContext("experimental-webgl");
        gl.viewportWidth = canvas.width;
        gl.viewportHeight = canvas.height;
    } catch (e) {
    }
    if (!gl) {
        alert("Could not initialise WebGL, sorry :-(.  Try a new version of chrome or firefox and make sure your newest graphics drivers are installed");
    }
}


//Type 0: Fragment shader, Type 1: Vertex Shader
function getShader(gl, str, type) {
	var xmlhhtp;
    var shader;
    if (type == 0) {
        shader = gl.createShader(gl.FRAGMENT_SHADER);
    } else if (type == 1) {
        shader = gl.createShader(gl.VERTEX_SHADER);
    } else {
        return null;
    }
	
    gl.shaderSource(shader, str);
    gl.compileShader(shader);

    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        alert(gl.getShaderInfoLog(shader));
        return null;
    }

    return shader;
}


var shaderProgram;

function initShaders() {
	var str = "precision mediump float;\n";
	str = str + "varying vec4 fColor;\n";
	str = str + "void main(void) {\n";
	str = str + "gl_FragColor = fColor;\n";
	str = str + "}\n\n";
    var fragmentShader = getShader(gl, str, 0);
    
    str = "attribute vec3 vPos;\n";
    str = str + "attribute vec4 vColor;\n";
	str = str + "uniform mat4 uMVMatrix;\n";
	str = str + "uniform mat4 uPMatrix;\n";
	str = str + "varying vec4 fColor;\n";
	str = str + "void main(void) {\n";
	str = str + "gl_PointSize = 3.0;\n";
    str = str + "gl_Position = uPMatrix * uMVMatrix * vec4(vPos, 1.0);\n";
    str = str + "fColor = vColor;\n";
	str = str + "}";
    var vertexShader = getShader(gl, str, 1);

    shaderProgram = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);

    if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
        alert("Could not initialise shaders");
    }

    gl.useProgram(shaderProgram);

    shaderProgram.vPosAttrib = gl.getAttribLocation(shaderProgram, "vPos");
    gl.enableVertexAttribArray(shaderProgram.vPosAttrib);

    shaderProgram.vColorAttrib = gl.getAttribLocation(shaderProgram, "vColor");
    gl.enableVertexAttribArray(shaderProgram.vColorAttrib);

    shaderProgram.pMatrixUniform = gl.getUniformLocation(shaderProgram, "uPMatrix");
    shaderProgram.mvMatrixUniform = gl.getUniformLocation(shaderProgram, "uMVMatrix");
}


var mvMatrix = mat4.create();
var mvMatrixStack = [];
var pMatrix = mat4.create();

function mvPushMatrix() {
    var copy = mat4.create();
    mat4.set(mvMatrix, copy);
    mvMatrixStack.push(copy);
}

function mvPopMatrix() {
    if (mvMatrixStack.length == 0) {
        throw "Invalid popMatrix!";
    }
    mvMatrix = mvMatrixStack.pop();
}


function setMatrixUniforms() {
    gl.uniformMatrix4fv(shaderProgram.pMatrixUniform, false, pMatrix);
    gl.uniformMatrix4fv(shaderProgram.mvMatrixUniform, false, mvMatrix);
}


function degToRad(degrees) {
    return degrees * Math.PI / 180;
}

var lastX;
var lastY;
var dragging = false;
var MOUSERATE = 0.005;

//Functions to handle mouse motion
function getMousePos(evt) {
	var rect = glcanvas.getBoundingClientRect();
	return {
		X: evt.clientX - rect.left,
		Y: evt.clientY - rect.top
	};
}

function releaseClick(evt) {
	evt.preventDefault();
	dragging = false;
	return false;
}

function makeClick(evt) {
	evt.preventDefault();
	dragging = true;
	return false;
}

function clickerDragged(evt) {
	evt.preventDefault();
	var mousePos = getMousePos(evt);
	var dx = mousePos.X - lastX;
	var dy = mousePos.Y - lastY;
	lastX = mousePos.X;
	lastY = mousePos.Y;
	if (dragging) {
		self.theta = self.theta - MOUSERATE*dx;
		self.phi = self.phi - MOUSERATE*dy;
		requestAnimFrame(repaint);
	}
	return false;
}


//Variables for polar camera
var theta = -Math.PI/2;
var phi = Math.PI/2;
var camCenter = [0.0, 0.0, 0.0];
var camR = 5.0;

var songVertexVBO;
var songColorVBO;
var times = [];

var pointsVBO = -1;
var colorsVBO = -1;
//Use the information in the Nx4 matrix X to initialize the vertex/color buffers
function initGLBuffers(X) {
	console.log("Initializing buffers...");
    var N = X.length;
    if (N <= 0) {
    	return;
    }
    DelaySeries = X;
    playIdx = N-1;
    playTime = X[X.length-1][3];
    var i = 0;
    var ci = 0;
    var li = 0;
    var ri = 0;
    
    var vertices = [];
    var colors = [];
    times = [];
    
    for (i = 0; i < N; i++) {
    	for (k = 0; k < 3; k++) {
    		vertices.push(X[i][k]);
    	}
    	times.push(X[i][3]);
    	ci = 63.0*(0.1+X[i][3])/(0.1+X[N-1][3]);
    	li = numeric.floor([ci])[0];
    	ri = numeric.ceil([ci])[0];
    	ri = numeric.min([ri], [63])[0];
    	//Linear interpolation for colormap
    	colors.push(COLORMAP_JET[li*3]*(ri-ci) + COLORMAP_JET[ri*3]*(ci-li));//Red
    	colors.push(COLORMAP_JET[li*3+1]*(ri-ci) + COLORMAP_JET[ri*3+1]*(ci-li));//Green
    	colors.push(COLORMAP_JET[li*3+2]*(ri-ci) + COLORMAP_JET[ri*3+2]*(ci-li));//Blue
    	colors.push(1);//Alpha
    }
    
    if (pointsVBO == -1) {
    	pointsVBO = gl.createBuffer();
    }
    gl.bindBuffer(gl.ARRAY_BUFFER, pointsVBO);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
    pointsVBO.itemSize = 3;
    pointsVBO.numItems = N;

	if (colorsVBO == -1) {
    	colorsVBO = gl.createBuffer();
    }
    gl.bindBuffer(gl.ARRAY_BUFFER, colorsVBO);
    gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(colors), gl.STATIC_DRAW);
    colorsVBO.itemSize = 4;
    colorsVBO.numItems = N;
    console.log("Finished initializing buffers");
    
    console.log("Centering camera on curve");
    //Now determine the bounding box of the curve and use
    //that to update the camera info
    var bbox = [vertices[0], vertices[0], vertices[1], vertices[1], vertices[2], vertices[2]];
    for (i = 0; i < N; i++) {
    	if (vertices[i*3] < bbox[0]) {
    		bbox[0] = vertices[i*3];
    	}
    	if (vertices[i*3] > bbox[1]) {
    		bbox[1] = vertices[i*3];
    	}
    	if (vertices[i*3+1] < bbox[2]) {
    		bbox[2] = vertices[i*3+1];
    	}
    	if (vertices[i*3+1] > bbox[3]) {
    		bbox[3] = vertices[i*3+1];
    	}
    	if (vertices[i*3+2] < bbox[4]) {
    		bbox[4] = vertices[i*3+2];
    	}
    	if (vertices[i*3+2] > bbox[5]) {
    		bbox[5] = vertices[i*3+2];
    	}
    }
    var dX = bbox[1] - bbox[0];
    var dY = bbox[3] - bbox[2];
    var dZ = bbox[5] - bbox[4];
    camR = Math.sqrt(dX*dX + dY*dY + dZ*dZ);
    camCenter = [bbox[0] + 0.5*dX, bbox[2] + 0.5*dY, bbox[4] + 0.5*dZ];
    console.log("Finished centering camera");
    
    requestAnimFrame(repaint);   
}


function drawScene() {
    gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight);
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
	
    mat4.perspective(45, 1.5, camR/100.0, camR*2, pMatrix);

    //mat4.identity(mvMatrix);
    var sinT = numeric.sin([theta])[0];
    var cosT = numeric.cos([theta])[0];
    var sinP = numeric.sin([phi])[0];
    var cosP = numeric.cos([phi])[0];
    var T = [-sinP*cosT, -cosP, sinP*sinT];
    var U = [-cosP*cosT, sinP, cosP*sinT];
    var R = [-sinT, 0, -cosT];
    var eye = [camCenter[0] - camR*T[0], camCenter[1] - camR*T[1], camCenter[2] - camR*T[2]];
	rotMat = [[R[0], U[0], -T[0], 0], [R[1], U[1], -T[1], 0], [R[2], U[2], -T[2], 0], [0, 0, 0, 1]];
	rotMat = numeric.transpose(rotMat);
	transMat = [[1, 0, 0, -eye[0]], [0, 1, 0, -eye[1]], [0, 0, 1, -eye[2]], [0, 0, 0, 1]];
	var mvMatrix4x4 = numeric.dot(rotMat, transMat);
	mvMatrix = [];
	var i = 0;
	var j = 0;
	for (i = 0; i < 4; i++) {
		for (j = 0; j < 4; j++) {
			mvMatrix.push(mvMatrix4x4[j][i]);
		}
	}

	if (pointsVBO != -1 && colorsVBO != -1) {
		//Find playing index with a linear search
		//TODO: Improve this to binary search
		while (DelaySeries[playIdx][3] < playTime && playIdx < DelaySeries.length - 1) {
			playIdx++;
		}
		gl.bindBuffer(gl.ARRAY_BUFFER, pointsVBO);
		gl.vertexAttribPointer(shaderProgram.vPosAttrib, pointsVBO.itemSize, gl.FLOAT, false, 0, 0);

		gl.bindBuffer(gl.ARRAY_BUFFER, colorsVBO);
		gl.vertexAttribPointer(shaderProgram.vColorAttrib, colorsVBO.itemSize, gl.FLOAT, false, 0, 0);
		setMatrixUniforms();
		//Draw Points
		gl.drawArrays(gl.POINTS, 0, playIdx+1);
		//Draw Lines
		gl.drawArrays(gl.LINES, 0, playIdx+1);
		gl.drawArrays(gl.LINES, 1, playIdx);
    }
}


function repaint() {
    drawScene();
}

function repaintWithContext(context) {
    if (playing) {
        playTime = context.currentTime - startTime + offsetTime;
        var timeSlider = document.getElementById('timeSlider');
        timeSlider.value = "" + parseInt(""+Math.round(playTime*1000.0/buffer.duration));
        drawScene();
        requestAnimFrame(function(){repaintWithContext(context)});
    }
    else {
        //If paused allow scrolling around
        playTime = offsetTime;
        drawScene();
    }
}


function webGLStart() {
    glcanvas = document.getElementById("LoopDittyGLCanvas");
    glcanvas.addEventListener('mousedown', makeClick);
    glcanvas.addEventListener('mouseup', releaseClick);
    glcanvas.addEventListener('mousemove', clickerDragged);
    
    glcanvas.addEventListener('touchstart', makeClick);
    glcanvas.addEventListener('touchend', releaseClick);
    glcanvas.addEventListener('touchmove', clickerDragged);
    
    initGL(glcanvas);
    initShaders();
    initGLBuffers(LOOP_DITTY_CURVE);

    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.enable(gl.DEPTH_TEST);
	
	requestAnimFrame(repaint);
}
