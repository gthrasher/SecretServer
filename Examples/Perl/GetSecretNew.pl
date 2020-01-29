# use strict;
# use warnings;

use LWP::UserAgent; 
use HTTP::Request;
use JSON::PP;

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
GetSecretUsername($authtoken, $secretId);
GetSecretPassword($authtoken, $secretId);

# 1) Authentication Token
sub GetToken()
{
	my($username, $password, $organizationCode, $domain) = @_;
	my $url = $baseUrl . "/oauth2/token";

    my $ua = LWP::UserAgent->new();
    my $response = $ua->post( $url, { 'username' => $username, 'password' => $password, 'grant_type' => 'password'});
    my $content = $response->content();
    my $regtoken = $1 if $content =~ /"access_token":"(.*?)["]/gm;
    # print "Token from Regex: $regtoken\n";
    return $regtoken;
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
    $json = JSON::PP->new->ascii->pretty->allow_nonref;
    $jdecoded = $json->decode($secretContent);
    print "HERE>>>> $jdecoded\n";
    print "ID: $jdecoded->{id}\n";
    print "ITEMS: $jdecoded->{items}\n";
    @itemArray = $jdecoded->{items};
    print "TEST: @itemArray\n";
    foreach my $item (@{$jdecoded->{items}}){
        my $slug = $item->{slug};
        print "ITEM: $slug\n";
        if(($slug eq "username") || ($slug eq "password")){
            print "$slug : $item->{itemValue}\n"
        }
    }

}

# 3) Get the Username from the Secret
sub GetSecretUsername()
{
    my($token, $secId) = @_;
    my $secUrl = $WebServiceUrl . "/secrets/" . $secId . "/fields/username";
    # print "calling $secUrl\n";

    my $ua = LWP::UserAgent->new();
    $ua->default_header(Authorization => 'Bearer ' . $token);
    my $response = $ua->get( $secUrl );
    my $secretContent = $response->content();
    print "Username: $secretContent\n";
}

# 4) Get the Password from the Secret
sub GetSecretPassword()
{
    my($token, $secId) = @_;
    my $secUrl = $WebServiceUrl . "/secrets/" . $secId . "/fields/password";
    # print "calling $secUrl\n";

    my $ua = LWP::UserAgent->new();
    $ua->default_header(Authorization => 'Bearer ' . $token);
    my $response = $ua->get( $secUrl );
    my $secretContent = $response->content();
    print "Password: $secretContent\n";
}