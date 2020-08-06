$UserID = $args[0]
$UserCurrentPWD = $args[1]
$UserNewPWD = $args[2]
$ISIMHost = $([uri]$args[3]).Authority
$baseUrl = "https://$($ISIMHost)"

#parse out the base URL from the one passed in from the Secret
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


$webrequest = Invoke-WebRequest -Uri $url -UseBasicParsing -SessionVariable websession

$url2 = "$($baseUrl)/itim/j_security_check"
$authBody = @{
    j_username=$UserID
    j_password=$UserCurrentPWD
}
$contentType = 'application/x-www-form-urlencoded'

try {
    $webrequest2 = Invoke-WebRequest -Uri $url2 -UseBasicParsing -WebSession $websession -Body $authBody -ContentType $conentType -Method POST 
    $StatCode = $webrequest2.StatusCode
    Write-Debug "STATUS CODE: $($StatCode)"
    if ($StatCode -eq "200"){
        throw "Login Failed"
    }
}
catch
{
    $StatusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "$($StatusCode)"
    if ($StatusCode -ne "404"){
        throw "Login Failed"
    }
} 

$url3 = "$($baseUrl)/itim/rest/systemusers/me"
$webrequest3 = Invoke-WebRequest -Uri $url3 -UseBasicParsing -WebSession $websession
$csrfToken = $webrequest3.Headers["CSRFToken"]
$content = $webrequest3 | ConvertFrom-Json
$userHref = $content._links.owner.href
$acctHref = $content._links.self.href


#  ISIM Account password change url
$pwdUrl = "$($baseUrl)$($acctHref)/password"

#build out the body of the password change
$reqBody = @"
{
    "_forms": [
        {
            "_inputs": [
                {
                    "property": "oldPassword",
                    "value": "$($UserCurrentPWD)"
                },
                {
                    "attribute": "erPassword",
                    "value": "$($UserNewPWD)"
                }
            ]
        }
    ]
}
"@

#call the password change
# just to validate: $pwdHeaders = @{"X-HTTP-Method-Override"='validate';"CSRFToken"=$($csrfToken)}
$pwdHeaders = @{"CSRFToken"=$($csrfToken)}
try
{
    $pwdrequest = Invoke-WebRequest -Uri $pwdUrl -UseBasicParsing -Headers $pwdHeaders -WebSession $websession -Body $reqBody -ContentType "application/json" -Method PUT
    $StatusCode = $Response.StatusCode
    Write-Debug "*** Password Change Success ***"
}
catch 
{
    $StatusCode = $_.Exception.Response.StatusCode.value__
    $StatusStream = $_.Exception.Response.GetResponseStream()
    $sr = New-Object System.IO.StreamReader $StatusStream
    $pwdRes = $sr.ReadToEnd()
    throw "Status Desc: $($pwdRes)"
}

 
