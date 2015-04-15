#Holds all of the saved info about the cover song:
#'LEigs', 'IsRips', 'IsMorse', 'Dists', 'bts', 'SampleDelays', 'Fs', 'TimeLoopHists', 'MFCCs', 'PointClouds'

#Holds a flattened version of PointClouds in a vertex buffer with
#pointers from times within beats to locations within the vertex buffer

#Provides classes to select and draw information about each beat
#in the cover song

from OpenGL.GL import *
from OpenGL.GLU import *
from OpenGL.GLUT import *
from OpenGL.arrays import vbo

import matplotlib
matplotlib.use('WXAgg')
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
from matplotlib.backends.backend_wx import NavigationToolbar2Wx
from matplotlib.figure import Figure
import wx

import wx
from wx import glcanvas
import numpy as np
import scipy
import scipy.io as sio
from scipy.io import wavfile
import scipy.spatial.distance as distance
from pylab import cm

import subprocess

#Constants
DGM1EXTENT = 2.0
MAXGEODESIC = 12
DOWNSAMPLEFAC = 2000

def doCenteringAndPCA(X, ncomponents = 3):
	#Subtract mean
	X = X - np.tile(np.mean(X, 0), (X.shape[0], 1))
	X[np.isinf(X)] = 0
	X[np.isnan(X)] = 0
	#Normalize to sphere
	XNorm = np.sqrt(np.sum(X*X, 1))
	XNorm = XNorm.reshape((len(XNorm), 1))
	XNorm = np.tile(XNorm, (1, X.shape[1]))
	X = X/XNorm
	#Do PCA
	D = (X.T).dot(X)
	(lam, eigvecs) = np.linalg.eig(D)
	lam = np.abs(lam)
	varExplained = np.sum(lam[0:ncomponents])/np.sum(lam)
	#print "2D Var Explained: %g"%(np.sum(lam[0:2])/np.sum(lam))
	eigvecs = eigvecs[:, 0:ncomponents]
	Y = X.dot(eigvecs)
	return (Y, varExplained)

class CoverSongMatching(object):
	def __init__(self, matfilename):
		X = sio.loadmat(matfilename)
		self.beatString1 = X['beatString1'].flatten()
		self.beatString2 = X['beatString2'].flatten()
		self.alignment = X['alignment']
		a = X['alignment']
		#NDNND-DNDD
		#|:||| | ::
		#NANNDAD-RR
		self.match = np.zeros((2, len(a[0])), dtype='int32')
		i1 = 0
		i2 = 0
		for i in range(len(a[0])):
			if a[0][i] == '-':
				self.match[0][i] = -1
				self.match[1][i] = i2
				i2 = i2 + 1
			elif a[1][i] == '-':
				self.match[0][i] = i1
				self.match[1][i] = -1
				i1 = i1 + 1
			else:
				self.match[0][i] = i1
				self.match[1][i] = i2
				i1 = i1 + 1
				i2 = i2 + 1
	
	#Given a beat position in one of the cover songs, find
	#the corresponding position in the other song under
	#this alignment
	def getOtherIdx(self, num, idx):
		i = 0
		for i in range(len(self.match[num])):
			if self.match[num][i] == idx:
				break
		return self.match[1-num][i]
	

#Stores vertex buffers and other information for a cover song
class CoverSong(object):
	def __init__(self, matfilename, soundfilename, num):
		self.num = num #Whether it's the original (0) or the cover (1)
		self.matfilename = matfilename
		self.soundfilename = soundfilename
		
		#Step 1: Load in precomputed beat information
		self.title = matfilename.split('.mat')[0]
		self.title = self.title.split('/')[-1]
		X = sio.loadmat(matfilename)
		self.Fs = float(X['Fs'].flatten()[0])
		self.TimeLoopHists = X['TimeLoopHists'].flatten() #Cell Array
		self.bts = X['bts'].flatten() #1D Matrix
		self.LEigs = X['LEigs'].flatten() #Cell Array
		self.LEigs = X['LEigs'].flatten() #2D Matrix
		self.SampleDelays = X['SampleDelays'].flatten()/self.Fs #Cell array
		self.IsRips = X['IsRips'].flatten() #Cell Array
		self.IsMorse = X['IsMorse'].flatten() #Cell Array
		self.MFCCs = X['MFCCs'] #2D Matrix
		self.PointClouds = X['PointClouds'].flatten()
		self.Dists = X['Dists']
		self.SampleStartTimes = np.zeros(self.SampleDelays.shape[0])
		self.BeatStartIdx = np.zeros(self.SampleDelays.shape[0], dtype='int32')
		self.VarsExplained = np.zeros(self.SampleDelays.shape[0], dtype='int32')		

		for i in range(self.SampleDelays.shape[0]):
			self.SampleDelays[i] = self.SampleDelays[i].flatten()
			self.SampleStartTimes[i] = self.SampleDelays[i][0]
		
		#Sort the DGMs0 by persistence since the birth time doesn't
		#really matter
		IsMorse = []
		for i in range(self.IsMorse.shape[0]):
			if self.IsMorse[i].shape[0] > 0 and self.IsMorse[i].shape[1] > 0:
				P = self.IsMorse[i][:, 1] - self.IsMorse[i][:, 0]
				P = np.sort(P)
				P = P[::-1]
				IsMorse.append(P)
			else:
				IsMorse.append(np.array([0]))
		self.IsMorse = IsMorse
		
		#Step 2: Setup a vertex buffer for this song
		N = self.PointClouds.shape[0]
		if N == 0:
			return
		cmConvert = cm.get_cmap('jet')
		print "Doing PCA on all windows..."
		(self.Y, varExplained) = doCenteringAndPCA(self.PointClouds[0])
		self.VarsExplained
		self.YColors = cmConvert(np.linspace(0, 1, self.Y.shape[0]))[:, 0:3]
		
		for i in range(1, self.PointClouds.shape[0]):
			(Yi, varExplained) = doCenteringAndPCA(self.PointClouds[i])
			self.Y = np.concatenate((self.Y, Yi), 0)
			Colorsi = cmConvert(np.linspace(0, 1, self.PointClouds[i].shape[0]))[:, 0:3]
			self.YColors = np.concatenate((self.YColors, Colorsi), 0)
			self.BeatStartIdx[i] = self.BeatStartIdx[i-1] + Colorsi.shape[0]
		print "Finished PCA"
		
		self.YVBO = vbo.VBO(np.array(self.Y, dtype='float32'))
		self.YColorsVBO = vbo.VBO(np.array(self.YColors, dtype='float32'))
		#TODO: Free vertex buffers when this is no longer used?
		
		#Step 3: Load in the song waveform
		name, ext = os.path.splitext(soundfilename)
		#TODO: Replace this ugly subprocess call with some Python
		#library that understand other files
		if ext.upper() != ".WAV":
			if "temp.wav" in set(os.listdir('.')):
				os.remove("temp.wav")
			subprocess.call(["avconv", "-i", soundfilename, "temp.wav"])
			self.Fs, self.waveform = wavfile.read("temp.wav")
		else:
			self.Fs, self.waveform = wavfile.read(soundfilename)
		if len(self.waveform.shape) > 1 and self.waveform.shape[1] > 1:
			self.waveform = self.waveform[:, 0]
		self.currBeat = 0
		
	def changeBeat(self, dBeat):
		self.currBeat = self.currBeat + dBeat
		if self.currBeat < 0:
			self.currBeat = 0
		if self.currBeat >= len(self.SampleDelays):
			self.currBeat = len(self.SampleDelays) - 1

class CoverSongFilesDialog(wx.Dialog):
	def __init__(self, *args, **kw):
		super(CoverSongFilesDialog, self).__init__(*args, **kw)
		#Remember parameters from last time
		self.matfilename = None
		self.soundfilename = None
		self.InitUI()
		self.SetSize((250, 200))
		self.SetTitle("Load Cover Song Data")

	def InitUI(self):
		vbox = wx.BoxSizer(wx.VERTICAL)
		
		hbox1 = wx.BoxSizer(wx.HORIZONTAL)
		matfileButton = wx.Button(self, label="Choose Mat File")
		self.matfileTxt = wx.TextCtrl(self)
		hbox1.Add(matfileButton)
		hbox1.Add(self.matfileTxt, flag=wx.RIGHT, border=5)

		hbox2 = wx.BoxSizer(wx.HORIZONTAL)
		soundfileButton = wx.Button(self, label='Choose Sound File')
		self.soundfileTxt = wx.TextCtrl(self)
		hbox2.Add(soundfileButton)
		hbox2.Add(self.soundfileTxt, flag=wx.RIGHT, border=5)

		hboxexit = wx.BoxSizer(wx.HORIZONTAL)
		okButton = wx.Button(self, label='Ok')
		closeButton = wx.Button(self, label='Close')
		hboxexit.Add(okButton)
		hboxexit.Add(closeButton, flag=wx.LEFT, border=5)

		vbox.Add(hbox1, 
		flag=wx.ALIGN_CENTER|wx.TOP|wx.BOTTOM, border=10)
		vbox.Add(hbox2, 
		flag=wx.ALIGN_CENTER|wx.TOP|wx.BOTTOM, border=10)
		vbox.Add(hboxexit, 
		flag=wx.ALIGN_CENTER|wx.TOP|wx.BOTTOM, border=10)

		self.SetSizer(vbox)

		okButton.Bind(wx.EVT_BUTTON, self.OnClose)
		closeButton.Bind(wx.EVT_BUTTON, self.OnClose)
		matfileButton.Bind(wx.EVT_BUTTON, self.OnChooseMatfile)
		soundfileButton.Bind(wx.EVT_BUTTON, self.OnChooseSoundfile)
		

	def OnChooseMatfile(self, evt):
		dlg = wx.FileDialog(self, "Choose a file", ".", "", "*", wx.OPEN)
		if dlg.ShowModal() == wx.ID_OK:
			filename = dlg.GetFilename()
			dirname = dlg.GetDirectory()
			filepath = os.path.join(dirname, filename)
			self.matfilename = filepath
			self.matfileTxt.SetValue(filepath)
		dlg.Destroy()
		return

	def OnChooseSoundfile(self, evt):
		dlg = wx.FileDialog(self, "Choose a file", ".", "", "*", wx.OPEN)
		if dlg.ShowModal() == wx.ID_OK:
			filename = dlg.GetFilename()
			dirname = dlg.GetDirectory()
			filepath = os.path.join(dirname, filename)
			self.soundfilename = filepath
			self.soundfileTxt.SetValue(filepath)
		dlg.Destroy()
		return

	def OnClose(self, e):
		self.Destroy()

class CoverSongBeatPlots(wx.Panel):
	def __init__(self, parent):
		wx.Panel.__init__(self, parent)
		self.figure = Figure((5.0, 5.0), dpi = 100)
		
		self.FigDMat = self.figure.add_subplot(221)
		self.FigDists = self.figure.add_subplot(222)
		self.DGM1 = self.figure.add_subplot(223)
		self.DGM0 = self.figure.add_subplot(224)
		
		self.canvas = FigureCanvas(self, -1, self.figure)
		self.sizer = wx.BoxSizer(wx.VERTICAL)
		self.sizer.Add(self.canvas, 1, wx.LEFT | wx.TOP)
		self.SetSizer(self.sizer)
		self.Fit()
		self.coverSong = None
		self.draw()

	def updateCoverSong(self, newCoverSong):
		self.coverSong = newCoverSong
		self.draw()

	def draw(self):
		if self.coverSong:
			if self.coverSong.currBeat >= len(self.coverSong.SampleDelays):
				return
			I1 = self.coverSong.IsRips[self.coverSong.currBeat]
			I0 = self.coverSong.IsMorse[self.coverSong.currBeat]
			EucGeo = self.coverSong.Dists[self.coverSong.currBeat, :]
			
			#Distance matrix
			idx = self.coverSong.BeatStartIdx[self.coverSong.currBeat]
			N = len(self.coverSong.SampleDelays[self.coverSong.currBeat])
			D = distance.squareform(distance.pdist(self.coverSong.Y[idx:idx+N, :]))
			diagVals = np.linspace(np.min(D), np.max(D), N)
			D[np.diag_indices(N)] = diagVals
			self.FigDMat.imshow(D, cmap=matplotlib.cm.jet)
			self.FigDMat.hold(True)
			self.FigDMat.set_title('Euclidean Distance Matrix')
			
			#Bar plot distances
			self.FigDists.cla()
			self.FigDists.bar([0, 1], EucGeo, color='r')
			self.FigDists.set_xticks([0.5, 1.5])
			self.FigDists.set_xticklabels(('Euclid', 'Geodesic'))
			self.FigDists.set_ylim([0, MAXGEODESIC])
			#TODO: Also plot letter here
			self.FigDists.set_title('Distances')
			
			#Plot DGM1
			self.DGM1.cla()
			if I1.shape[0] > 0 and I1.shape[1] > 0:
				self.DGM1.plot(I1[:, 0], I1[:, 1], 'b.')
				self.DGM1.hold(True)
				maxVal = max(np.max(I1) + 0.2, DGM1EXTENT)
				self.DGM1.plot([0, maxVal], [0, maxVal], 'r')
			else:
				self.DGM1.plot([0, DGM1EXTENT], [0, DGM1EXTENT], 'r')
			self.DGM1.set_title('DGM1')
			#Plot DGM0
			self.DGM0.cla()
			if len(I0) > 0:
				self.DGM0.plot(I0)
				self.DGM0.set_xlim([0, 60])
				self.DGM0.set_ylim([0, 1])
				self.DGM0.hold(True)
			self.DGM0.set_title('DGM0')
		self.canvas.draw()

class CoverSongWaveformPlots(wx.Panel):
	def __init__(self, parent):
		wx.Panel.__init__(self, parent)
		self.parent = parent
		self.figure = Figure((10.0, 1.0), dpi=100)
		self.axes = self.figure.add_subplot(111)
		self.canvas = FigureCanvas(self, -1, self.figure)
		self.sizer = wx.BoxSizer(wx.VERTICAL)
		self.sizer.Add(self.canvas, 1, wx.LEFT | wx.TOP | wx.GROW)
		self.SetSizer(self.sizer)
		self.Fit()
		self.coverSong = None
		self.cid = self.canvas.mpl_connect('button_press_event', self.onClick)
		self.draw()

	def updateCoverSong(self, newCoverSong):
		self.coverSong = newCoverSong
		if self.coverSong:
			self.w = self.coverSong.waveform.flatten()
			N = np.ceil( float(len(self.w)) / DOWNSAMPLEFAC) * DOWNSAMPLEFAC
			w = np.zeros(N)
			w[0:len(self.w)] = self.w
			w = w.reshape((N/DOWNSAMPLEFAC, DOWNSAMPLEFAC))
			w = np.mean(w, 1)
			self.w = w
			self.t = np.arange(0, N)/self.coverSong.Fs
			self.t = self.t[0:-1:DOWNSAMPLEFAC]
			self.y0 = np.min(self.w)
			self.y1 = np.max(self.w)
						
			self.draw()

	def draw(self):
		if self.coverSong:
			#Plot waveform
			self.axes.clear()
			self.axes.plot(self.t, self.w, 'b')
			self.axes.hold(True)
			#Plot current marker in song
			time = self.coverSong.SampleStartTimes[self.coverSong.currBeat]
			self.axes.plot(np.array([time, time]), np.array([self.y0, self.y1]), 'g')
			self.axes.set_title(self.coverSong.title)
		self.canvas.draw()
	
	def onClick(self, evt):
		if self.parent.matching:
			#If there is a matching, jump to the matched beat in the other song
			self.coverSong.currBeat = self.parent.matching.getOtherIdx(self.parent.glcanvas.selectedCover.num, self.parent.glcanvas.selectedCover.currBeat)
		elif self.parent.glcanvas.selectedCover:
			#If there is no matching, just go to the exact same position in
			#the other song
			self.coverSong.currBeat = self.parent.glcanvas.selectedCover.currBeat
		self.parent.glcanvas.selectedCover = self.coverSong
		self.parent.updateCover()

if __name__ == '__main__':
	c = CoverSongMatching('CaliforniaLove_Orig_Cover3_NW.mat')
	print c.alignment[0][0:10]
	print c.alignment[1][0:10]
	print c.alignment[2][0:10]
	print c.getOtherIdx(0, 5)
	print c.getOtherIdx(1, 5)
	print c.getOtherIdx(1, 6)
