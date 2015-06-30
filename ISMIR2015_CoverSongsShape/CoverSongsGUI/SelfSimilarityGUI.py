import wx
from wx import glcanvas
from OpenGL.GL import *
from OpenGL.GLU import *
from OpenGL.GLUT import *

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

DEFAULT_SIZE = wx.Size(1200, 800)
DEFAULT_POS = wx.Point(10, 10)

class SelfSimilarityPlot(wx.Panel):
    def __init__(self, parent, coverSong):
        wx.Panel.__init__(self, parent)
        self.figure = Figure((5.0, 5.0), dpi = 100)
        
        self.coverSong = coverSong
        self.FigDMat = self.figure.add_subplot(111)
        
        self.currBeat = self.coverSong.currBeat
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
        if idxstart < len(self.coverSong.BeatStartIdx) - 1:
            idxend = self.coverSong.BeatStartIdx[self.currBeat+1]
        else:
            idxend = self.coverSong.Y.shape[0]
        Y = self.coverSong.Y[idxstart:idxend, :]
        dotY = np.reshape(np.sum(Y*Y, 1), (Y.shape[0], 1))
        self.D = (dotY + dotY.T) - 2*(np.dot(Y, Y.T))

    def draw(self):
        if self.coverSong.currBeat >= len(self.coverSong.SampleDelays):
            return
        if not (self.currBeat == self.coverSong.currBeat):
            self.currBeat = self.coverSong.currBeat
            self.updateD()
            
        self.FigDMat.imshow(self.D, cmap=matplotlib.cm.jet)
        self.FigDMat.hold(True)
        self.FigDMat.set_title('Euclidean Distance Matrix')
        #TODO: Plot moving horizontal line 
        self.canvas.draw()

class LoopDittyCanvas(glcanvas.GLCanvas):
    def __init__(self,  coverSong, SSMPlot):
        attribs = (glcanvas.WX_GL_RGBA, glcanvas.WX_GL_DOUBLEBUFFER, glcanvas.WX_GL_DEPTH_SIZE, 24)
        glcanvas.GLCanvas.__init__(self, -1, attribList = attribs)    
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
        self.DrawEdges = True
        
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

        StartPoint = self.coverSong.BeatStartIdx[self.coverSong.currBeat]
        #Find endpoint based on how long sound has been playing
        startTime = self.coverSong.SampleDelays[self.coverSong.beatIdx[self.coverSong.currBeat]] 
        EndTime = startTime + float(pygame.mixer.music.get_pos()) / 1000.0
        EndPoint = StartPoint
        N = 0
        if self.coverSong.currBeat < len(self.coverSong.beatIdx)-1:
            N = self.coverSong.BeatStartIdx[self.coverSong.currBeat+1] - self.coverSong.BeatStartIdx[self.coverSong.currBeat]
        else:
            N = len(self.coverSong.SampleDelays) - self.coverSong.BeatStartIdx[self.coverSong.currBeat]
        i = 0
        while self.coverSong.SampleDelays[self.coverSong.beatIdx[self.coverSong.currBeat] + i] < EndTime:
            i = i+1
            EndPoint = EndPoint + 1
            if i >= N - 1:
                pygame.mixer.music.stop()
                break
            else:
                self.Refresh()
        
        self.YVBO.bind()
        glEnableClientState(GL_VERTEX_ARRAY)
        glVertexPointerf( self.YVBO )
        
        self.selectedCover.YColorsVBO.bind()
        glEnableClientState(GL_COLOR_ARRAY)
        glColorPointer(3, GL_FLOAT, 0, self.selectedCover.YColorsVBO)
        
        if self.DrawEdges:
            glDrawArrays(GL_LINES, StartPoint, EndPoint - StartPoint)
            glDrawArrays(GL_LINES, StartPoint+1, EndPoint - StartPoint)
        glDrawArrays(GL_POINTS, StartPoint, EndPoint - StartPoint + 1)
        self.selectedCover.YVBO.unbind()
        self.selectedCover.YColorsVBO.unbind()
        glDisableClientState(GL_VERTEX_ARRAY)
        glDisableClientState(GL_COLOR_ARRAY)
        
        self.SwapBuffers()
        self.SSMPlot.draw()
    
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
        pygame.mixer.music.play(0, self.startTime)
        self.curve1Canvas.Refresh()

    def OnPlayButton2(self, evt):
        C = self.cover2Info
        startTime = C.SampleDelays[C.beatIdx[C.currBeat]] 
        pygame.mixer.music.load(C.songfilename)
        pygame.mixer.music.play(0, self.startTime)
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
        
        rows = []
        #Play button for song 1
        row = wx.BoxSizer(wx.HORIZONTAL)
        playButton1 = wx.Button(self, label = 'PLAY')
        row.Add(playButton1)
        playButton1.Bind(wx.EVT_BUTTON, self.OnPlayButton1)
        rows.append(row)
        
        #Curve and self-similarity row for song 1
        row = wx.BoxSizer(wx.HORIZONTAL)
        self.SSM1Canvas = SelfSimilarityPlot(self, cover1Info)        
        self.curve1Canvas = LoopDittyFrame(cover1Info, self.SSM1Canvas)
        row.Add(self.curve1Canvas, 1, wx.LEFT | wx.GROW)
        row.Add(self.SSM1Canvas, 1, wx.LEFT)
        rows.append(row)
        
        #Play button for song 2
        row = wx.BoxSizer(wx.HORIZONTAL)
        playButton2 = wx.Button(self, label = 'PLAY')
        row.Add(playButton2)
        playButton2.Bind(wx.EVT_BUTTON, self.OnPlayButton2)
        rows.append(row)
        
        #Curve and self-similarity row for song 2
        row = wx.BoxSizer(wx.HORIZONTAL)
        self.SSM2Canvas = SelfSimilarityPlot(self, cover2Info)        
        self.curve2Canvas = LoopDittyFrame(cover2Info, self.SSM2Canvas)
        row.Add(self.curve2Canvas, 1, wx.LEFT | wx.GROW)
        row.Add(self.SSM2Canvas, 1, wx.LEFT)
        rows.append(row)
        
        #Add everything to a vertical box sizer    
        self.sizer = wx.BoxSizer(wx.VERTICAL)
        for row in rows:
            self.sizer.Add(row, 0, wx.EXPAND)
        
        self.SetSizer(self.sizer)
        self.Layout()
        self.Show()
