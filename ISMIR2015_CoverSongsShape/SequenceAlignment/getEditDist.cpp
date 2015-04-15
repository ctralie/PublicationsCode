//http://www.mathworks.com/help/matlab/matlab_external/debugging-c-c-language-mex-files.html

//Programmer: Chris Tralie
//Purpose: To implement variants of edit dist with backtracking
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

#define TYPE_LEVENSHTEIN 1
#define TYPE_NEEDLEMAN_WUNSCH 2

using namespace std;


//Inputs: s1 (1 x N matrix of integers), s2 (1 x M matrix of integers)
//type (1: Levenshtein, 2: Needleman-Wunsch)

//Outputs: 1) Distance (scalar)
//2) Matching (L x 2 matrix of indices) (Optional)
//3) (N+1) x (M+1) dynamic programming matrix (Optional)
void mexFunction(int nOutArray, mxArray *OutArray[], int nInArray, const mxArray *InArray[]) {  
	//Levenshtein Distance by default
	bool minType = true;
	double matchScore = 0;
	double mismatchScore = 2;
	double gapScore = 1;

	///////////////MEX INPUTS/////////////////
	const mwSize *dims;
	if (nInArray < 1) {
		mexErrMsgTxt("Error: s1 required\n");
		return;
	}
	dims = mxGetDimensions(InArray[0]);
	int N = max(dims[0], dims[1]) + 1;
	double* s1 = (double*)mxGetPr(InArray[0]);
	
	if (nInArray < 2) {
		mexErrMsgTxt("Error: s2 required\n");
		return;
	}
	dims = mxGetDimensions(InArray[1]);
	int M = max(dims[0], dims[1]) + 1;
	double* s2 = (double*)mxGetPr(InArray[1]);
	
	if (nInArray < 3) {
		mexErrMsgTxt("Error: type required\n");
		return;
	}
	int type = (int)((double*)mxGetPr(InArray[2]))[0];
	
	double* D = new double[N*M];
	if (type == TYPE_LEVENSHTEIN) {
		//Defaults are correct, just initialize first row
		//and last column to zero
		for (int i = 0; i < N; i++) {
			D[i] = i;
		}
		for (int i = 0; i < M; i++) {
			D[i*N] = i;
		}
	}
	else if (type == TYPE_NEEDLEMAN_WUNSCH) {
		minType = false;
		matchScore = 2;
		mismatchScore = -3;
		gapScore = -2;
		//Don't penalize as much at the beginning
		for (int i = 1; i < N; i++) {
			D[i] = -i;
		}
		for (int i = 1; i < M; i++) {
			D[i*N] = -i;
		}
	}
	else {
		mexErrMsgTxt("Error: Unrecognized type.  Defaulting to Levenshtein distance");
	}

	mexPrintf("gapScore = %g, matchScore = %g, mismatchScore = %g\n", gapScore, matchScore, mismatchScore);

	///////////////ALGORITHM/////////////////
	double d1, d2, d3;
	for (int i = 1; i < N; i++) {
		for (int j = 1; j < M; j++) {
			d1 = D[(i-1)+j*N] + gapScore;
			d2 = D[i+(j-1)*N] + gapScore;
			d3 = D[(i-1)+(j-1)*N];
			d3 += (s1[i-1]==s2[j-1])?matchScore:mismatchScore;
			if (minType) {
				D[i+j*N] = min(min(d1, d2), d3);
				//mexPrintf("(%i, %i), %g + %g, %g + %g, %g + %g:   %g\n", i+1, j+1, D[(i-1)+j*N], gapScore, D[i+(j-1)*N], gapScore, D[(i-1)+(j-1)*N], (s1[i-1]==s2[j-1])?matchScore:mismatchScore, D[i+j*N]);
			}
			else {
				D[i+j*N] = max(max(d1, d2), d3);			
			}
		}
	}
	
	
	///////////////MEX OUTPUTS/////////////////
	mwSize outdims[2];
	outdims[0] = 1;
	outdims[1] = 1;
	OutArray[0] = mxCreateNumericArray(2, outdims, mxDOUBLE_CLASS, mxREAL);
	double* dist = (double*)mxGetPr(OutArray[0]);
	*dist = D[N-1+N*(M-1)];
	
	if (nOutArray > 1) {
		//Recursive backtrace
	}

	if (nOutArray > 2) {
		outdims[0] = N;
		outdims[1] = M;
		OutArray[2] = mxCreateNumericArray(2, outdims, mxDOUBLE_CLASS, mxREAL);
		double* DOut = mxGetPr(OutArray[2]);
		memcpy(DOut, D, N*M*sizeof(double));
	}
	
	///////////////CLEANUP/////////////////
	delete[] D;
}
