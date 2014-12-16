/**********************************************************************
Copyright ©2014 Advanced Micro Devices, Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

•	Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
•	Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
********************************************************************/
//Tinkerer: Bridget Barhight Dec 2014
/*!
 * Sample kernel which multiplies every element of the input array with
 * a constant and stores it at the corresponding output array
 */


__kernel void templateKernel(__global  double * output,
                             __global  double * input
														   )
{
//250 is the number of units.
//starting at 4, and calculating i to i*250 for the right access.
	int sqrtwidth=1000; //TODO: pass this in
	int numUnits =250; //TODO: pass this in.
    uint tid = get_global_id(0);
	printf( " %d ",  tid);
	int calcI =0;
	double temp = 0.0;
	bool found_big_change = false;
	while(1)
	{
	found_big_change = false;
		for(int i = 4; i<3996; i++) //start at 1000, go to 999000. 
		{
			
			 calcI = (i*numUnits)+tid;
			if(calcI%1000 == 0 || (calcI+1) %1000 == 0 || calcI <=sqrtwidth || calcI >=(sqrtwidth*sqrtwidth)-sqrtwidth)
				continue;
			temp = ( input[calcI-1] + input[calcI+1] + input[calcI+sqrtwidth] + input[calcI-sqrtwidth] ) / 4.0;
						if( !found_big_change && fabs( ( temp - input[calcI] ) / input[calcI] ) > 1.0E-2 ) {
							found_big_change = true;
						}
						input[calcI] = temp;
			
			
        }
		if( !found_big_change ) {
            break;
		}
	}
		for(int i = 4; i<3996; i++) //start at 1000, go to 999000. 
		{
			calcI = (i*numUnits)+tid;
			output[calcI] = input[calcI];
		}
}
