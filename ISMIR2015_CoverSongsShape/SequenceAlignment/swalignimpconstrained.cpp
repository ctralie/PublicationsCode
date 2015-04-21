//Programmer: Chris Tralie
//Purpose: To implement an implicit version of Smith-Waterman that works on
//a binary dissimilarity matrix, with local constraints added as described in
//"Chroma Binary Similarity And Local Alignment Applied To Cover Song Identification"
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

double Delta(double a, double b) {
	double gapOpening = -0.5; //Parameters used in the paper
	double gapExtension = -0.7;
	if (b > 0) {
		return 0;
	}
	if (b == 0 && a > 0) {
		return gapOpening;
	}
	return gapExtension;
}

double Match(double i) {
	double matchScore = 1;
	double mismatchScore = -1;
	if (i == 0) {
		return mismatchScore;
	}
	return matchScore;
}

//Inputs: D (a binary N x M cross-similarity matrix)

//Outputs: 1) Distance (scalar)
//2) (N+1) x (M+1) dynamic programming matrix (Optional)
void mexFunction(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[]) {  
	///////////////MEX INPUTS/////////////////
	const mwSize *dims;
	if (nInArray < 1) {
		mexErrMsgTxt("Error: D required\n");
		return;
	}
	dims = mxGetDimensions(InArray[0]);
	int N = (int)dims[0]+1;
	int M = (int)dims[1]+1;
	if (N < 4 || M < 4) {
		double* score = (double*)mxGetPr(OutArray[0]);
		*score = 0;
	}
	double* S = (double*)mxGetPr(InArray[0]);
	
	double* D = new double[N*M];

	
	//Don't penalize as much at the beginning
	for (int k = 0; k < 3; k++) {
		//Initialize first 3 columns to zero
		for (int i = 0; i < N; i++) {
			D[i+k*N] = 0;
		}
		//Initialize first 3 rows to zero
		for (int i = 0; i < M; i++) {
			D[k+i*N] = 0;
		}
	}

	double maxD = 0;
	///////////////ALGORITHM/////////////////
	double d1, d2, d3;
	for (int i = 3; i < N; i++) {
		for (int j = 3; j < M; j++) {
			double MS = Match(S[(i-1)+(j-1)*(N-1)]);
			//H_(i-1, j-1) + S_(i-1, j-1) + delta(S_(i-2,j-2), S_(i-1, j-1))
			d1 = D[(i-1)+(j-1)*N] + MS + Delta(S[(i-2)+(j-2)*(N-1)], S[(i-1)+(j-1)*(N-1)]);
			//H_(i-2, j-1) + S_(i-1, j-1) + delta(S_(i-3, j-2), S_(i-1, j-1))
			d2 = D[(i-2)+(j-1)*N] + MS + Delta(S[(i-3)+(j-2)*(N-1)], S[(i-1)+(j-1)*(N-1)]);
			//H_(i-1, j-2) + S_(i-1, j-1) + delta(S_(i-2, j-3), S_(i-1, j-1))
			d3 = D[(i-1)+(j-2)*N] + MS + Delta(S[(i-2)+(j-3)*(N-1)], S[(i-1)+(j-1)*(N-1)]);
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
	double* score = (double*)mxGetPr(OutArray[0]);
	*score = maxD;
	
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
