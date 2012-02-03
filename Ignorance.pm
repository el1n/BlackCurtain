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
use YAML::XS qw();
use JSON::XS qw();
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
	my %COOKIE = CGI::Cookie->raw_fetch();
	my %SES = %{($s->{CGI::Session} = CGI::Session->new($s->{args}->{CGI::Session}->[0],$COOKIE{IGNORANCE_SID},$s->{args}->{CGI::Session}->[2]))->dataref()};
	my %GET = $ENV{REQUEST_METHOD} eq "GET" ? map{$_,join(" ",$s->{CGI}->param($_))}$s->{CGI}->param() : map{$_,join(" ",$s->{CGI}->url_param($_))}$s->{CGI}->url_param();
	my %POST = $ENV{REQUEST_METHOD} eq "POST" ? map{$_,join(" ",$s->{CGI}->param($_))}$s->{CGI}->param() : undef;
	my %QUERY = (%GET,%POST);
	my %BORROW;

	my $pass = 0;
	for my $callback (@{$s->{callback}}){
		my($regex,$sub,$i,@args) = @{$callback};

		if($ENV{PATH_INFO} =~ $regex){
			my @m = map{${$_}}(1..($i > 0 ? $i : 9));

			my $pkg = Mouse::Util::get_code_package($sub);
			local *{$pkg."::ENV"} = \%ENV;
			local *{$pkg."::COOKIE"} = \%COOKIE;
			local *{$pkg."::SES"} = \%SES;
			local *{$pkg."::GET"} = \%GET;
			local *{$pkg."::POST"} = \%POST;
			local *{$pkg."::QUERY"} = \%QUERY;
			local *{$pkg."::BORROW"} = \%BORROW;
		
			my($issue,$d,%r) = $sub->([$ENV{PATH_INFO} =~m/\/+([0-9A-Za-z_-]+)/go],\@m,{pass =>$pass++});
			push(@{$r{cookie}},$s->{CGI}->cookie(qw(-name IGNORANCE_SID -value),$s->{CGI::Session}->id()));
			if($issue =~ /^none$/io){
				if(!$s->{CGI}->{".header_printed"}){
					print $s->{CGI}->header(qw(-type text/html -charset UTF-8 -cookie),$r{cookie});
				}
			}elsif($issue =~ /^data$/io){
				if(!$s->{CGI}->{".header_printed"}){
					print $s->{CGI}->header(qw(-type text/html -charset UTF-8 -cookie),$r{cookie});
				}
				print $d;
			}elsif($issue =~ /^file$/io){
			}elsif($issue =~ /^jump$/io){
				if(!$s->{CGI}->{".header_printed"}){
					print $s->{CGI}->redirect(qw(-url),$d,qw(-cookie),$r{cookie});
				}
			}elsif($issue =~ /^(?:Text::)?Xslate$/io){
				$s->{Text::Xslate} ||= Text::Xslate->new(@{$s->{args}->{Text::Xslate}});
				$d->{ENV} = \%ENV;
				$d->{SES} = \%SES;
				$d->{COOKIE} = \%COOKIE;
				$d->{GET} = \%GET;
				$d->{POST} = \%POST;
				$d->{QUERY} = \%QUERY;
				$d->{BORROW} = \%BORROW;
				$d->{MATCH} = \@m;
				$d->{URL} = sub($){return($ENV{SCRIPT_NAME}.shift())};
				if(!$s->{CGI}->{".header_printed"}){
					print $s->{CGI}->header(qw(-type text/html -charset UTF-8 -cookie),$r{cookie});
				}
				print defined($r{file}) ? $s->{Text::Xslate}->render($r{file},$d) : $s->{Text::Xslate}->render_string($r{data},$d);
			}elsif($issue =~ /^XML(?:::Simple)?$/io){
				if(!$s->{CGI}->{".header_printed"}){
					print $s->{CGI}->header(qw(-type application/xml -charset UTF-8 -cookie),$r{cookie});
				}
				print XML::Simple::XMLout($d);
			}elsif($issue =~ /^YAML(?:::XS)?$/io){
				if(!$s->{CGI}->{".header_printed"}){
					print $s->{CGI}->header(qw(-type text/plain -charset UTF-8 -cookie),$r{cookie});
				}
				print YAML::XS::Dump($d);
			}elsif($issue =~ /^JSON(?:::XS)?$/io){
				if(!$s->{CGI}->{".header_printed"}){
					print $s->{CGI}->header(qw(-type application/json -charset UTF-8 -cookie),$r{cookie});
				}
				print JSON::XS::encode_json($d);
			}elsif($issue =~ /^(?:Data::)?Dumper$/io){
				$d->{ENV} = \%ENV;
				$d->{SES} = \%SES;
				$d->{COOKIE} = \%COOKIE;
				$d->{GET} = \%GET;
				$d->{POST} = \%POST;
				$d->{QUERY} = \%QUERY;
				$d->{BORROW} = \%BORROW;
				$d->{MATCH} = \@m;
				if(!$s->{CGI}->{".header_printed"}){
					print $s->{CGI}->header(qw(-type text/plain -charset UTF-8 -cookie),$r{cookie});
				}
				print Data::Dumper::Dumper($d);
			}
		}
	}
	$s->{CGI::Session}->{_DATA} = \%SES;
	$s->{CGI::Session}->_set_status($s->{CGI::Session}->STATUS_MODIFIED);
	$s->{CGI::Session}->close();

	return();
}

1;
