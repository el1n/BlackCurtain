package BlackCurtain::Ignorance;
use Carp;
use vars qw($VERSION);
require Mouse::Util;
use Encode;
use CGI;
use CGI::Session;
use CGI::Cookie;
use Text::Xslate;
use XML::Simple;
use YAML::Syck qw();
use JSON::Syck qw();
use Data::Dumper;

sub new:method
{
	my $s = shift();
	my $a = shift();
	my %a = @_;

	return(bless({callback =>$a,args =>\%a,map{$_,$_->new(@{$a{$_}})}qw(CGI)},$s));
}

sub perform:method
{
	my $s = shift();
	my %a = @_;

	my %ENV = %ENV;
	my %COOKIE = map{$_->name(),join(" ",$_->value())}grep{ref($_)}CGI::Cookie->fetch();
	my %SES = %{($s->{CGI::Session} = CGI::Session->new($s->{args}->{CGI::Session}->[0],$COOKIE{IGNORANCE_SID},$s->{args}->{CGI::Session}->[2]))->dataref()};
	my %GET = map{$_,join(" ",$s->{CGI}->url_param($_))}$s->{CGI}->url_param();
	my %POST = $ENV{REQUEST_METHOD} eq "POST" ? map{$_,join(" ",$s->{CGI}->param($_))}$s->{CGI}->param() : undef;
	my %QUERY = (%GET,%POST);

	my $sub = $s->{callback}->{(grep{$ENV{PATH_INFO} =~ $_}keys(%{$s->{callback}}))[0]};
	my $pkg = Mouse::Util::get_code_package($sub);
	local *{$pkg."::ENV"} = \%ENV;
	local *{$pkg."::COOKIE"} = \%COOKIE;
	local *{$pkg."::SES"} = \%SES;
	local *{$pkg."::GET"} = \%GET;
	local *{$pkg."::POST"} = \%POST;
	local *{$pkg."::QUERY"} = \%QUERY;

	my($issue,$d,%r) = $sub->([$ENV{PATH_INFO} =~m/\/+([0-9A-Za-z_]+)/o]);
	push(@{$r{cookie}},$s->{CGI}->cookie(qw(-name IGNORANCE_SID -value),$s->{CGI::Session}->id()));
	if($issue =~ /^none$/io){
	}elsif($issue =~ /^data$/io){
	}elsif($issue =~ /^file$/io){
	}elsif($issue =~ /^jump$/io){
	}elsif($issue =~ /^(?:Text::)?Xslate$/io){
		$s->{Text::Xslate} ||= Text::Xslate->new(@{$s->{args}->{Text::Xslate}});
		$d->{ENV} = \%ENV;
		$d->{SES} = \%SES;
		$d->{COOKIE} = \%COOKIE;
		$d->{GET} = \%GET;
		$d->{POST} = \%POST;
		$d->{URL} = sub($){return($ENV{SCRIPT_NAME}.shift())};
		print $s->{CGI}->header(qw(-type text/html -charset UTF-8 -cookie),$r{cookie});
		print $s->{Text::Xslate}->render($r{file},$d);
	}elsif($issue =~ /^XML(?:::Simple)?$/io){
		print $s->{CGI}->header(qw(-type application/xml -charset UTF-8 -cookie),$r{cookie});
		print XML::Simple::XMLout($d);
	}elsif($issue =~ /^YAML(?:::Syck)?$/io){
		print $s->{CGI}->header(qw(-type text/plain -charset UTF-8 -cookie),$r{cookie});
		print YAML::Syck::Dump($d);
	}elsif($issue =~ /^JSON(?:::Syck)?$/io){
		print $s->{CGI}->header(qw(-type application/json -charset UTF-8 -cookie),$r{cookie});
		print JSON::Syck::Dump($d);
	}elsif($issue =~ /^Data::Dumper(?:)?$/io){
		$d->{ENV} = \%ENV;
		$d->{SES} = \%SES;
		$d->{COOKIE} = \%COOKIE;
		$d->{GET} = \%GET;
		$d->{POST} = \%POST;
		print $s->{CGI}->header(qw(-type text/plain -charset UTF-8 -cookie),$r{cookie});
		print Data::Dumper::Dumper($d);
	}
	$s->{CGI::Session}->{_DATA} = \%SES;
	$s->{CGI::Session}->save_param();
	$s->{CGI::Session}->close();
	return();
}

1;
