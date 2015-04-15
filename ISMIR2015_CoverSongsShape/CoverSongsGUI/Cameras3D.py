from OpenGL.GL import *
from OpenGL.GLU import *
from OpenGL.GLUT import *
import numpy as np
import scipy.linalg as linalg
import math

#This function pushes a matrix onto the stack that puts everything
#in the frame of a camera which is centered at position "P",
#is pointing towards "t", and has vector "r" to the right
#t - towards vector
#u - up vector
#r - right vector
#P - Camera center
def gotoCameraFrame(t, u, r, P):
	rotMat = np.array([ [r[0], u[0], -t[0], 0], [r[1], u[1], -t[1], 0], [r[2], u[2], -t[2], 0], [0, 0, 0, 1] ])
	rotMat = linalg.inv(rotMat)
	transMat = np.array([ [1, 0, 0, -P[0]], [0, 1, 0, -P[1]], [0, 0, 1, -P[2]], [0, 0, 0, 1] ])
	#Translate first then rotate
	mat = rotMat.dot(transMat)
	#OpenGL is column major and mine are row major so take transpose
	mat = mat.T
	glMatrixMode(GL_MODELVIEW)
	glLoadIdentity()
	glMultMatrixd(mat.flatten())

class MousePolarCamera(object):
	#Coordinate system is defined as in OpenGL as a right
	#handed system with +z out of the screen, +x to the right,
	#and +y up
	#phi is CCW down from +y, theta is CCW away from +z
	def __init__(self, pixWidth, pixHeight, yfov = 0.75):
		self.pixWidth = pixWidth
		self.pixHeight = pixHeight
		self.yfov = yfov
		self.center = np.array([0, 0, 0])
		self.R = 1
		self.theta = 0
		self.phi = 0 
		self.updateVecsFromPolar()
	
	def centerOnBBox(self, bbox, theta = -math.pi/2, phi = math.pi/2):
		self.center = np.mean(bbox, 0)
		diagLength = np.sqrt( (bbox[1, :] - bbox[0, :])**2 )
		self.R = diagLength*1.5
		self.theta = theta
		self.phi = phi
		self.updateVecsFromPolar()		

	def centerOnPoints(self, X):
		bbox = np.array( [[np.max(X)], [np.min(X)]] )
		self.centerOnBBox(bbox)

	def updateVecsFromPolar(self):
		[sinT, cosT, sinP, cosP] = [math.sin(self.theta), math.cos(self.theta), math.sin(self.phi), math.cos(self.phi)]
		#Make the camera look inwards
		#i.e. towards is -dP(R, phi, theta)/dR, where P(R, phi, theta) is polar position
		self.towards = np.array([-sinP*cosT, -cosP, sinP*sinT])
		self.up = np.array([-cosP*cosT, sinP, cosP*sinT])
		self.eye = self.center - self.R*self.towards

	def gotoCameraFrame(self):
		gotoCameraFrame(self.towards, self.up, np.cross(self.towards, self.up), self.eye)
	
	def orbitUpDown(self, dP):
		dP = 1.5*dP/float(self.pixHeight)
		self.phi = self.phi+dP
		self.updateVecsFromPolar()
	
	def orbitLeftRight(self, dT):
		dT = 1.5*dT/float(self.pixWidth)
		self.theta = self.theta-dT
		self.updateVecsFromPolar()
	
	def zoom(self, rate):
		rate = rate / float(self.pixHeight)
		self.R = self.R*pow(4, rate)
		self.updateVecsFromPolar()
	
	def translate(self, dx, dy):
		length = np.sqrt((self.center-self.eye)**2)*math.tan(self.yfov);
		dx = length*dx / float(self.pixWidth)
		dy = length*dy / float(self.pixHeight)
		r = np.cross(self.towards, self.up)
		self.center = self.center - dx*r - dy*self.up
		self.updateVecsFromPolar()
