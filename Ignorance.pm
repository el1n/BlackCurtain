package BlackCurtain::Ignorance;
use Carp;
use vars qw($VERSION);
use Mouse::Util;
use Encode;
use CGI;
use CGI::Session;
use CGI::Cookie;
use Text::Xslate;
use XML::Simple;
use JSON;
use Data::Dumper;

sub new:method
{
	my $s = shift();
	my $a = shift();
	my %a = @_;

	return(bless({callback =>$a,args =>\%a,CGI =>CGI->new()},$s));
}

sub perform:method
{
	my $s = shift();
	my %a = @_;

	my %ENV = %ENV;
	my %GET;
	my %POST;
	my %QUERY = (%GET,%POST);
	my %COOKIE = map{$_->name(),join(" ",$_->value())}grep{ref($_)}CGI::Cookie->fetch();
	my %SES = %{($s->{CGI::Session} = CGI::Session->new($j->{args}->{CGI::Session}->[0],$COOKIE{IGNORANCE_SESSION},$j->{args}->{CGI::Session}->[2]))->dataref()};
	my @ARGV = $ENV{PATH_INFO} =~m/\/+([0-9A-Za-z_]+)/go;

	my $func = $s->{callback}->{(grep{$ENV{PATH_INFO} =~ $_}keys(%{$j->{callback}}))[0]} || \&{(caller())[0]."::req_".($ARGV[0] || "index")};

	my $ns = Mouse::Util::get_code_package($func);
	local *{$ns."::ENV"}{HASH} = \%ENV;
	local *{$ns."::GET"}{HASH} = \%GET;
	local *{$ns."::POST"}{HASH} = \%POST;
	local *{$ns."::QUERY"}{HASH} = \%QUERY;
	local *{$ns."::COOKIE"}{HASH} = \%COOKIE;
	local *{$ns."::SES"}{HASH} = \%SES;
	my($issue,$d,%r) = $func->();
	if($issue =~ /^none$/io){
	}elsif($issue =~ /^jump$/io){
	}elsif($issue =~ /^(?:Text::)?Xslate$/io){
		$d->{ENV} = \%ENV;
		$d->{SES} = \%SES;
		$d->{COOKIE} = \%COOKIE;
		$d->{GET} = \%GET;
		$d->{POST} = \%POST;
		$d->{URL} = sub($){return($ENV{SCRIPT_NAME}.shift())};
		print $s->{CGI}->header(qw(-type text/html -charset UTF-8 -cookie),[$j->{CGI}->cookie(qw(-name IGNORANCE_SESSION -value),$j->{CGI::Session}->id())]);
		print $s->{Text::Xslate}->render($r{file},$d);
	}elsif($issue =~ /^XML(?:::Simple)?$/io){
	}elsif($issue =~ /^JSON$/io){
	}elsif($issue =~ /^Data::Dumper(?:)?$/io){
		$d->{ENV} = \%ENV;
		$d->{SES} = \%SES;
		$d->{COOKIE} = \%COOKIE;
		$d->{GET} = \%GET;
		$d->{POST} = \%POST;
		print $s->{CGI}->header(qw(-type text/plain -charset UTF-8 -cookie),[$j->{CGI}->cookie(qw(-name IGNORANCE_SESSION -value),$j->{CGI::Session}->id())]);
		print Data::Dumper::Dumper($d);
	}
	return();
}

1;
