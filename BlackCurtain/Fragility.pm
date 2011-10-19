package BlackCurtain::Fragility;
use Carp;
use base qw(Clone);
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

AUTOLOAD
{
	my $j = shift();
	my @a = @_;

	if(eval(qq(require $AUTOLOAD))){
		return($AUTOLOAD->new(@a));
	}else{
		Carp::croak($@);
	}
}

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
	my @a = map{ref($_) eq "ARRAY" ? @{$_} : $_}@_;

	if(($j->{s} = $j->{a}->request(blessed($q) ? $q : HTTP::Request->new(ref($q) eq "HASH" ? %{$q} : (GET =>$q))))->is_success()){
		my $h = $j->{s}->{_headers}->as_string();
		my $b = $j->{s}->decoded_content(default_charset =>"UTF-8");
		my $f = [map{HTML::Form->parse($_,$j->{s}->{_request}->uri())}($b =~m/(<form.*?<\/form>)/gios)];

		my @r = map{
			if(defined($_->{regex}) || ref($_) ne "HASH"){
				$b =~ /$_->{regex}/i;
				defined($1) ? $1 : 1;
			}elsif(defined($_->{word})){
				$b =~ /\Q$_->{word}\E/ig;
			}elsif(defined($_->{form})){
				my $a = $_;
				(grep{(!defined($a->{form})) || ($_->{attr}->{id} =~ /$a->{form}/i || $_->{attr}->{name} =~ /$a->{form}/i)}@{$f})[0];
			}elsif(defined($_->{code})){
				$_->{code} == $j->{s}->code();
			}else{
			}
		}@a;
	
		return($j->{s}->code(),$b,$f,@r);
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
