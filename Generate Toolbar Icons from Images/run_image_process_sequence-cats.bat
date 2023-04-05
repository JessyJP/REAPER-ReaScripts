REM # ============ Presetup ==================================
@echo off
cls

REM # ============ Setup: set various paths and settings ==================================

set prefix="./Image-Batch-Processing-Python-Scripts/Image_Process_Scripts"
set input="./Input-Images/FunnyCats"
set output="./Output_Cathalog_Icons"

REM # ============ Cleanup: remove the Output directory and all its contents ==================================
del /s /q %output%\*.*
rmdir /s /q %output%\

REM # ============ Main Sequence ==============================================================================
python %prefix%/convert.py 	%input%/  PNG		 %output%/Converted/
python %prefix%/trim.py 	0 0 0 0 		%output%/Converted/ 		 %output%/Step_1_NoWindowBorders/
python %prefix%/contrast.py  	%output%/Step_1_NoWindowBorders/ 1.05 %output%/Step_2_Contrast
python %prefix%/brightness.py  	%output%/Step_2_Contrast 1.05 %output%/Step_3_Brightness 
python %prefix%/blur.py  	%output%/Step_3_Brightness/  7 %output%/Step_4_Blur/  
python %prefix%/brightness.py  	%output%/Step_4_Blur/ 1.5 %output%/Step_5_Very_Bright

REM python %prefix%/adjust_colour_balance.py 128 128 128 %output%/Step_1_NoWindowBorders %output%/Step2_B

python %prefix%/append.py -ha 	%output%/Step_6_Combined 	%output%/Step_3_Brightness  %output%/Step_5_Very_Bright %output%/Step_4_Blur/
python %prefix%/resize.py 	675 150  	%output%/Step_6_Combined/  	%output%/Final/


