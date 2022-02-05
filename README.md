## NetCheck 

A basic PowerShell network troubleshooting utility that will test relevant elements of a users internal network and their public Internet connection provided by the ISP.  

### Features

The following tests are included in this script:

- Latency, Jitter and Packet Loss between the client device and the internal router/gateway. 
- Latency, Jitter and Packet Loss between the client device, router/gateway and specified remote testing site (google.com by default). 
- Trace route of all hops (included latency test) from the client device to the specified remote testing host. 
- Speedtest.net CLI integration for Download and Upload capability testing.  
- Minimum assessment parameters to test against and surface alerts for requirement deviations:
    - Maximum acceptable Latency, Jitter and Packet Loss for local network hop(s).
    - Maximum acceptable Latency, Jitter and Packet Loss for Internet hops.
    - Minimum Download and Upload speeds. 

The script is configured to write output to the screen and also write to a file (log.txt by default in the same directory as the script).

### Configuration

All configuration can be found just below the license information near the top of the script file. 

```PowerShell
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
```

### Requirements

- This script is designed to be run on Windows 10 and Windows 11.
- The script must be run from a local directory/folder on the device with permissions to write files for purposes of logging and/or speedtest.net CLI executable download that is used by this script.   
- The script should be customized, especially the acceptable parameters section, and then code signed for use in your environment.  The script can execute without code signing if you have configured your system to allow unsigned remote scripts which is generally a terrible idea from a security perspective. 

### Example Output

Actual script execution includes pretty screen colors!

```
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
02/05/2022 12:33:54 - Starting up NetCheck
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
02/05/2022 12:33:54 - Client Local IP address: 172.16.161.132
02/05/2022 12:33:54 - Client Local Gateway: 172.16.161.2
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
02/05/2022 12:33:54 - Testing client to local router connection (this test will take about 10 seconds)...
02/05/2022 12:33:54 - [PC]<-----Local Network----->[Router]
02/05/2022 12:34:04 - Local Average Latency: 0 ms
02/05/2022 12:34:04 - Local Minimum Latency: 0 ms
02/05/2022 12:34:04 - Local Maximum Latency: 0 ms
02/05/2022 12:34:04 - Local Packet Loss: 0 %
02/05/2022 12:34:04 - Local Jitter: 0 ms
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
02/05/2022 12:34:04 - Testing client to local router and out to the remote Internet host (this test will take about 10 seconds)...
02/05/2022 12:34:04 - [PC]<-----Local Network----->[Router]<-----Internet Network----->[Remote Host]
02/05/2022 12:34:13 - Remote Average Latency: 10.5 ms
02/05/2022 12:34:13 - Remote Minimum Latency: 9 ms
02/05/2022 12:34:13 - Remote Maximum Latency: 14 ms
02/05/2022 12:34:13 - Remote Packet Loss: 0 %
02/05/2022 12:34:13 - Remote Jitter: 2 ms
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
02/05/2022 12:34:13 - Running trace route to remote test host... (this can take more than 30 seconds)
02/05/2022 12:35:02 -  
02/05/2022 12:35:02 - Tracing route to google.com [142.251.32.14] 
02/05/2022 12:35:02 - over a maximum of 30 hops: 
02/05/2022 12:35:02 -  
02/05/2022 12:35:02 -   1    <1 ms    <1 ms    <1 ms  172.16.161.2   
02/05/2022 12:35:02 -  14    13 ms    15 ms    14 ms  108.170.230.146  
02/05/2022 12:35:02 -  15    11 ms    11 ms    10 ms  142.251.60.21  
02/05/2022 12:35:02 -  16    16 ms    14 ms     9 ms  ord38s33-in-f14.1e100.net [142.251.32.14]  
02/05/2022 12:35:02 -  
02/05/2022 12:35:02 - Trace complete. 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
02/05/2022 12:35:03 - Running Speedtest.net Bandwidth Test... (this usually takes around 30 seconds)
02/05/2022 12:35:26 - Calculating Results...
02/05/2022 12:35:26 - ISP: Comcast Cable
02/05/2022 12:35:26 - Download Speed: 313.61 Mbps
02/05/2022 12:35:26 - Upload Speed: 22.84 Mbps
02/05/2022 12:35:26 - Speed Test Review URL: https://www.speedtest.net/result/c/
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
02/05/2022 12:35:26 - Internet download speed meets requirements (minimum speed of 50 Mbps)
02/05/2022 12:35:27 - Internet upload speed meets requirements (minimum speed of 5 Mbps)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
02/05/2022 12:35:27 - Connection Health Checks have passed successfully!
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
02/05/2022 12:35:27 - NetCheck Shutting Down
```