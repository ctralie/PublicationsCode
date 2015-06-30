#Holds functions to compute PCA on point-centered and sphere-normalized
#beat blocks and to compute self-similarity images
import numpy as np
from pylab import cm
import pygame
import pygame.mixer

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


#Stores point clouds and other information for a cover song
class CoverSongInfo(object):
    def __init__(self, songfilename, MFCCs, SampleDelays, beatIdx, BeatsPerWin):
        self.songfilename = songfilename
        self.title = songfilename.split('.mp3')[0]
        self.title = self.title.split('/')[-1]
        self.SampleDelays = SampleDelays
        self.MFCCs = MFCCs
        self.BeatsPerWin = BeatsPerWin
        self.beatIdx = beatIdx #Indexes from the beats into to the SampleDelays array
        
        #Do PCA on all windows and assign colormaps to each point cloud
        N = len(beatIdx) - BeatsPerWin - 1
        if N == 0:
            return
        self.BeatStartIdx = np.zeros(N)
        cmConvert = cm.get_cmap('jet')
        print "Doing PCA on all windows..."
        P0 = MFCCs[beatIdx[0]:beatIdx[1], :]
        (self.Y, varExplained) = doCenteringAndPCA(P0)
        self.YColors = cmConvert(np.linspace(0, 1, self.Y.shape[0]))[:, 0:3]
        
        for i in range(N):
            P = MFCCs[beatIdx[i]:beatIdx[i+BeatsPerWin]]
            if P.size == 0:
                N = i
                break
            (Yi, varExplained) = doCenteringAndPCA(P)
            self.Y = np.concatenate((self.Y, Yi), 0)
            Colorsi = cmConvert(np.linspace(0, 1, P.shape[0]))[:, 0:3]
            self.YColors = np.concatenate((self.YColors, Colorsi), 0)
            self.BeatStartIdx[i] = self.BeatStartIdx[i-1] + Colorsi.shape[0]
        self.BeatStartIdx = self.BeatStartIdx[0:N]
        print "Finished PCA on %i windows for %s"%(N, self.title)
        
        self.currBeat = 0
        
    def changeBeat(self, newBeat):
        self.currBeat = newBeat
        if self.currBeat < 0:
            self.currBeat = 0
        if self.currBeat >= len(self.SampleDelays) - self.BeatsPerWin - 1:
            self.currBeat = len(self.SampleDelays) - self.BeatsPerWin - 1
