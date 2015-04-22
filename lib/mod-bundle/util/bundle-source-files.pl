#!/usr/bin/env perl

use strict ;
use File::Path qw(mkpath) ;
use File::Copy ;
use File::Copy::Recursive qw/dircopy/ ;
use Data::Dump qw(dump) ;
use List::Util qw/min max/ ;

my @function_index = @ARGV ;

# === index the full list of functions

my %t ;

map
{
 my ($qdp,$function) = @{[split '/', $_ ]}[-2,-1] ;
 $t{$qdp}->{$function} = $_ ;
}
 @function_index ;

#///

#map { printf "%-12s %-48s %3d %s\n", @{$_} ; } sort { $a->[2] <=> $b->[2] }
map { my $qdp = $_ ;
 map { my $function = $_ ;
  my %d = do $t{$qdp}->{$function} ;
  my @d = keys %{$d{function}} ;

  if( (0+@d) == 0 )
  {
   printf "%8s %-48s %3d%s", $qdp, $function, 0+@d, (0+@d)?"":" [SKIP]" ;
   printf "\n" ;
  }

  #[ $qdp, $function, 0+@d, $t{$qdp}->{$function} ] ;

  if( (0+@d) > 0 )
  {
   my $N = ((0+@d)>50)?16:1 ;

   my @p = split '/', $t{$qdp}->{$function} ; pop(@p) ;
   my $bundle = join('/', @p, "bundle") ;
   mkpath $bundle ;
   my $f ; ( $f = $function ) =~ s/.pm// ;

   my @s_ ; map { @{$s_[$_]} = () } 0..$N-1 ;

   { my $i = 0 ; map { push @{$s_[$i%$N]}, $_ ; $i++ ; } @d ; }

   printf "%8s %-48s %3d [parts = %4d] ->  ", $qdp, $function, 0+@d, $N ;

   map {
    my $i = $_ ;
    open my $o,">", "$bundle/$f.$i.c" ;
     map { printf $o "#include \"$_\"\n" ; } @{$d{include}} ;
     map { my $function = $_ ;
      map { printf $o "%s\n",$_ ; } @{$d{function}->{$function}->{definition}} ;
     } @{$s_[$i]} ;
    close $o ;
    printf "[%d]", $i ;
   } 0..$#s_ ;
   printf "\n" ;
  }

 } sort keys %{$t{$qdp}} ;
} sort keys %t ;

