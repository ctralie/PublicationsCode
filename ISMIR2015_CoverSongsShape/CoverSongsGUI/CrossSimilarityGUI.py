import wx
from wx import glcanvas
from OpenGL.GL import *
from OpenGL.GLU import *
from OpenGL.GLUT import *

import matplotlib
from matplotlib import animation
matplotlib.use('WXAgg')
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
from matplotlib.backends.backend_wx import NavigationToolbar2Wx
from matplotlib.figure import Figure
import wx

import numpy as np
import scipy
import scipy.io as sio
from scipy.io import wavfile

from sys import exit, argv
import os
import math
import time

import pygame

DEFAULT_SIZE = wx.Size(1000, 1000)
DEFAULT_POS = wx.Point(10, 10)
SCROLL_RATE = 0.9

#Using PyOpenGL to help with automatic updating/threading.  SUPER HACKY!
class DummyGLCanvas(glcanvas.GLCanvas):
	def __init__(self, parent, plot):
		attribs = (glcanvas.WX_GL_RGBA, glcanvas.WX_GL_DOUBLEBUFFER, glcanvas.WX_GL_DEPTH_SIZE, 24)
		glcanvas.GLCanvas.__init__(self, parent, -1, attribList = attribs)	
		self.context = glcanvas.GLContext(self)	
		self.plot = plot
		glutInit('')
		glEnable(GL_NORMALIZE)
		glEnable(GL_DEPTH_TEST)
		wx.EVT_PAINT(self, self.processPaintEvent)
	
	def processEraseBackgroundEvent(self, event): pass #avoid flashing on MSW.

	def processPaintEvent(self, event):
		dc = wx.PaintDC(self)
		self.SetCurrent(self.context)
		self.repaint()

	def repaint(self):
		time.sleep(0.2)
		self.plot.draw()
		self.SwapBuffers()
		self.Refresh()

class CrossSimilarityPlot(wx.Panel):
	def __init__(self, parent):
		wx.Panel.__init__(self, parent)
		self.parent = parent
		self.figure = Figure((10.0, 10.0), dpi=100)
		self.axes = self.figure.add_subplot(111)
		self.canvas = FigureCanvas(self, -1, self.figure)
		self.sizer = wx.BoxSizer(wx.VERTICAL)
		self.sizer.Add(self.canvas, 1, wx.LEFT | wx.TOP | wx.GROW)
		self.SetSizer(self.sizer)
		self.Fit()
		self.CSM = np.array([])
		self.Fs = 44100
		self.songnames = ["", ""]
		self.SampleDelays = [np.array([]), np.array([])]
		self.bts = [np.array([]), np.array([])]
		self.MFCCs = [np.array([[]]), np.array([[]])]
		self.drawRange = [0, 1, 0, 1]
		self.drawRadius = 1
		
		#Song Playing info
		self.currSong = 0 #Playing the first or second song? (first is along vertical, second is along horizontal)
		self.currPos = 0 #Position in the distance matrix
		self.startTime = 0
		self.Playing = False
		self.updatingScroll = False
		
		self.cid = self.canvas.mpl_connect('button_press_event', self.OnClick)
		self.canvas.mpl_connect('scroll_event', self.OnScroll)
		
	def updateInfo(self, CSM, Fs, songfilename1, songfilename2, SampleDelays1, SampleDelays2, bts1, bts2, MFCCs1, MFCCs2):
		self.CSM = CSM
		self.drawRange = [0, CSM.shape[0], 0, CSM.shape[1]]
		self.Fs = Fs
		self.songnames = [songfilename1, songfilename2]
		self.SampleDelays = [SampleDelays1, SampleDelays2]
		self.bts = [bts1, bts2]
		self.MFCCs = [MFCCs1, MFCCs2]
		self.currSong = 0
		self.currPos = -1
		self.startTime = 0
		pygame.mixer.init(frequency=self.Fs)
		pygame.mixer.music.load(songfilename1)
		self.draw(True)

	def draw(self, firstTime = False):
		if self.CSM.size == 0:
			return
		thisTime = self.startTime
		if self.Playing:
			thisTime += float(pygame.mixer.music.get_pos()) / 1000.0
		thisPos = self.currPos
		while self.bts[self.currSong][thisPos] < thisTime:
			thisPos = thisPos + 1
			if thisPos == len(self.bts[self.currSong]) - 1:
				break
		
		if thisPos != self.currPos or firstTime:
			self.currPos = thisPos
			self.axes.clear()
			imgplot = self.axes.imshow(self.CSM[self.drawRange[0]:self.drawRange[1], self.drawRange[2]:self.drawRange[3]])
			imgplot.set_interpolation('nearest')
			self.axes.hold(True)
			#Plot current marker in song
			if self.currSong == 0:
				#Horizontal line for first song
				self.axes.plot([0, self.drawRange[3]], [self.currPos-self.drawRange[0], self.currPos-self.drawRange[0]], 'r')
			else:
				#Vertical line for second song
				self.axes.plot([self.currPos-self.drawRange[2], self.currPos-self.drawRange[2]], [0, self.drawRange[1]], 'r')
			self.axes.set_xlim([0, self.drawRange[3]-self.drawRange[2]])
			self.axes.set_ylim([self.drawRange[1]-self.drawRange[0], 0])
		self.canvas.draw()
	
	def OnClick(self, evt):
		if self.CSM.size == 0:
			return
		thisSong = 0
		if evt.button == 1: #TODO: Magic numbers?
			thisSong = 0
		elif evt.button == 2:
			#Reset scrolling to normal
			self.drawRange = [0, self.CSM.shape[0], 0, self.CSM.shape[1]]
			self.drawRadius = 1
			self.draw()
			return
		else:
			thisSong = 1
		if not (thisSong == self.currSong):
			self.currSong = thisSong
			print "\n\nIniting mixer with sampling frequency Fs = %g"%self.Fs
			pygame.mixer.init(frequency=self.Fs)
			pygame.mixer.music.load(self.songnames[self.currSong])
		idx = [0, 0]
		idx[0] = int(math.floor(evt.ydata)) + self.drawRange[0]
		idx[1] = int(math.floor(evt.xdata)) + self.drawRange[2]
		print "Jumping to %g seconds in %s"%(self.bts[self.currSong][idx[self.currSong]], self.songnames[self.currSong])
		self.startTime = self.bts[self.currSong][idx[self.currSong]]
		pygame.mixer.music.play(0, self.startTime)
		self.Playing = True
		self.currPos = idx[self.currSong]
		self.draw()

	def OnScroll(self, evt):
		idx = [0, 0]
		idx[0] = int(math.floor(evt.ydata))
		idx[1] = int(math.floor(evt.xdata))
		
		if evt.step > 0:
			#Zoom in
			self.drawRadius = self.drawRadius*SCROLL_RATE
		else:
			#Zoom out
			self.drawRadius = self.drawRadius/SCROLL_RATE
			if self.drawRadius > 1:
				self.drawRadius = 1
		#Find selected point in original coordinates
		selX = idx[1] + self.drawRange[2]
		selY = idx[0] + self.drawRange[0]
		#Find new window size
		dXWin = int(np.round(self.drawRadius*self.CSM.shape[1]/2.0))
		dYWin = int(np.round(self.drawRadius*self.CSM.shape[0]/2.0))
		d = [selY - dYWin, selY + dYWin, selX - dXWin, selX + dXWin]
		d[0] = max(0, d[0])
		d[1] = min(self.CSM.shape[0], d[1])
		d[2] = max(0, d[2])
		d[3] = min(self.CSM.shape[1], d[1])
		print d
		self.drawRange = d
		self.draw()
		
	def OnPlayButton(self, evt):
		if len(self.bts[0]) == 0:
			return
		self.Playing = True
		if self.currPos == -1:
			self.currPos = 0
		self.startTime = self.bts[self.currSong][self.currPos]
		pygame.mixer.music.play(0, self.startTime)
		self.draw()
	
	def OnPauseButton(self, evt):
		self.Playing = False
		pygame.mixer.music.stop()
		self.draw()

class CrossSimilaritysFrame(wx.Frame):
	(ID_LOADMATRIX) = (1)
	
	def __init__(self, parent, id, title, pos=DEFAULT_POS, size=DEFAULT_SIZE, style=wx.DEFAULT_FRAME_STYLE, name = 'GLWindow'):
		style = style | wx.NO_FULL_REPAINT_ON_RESIZE
		super(CrossSimilaritysFrame, self).__init__(parent, id, title, pos, size, style, name)
		#Initialize the menu
		self.CreateStatusBar()
		
		#Sound variables
		self.Fs = 22050
		
		self.size = size
		self.pos = pos
		
		filemenu = wx.Menu()
		menuLoadMatrix = filemenu.Append(CrossSimilaritysFrame.ID_LOADMATRIX, "&Load Dissimilarity Matrix","Load Dissimilarity Matrix")
		self.Bind(wx.EVT_MENU, self.OnLoadMatrix, menuLoadMatrix)
		
		# Creating the menubar.
		menuBar = wx.MenuBar()
		menuBar.Append(filemenu,"&File") # Adding the "filemenu" to the MenuBar
		self.SetMenuBar(menuBar)  # Adding the MenuBar to the Frame content.

		#The numpy plot that will store the dissimilarity matrix
		self.CSPlot = CrossSimilarityPlot(self)

		#The play/pause buttons		
		buttonRow = wx.BoxSizer(wx.HORIZONTAL)
		playButton = wx.Button(self, label = 'PLAY')
		playButton.Bind(wx.EVT_BUTTON, self.CSPlot.OnPlayButton)
		pauseButton = wx.Button(self, label = 'PAUSE')
		pauseButton.Bind(wx.EVT_BUTTON, self.CSPlot.OnPauseButton)
		buttonRow.Add(playButton, 0, wx.EXPAND)
		buttonRow.Add(pauseButton, 0, wx.EXPAND)		

		self.glcanvas = DummyGLCanvas(self, self.CSPlot)
		self.glcanvas.Refresh()

		self.sizer = wx.BoxSizer(wx.VERTICAL)
		self.sizer.Add(buttonRow, 0, wx.EXPAND)
		self.sizer.Add(self.CSPlot, 0, wx.GROW)
		
		self.SetSizer(self.sizer)
		self.Layout()
		self.Show()

	def OnLoadMatrix(self, evt):
		dlg = wx.FileDialog(self, "Choose a file", ".", "", "*", wx.OPEN)
		if dlg.ShowModal() == wx.ID_OK:
			filename = dlg.GetFilename()
			dirname = dlg.GetDirectory()
			print "Loading %s...."%filename
			filepath = os.path.join(dirname, filename)
			data = sio.loadmat(filepath)
			CSM = data['CSM']
			Fs = data['Fs'].flatten()[0]
			#The sound files need to be in the same directory
			songfilename1 = str(data['songfilename1'][0])
			songfilename2 = str(data['songfilename2'][0])
			SampleDelays1 = data['SampleDelays1'].flatten()
			SampleDelays2 = data['SampleDelays2'].flatten()
			bts1 = data['bts1'].flatten()
			bts2 = data['bts2'].flatten()
			MFCCs1 = data['MFCCs1']
			MFCCs2 = data['MFCCs2']
			self.CSPlot.updateInfo(CSM, Fs, songfilename1, songfilename2, SampleDelays1, SampleDelays2, bts1, bts2, MFCCs1, MFCCs2)
		dlg.Destroy()
		return

if __name__ == "__main__":
	pygame.init()
	app = wx.App()
	frame = CrossSimilaritysFrame(None, -1, 'Cross Similarity GUI')
	frame.Show(True)
	app.MainLoop()
	app.Destroy()
