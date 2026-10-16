@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
cd /d E:\Linkbar\src
msbuild Linkbar.dproj /t:Build /p:Config=Release /p:Platform=Win64 /p:DCC_ExeOutput=E:\Linkbar\src\IA\TMP\out /p:DCC_DcuOutput=E:\Linkbar\src\IA\TMP\dcu /v:minimal
