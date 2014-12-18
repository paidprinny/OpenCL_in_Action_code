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
    int sqrtwidth=1000;                                          //TODO: pass this in This is the sqrt of the entire array size. (sqrt(1,000,000) == 1000 )
    int numUnits =250;                                           //TODO: pass this in. This is the number of threads that are requested to be working on this program.         
    uint tid = get_global_id(0);                                 //The id of the device
    int calcI =0;                                                //this will hold the calculated value of i. 
    int iterations=0;                                            //number of iterations
    double temp = 0.0;                                           //temporary value for storage
    bool found_big_change = false;				                 //check if we need to stop.
	int start_row = (sqrtwidth/numUnits)*tid*sqrtwidth;	         //position to start. "row" is conceptual. Needed to multiply by sqrtwidth
	int end_row   = (sqrtwidth/numUnits*sqrtwidth)+start_row;    //row to end on.
	double localArray[6000];                                     //can't figure out how to get the magic number to go away at the moment.
    int loopCounter = 5000;
    if(tid==0 || tid==249)//catch the first and last threads
       loopCounter = 4000;

     /* Okay, let's do this right. Inside the loop, I'm going to pull from global into local,
        and perform all the calculations in local. After 500 runs through, I should have a reasonably
        uniform answer, which will let me incorporate the next processor's row into my data. */
  /* Adding this is going to need me to make specific commands for the first and last thread
     so that they don't overwrite the static value. */  
    while(1)
    {
	    if(tid==0)
           for(int i =0; i<5000; i++)
               localArray[i]=input[i];
        else if(tid==249)
        {
           int r =0;
           for(int i = start_row-sqrtwidth; i<end_row; i++)
               {
                  localArray[r] = input[i];
                  r++;
               }
        }
        else
        {
           int r =0;
	       for(int i= start_row-sqrtwidth; i<end_row+sqrtwidth; i++)
           {
	         localArray[r]= input[i];
             r++;
           }
        }
		barrier(CLK_GLOBAL_MEM_FENCE);
	    found_big_change = false;
	    for(int p =0; p<500; p++)// 500 seems to be a good one.
	    {
	      for(int i = sqrtwidth; i<loopCounter; i++)  // Ignore the first and last "rows" in our local array, they're for access only.'
	         {
	           if(i % 1000 == 0 || (i+1) % 1000 == 0)
			       continue;
	           temp = ( localArray[i-1] + localArray[i+1] + localArray[i+sqrtwidth] + localArray[i-sqrtwidth] ) / 4.0;
	           if( !found_big_change && fabs( ( temp - localArray[i] ) / localArray[i] ) > 1.0E-2 )
	               found_big_change = true;
	        localArray[i] = temp;		
          }
	    }
	  //Placing the barrier here gives better results, takes a bit more time, and oh, let's not forget about the high likelihood of getting so close to zero that zero exists.
	  barrier(CLK_GLOBAL_MEM_FENCE);
	  iterations++;
      if(tid==0)
           for(int i =sqrtwidth; i<4000; i++)
               input[i]=localArray[i];
      else if(tid==249)
      {
           int r =sqrtwidth;
           for(int i = start_row; i<end_row-sqrtwidth; i++)
               {
                  input[i] = localArray[r];
                  r++;
               }
      }
      else
      {
           int r =sqrtwidth;
	       for(int i= start_row; i<end_row; i++)
           {
	         input[i]= localArray[r];
             r++;
           }
      }
	  printf("iteration #%d complete for id %d\n", iterations, tid);
	  if( !found_big_change ) 
      {
         break;
	  }
	}
	for(int i = 0; i<4000; i++) //start at 1000, go to 999000. 
	{
	    calcI = (i*numUnits)+tid;
	    output[calcI] = input[calcI];
	}
}
