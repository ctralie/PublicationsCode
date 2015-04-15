//Programmer: Chris Tralie
//Purpose: To implement an implicit version of Smith-Waterman that works on
//a binary dissimilarity matrix
#include <mex.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <iostream>
#include <algorithm>
#include <queue>
#include <list>
#include <vector>
#include <assert.h>

using namespace std;


//Inputs: D (a binary N x M dissimilarity matrix)

//Outputs: 1) Distance (scalar)
//2) (N+1) x (M+1) dynamic programming matrix (Optional)
void mexFunction(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[]) {  
	///////////////MEX INPUTS/////////////////
	const mwSize *dims;
	if (nInArray < 1) {
		mexErrMsgTxt("Error: s1 required\n");
		return;
	}
	dims = mxGetDimensions(InArray[0]);
	int N = (int)dims[0]+1;
	int M = (int)dims[1]+1;
	double* S = (double*)mxGetPr(InArray[0]);
	
	double* D = new double[N*M];
	double matchScore = 2;
	double mismatchScore = -3;
	double gapScore = -2;
	//Don't penalize as much at the beginning
	D[0] = 0;
	for (int i = 1; i < N; i++) {
		D[i] = i*gapScore;
	}
	for (int i = 1; i < M; i++) {
		D[i*N] = i*gapScore;
	}

	//mexPrintf("gapScore = %g, matchScore = %g, mismatchScore = %g\n", gapScore, matchScore, mismatchScore);

	double maxD = 0;
	///////////////ALGORITHM/////////////////
	double d1, d2, d3;
	for (int i = 1; i < N; i++) {
		for (int j = 1; j < M; j++) {
			d1 = D[(i-1)+j*N] + gapScore;
			d2 = D[i+(j-1)*N] + gapScore;
			d3 = D[(i-1)+(j-1)*N];
			d3 += (S[(i-1)+(j-1)*(N-1)] > 0)?matchScore:mismatchScore;
			D[i+j*N] = max(max(max(d1, d2), d3), 0.0);
			if (D[i+j*N] > maxD) {
				maxD = D[i+j*N];
			}
		}
	}
	
	///////////////MEX OUTPUTS/////////////////
	mwSize outdims[2];
	outdims[0] = 1;
	outdims[1] = 1;
	OutArray[0] = mxCreateNumericArray(2, outdims, mxDOUBLE_CLASS, mxREAL);
	double* dist = (double*)mxGetPr(OutArray[0]);
	*dist = maxD;
	
	if (nOutArray > 1) {
		outdims[0] = N;
		outdims[1] = M;
		OutArray[1] = mxCreateNumericArray(2, outdims, mxDOUBLE_CLASS, mxREAL);
		double* DOut = mxGetPr(OutArray[1]);
		memcpy(DOut, D, N*M*sizeof(double));
	}
	
	///////////////CLEANUP/////////////////
	delete[] D;
}
