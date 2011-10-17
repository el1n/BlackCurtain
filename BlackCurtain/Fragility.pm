package BlackCurtain::Fragility;
use Carp;
use vars qw($AUTOLOAD);
use Scalar::Util qw(blessed);
use Encode;
use LWP::UserAgent;
use Crypt::SSLeay;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Response;
use HTTP::Cookies;
use HTML::Form;

sub new
{
	my $j = shift();
	my %a = @_;

	$j = bless({},$j);
	$j->clean();

	return($j);
}

sub clean
{
	my $j = shift();

	$j->{a} = LWP::UserAgent->new(
		#agent =>
		#from =>
		#conn_cache =>
		cookie_jar =>HTTP::Cookies->new(),
		default_headers =>HTTP::Headers->new(
			User_Agent =>"Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Win64; x64; Trident/4.0",
			Accept_Encoding =>"gzip, deflate",
			Accept_Language =>"ja_JP",
		),
		#local_address =>
		#ssl_opts =>
		#max_size =>
		#max_redirect =>
		#parse_head =>
		#protocols_allowed =>
		#protocols_forbidden =>
		requests_redirectable =>[qw(GET HEAD POST)],
		timeout =>60,
	);

	return();
}

sub http
{
	my $j = shift();
	my $q = shift();
	my $a = shift();

	if(($j->{s} = $j->{a}->request(blessed($q) ? $q : HTTP::Request->new(ref($q) eq "HASH" ? %{$q} : (GET =>$q))))->is_success()){
		#my $h = $j->{s}->{_headers}->as_string();
		my $b = $j->{s}->decoded_content();
		my $f = [map{HTML::Form->parse($_,$j->{s}->{_request}->uri())}($b =~m/(<form.*?<\/form>)/ios)];
	
		return($j->{s}->code(),$b,$f);
	}else{
		return(0);
	}
}

sub pop3
{
	my $j = shift();
}

sub imap
{
	my $j = shift();
}

1;
