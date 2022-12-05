#!/usr/bin/perl -w
use strict;
use IO::File;
my $fh_in = IO::File->new("decker.bim.bak",'r');
my $fh_out = IO::File->new(">decker.V2.bim");
my $fh_50K_V2 = IO::File->new("/public/home/wangjinpeng/01.cattle/07.WIDDE_and_Decker_50K/02.50K_V2/50K_V2_filter.bim",'r');
my %V2;
while(<$fh_50K_V2>){
	chomp;
	my @eles = split /\s+/, $_;
	my ($chr, $snpid, $zero, $pos, $allele1, $allele2)=@eles;
	my $loci="$chr-$pos";
	$V2{$loci}{snpid}=$snpid;
	$V2{$loci}{allele1}=$allele1;
	$V2{$loci}{allele2}=$allele2;
}

my %decker;

while(<$fh_in>){
	chomp;
	my $line = $_;
	my @eles = split /\s+/, $line;
	my ($chr, $snpid, $zero, $pos, $allele1, $allele2)=@eles;
	my $loci="$chr-$pos";

	if(exists $V2{$loci}){
		my $V2_snpid=$V2{$loci}{snpid};
		my $V2_allele1=$V2{$loci}{allele1};
		my $V2_allele2=$V2{$loci}{allele2};
		my $V2_geno="$V2_allele1$V2_allele2";
		if(exists $decker{$loci} ){
			$V2_snpid="$V2_snpid-dup";
		}else{
			$decker{$loci}=1
		}
		


		if($V2_geno=~/A/){
			my $new_decker_B;
			if($V2_allele1 eq "A"){
				$new_decker_B = $V2_allele2;
			}
			if($V2_allele2 eq "A"){
				$new_decker_B = $V2_allele1;
			}
			if($allele1 eq "A"){
				$allele2 = $new_decker_B;
			}
			if($allele2 eq "A"){
				$allele1 = $new_decker_B;
			}
			$fh_out->print("$chr\t$V2_snpid\t$zero\t$pos\t$allele1\t$allele2\n");
		}
		else{
			if($allele1 eq "A"){
				$allele1 = "C";
				$allele2 = "G";
			}
			if($allele2 eq "A"){
				$allele2 ="C";
				$allele1  ="G";
			}
			$fh_out->print("$chr\t$V2_snpid\t$zero\t$pos\t$allele1\t$allele2\n");
		}
	}
	else{
		$fh_out->print("$line\n");
	}
}

