# MIT License
#
# Copyright © 2022 Steve Sinchak
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial
# portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
# TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

##############################################################
### NetCheck Version .1                                    ###
### Public Repo: https://github.com/stevesinchak/NetCheck/ ###
##############################################################

# Script Variables
$CurrentPath=$PSScriptRoot
$RemoteHostTest="google.com"
$RemoteHostTestQty=10
$RemoteHostTestDelay=1 # Measured in Seconds
$LocalGatewayTestQty=10
$LocalGatewayTestDelay=1 # Measured in Seconds
$WriteLogToFile=$true
$LogFilePath="$CurrentPath\log.txt"
$SpeedTestDownloadURL="https://install.speedtest.net/app/cli/ookla-speedtest-1.1.1-win64.zip"

# Minimum Acceptable Criteria
$SpeedTestDownloadMinimum=50 # Measured in Mbps
$SpeedTestUploadMinimum=5 # Measured in Mbps
$AcceptableLocalPacketLoss=0 # Measured in %
$AcceptableLocalLatency=5 # Measured in milliseconds
$AcceptableLocalJitter=5 # Measured in milliseconds
$AcceptableRemotePacketLoss=0 # Measured in %
$AcceptableRemoteLatency=20 # Measured in milliseconds
$AcceptableRemoteJitter=10 # Measured in milliseconds

# Do not modify - Internal variable to tracks if any minimum acceptable criteria is not met
$HealthyConnection=$true

###########################################################################################################
### Logging helper function (Log-Item "message" "Green")                                                ###
### Parameters:                                                                                         ###
###  $message = Mandatory, what you want displayed on screen and in file if file logging is enabled     ###
###  $Color = Defaults to "White", but a PowerShell color can be passed to alter text display on screen ###
###########################################################################################################

function Log-Item {

    param (
        [Parameter(Mandatory)]
        [string]$Message,
   
        $Color = "White"
    )

    $DateTime=Get-Date

    if ($Message -eq '-')
    {
        $Message="~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        Write-Host "$Message" -ForegroundColor Blue
    }
    else {
        Write-Host "$DateTime - " -ForegroundColor "White" -NoNewLine
        Write-Host "$Message" -ForegroundColor $Color
    }

    # Optional write log to file
    if ($WriteLogToFile)
    {
        "$DateTime - $Message" | Out-File -FilePath $LogFilePath -Append 
    } 

}
#########################
### Main Script Start ###
#########################
Log-Item "-"
Log-Item "Starting up NetCheck" "Yellow"
Log-Item "-"

# Get local client IP
$LocalIP=Get-Netipaddress -AddressFamily IPv4 -InterfaceAlias Ethernet* | Select-Object -ExpandProperty "IPAddress"

# Get default gateway
$LocalGatewayIP=Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -ExpandProperty "NextHop"

Log-Item "Client Local IP address: $LocalIP"
Log-Item "Client Local Gateway: $LocalGatewayIP"
Log-Item "-"

################################################################
### Test client to local router to find local network issues ###
################################################################

$TestDuration=$LocalGatewayTestQty*$LocalGatewayTestDelay
Log-Item "Testing client to local router connection (this test will take about $TestDuration seconds)..." "Yellow"
Log-Item "[PC]<-----Local Network----->[Router]" "Cyan"

$LocalLatencyTestResult=Test-Connection $LocalGatewayIP -Count $LocalGatewayTestQty -Delay $LocalGatewayTestDelay
$LocalLatencyTestResultCalculations=$LocalLatencyTestResult | Measure-Object -Property ResponseTime -Minimum -Maximum -Average
$LocalLatencyAverage=$LocalLatencyTestResultCalculations | Select-Object -ExpandProperty "Average"
$LocalLatencyMinimum=$LocalLatencyTestResultCalculations | Select-Object -ExpandProperty "Minimum"
$LocalLatencyMaximum=$LocalLatencyTestResultCalculations | Select-Object -ExpandProperty "Maximum"
$LocalPacketLossPercentage=100-(($LocalLatencyTestResult.ResponseTime.Count/$LocalGatewayTestQty)*100)

# Calculating jitter (deviation between pings) for additional quality measure
$LatencyDifferenceTotal=0
for ($x=0;$x -lt $LocalLatencyTestResult.ResponseTime.Count-1;$x++)
{
    $L1=$LocalLatencyTestResult[$x].ResponseTime
    $L2=$LocalLatencyTestResult[$x+1].ResponseTime
    $CalculatedDifference=0
    if (($null -ne $L1) -or ($null -ne $L2))
    {
        $CalculatedDifference=[Math]::Abs($L1-$L2)
    }

    $LatencyDifferenceTotal += $CalculatedDifference
}
$LocalJitter=$LatencyDifferenceTotal/$LocalLatencyTestResult.ResponseTime.Count

Log-Item "Local Average Latency: $LocalLatencyAverage ms"
Log-Item "Local Minimum Latency: $LocalLatencyMinimum ms"
Log-Item "Local Maximum Latency: $LocalLatencyMaximum ms"
Log-Item "Local Packet Loss: $LocalPacketLossPercentage %"
Log-Item "Local Jitter: $LocalJitter ms"

# Check for maximum threshold violations
if ($LocalLatencyAverage -gt $AcceptableLocalLatency) { 
    Log-Item "LOCAL NETWORK ISSUE - Average Latency is too high indicating poor network condition!" "Red"
    $HealthyConnection=$false
}
if ($LocalLatencyMinimum -gt $AcceptableLocalLatency) { 
    Log-Item "LOCAL NETWORK ISSUE - Minimum Latency is too high indicating poor network condition!" "Red"
    $HealthyConnection=$false
}
if ($LocalLatencyMaximum -gt $AcceptableLocalLatency) { 
    Log-Item "LOCAL NETWORK ISSUE - Maximum Latency is too high indicating poor network condition!" "Red"
    $HealthyConnection=$false
}
if ($LocalPacketLossPercentage -gt $AcceptableLocalPacketLoss) { 
    Log-Item "LOCAL NETWORK ISSUE - Packet loss is detected indicating poor network condition!" "Red"
    $HealthyConnection=$false
}
if ($LocalJitter -gt $AcceptableLocalJitter) { Log-Item "LOCAL NETWORK ISSUE - Network jitter is too high indicating poor network condition!" "Red"
    $HealthyConnection=$false
}

Log-Item "-"

##############################################################################
### Test client to local router and out to the Internet to find ISP issues ###
##############################################################################

$TestDuration=$RemoteHostTestQty*$RemoteHostTestDelay
Log-Item "Testing client to local router and out to the remote Internet host (this test will take about $TestDuration seconds)..." "Yellow"
Log-Item "[PC]<-----Local Network----->[Router]<-----Internet Network----->[Remote Host]" "Cyan"

$RemoteLatencyTestResult=Test-Connection $RemoteHostTest -Count $RemoteHostTestQty -Delay $RemoteHostTestDelay
$RemoteLatencyTestResultCalculations=$RemoteLatencyTestResult | Measure-Object -Property ResponseTime -Minimum -Maximum -Average
$RemoteLatencyAverage=$RemoteLatencyTestResultCalculations | Select-Object -ExpandProperty "Average"
$RemoteLatencyMinimum=$RemoteLatencyTestResultCalculations | Select-Object -ExpandProperty "Minimum"
$RemoteLatencyMaximum=$RemoteLatencyTestResultCalculations | Select-Object -ExpandProperty "Maximum"
$RemotePacketLossPercentage=100-(($RemoteLatencyTestResult.ResponseTime.Count/$RemoteHostTestQty)*100)

# Calculating jitter (deviation between pings) for additional quality measure
$LatencyDifferenceTotal=0
for ($x=0;$x -lt $RemoteLatencyTestResult.ResponseTime.Count-1;$x++)
{
    $L1=$RemoteLatencyTestResult[$x].ResponseTime
    $L2=$RemoteLatencyTestResult[$x+1].ResponseTime
    $CalculatedDifference=0
    if (($null -ne $L1) -or ($null -ne $L2))
    {
        $CalculatedDifference=[Math]::Abs($L1-$L2)
    }

    $LatencyDifferenceTotal += $CalculatedDifference
}
$RemoteJitter=$LatencyDifferenceTotal/$RemoteLatencyTestResult.ResponseTime.Count

Log-Item "Remote Average Latency: $RemoteLatencyAverage ms"
Log-Item "Remote Minimum Latency: $RemoteLatencyMinimum ms"
Log-Item "Remote Maximum Latency: $RemoteLatencyMaximum ms"
Log-Item "Remote Packet Loss: $RemotePacketLossPercentage %"
Log-Item "Remote Jitter: $RemoteJitter ms"

# Check for maximum threshold violations
if ($RemoteLatencyAverage -gt $AcceptableRemoteLatency) { 
    Log-Item "INTERNET CONNECTION ISSUE - Average Latency is too high indicating poor network condition!" "Red"
    $HealthyConnection=$false
}
if ($RemoteLatencyMinimum -gt $AcceptableRemoteLatency) { 
    Log-Item "INTERNET CONNECTION ISSUE - Minimum Latency is too high indicating poor network condition!" "Red"
    $HealthyConnection=$false
}
if ($RemoteLatencyMaximum -gt $AcceptableRemoteLatency) { 
    Log-Item "INTERNET CONNECTION ISSUE - Maximum Latency is too high indicating poor network condition!" "Red"
    $HealthyConnection=$false
}
if ($RemotePacketLossPercentage -gt $AcceptableRemotePacketLoss) { 
    Log-Item "INTERNET CONNECTION ISSUE - Packet loss is detected indicating poor network condition!" "Red"
    $HealthyConnection=$false
}
if ($RemoteJitter -gt $AcceptableRemoteJitter) { 
    Log-Item "INTERNET CONNECTION ISSUE - Network jitter is too high indicating poor network condition!" "Red"
    $HealthyConnection=$false
}

Log-Item "-"

#####################################################################################
### Grab trace route to remote test host for advanced ISP routing troubleshooting ###
#####################################################################################
Log-Item "Running trace route to remote test host... (this can take more than 30 seconds)" "Yellow"
$TraceRoute = &TRACERT.EXE $RemoteHostTest
foreach($Route in $TraceRoute)
{
        Log-Item "$Route "
}

######################################################################
### Run Internet speed test and check against minimum requirements ###
######################################################################

Log-Item "-"
Log-Item "Running Speedtest.net Bandwidth Test... (this usually takes around 30 seconds)" "Yellow"

# Download and extract SpeedTest.Net CLI Tool if it does not already exist in PWD
if (-Not (Test-Path -Path $CurrentPath\speedtest.exe -PathType Leaf))
{
    Log-Item "Downloading and extracting Speedtest.net CLI tool because it does not already exist"
    Invoke-WebRequest -Uri $SpeedTestDownloadURL -OutFile $CurrentPath\speedtest_temp.zip
    Expand-Archive -Path speedtest_temp.zip -DestinationPath $CurrentPath
    Remove-Item $CurrentPath\speedtest_temp.zip # Clean up temp download zip
}

# Run speedtest cli and export results in json. Then convert output to powershell object so we can analyze
$SpeedTestResults = &$CurrentPath\speedtest.exe --accept-license --format=json-pretty | ConvertFrom-Json

Log-Item "Calculating Results..." "Cyan"
$ISPName=$SpeedTestResults.isp
$ISPDownload=[Math]::round((($SpeedTestResults.download | Select-Object -ExpandProperty "bandwidth")/1000000)*8,2)
$ISPUpload=[Math]::round((($SpeedTestResults.upload | Select-Object -ExpandProperty "bandwidth")/1000000)*8,2)
$ISPResultURL=$SpeedTestResults.result | Select-Object -ExpandProperty "url"

Log-Item "ISP: $ISPName"
Log-Item "Download Speed: $ISPDownload Mbps"
Log-Item "Upload Speed: $ISPUpload Mbps"
Log-Item "Speed Test Review URL: $ISPResultURL"
Log-Item "-"

# Check Download and upload speed meet minimum requirements
if ($ISPDownload -gt $SpeedTestDownloadMinimum)
{
    Log-Item "Internet download speed meets requirements (minimum speed of $SpeedTestDownloadMinimum Mbps)" "Green"
} else {
    Log-Item "INTERNET DOWNLOAD SPEED DOES NOT MEET REQUIREMENT OF $SpeedTestDownloadMinimum Mbps!" "Red"
    $HealthyConnection=$false
}
if ($ISPUpload -gt $SpeedTestUploadMinimum)
{
    Log-Item "Internet upload speed meets requirements (minimum speed of $SpeedTestUploadMinimum Mbps)" "Green"
} else {
    Log-Item "INTERNET UPLOAD SPEED DOES NOT MEET REQUIREMENT OF $SpeedTestUploadMinimum Mbps!" "Red"
    $HealthyConnection=$false
}

############################################################
### Check if there were any acceptable criteria failures ###
############################################################

Log-Item "-"
if ($HealthyConnection)
{
    Log-Item "Connection Health Checks have passed successfully!" "Green"
}
else {
    Log-Item "Health checks have FAILED - Network issues are present, review log file for details!" "Red"
}
Log-Item "-"

################
### All Done ###
################
Log-Item "NetCheck Shutting Down" "Yellow"