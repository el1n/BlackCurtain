package BlackCurtain::Fragility::AmazonPromoCode;
use Carp;
use base qw(BlackCurtain::Fragility);

sub redeem
{
	my $j = shift();
	my $c = shift();
	my $u = shift();
	my $p = shift();

	if($u ne $j->{__PACKAGE__}->{u} || $p ne $j->{__PACKAGE__}->{p}){
		$j->clean();
	}
	$j->{__PACKAGE__}->{u} = $u;
	$j->{__PACKAGE__}->{p} = $p;

	$j->http("https://www.amazon.co.jp/gp/css/account/payment/view-gc-balance.html/ref=ya__reddem",{form =>"ap_signin_form"});
}

1;
