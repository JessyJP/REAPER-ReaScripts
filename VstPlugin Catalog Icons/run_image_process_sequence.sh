#!/bin/sh
python ./Image_Process_Scripts/trim.py 	71 1 2 1 		./Input/ 		 ./Output/VstThumbnails/
python ./Image_Process_Scripts/adjust_colour_balance.py 255 255 255 ./Output/VstThumbnails ./Output/red_shift
REM python ./Image_Process_Scripts/append.py -h 				./Output/Combined 		 ./Output/VstThumbnails 3
python ./Image_Process_Scripts/resize.py 	300 200  		./Output/VstThumbnails/  ./Output/VstThumbnails/
