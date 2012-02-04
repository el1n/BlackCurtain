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
use XML::Simple qw();
use YAML::XS qw();
use JSON::XS qw();

AUTOLOAD
{
	my $s = shift();
	my @g = @_;

	if(eval(qq(require $AUTOLOAD))){
		return($AUTOLOAD->new(@g));
	}else{
		Carp::croak($@);
	}
}

sub new
{
	my $s = shift();
	my %g = @_;

	$s = bless({},$s);
	$s->clean();

	return($s);
}

sub clean
{
	my $s = shift();
	my %g = @_;

	$s->{a} = LWP::UserAgent->new(
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
		timeout =>30,
		%g,
	);

	return();
}

sub spider
{
	my $s = shift();
	my $q = shift();
	my $t = shift();
	my @g = @_;

	if(($s->{s} = $s->{a}->request(blessed($q) ? $q : HTTP::Request->new(ref($q) eq "HASH" ? %{$q} : (GET =>$q))))->is_success()){
		$s->{h} = $s->{s}->{_headers}->as_string();
		$s->{b} = $s->{s}->decoded_content(default_charset =>"UTF-8");
		if(defined($t) ? $t =~ /^HTML$/io : $s->{s}->header("Content-Type") =~ /^text\/html/io){
			$s->{d} = [map{HTML::Form->parse($_,$s->{s}->{_request}->uri())}($s->{b} =~m/(<form.*?<\/form>)/gios)];
		}elsif(defined($t) ? $t =~ /^XML$/io : $s->{s}->header("Content-Type") =~ /^application\/xml/io){
			$s->{d} = XML::Simple::XMLin($s->{b});
		}else{
		}

		return($s->{s}->code(),$s->{b},$s->{d},$s->seek(@g));
	}else{
		return($s->{s}->code());
	}
}

sub seek
{
	my $s = shift();
	my @g = map{ref($_) eq "ARRAY" ? @{$_} : $_}@_;

	my @r = map{
		if(defined($_->{regex}) || ref($_) ne "HASH"){
			$s->{b} =~ /$_->{regex}/i;
			defined($1) ? $1 : 1;
		}elsif(defined($_->{word})){
			$s->{b} =~ /\Q$_->{word}\E/ig;
		}elsif(defined($_->{form})){
			my $a = $_;
			(grep{(!defined($a->{form})) || ($_->{attr}->{id} =~ /$a->{form}/i || $_->{attr}->{name} =~ /$a->{form}/i)}@{$s->{f}})[0];
		}elsif(defined($_->{code})){
			$_->{code} == $s->{s}->code();
		}else{
		}
	}@g;

	return(@r);
}

1;
