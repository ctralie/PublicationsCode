import wx
from wx import glcanvas
from OpenGL.GL import *
from OpenGL.GLU import *
from OpenGL.GLUT import *
from OpenGL.arrays import vbo

from sys import exit, argv
import numpy as np
import scipy.io as sio
from scipy.io import wavfile
from pylab import cm
import os
import math
import time

from Cameras3D import *

import matplotlib
matplotlib.use('WXAgg')
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
from matplotlib.backends.backend_wx import NavigationToolbar2Wx
from matplotlib.figure import Figure
import wx

from CoverSongInfo import *

import pygame
import PIL.Image as Image

DEFAULT_SIZE = wx.Size(800, 800)
DEFAULT_POS = wx.Point(10, 10)
CSMNEIGHB = (10, 10)

#GUI element for plotting the self-similarity matrices
class SelfSimilarityPlot(wx.Panel):
    def __init__(self, parent, coverSong):
        wx.Panel.__init__(self, parent)
        self.figure = Figure((5.0, 5.0), dpi = 100)
        
        self.coverSong = coverSong
        self.FigDMat = self.figure.add_subplot(111)
        
        self.currBeat = self.coverSong.currBeat
        self.D = np.zeros((50, 50))
        self.updateD()
        
        self.canvas = FigureCanvas(self, -1, self.figure)
        self.sizer = wx.BoxSizer(wx.VERTICAL)
        self.sizer.Add(self.canvas, 1, wx.LEFT | wx.TOP)
        self.SetSizer(self.sizer)
        self.Fit()
        self.draw()

    def updateD(self):
        #Compute self-similarity image
        idxstart = self.coverSong.BeatStartIdx[self.currBeat]
        idxend = 0
        if self.currBeat < len(self.coverSong.BeatStartIdx) - 1:
            idxend = self.coverSong.BeatStartIdx[self.currBeat+1]
        else:
            idxend = self.coverSong.Y.shape[0]
        Y = self.coverSong.Y[idxstart:idxend, :]
        dotY = np.reshape(np.sum(Y*Y, 1), (Y.shape[0], 1))
        print "Y.shape = ", Y.shape
        self.D = (dotY + dotY.T) - 2*(np.dot(Y, Y.T))

    def draw(self):
        if self.coverSong.currBeat >= len(self.coverSong.SampleDelays):
            return
        if not (self.currBeat == self.coverSong.currBeat):
            self.currBeat = self.coverSong.currBeat
            self.updateD()
            
        self.FigDMat.imshow(self.D, cmap=matplotlib.cm.jet)
        self.FigDMat.hold(True)
        self.FigDMat.set_title("SSM %s"%self.coverSong.title)
        #TODO: Plot moving horizontal line 
        self.canvas.draw()

#GUI element for plotting a subsection of the cross-similarity matrix to help
#user navigate to nearby pixels in the cross-similarity matrix
class CSMSectionPlot(wx.Panel):
    def __init__(self, parent, coverSong1, coverSong2, CSM, idx, glplots):
        wx.Panel.__init__(self, parent)
        self.figure = Figure((5.0, 5.0), dpi = 100)
        
        self.coverSong1 = coverSong1
        self.coverSong2 = coverSong2
        self.CSM = CSM
        self.minC = np.min(CSM)
        self.maxC = np.max(CSM)
        self.idx = idx
        self.glplots = glplots
        self.CSMPlot = self.figure.add_subplot(111)

        self.canvas = FigureCanvas(self, -1, self.figure)
        self.cid = self.canvas.mpl_connect('button_press_event', self.OnClick)
        self.sizer = wx.BoxSizer(wx.VERTICAL)
        self.sizer.Add(self.canvas, 1, wx.LEFT | wx.TOP)
        self.SetSizer(self.sizer)
        self.Fit()
        self.draw()

    def updateIdx(self, idx):
        self.idx = idx
        self.coverSong1.changeBeat(self.idx[0])
        self.coverSong2.changeBeat(self.idx[1])
        for g in self.glplots:
            g.Refresh()
        self.draw()

    def OnClick(self, evt):
        idx = [0, 0]
        idx[0] = int(math.floor(evt.ydata))
        idx[1] = int(math.floor(evt.xdata))
        print "idx = ", idx
        self.updateIdx(idx)

    def draw(self):
        i1 = max(0, self.idx[0] - CSMNEIGHB[0])
        i2 = min(self.CSM.shape[0], self.idx[0] + CSMNEIGHB[0])
        j1 = max(0, self.idx[1] - CSMNEIGHB[1])
        j2 = min(self.CSM.shape[1], self.idx[1] + CSMNEIGHB[1])
        C = self.CSM[i1:i2+1, j1:j2+1]
        self.CSMPlot.cla()
        self.CSMPlot.imshow(C, cmap=matplotlib.cm.jet, interpolation = 'nearest', extent = (j1, j2, i1, i2), vmin = self.minC, vmax = self.maxC)
        self.CSMPlot.hold(True)
        self.CSMPlot.plot(np.array([self.idx[1]]), np.array([self.idx[0]]), 'rx')
        self.canvas.draw()

#GUI Elemetn for plotting the time-ordered point clouds after PCA using OpenGL
class LoopDittyCanvas(glcanvas.GLCanvas):
    def __init__(self, parent, coverSong, SSMPlot):
        attribs = (glcanvas.WX_GL_RGBA, glcanvas.WX_GL_DOUBLEBUFFER, glcanvas.WX_GL_DEPTH_SIZE, 24)
        glcanvas.GLCanvas.__init__(self, parent, -1, attribList = attribs)    
        self.context = glcanvas.GLContext(self)
        
        self.coverSong = coverSong
        self.SSMPlot = SSMPlot
        #Camera state variables
        self.size = self.GetClientSize()
        self.camera = MousePolarCamera(self.size.width, self.size.height)
        
        #Main state variables
        self.MousePos = [0, 0]
        self.initiallyResized = False
        
        self.bbox = np.array([ [1, 1, 1], [-1, -1, -1] ])
        
        #Set up OpenGL vertex buffer for points and colors
        self.YVBO = vbo.VBO(np.array(self.coverSong.Y, dtype='float32'))
        self.YColorsVBO = vbo.VBO(np.array(self.coverSong.YColors, dtype='float32'))
        
        #Point cloud and playing information
        self.DrawEdges = False
        self.Playing = False
        
        self.GLinitialized = False
        #GL-related events
        wx.EVT_ERASE_BACKGROUND(self, self.processEraseBackgroundEvent)
        wx.EVT_SIZE(self, self.processSizeEvent)
        wx.EVT_PAINT(self, self.processPaintEvent)
        #Mouse Events
        wx.EVT_LEFT_DOWN(self, self.MouseDown)
        wx.EVT_LEFT_UP(self, self.MouseUp)
        wx.EVT_RIGHT_DOWN(self, self.MouseDown)
        wx.EVT_RIGHT_UP(self, self.MouseUp)
        wx.EVT_MIDDLE_DOWN(self, self.MouseDown)
        wx.EVT_MIDDLE_UP(self, self.MouseUp)
        wx.EVT_MOTION(self, self.MouseMotion)        
        #self.initGL()
    
    
    def processEraseBackgroundEvent(self, event): pass #avoid flashing on MSW.

    def processSizeEvent(self, event):
        self.size = self.GetClientSize()
        self.SetCurrent(self.context)
        glViewport(0, 0, self.size.width, self.size.height)
        if not self.initiallyResized:
            #The canvas gets resized once on initialization so the camera needs
            #to be updated accordingly at that point
            self.camera = MousePolarCamera(self.size.width, self.size.height)
            self.camera.centerOnBBox(self.bbox, math.pi/2, math.pi/2)
            self.initiallyResized = True

    def processPaintEvent(self, event):
        dc = wx.PaintDC(self)
        self.SetCurrent(self.context)
        if not self.GLinitialized:
            self.initGL()
            self.GLinitialized = True
        self.repaint()

    def repaint(self):
        #Set up projection matrix
        glMatrixMode(GL_PROJECTION)
        glLoadIdentity()
        farDist = 3*np.sqrt(np.sum( (self.camera.eye - np.mean(self.bbox, 0))**2 ))
        nearDist = farDist/50.0
        gluPerspective(180.0*self.camera.yfov/np.pi, float(self.size.x)/self.size.y, nearDist, farDist)
        
        #Set up modelview matrix
        self.camera.gotoCameraFrame()    
        glClearColor(0.0, 0.0, 0.0, 0.0)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
        
        glDisable(GL_LIGHTING)
        glColor3f(1, 0, 0)
        glPointSize(3)

        StartPoint = int(self.coverSong.BeatStartIdx[self.coverSong.currBeat])
        #Find endpoint based on how long sound has been playing
        startTime = self.coverSong.SampleDelays[self.coverSong.beatIdx[self.coverSong.currBeat]] 
        EndTime = startTime + float(pygame.mixer.music.get_pos()) / 1000.0
        EndPoint = StartPoint
        N = 0
        if self.coverSong.currBeat < len(self.coverSong.beatIdx)-1:
            N = self.coverSong.BeatStartIdx[self.coverSong.currBeat+1] - self.coverSong.BeatStartIdx[self.coverSong.currBeat]
        else:
            N = len(self.coverSong.SampleDelays) - self.coverSong.BeatStartIdx[self.coverSong.currBeat]
        N = int(N)
        if self.Playing:
            i = 0
            while self.coverSong.SampleDelays[self.coverSong.beatIdx[self.coverSong.currBeat] + i] < EndTime:
                i = i+1
                EndPoint = EndPoint + 1
                if i >= N - 1:
                    pygame.mixer.music.stop()
                    self.Playing = False
                    break
            self.Refresh()
        else:
            EndPoint = StartPoint + N
        
        self.YVBO.bind()
        glEnableClientState(GL_VERTEX_ARRAY)
        glVertexPointerf( self.YVBO )
        
        self.YColorsVBO.bind()
        glEnableClientState(GL_COLOR_ARRAY)
        glColorPointer(3, GL_FLOAT, 0, self.YColorsVBO)
        
        if self.DrawEdges:
            glDrawArrays(GL_LINES, StartPoint, EndPoint - StartPoint)
            glDrawArrays(GL_LINES, StartPoint+1, EndPoint - StartPoint)
        glDrawArrays(GL_POINTS, StartPoint, EndPoint - StartPoint + 1)
        self.YVBO.unbind()
        self.YColorsVBO.unbind()
        glDisableClientState(GL_VERTEX_ARRAY)
        glDisableClientState(GL_COLOR_ARRAY)
        
        self.SwapBuffers()
        #self.SSMPlot.Refresh()
    
    def initGL(self):        
        glutInit('')
        glEnable(GL_NORMALIZE)
        glEnable(GL_DEPTH_TEST)

    def handleMouseStuff(self, x, y):
        #Invert y from what the window manager says
        y = self.size.height - y
        self.MousePos = [x, y]

    def MouseDown(self, evt):
        x, y = evt.GetPosition()
        self.CaptureMouse()
        self.handleMouseStuff(x, y)
        self.Refresh()
    
    def MouseUp(self, evt):
        x, y = evt.GetPosition()
        self.handleMouseStuff(x, y)
        self.ReleaseMouse()
        self.Refresh()

    def MouseMotion(self, evt):
        x, y = evt.GetPosition()
        [lastX, lastY] = self.MousePos
        self.handleMouseStuff(x, y)
        dX = self.MousePos[0] - lastX
        dY = self.MousePos[1] - lastY
        if evt.Dragging():
            if evt.MiddleIsDown():
                self.camera.translate(dX, dY)
            elif evt.RightIsDown():
                self.camera.zoom(-dY)#Want to zoom in as the mouse goes up
            elif evt.LeftIsDown():
                self.camera.orbitLeftRight(dX)
                self.camera.orbitUpDown(dY)
        self.Refresh()

class CoverSongsFrame(wx.Frame):
    def OnPlayButton1(self, evt):
        C = self.cover1Info
        startTime = C.SampleDelays[C.beatIdx[C.currBeat]] 
        pygame.mixer.music.load(C.songfilename)
        pygame.mixer.music.play(0, startTime)
        self.curve1Canvas.Playing = True
        self.curve2Canvas.Playing = False
        self.curve1Canvas.Refresh()

    def OnPlayButton2(self, evt):
        C = self.cover2Info
        startTime = C.SampleDelays[C.beatIdx[C.currBeat]] 
        pygame.mixer.music.load(C.songfilename)
        pygame.mixer.music.play(0, startTime)
        self.curve2Canvas.Playing = True
        self.curve1Canvas.Playing = False
        self.curve2Canvas.Refresh()

    def __init__(self, parent, id, title, cover1Info, cover2Info, CSM, idx, pos=DEFAULT_POS, size=DEFAULT_SIZE, style=wx.DEFAULT_FRAME_STYLE, name = 'GLWindow'):
        style = style | wx.NO_FULL_REPAINT_ON_RESIZE
        super(CoverSongsFrame, self).__init__(parent, id, title, pos, size, style, name)
        #Initialize the menu
        self.CreateStatusBar()
        
        self.cover1Info = cover1Info
        self.cover2Info = cover2Info
        self.CSM = CSM
        self.idx = idx #The selected position in the cross-similarity matrix
        self.cover1Info.changeBeat(self.idx[0])
        self.cover2Info.changeBeat(self.idx[1])
        
        #Sound variables
        self.Playing = True
        
        self.size = size
        self.pos = pos
        
        
        #Curve and self-similarity row for song 1
        gridSizer = wx.GridSizer(3, 2, 5, 5)
        self.SSM1Canvas = SelfSimilarityPlot(self, cover1Info)
        self.SSM1Canvas.updateD()
        self.curve1Canvas = LoopDittyCanvas(self, cover1Info, self.SSM1Canvas)
        gridSizer.Add(self.curve1Canvas, 1, wx.EXPAND)
        gridSizer.Add(self.SSM1Canvas, 1, wx.EXPAND)
        
        #Curve and self-similarity row for song 2
        self.SSM2Canvas = SelfSimilarityPlot(self, cover2Info)
        self.SSM2Canvas.updateD()
        self.curve2Canvas = LoopDittyCanvas(self, cover2Info, self.SSM2Canvas)
        gridSizer.Add(self.curve2Canvas, 1, wx.EXPAND)
        gridSizer.Add(self.SSM2Canvas, 1, wx.EXPAND)
        
        buttonRow = wx.BoxSizer(wx.VERTICAL)
        playButton1 = wx.Button(self, label = "Play %s"%cover1Info.title)
        buttonRow.Add(playButton1)
        playButton1.Bind(wx.EVT_BUTTON, self.OnPlayButton1)
        playButton2 = wx.Button(self, label = 'Play %s'%cover2Info.title)
        buttonRow.Add(playButton2)
        playButton2.Bind(wx.EVT_BUTTON, self.OnPlayButton2)
        gridSizer.Add(buttonRow, 1, wx.EXPAND)
        
        CSMSection = CSMSectionPlot(self, cover1Info, cover2Info, CSM, idx, [self.curve1Canvas, self.curve2Canvas])
        gridSizer.Add(CSMSection, 1, wx.EXPAND)
        
        self.SetSizer(gridSizer)
        self.Layout()
        self.Show()
