$UserID = $args[0]
$UserCurrentPWD = $args[1]
$ISIMHost = $([uri]$args[2]).Authority
Write-Host $ISIMHost
$baseUrl = "https://$($ISIMHost)"

#parse out the base URL from the one passed in from the Secret
Write-Host $baseUrl


$url = "$($baseUrl)/itim/restlogin/login.jsp"

# attempt to get past the "underlying connection closed..." error
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

# attempt to get past the "could not establish trust relationship for the SSL/TLS secure channel"
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPort, X509Certificate certificate, WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy


$webrequest = Invoke-WebRequest -Uri $url -SessionVariable websession


$url2 = "$($baseUrl)/itim/j_security_check"
$authBody = @{
    j_username=$UserID
    j_password=$UserCurrentPWD
}
$contentType = 'application/x-www-form-urlencoded'

try
{
    $webrequest2 = Invoke-WebRequest -Uri $url2 -WebSession $websession -Body $authBody -ContentType $conentType -Method POST
    $StatCode = $webrequest2.StatusCode
    Write-Debug "STATUS CODE: $($StatCode)"
    if ($StatCode -eq "200"){
        #failed
        throw "Login Failed"
    }
}
catch
{
    #Write-Host "Failed"
    $StatusCode = $_.Exception.Response.StatusCode.value__
    if ($StatusCode -eq "404"){
        #success
        Write-Debug "Login successful"
    } else {
        # throw "Failed with $($StatusCode)"
        $StatusStream = $_.Exception.Response.GetResponseStream()
        $sr = New-Object System.IO.StreamReader $StatusStream
        $loginRes = $sr.ReadToEnd()
        throw "Status Code: $($StatusCode)  -- Status Desc: $($loginRes)"
    }
}  
