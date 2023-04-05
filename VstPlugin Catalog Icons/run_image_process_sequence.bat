REM # ============ Presetup ==================================
@echo off
cls

REM # ============ Setup: set various paths and settings ==================================

set prefix="./Image-Batch-Processing-Python-Scripts/Image_Process_Scripts"
set input="./Input-Images/VST_pluing_screenshots"
set output="./Output_Cathalog_Icons"

REM # ============ Cleanup: remove the Output directory and all its contents ==================================
del /s /q %output%\*.*
rmdir /s /q %output%\

REM # ============ Main Sequence ==============================================================================
python %prefix%/trim.py 	71 1 2 1 		%input%/ 		 %output%/Step_1_NoWindowBorders/
python %prefix%/contrast.py  	%output%/Step_1_NoWindowBorders/ 1.05 %output%/Step_2_Contrast
python %prefix%/brightness.py  	%output%/Step_2_Contrast 1.05 %output%/Step_3_Brightness 
python %prefix%/blur.py  	%output%/Step_3_Brightness/  7 %output%/Step_4_Blur/  
python %prefix%/brightness.py  	%output%/Step_2_Contrast 3 %output%/Step_5_Very_Bright

REM python %prefix%/adjust_colour_balance.py 128 128 128 %output%/Step_1_NoWindowBorders %output%/Step2_B

python %prefix%/append.py -h 	%output%/Step_6_Combined 	%output%/Step_3_Brightness  %output%/Step_5_Very_Bright %output%/Step_4_Blur/
python %prefix%/resize.py 	900 200  	%output%/Step_6_Combined/  	%output%/Final/


