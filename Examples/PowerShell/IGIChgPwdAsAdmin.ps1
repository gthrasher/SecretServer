$AdminID = $args[0]
$AdminPWD = $args[1]
$UserID = $args[2]
$UserCurrentPWD = $args[3]
$UserNewPWD = $args[4]
$IGIHost = $([uri]$args[5]).Authority
Write-Host $IGIHost
$Url = "https://$($IGIHost)"

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

# Attempt to authenticate as admin
$LoginUrl = "$($Url)/igi/v2/security/login"

# Attempt to login...format for PS 5.1
$credPair = "$($AdminID):$($AdminPWD)"
$encodedCred = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))

$headers = @{ Authorization = "Basic $encodedCred"; realm = "Admin" }
$authToken = Invoke-RestMethod -Uri $LoginUrl -Method Get -Headers $headers -UseBasicParsing

# need to get the User Account ID
$searchUrl = "$($Url)/igi/v2/agc/users/accounts/.search"

$searchHeaders = @{
    "Content-Type" = "application/scim+json";
    "realm" = "Ideas";
    "Authorization" = "Bearer $($authToken)"
}

# Attempt to create properly formatted scim+json to pass as body
$ideas = "Ideas"
$searchBody = ConvertFrom-Json -InputObject "{schemas: ['urn:ietf:params:scim:api:messages:2.0:SearchRequest'],filter: 'urn:ibm:params:scim:schemas:resource:bean:agc:2.0:Account:person_code eq `"$($UserId)`" and urn:ibm:params:scim:schemas:resource:bean:agc:2.0:Account:pwdcfg_name eq `"$($ideas)`"'}" # hack to convert the embedded schemas array to a System.Object
$testSearchBody = $(ConvertTo-Json -InputObject $searchBody) # need to get the body in propery Json format for PS

$searchResponse = Invoke-RestMethod -Uri $searchUrl -Method Post -Header $searchHeaders -Body $testSearchBody -UseBasicParsing
$accountID = $searchResponse.resources.id

# Attempt to change password for User Account
$chgPwdUrl = "$($Url)/igi/v2/agc/users/accounts/$($accountID)/password"

# Attempt to create properly formatted scim+json to pass as body
$body = ConvertFrom-Json -InputObject "{schemas: ['urn:ibm:params:scim:api:messages:2.0:ChangePwd'],IGIPwd:'Test1234',newPassword:'Floober'}" # hack to convert the embedded schemas array to a System.Object
$testBody = $(ConvertTo-Json -InputObject $body) # need to get the body in propery Json format for PS

$pwdHeaders = @{
    "Content-Type" = "application/scim+json";
    "realm" = "Ideas";
    "Authorization" = "Bearer $($authToken)"
}

$pwdChangeResponse = Invoke-RestMethod -Uri $chgPwdUrl -Method Post -Header $pwdHeaders -Body $testBody -UseBasicParsing
Write-Host $($pwdChangeResponse)





 
