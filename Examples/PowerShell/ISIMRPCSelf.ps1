$UserID = $args[0]
$UserCurrentPWD = $args[1]
$UserNewPWD = $args[2]
$ISIMHost = $([uri]$args[3]).Authority
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

##debugging cookies
#$cookies = $websession.Cookies.GetCookies($url)
# foreach ($cookie in $cookies){
#    Write-Host "$($cookie.name) = $($cookie.value)"
#}

$url2 = "$($baseUrl)/itim/j_security_check"
$authBody = @{
    j_username=$UserID
    j_password=$UserCurrentPWD
}
$contentType = 'application/x-www-form-urlencoded'

$webrequest2 = Invoke-WebRequest -Uri $url2 -WebSession $websession -Body $authBody -ContentType $conentType -Method POST 

## debugging cookies
# $cookies2 = $websession.Cookies.GetCookies($url2)
# foreach ($cookie2 in $cookies2){
#   Write-Host "$($cookie2.name) = $($cookie2.value)"
# }

$url3 = "$($baseUrl)/itim/rest/systemusers/me"
$webrequest3 = Invoke-WebRequest -Uri $url3 -WebSession $websession
$csrfToken = $webrequest3.Headers["CSRFToken"]
Write-Host "CSRFToken: $($csrfToken)"
$content = $webrequest3 | ConvertFrom-Json
$userHref = $content._links.owner.href
Write-Host "Me Content: $($userHref)"

# self change
Write-Host "Self Change"
$acctHref = $content._links.self.href
Write-Host "Self SystemUser Href: $($acctHref)"

#  ISIM Account password change url
$pwdUrl = "$($baseUrl)$($acctHref)/password"
Write-Host "Systemuser Password URL: $($pwdUrl)"

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
$pwdHeaders = @{"CSRFToken"=$($csrfToken)}
try
{
    $pwdrequest = Invoke-WebRequest -Uri $pwdUrl -Headers $pwdHeaders -WebSession $websession -Body $reqBody -ContentType "application/json" -Method PUT
    $StatusCode = $Response.StatusCode
    Write-Host "Success"
}
catch 
{
    $StatusCode = $_.Exception.Response.StatusCode.value__
    $StatusStream = $_.Exception.Response.GetResponseStream()
    $sr = New-Object System.IO.StreamReader $StatusStream
    $pwdRes = $sr.ReadToEnd()
    $pwdContent = $pwdrequest | ConvertFrom-Json
    Write-Host "PWD Result: $($pwdContent)"
    Write-Host "Status Desc: $($pwdRes)"
}
Write-Host "STATUS: $($StatusCode)"

 
