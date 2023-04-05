@echo off
REM # ============ Cleanup: remove the Output directory and all its contents ==================================
cls
del /s /q Output\*.*
rmdir /s /q Output\

prefix="./Image-Batch-Processing-Python-Scripts/Image_Process_Scripts"
input="./VST_pluing_screenshots"
output="./Cathalog_Icons"

REM # ============ Main Sequence ==============================================================================
REM python %prefix%/_trim.py 	71 1 2 1 		%input%/ 		 %output%/Step_1_NoWindowBorders/
REM python %prefix%/_blur.py  	%output%/Step_2_blur/  %output%/Step_1_NoWindowBorders/  10

REM python %prefix%/_adjust_colour_balance.py 0 0 0 %output%/Step_1_NoWindowBorders %output%/Step2_B
REM python %prefix%/_append.py -h 				%output%/Combined 		 %output%/Step_1_NoWindowBorders 3
REM python %prefix%/_resize.py 	300 200  		%output%/Step_1_NoWindowBorders/  %output%/Step_1_NoWindowBorders/


