package BlackCurtain::Ignorance;
use Carp;
use vars qw($VERSION);
use Encode;
use CGI;
use CGI::Session;
use Text::Xslate;

sub new:method
{
	my $j = shift();
	my $a = shift();
	my %a = @_;

	return(bless({callback =>$a,map{$_,$_->new(@{$a{$_}})}qw(CGI CGI::Session Text::Xslate)},$j));
}

sub perform:method
{
	my $j = shift();

	local %ENV = (%ENV,SESSION =>$j->{CGI}->cookie("IGNORANCE_SESSION"));
	local %SES;
	local %COOKIE = (map{$_,$j->{CGI}->{".cookies"}->{$_}->value()}keys(%{$j->{CGI}->{".cookies"}}));
	local %GET;
	local %POST;
	my %r = &{$j->{callback}->{(grep{$ENV{PATH_INFO} =~ $_}keys(%{$j->{callback}}))[0]}}();
	if($r{engine} eq "none"){
	}elsif($r{engine} eq "Text::Xslate"){
		$a->{ENV} = \%ENV;
		$a->{SES} = \%SES;
		$a->{COOKIE} = \%COOKIE;
		$a->{GET} = \%GET;
		$a->{POST} = \%POST;
		print $j->{CGI}->header(qw(-type text/html -charset UTF-8 -cookie),[map{$j->{CGI}->cookie(-name =>$_,-value =>$COOKIE{$_})}keys(%COOKIE)]);
		print $j->{Text::Xslate}->render($r{file},$a);
	}
	return();
}

1;
