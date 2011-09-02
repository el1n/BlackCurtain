package BlackCurtain::DBI::ORM;
use Carp;
use vars;
use DBI;

sub loadscheme()
{
	shift();
	my $scheme = shift();
	my %a = @_;

	if(!defined(&{"BlackCurtain::DBI::Scheme::".$scheme."::new"})){
		@{"BlackCurtain::DBI::Scheme::".$scheme."::ISA"} = qw(BlackCurtain::DBI::ORM::Scheme);
	}

	if(my $j = ("BlackCurtain::DBI::Scheme::".$scheme)->new(%a)){
		(my $sth = $j->{dbh}->prepare("SHOW COLUMNS FROM `".$scheme."`"))->execute();
		for(my $i = 0;my $record = $sth->fetch();++$i){
			${"BlackCurtain::DBI::Scheme::".$scheme."::STRUCTURE"}->{undef} = $scheme;
			${"BlackCurtain::DBI::Scheme::".$scheme."::STRUCTURE"}->{$i} = [$i,undef,undef,undef,@{$record}];
			${"BlackCurtain::DBI::Scheme::".$scheme."::STRUCTURE"}->{$record->[0]} = ${"BlackCurtain::DBI::Scheme::".$scheme."::STRUCTURE"}->{$i};
			if($record->[3] eq "PRI"){
				${"BlackCurtain::DBI::Scheme::".$scheme."::STRUCTURE"}->{"PRIMARY"} = ${"BlackCurtain::DBI::Scheme::".$scheme."::STRUCTURE"}->{$i};
			}elsif($record->[3] eq "MUL"){
			}
		}
		return($j);
	}else{
		return();
	}
}

package BlackCurtain::DBI::ORM::Scheme;
use Carp;
use vars qw($AUTOLOAD);
use DBI;

AUTOLOAD
{
	my $j = shift();
	my @a = @_;

	(my $func = $AUTOLOAD) =~s/^.+:://igo;
	if(defined(my $i = ${ref($j)."::STRUCTURE"}->{$func}->[0])){
		*{$AUTOLOAD} = sub(){
			my $j = shift();
			my $k = shift();
			my $v = shift();

			if(defined($k) && defined(${ref($j)."::STRUCTURE"}->{"PRIMARY"}) && $k ne $j->{cache}->[${ref($j)."::STRUCTURE"}->{"PRIMARY"}->[0]]){
				$j->pop(${ref($j)."::STRUCTURE"}->{"PRIMARY"}->[4] =>$k);
			}
			return($j->{cache}->[$i]);
		};
		return($j->$func(@a));
	}else{
		return();
	}
}

sub new()
{
	my $j = shift();
	my %a = @_;

	if(!defined($a{dbh})){
		if(!($a{dbh} = (defined($a{dbi}) ? $a{dbi} : "DBI")->connect(@{$a{dsn}}))){
		}
	}
	return(bless({dbh =>$a{dbh}},$j));
}

sub pop()
{
	my $j = shift();
	my %a = @_;

	(my $sth = $j->prepare([keys(%a)],1))->execute(values(%a));
	$j->{cache} = $sth->fetch();
	return();
}

sub prepare()
{
	my $j = shift();
	my $a = shift();
	my $c = int(shift());
	my $i = int(shift());
	my $label = "".join(",",@{$a});

	if(!defined($j->{$label})){
		$j->{$label} = $j->{dbh}->prepare(sprintf("SELECT * FROM `%s` WHERE %s%s",${ref($j)."::STRUCTURE"}->{undef},join(" AND ",map{ sprintf(defined(${ref($j)."::STRUCTURE"}->{$_}->[1]) ? "`%s` = %s(?)" : "%s = ?",$_,${ref($j)."::STRUCTURE"}->{$_}->[1]) }@{$a}),($c > 0 ? sprintf(" LIMIT %d,%d",$i,$c) : undef)));
	}
	return($j->{$label});
}

1;
