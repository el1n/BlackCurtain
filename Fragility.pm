package BlackCurtain::Fragility;
use 5.10.0;
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
use HTML::TreeBuilder;
use HTML::Form;
use XML::Simple qw();
use YAML::XS qw();
use JSON::XS qw();

AUTOLOAD
{
	my($s,@a) = @_;

	if(eval(qq(require $AUTOLOAD))){
		return($AUTOLOAD->new(@a));
	}else{
		Carp::croak($@);
	}
}

sub new
{
	my($s,%a) = @_;

	return(($s = bless({},$s))->clean(%a));
}

sub clean
{
	my($s,%a) = @_;

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
		%a,
	);
	$s->{a}->add_handler(response_done =>sub(){shift()->{def_headers}->header(Referer =>$s->{_request}->{_uri})});

	return($s);
}

sub spider
{
	my($s,$q,$y,@a) = @_;

	if(($s->{s} = $s->{a}->request(blessed($q) ? $q : HTTP::Request->new(ref($q) eq "HASH" ? %{$q} : (GET =>$q))))->is_success()){
		$s->{h} = $s->{s}->{_headers}->as_string();
		$s->{b} = $s->{s}->decoded_content(default_charset =>"UTF-8");
		given($y // $s->{s}->header("Content-Type")){
			when(/^(?:text\/)?html$/io){
				$s->{d} = HTML::TreeBuilder->new_from_content($s->{b});
			}
			when(/^(?:application\/)?xml$/io){
				$s->{d} = XML::Simple::XMLin($s->{b});
			}
			when(/^(?:application\/)?json$/io){
				$s->{d} = JSON::XS::decode_json($s->{b});
			}
			when(/^(?:application\/(?:x-))?yaml$/io){
				$s->{d} = YAML::XS::Load($s->{b});
			}
		}

		return($s->{s}->code(),$s->{b},$s->{d},$s->seek(@a));
	}else{
		return($s->{s}->code());
	}
}

sub seek
{
	my($s,@a) = @_;
	my @r;

	while(my($op,$var) = (shift(@a),shift(@a))){
		given($op){
			when("regx"){
				push(@r,$s->{b} =~ /$var/i ? defined($1) ? $1 : 1 : 0);
			}
			when(ref() eq "ARRAY" && $_->[0] eq "regx"){
				push(@r,[$s->{b} =~ /$var/gi]);
			}
			when("form"){
				$s->{form} //= [HTML::Form->parse($s->{b},$s->{s}->request()->uri())];
				push(@r,(grep{grep(/\Q$var\E/i,@{$_}{qw(id class name)})}@{$s->{form}})[0]);
			}
			when(ref() eq "ARRAY" && $_->[0] eq "form"){
				$s->{form} //= [HTML::Form->parse($s->{b},$s->{s}->request()->uri())];
				push(@r,[grep{grep(/\Q$var\E/i,@{$_}{qw(id class name)})}@{$s->{form}}]);
			}
		}
	}
	return(@r);
}

1;
