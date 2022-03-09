#ps1_sysnative

$ProgressPreference = 'SilentlyContinue'

$7zip_download_url = "https://www.7-zip.org/a/7z2107-x64.exe"
$driver_url = "https://us.download.nvidia.com/tesla/511.65/511.65-data-center-tesla-desktop-winserver-2016-2019-2022-dch-international.exe"

if(![System.IO.File]::Exists("C:\Windows\Temp\nvidia_driver.exe")){
    Invoke-WebRequest -Uri $driver_url -OutFile C:\Windows\Temp\nvidia_driver.exe
    }

if(![System.IO.File]::Exists("C:\Windows\Temp\7z2107-x64.exe")){
    Invoke-WebRequest -Uri $7zip_download_url -OutFile C:\Windows\Temp\7z2107-x64.exe
    C:\Windows\Temp\7z2107-x64.exe /S /D="C:\Windows\Temp\7-Zip"
    }
Start-Sleep -s 10

if(![System.IO.Directory]::Exists("C:\Windows\Temp\nvidia\")){
    C:\Windows\Temp\7-Zip\7z.exe x -aou -oC:\Windows\Temp\nvidia -y C:\Windows\Temp\nvidia_driver.exe
    }
    
Start-Sleep -s 10

if(![System.IO.Directory]::Exists("C:\Program Files\NVIDIA Corporation\")){
    C:\Windows\Temp\nvidia\setup.exe -s -noreboot -clean -noeula -passive
    } 
