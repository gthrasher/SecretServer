# use strict;
# use warnings;

use LWP::UserAgent; 
use HTTP::Request;
use JSON::PP;

my $json = JSON::PP->new->ascii->pretty->allow_nonref;

# Update these values to match your user settings and instance URL. This example will work against Secret Server Online.
my $username = "ssadmin";
my $password= "secret";
my $organizationCode= ""; # Can be left blank for Secret Server Installed (on-premise) edition
my $domain = ""; # Only needed for AD login
my $baseUrl = "https://gtwinss.grey.lab/SecretServer";
my $WebServiceUrl = $baseUrl . "/api/v1"; # Or URL to your server and to the SSWebService.asmx file

my $secretId = "12";

my $authtoken = GetToken($username ,$password,$organizationCode,$domain);

my $secretData = GetFullSecret($authtoken, $secretId);

# 1) Authentication Token
sub GetToken()
{
	my($username, $password, $organizationCode, $domain) = @_;
	my $url = $baseUrl . "/oauth2/token";

    my $ua = LWP::UserAgent->new();
    my $response = $ua->post( $url, { 'username' => $username, 'password' => $password, 'grant_type' => 'password'});
    my $content = $response->content();
    
    my $jsonContent = $json->decode($content);
    my $jToken = $jsonContent->{access_token};
    print "JSON Token: $jToken\n";
    return $jToken;
}

# 2) Get Secret Data
sub GetFullSecret()
{
    my($token, $secId) = @_;
    my $secUrl = $WebServiceUrl . "/secrets/" . $secId;
    # print "calling $secUrl\n";

    my $ua = LWP::UserAgent->new();
    $ua->default_header(Authorization => 'Bearer ' . $token);
    my $response = $ua->get( $secUrl );
    my $secretContent = $response->content();
    print "$secretContent\n";

    print "testing JSON...\n";
    # $json = JSON::PP->new->ascii->pretty->allow_nonref;
    $jdecoded = $json->decode($secretContent);
    print "ID: $jdecoded->{id}\n";
    @itemArray = $jdecoded->{items};
    foreach my $item (@{$jdecoded->{items}}){
        my $slug = $item->{slug};
        if(($slug eq "username") || ($slug eq "password")){
            print "$slug : $item->{itemValue}\n"
        }
    }

}