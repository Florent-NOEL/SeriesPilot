# Get the configuration
$videoConfig = Get-Content -Path "$PSScriptRoot\videoConfig.json" | ConvertFrom-Json
$manualFile = $videoConfig.manualFile
$sendVideoPath = $videoConfig.sendVideoPath
$listSerieLocations = $videoConfig.listSerieLocations
$cmdletLength = $videoConfig.cmdletLength

# open seris or manual
function serie {
    param (
        [string]$cmdlet,
        [string]$season,
        [string]$episode
    )
    [array]$listeSerie = findAllSeries
    [string]$name
    [string]$path
    if ($cmdlet -eq "man") {
        $man = Get-Content -LiteralPath $manualFile
        Write-Output $man
        return
    }
    if (($cmdlet -eq "") -or ($season -eq "") -or ($season -eq "") -or ($cmdlet -eq "ls") -or ($episode -eq "")) {
        Write-Output "use format: serie got s1 1"
        Write-Output "use format: serie shortcut season episode"
        Write-Output $listeSerie | Sort-Object -Property name
        return
    }
    $serieObject = findSerieNameAndPath $cmdlet
    [string]$path = $serieObject.path
    [string]$name = $serieObject.name
    [string]$requestStatus = $serieObject.requestStatus
    Switch ($requestStatus) {     
        "found" {
            $format = findFormat $name $season $episode $path
            $episodeNumber = countEpisode $name $season $path
            if ([int]$episode -gt $episodeNumber) {
                Write-Output "The season has only $episodeNumber episodes."
                return
            }
            Start-Process -Path vlc "$path\$name\$season\$cmdlet-$season-e$episode$format"
        }
        default {
            Write-Output "Invalid location"
        }
    }
}

function mvSerie {
    param(
        [string]$cmdlet,
        [string]$season,
        [string]$name
    )
    [string]$pwd = Get-Location
    #Make the fuction only accessible within the download folder
    if (!($pwd -like "*Downloads*")) {
        Write-Output "The function can be reach only in the Downloads directory"
        return
    }
    if (($cmdlet -eq "") -or ($season -eq "")) {
        Write-Output "use format: mvSerie shortcut season name"
        Write-Output "use format: mvSerie got s1 Game-of-thrones"
        return
    }
    #Controle if the serie already exist
    $serieObject = findSerieNameAndPath $cmdlet
    $requestStatus = $serieObject.requestStatus
    switch ($requestStatus) {
        ("found") {
            if (($serieObject.name -ne $name) -and ($name -ne "")) {
                Write-Output "this shortcut already exist or there is no name for this serie"
                Write-Output "use format: mvSerie shortcut season name"
                return
            }
            $name = $serieObject.name
            if (Test-path -Path "$sendVideoPath\$name\$season") { 
                Write-Output "This season alredy exist, you may use addEpisode instead"
                Write-Output "use format: addEpisode got s1"
                Write-Output "use format: addEpisode shortcut season"
                return
            }
            mkdir "$sendVideoPath\$name\$season"
        }
        ("not found") {
            mkdir "$sendVideoPath\$name"
            mkdir "$sendVideoPath\$name\$season"
        }
    } 
    #Move from present working directory
    $episodeNumber = 1
    sendEpisode $episodeNumber $name $season $cmdlet
}

function season {
    param(
        [string]$cmdlet
    )
    [string]$requestStatus
    [string]$name
    [string]$path 
    $serieObject = findSerieNameAndPath $cmdlet
    [string]$path = $serieObject.path
    [string]$name = $serieObject.name
    [string]$requestStatus = $serieObject.requestStatus
    Switch ($requestStatus) {
        "found" {
        
            $serieDirectory = Get-ChildItem -LiteralPath "$path\$name\"
            $season = [PSCustomObject]@{
                cmdlet = $cmdlet
                name   = $name
                season = $serieDirectory.name.count
            }
            $serieDirectory | Foreach-Object {
                $episodes = Get-ChildItem $_
                $episodes = $episodes.name.count
                Add-Member -NotePropertyMembers @{$_.name = $episodes } -InputObject $season[0]
            }
            return $season
        }
        default {
            Write-Output "Invalid serie shortcut"
        }
    }  
}
#Add episode to an existing season
function addEpisode {
    param(
        [string]$cmdlet,
        [string]$season
    )
    if (($cmdlet -eq "") -or ($season -eq "")) {
        $requestStatus = "ls"
        Write-Output "use format: addEpisode got s1"
        Write-Output "use format: addEpisode shortcut season"
        return
    }
    [string]$pwd = Get-Location
    #Make the fuction only accessible within the download folder
    if (!($pwd -like "*Downloads*")) {
        Write-Output "The function can be reach only in the Downloads directory"
        return
    }
    $serieObject = findSerieNameAndPath $cmdlet
    if ($serieObject.requestStatus -eq "not found") {
        Write-Output "The serie do not exist"
        return
    }
    $path = $serieObject.path
    $name = $serieObject.name
    $requestStatus = $serieObject.requestStatus
    if (!(Test-path -Path "$path\$name\$season")) {
        Write-Output "The saison do not exist"
        return
    }
    $episodeNumber = countEpisode $name $season $path
    $episodeNumber++
    Switch ($requestStatus) {
        "found" {
            sendEpisode $episodeNumber $name $season $cmdlet
        }
        default {
            Write-Output "not found"
        }
    }
    
}
function delSerie {
    param(
        [array]$cmdlets
    )
    if ($cmdlets -eq "") {
        Write-Output "use format: delSerie cmdlet1, cmdlet2..."
    }
    foreach ($cmdlet in $cmdlets) {
        $serieObject = findSerieNameAndPath $cmdlet
        if ($serieObject.requestStatus -eq "not found") {
            Write-Output "The serie do not exist"
            return
        }
        $path = $serieObject.path
        $name = $serieObject.name
        Remove-Item -LiteralPath "$path\$name"
    }  
}


#Boiler plate code
function countEpisode {
    param(
        $name,
        $season,
        $path
    )
    $counter = 0
    $listepisode = Get-ChildItem -LiteralPath "$path\$name\$season"
    foreach ($episode in $listepisode) {
        $counter++
    }
    return $counter
}
function findFormat {
    param(
        $name,
        $season,
        $episode,
        $path
    )
    $listepisode = Get-ChildItem -LiteralPath "$path\$name\$season"
    $formatObject = $listepisode[$episode - 1] | Select-Object Extension
    return $formatObject.Extension
}

function findAllSeries {
    $listSerie = @()
    foreach ($path in $listSerieLocations) {
        $listSerieDirectory = Get-ChildItem -Directory -LiteralPath $path -Exclude "str"
        foreach ($Directory in $listSerieDirectory) {
            $episode1 = Get-ChildItem $Directory | Select-Object -First 1 | Get-ChildItem | Select-Object -First 1 -Property Name
            $cmdlet = $episode1.Name.Substring(0, $cmdletLength)
            $name = $Directory.Name
            $listSerie += [PSCustomObject]@{
                cmdlet = $cmdlet
                name   = $name
                path   = $path
            }
        }  
    }
    return $listSerie
}

function findSerieNameAndPath {
    param(
        $cmdlet
    )
    [string]$requestStatus = "not found"
    [string]$name
    [string]$path
    [array]$listeSerie = findAllSeries
    foreach ($item in $listeSerie) {
        if ($item.cmdlet -eq $cmdlet) {
            $requestStatus = "found"
            $name = $item.name
            $path = $item.path
        }
    }
    return [PSCustomObject]@{
        cmdlet        = $cmdlet
        name          = $name
        path          = $path
        requestStatus = $requestStatus
    }

}

function sendEpisode {
    param(
        $episodeNumber,
        $name,
        $season,
        $cmdlet
    )
    $listepisode = Get-ChildItem -LiteralPath $pwd
    foreach ($episode in $listepisode) {
        $formatObject = $episode | Select-Object Extension
        $format = $formatObject.Extension
        Move-Item -LiteralPath "$episode" "$sendVideoPath\$name\$season\$cmdlet-$season-e$episodeNumber$format"
        Write-Output "$cmdlet-$season-e$episodeNumber$format"
        $episodeNumber++
    }
}
    
Export-ModuleMember -Function serie, mvSerie, season, addEpisode, delSerie, findAllSeries