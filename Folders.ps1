        #region FOLDERS4

       $ufolders = @('c:\windows\ccmcache','c:\windows\temp','C:\Windows\WinSxS','c:\windows\softwaredistribution\download')
       $ufolders += (Get-ChildItem -Path c:\users -Directory).FullName
       $ufarray = @()
       foreach ($folder in $ufolders){
            $frn = new-object -TypeName PSObject
            $frn | Add-Member -MemberType NoteProperty -Name "Folder" -Value $folder -Force
            $frn | Add-Member -MemberType NoteProperty -Name "Size" -Value $(Get-RoboSize $folder).TotalGB -Force
            $ufarray += $frn
       }
       [System.Collections.ArrayList]$folderArrayList = $ufArray
       #endregion FOLDERS 
