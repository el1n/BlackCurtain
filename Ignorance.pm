package BlackCurtain::Ignorance;
use Carp;
use vars qw($VERSION);
use Encode;
use CGI;
use CGI::Session;
use CGI::Cookie;
use Text::Xslate;

sub new:method
{
	my $j = shift();
	my $a = shift();
	my %a = @_;

	return(bless({callback =>$a,args =>\%a,map{$_,$_->new(@{$a{$_}})}qw(CGI Text::Xslate)},$j));
}

sub perform:method
{
	my $j = shift();
	my %a = @_;

	local %ENV = %ENV;
	local %GET;
	local %POST;
	local %COOKIE = map{$_->name(),$_->value()}grep{ref($_)}CGI::Cookie->fetch();
	local %SES = %{($j->{CGI::Session} = CGI::Session->new($j->{args}->{CGI::Session}->[0],$COOKIE{IGNORANCE_SESSION},$j->{args}->{CGI::Session}->[2]))->dataref()};
	my($issue,$d,%r) = &{$j->{callback}->{(grep{$ENV{PATH_INFO} =~ $_}keys(%{$j->{callback}}))[0]}}();
	if($issue eq "none"){
	}elsif($issue eq "jump"){
	}elsif($issue eq "Text::Xslate"){
		$d->{ENV} = \%ENV;
		$d->{SES} = \%SES;
		$d->{COOKIE} = \%COOKIE;
		$d->{GET} = \%GET;
		$d->{POST} = \%POST;
		$d->{URL} = sub($){return($ENV{SCRIPT_NAME}.shift())};
		print $j->{CGI}->header(qw(-type text/html -charset UTF-8 -cookie),[$j->{CGI}->cookie(qw(-name IGNORANCE_SESSION -value),$j->{CGI::Session}->id())]);
		print $j->{Text::Xslate}->render($r{file},$d);
	}
	return();
}

1;
