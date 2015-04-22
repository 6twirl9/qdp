#!/bin/bash -u

# === command line
if [[ $# -lt 1 ]] ; then
#echo "Usage: $0 [ mode -> header|c_source ] [ precision & colour -> [qdp_]?(df?[23n]?|f[23n]?|int) ] [ output directory ]"
echo "Usage: $0 [ precision & colour -> (.*/)?qdp_(df?[23n]?|f[23n]?|int)/[^/]+ ] [ mode -> common|header|c_source|show_generated_only ]+"
exit
fi

for i in pc ; do
 [[ $# -eq 0 ]] && break ;
 eval $i=$1 ; shift ;
done

pc_=$pc

show_generated_only=false

mode_l=""
for i in $* ; do
 [[ $i == show_generated_only ]] && { eval "$i=true;" ; continue ; }
 mode_l="$mode_l $i"
done

pc=$(dirname $pc)

output=$pc

mkdir -p $output

pc=$(basename $pc)
pc=${pc/qdp_}

template=$(dirname $0)

for i in pc output template ; do
 eval i_=\$$i ; printf "%8s = %s\n" $i "$i_" ;
done

#///

for mode in $mode_l ; do

printf "\n\nMODE = $mode\n\n"

# === alias to and wrappers for perl scripts

for i in types qdp ; do
 eval $i=\"$template/generate_$i.pl $mode\"
done

for i in generic profile virtualNc ; do
 eval $i=\"$template/$i.pl $mode\"
done

function types     { local pc in this ; pc=$1 ; in=$2 ; shift 2 ; this="types" ;
 if $show_generated_only ; then
  for out in $* ; do
   out=$(basename $out) ; out=${out/QDP_/QDP_$(echo $pc | tr '[a-z]' '[A-Z]')_} ;
   [[ $mode == "c_source" ]] && out=$out.pm ;
   printf "%s %8s %s\n" GENERATED $this $output/$out ;
  done
 else
  for out in $* ; do
   printf "# %-16s -> %8s -> %-12s ...\n" $(basename $in) $this $(basename $out) ; $types $pc $in $out ;
  done
 fi
}

function qdp       { local pc out this ; pc=$1 ; out=$2; this="qdp" ;
 if $show_generated_only ; then
  #printf "%s %8s %s\n" GENERATED $this $out ;
  echo
 else
  printf "# %-16s -> %8s -> %-12s ... [$pc]\n" "" $this $(basename $out) ; $qdp -l $pc -d $out ;
 fi
}

function generic   { local g pc in out this ; g=$1 ; pc=$2 ; in=$3 ; out=$4; this="generic" ;
 if $show_generated_only ; then printf "%s %8s %s\n" GENERATED $this $out ; else
  printf "# %-16s -> %8s -> %-12s ...\n" $(basename $in) $this $(basename $out) ; $generic $g $pc $in $out ;
 fi
}

function profile   { local in out this ; in=$1 ; out=$2; this="profile" ;
 if $show_generated_only ; then printf "%s %8s %s\n" GENERATED $this $out ; else
  printf "# %-16s -> %8s -> %-12s ...\n" $(basename $in) $this $(basename $out) ;  $profile $in $out ;
 fi
}

function virtualNc { local in out this ; in=$1 ; out=$2; this="virtualNc" ;
 if $show_generated_only ; then printf "%s %8s %s\n" GENERATED $this $out ; else
  printf "# %-16s -> %8s -> %-12s ...\n" $(basename $in) $this $(basename $out) ; $virtualNc $in $out ;
 fi
}


#///

if [[ $mode == common    ]] ; then # === <- {include,lib/qdp_common}/Makefile.am (no change from qdp-1.9.0-a8)

#
# check for "common"
#
# > grep -nR '$(GEN_TYPES)' *
#
#include/Makefile.am:28:qdp_types.h: $(GENDIR)/qdp_types.h $(GEN_TYPES)
#include/Makefile.am:29:	$(PERL) $(GEN_TYPES) common $(GENDIR)/$@ $(INCDIR)/$@
#
#include/Makefile.am:31:qdp_io.h: $(GENDIR)/qdp_io.h $(GEN_TYPES)
#include/Makefile.am:32:	$(PERL) $(GEN_TYPES) common $(GENDIR)/$@ $(INCDIR)/$@
#
#lib/qdp_common/Makefile.am:10:GEN_TYPES_DEP = $(GEN_TYPES) $(GENDIR)/datatypes.pl
#lib/qdp_common/Makefile.am:32:	$(PERL) $(GEN_TYPES) common $(GENDIR)/qdp_common_internal.h $@
#

for i in types io common_internal ; do
 types $pc $template/qdp_$i.h $output/qdp_$i.h ;
done

if ! $show_generated_only ; then
 cp -pr qdp_common/* $output/
fi

rm -f $pc_.c.pm
touch $pc_

fi
#///
if [[ $mode == header    ]] ; then # === <- generate_headers                     (qdp commit 97995b41b55d73c8b90688824e4cc1b80b357e95)

types    $pc $template/qdp_pc.h $output/qdp_$pc.h ;
qdp      $pc $output

pat_=( "[df][df]*[23n]$" "[df][23n]*$" "[df][23n]$" ) ;
tag_=( ""                "_color"      "_precision" ) ;
  g_=( "g"               "c"           "p"          ) ;

for(( i = 0 ; i < ${#pat_[*]} ; i++ )) ; do

 pat=${pat_[$i]} ; tag=${tag_[$i]} ; g=${g_[$i]} ;

 if [[ $pc =~ ^$pat ]]  ; then
  printf "# matched $pat\n\n" ;
  types      $pc $template/qdp${tag}_generic.h $output/qdp_${pc}${tag}_generic.h ;
  generic $g $pc   $output/qdp_$pc.h           $output/qdp_${pc}${tag}_generic.h ;
 fi

done

types   $pc $template/qdp_profile.h  $output/qdp_${pc}_profile.h
profile       $output/qdp_$pc.h      $output/qdp_${pc}_profile.h

types   $pc $template/qdp_internal.h $output/qdp_${pc}_internal.h

fi
#///
if [[ $mode == c_source  ]] ; then # === <- generate_sources                     (no change from qdp-1.9.0-a8)
echo $output
types    $pc $output $template/*.c
qdp      $pc $output
fi
#///
if [[ $mode == virtualNc ]] ; then # === <- make_virtualNc                      (qdp commit 97995b41b55d73c8b90688824e4cc1b80b357e95)

[[ $pc =~ ^[df]n$ ]] && tag_=( "" "_color" "_precision" ) ;
[[ $pc ==   dfn   ]] && tag_=(    "_color"              ) ;

# not sure where to put the virtual Nc = 1, leave it where Nc = n is.
pc_=${pc%n}1 ; output_=$output ;

# n = 1
virtualNc $output/qdp_${pc}.h $output_/qdp_${pc_}.h

if $show_generated_only ; then
 for(( i = 0 ; i < ${#tag_[*]} ; i++ )) ; do
   echo GENERATED virtualNc $output_/qdp_${pc_}${tag_[$i]}_generic.h
 done
else
 for(( i = 0 ; i < ${#tag_[*]} ; i++ )) ; do
  cat $output/qdp_${pc}${tag_[$i]}_generic.h			\
   | sed -e 's/QDP_Nc,\?//;s/\(QDP_[DFQ]*\)N/\11/g;'	\
   > $output_/qdp_${pc_}${tag_[$i]}_generic.h
 done
fi

fi
#///

done


