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

	return(bless({callback =>$a,map{$_ =>$_->new(@{$a{$_}})}qw(CGI CGI::Session Text::Xslate)},$j));
}

sub perform:method
{
	my $j = shift();
	my $a = shift();
	my %a = @_;

	my %_COOKIE = CGI::Cookie->fetch();
	$j->{CGI::Session}->load(defined($_COOKIE{IGNORANCE_SESSION}) ? $_COOKIE{IGNORANCE_SESSION}->value() : undef);

	local %ENV = (%ENV,SESSION =>$j->{CGI::Session}->id());
	local %SES = %{$j->{CGI::Session}->dataref()};
	local %COOKIE = map{$_ =>$_->value()}keys(%_COOKIE);
	local %GET;
	local %POST;
	my($engine,%r) = &{$j->{callback}->{(grep{$ENV{PATH_INFO} =~ $_}keys(%{$j->{callback}}))[0]}}();
	if($engine eq "none"){
	}elsif($engine eq "jump"){
	}elsif($engine eq "Text::Xslate"){
		$a->{ENV} = \%ENV;
		$a->{SES} = \%SES;
		$a->{COOKIE} = \%COOKIE;
		$a->{GET} = \%GET;
		$a->{POST} = \%POST;
		print $j->{CGI}->header(qw(-type text/html -charset UTF-8 -cookie),[$j->{}->cookie("IGNORANCE_SESSION",$ENV{SESSION})]);
		print $j->{Text::Xslate}->render($r{file},$a);
	}
	return();
}

1;
