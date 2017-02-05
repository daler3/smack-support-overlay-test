#!/bin/bash

#declare -i SUCCESS=0
#declare -i FAILURE=0
###create overlay######
clear
clear
clear
#mkdir /home/daniele/Desktop/ovtest/base
export BASEDIR="/home/daniele/Desktop/ovtest/base"

mkdir "$BASEDIR/lower"
mkdir "$BASEDIR/upper"
mkdir "$BASEDIR/merged"
mkdir "$BASEDIR/work"
mkdir "$BASEDIR/upper/subupper"
mkdir "$BASEDIR/lower/sublower"

#setlabel
attr -S -s SMACK64 -V "SMACK64_lowerdir" $BASEDIR/lower
attr -S -s SMACK64 -V "SMACK64_upperdir" $BASEDIR/upper
attr -S -s SMACK64 -V "SMACK64_subupperdir_trans" $BASEDIR/upper/subupper
attr -S -s SMACK64 -V "SMACK64_sublowerdir_trans" $BASEDIR/lower/sublower
attr -S -s SMACK64 -V "SMACK64_mergeddir" $BASEDIR/merged
attr -S -s SMACK64 -V "SMACK64_workdir" $BASEDIR/work

#settransmute
attr -S -s SMACK64TRANSMUTE -V "TRUE" $BASEDIR/upper/subupper
attr -S -s SMACK64TRANSMUTE -V "TRUE" $BASEDIR/lower/sublower

echo "file in upper preparation phase" > $BASEDIR/upper/subupper/upperfile_pre
echo "file in lower preparation phase" > $BASEDIR/lower/sublower/lowerfile_pre


#mounting overlay
mount -t overlay -o lowerdir=$BASEDIR/lower,upperdir=$BASEDIR/upper,workdir=$BASEDIR/work overlay $BASEDIR/merged
echo '------------------'
echo '------------------'
echo "Overlay mounted."
echo '------------------'
echo '------------------'



echo "- TEST 0: Check if the label of the folders in the merged dir is the same as the original"
labelfoldermergup="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/subupper --only-values 2> /dev/null)"
labelfoldermerglow="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/sublower --only-values 2> /dev/null)"
labelfolderup="$(getfattr -d -n security.SMACK64 $BASEDIR/upper/subupper --only-values 2> /dev/null)"
labelfolderlow="$(getfattr -d -n security.SMACK64 $BASEDIR/lower/sublower --only-values 2> /dev/null)"

echo "--- TEST 0.1: Merged Vs Upper? "
if [ $labelfoldermergup == $labelfolderup ];
then
    echo "------ YES"
else
	echo "------ NO"
fi


echo "--- TEST 0.2: Merged Vs Lower? "
if [ $labelfoldermerglow == $labelfolderlow ];
then
    echo "------ YES"
else
	echo "------ NO"
fi



##create a file in up 
echo "file in upper" > $BASEDIR/merged/subupper/upperfile
labelfolder="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/subupper --only-values 2> /dev/null)"
filelabelmerg="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/subupper/upperfile --only-values 2> /dev/null)"
filelabelup="$(getfattr -d -n security.SMACK64 $BASEDIR/upper/subupper/upperfile --only-values 2> /dev/null)"


echo "- TEST 1: Create file in the upperdir. Is the file label the same as the folder's?"

echo "--- TEST 1.1: In the mergeddir? "
if [ $labelfolder ==  $filelabelmerg ];
then
    echo "------ YES"
else
	echo "------ NO"
fi


echo "--- TEST 1.2: In the upperdir? "
if [ $labelfolder ==  $filelabelup ];
then
    echo "------ YES"
else
	echo "------ NO"
fi


##create a file in down
echo "file in lower" > $BASEDIR/merged/sublower/lowerfile
labelfolder="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/sublower --only-values 2> /dev/null)"
filelabelmerg="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/sublower/lowerfile --only-values 2> /dev/null)"
filelabelup="$(getfattr -d -n security.SMACK64 $BASEDIR/upper/sublower/lowerfile --only-values 2> /dev/null)"
filelabellow="$(getfattr -d -n security.SMACK64 $BASEDIR/lower/sublower/lowerfile --only-values 2> /dev/null)"

echo "- TEST 2: Create file in the lowerdir. Is the file label the same as the folder's?"

echo "--- TEST 2.1: In the mergedir? "
if [ $labelfolder ==  $filelabelmerg ];
then
    echo "------ YES"
else
	echo "------ NO"
fi


echo "--- TEST 2.2: In the upperdir? "
if [ $labelfolder ==  $filelabelup ];
then
    echo "------ YES"
else
	echo "------ NO"
fi

echo "--- TEST 2.3: In the lowerdir? "
if [ $labelfolder ==  $filelabellow ];
then
    echo "------ YES"
else
	echo "------ NO"
fi


####change the labels to the dir in merged and check files' labels (if change)
attr -S -s SMACK64 -V "SMACK64_subupperdir_trans_MODIFIED" $BASEDIR/merged/subupper
attr -S -s SMACK64 -V "SMACK64_sublowerdir_trans_MODIFIED" $BASEDIR/merged/sublower

#we know that the label is modified just in the upper
#we check what happens to the file in merged
labelfoldermerg_up="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/subupper --only-values 2> /dev/null)"
labelfoldermerg_low="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/sublower --only-values 2> /dev/null)"
filelabelmergup="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/subupper/upperfile --only-values 2> /dev/null)"
filelabelmerglow="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/sublower/lowerfile --only-values 2> /dev/null)"

echo "- TEST 3: Change the label in the merge of the transmute dir. What happens to the file inside it? Do they change label as well?"

echo "--- TEST 3.1: In the merged, originally in the upper: "
if [ $labelfoldermerg_up == $filelabelmergup ];
then
    echo "------ YES"
else
	echo "------ NO"
fi


echo "--- TEST 3.2: In the merged, originally in the lower: "
if [ $labelfoldermerg_low == $filelabelmerglow ];
then
    echo "------ YES"
else
	echo "------ NO"
fi



######modifying files created in preparation phase
labelupperfilepre_pretest="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/subupper/upperfile_pre --only-values 2> /dev/null)"
labellowerfilepre_pretest="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/sublower/lowerfile_pre --only-values 2> /dev/null)"
echo " --file in the upper created in preparation phase modified" >> $BASEDIR/merged/subupper/upperfile_pre #append
echo " --file in the lower created in preparation phase modified" >> $BASEDIR/merged/sublower/lowerfile_pre #append
labelupperfilepre_aft="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/subupper/upperfile_pre --only-values 2> /dev/null)"
labellowerfilepre_aft="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/sublower/lowerfile_pre --only-values 2> /dev/null)"

echo "- TEST 4: Modifying files created in preparation phase. What happens to the label of these files (in merged dir)?"

echo "--- TEST 4.1: Label of the upper file (created in prep. phase): Is it the same as before? "

if [ $labelupperfilepre_pretest == $labelupperfilepre_aft ];
then
    echo "------ YES"
else
	echo "------ NO"
fi

echo "--- TEST 4.2: Label of the lower file (created in prep. phase): Is it the same as before? "

if [ $labellowerfilepre_pretest == $labellowerfilepre_aft ];
then
    echo "------ YES"
else
	echo "------ NO"
fi


labelupperfile_pretest="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/subupper/upperfile --only-values 2> /dev/null)"
labellowerfile_pretest="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/sublower/lowerfile --only-values 2> /dev/null)"
echo " --file in the upper created in second phase modified" >> $BASEDIR/merged/subupper/upperfile #append
echo " --file in the lower created in second phase modified" >> $BASEDIR/merged/sublower/lowerfile #append
labelupperfile_aft="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/subupper/upperfile --only-values 2> /dev/null)"
labellowerfile_aft="$(getfattr -d -n security.SMACK64 $BASEDIR/merged/sublower/lowerfile --only-values 2> /dev/null)"

echo "- TEST 5: Modifying files created in the second phase, after mounting overlay. What happens to the label of these files (in merged dir)?"
echo "--- TEST 5.1: Label of the upper file (created in second phase): Is it the same as before? "

if [ $labelupperfile_pretest == $labelupperfile_aft ];
then
    echo "------ YES"
else
	echo "------ NO"
fi

echo "--- TEST 5.2: Label of the lower file (created in second phase): Is it the same as before? "

if [ $labellowerfile_pretest == $labellowerfile_aft ];
then
    echo "------ YES"
else
	echo "------ NO"
fi

###cleanup####
echo '-----------------'
echo '-----------------'
echo '-----------------'
echo 'Unmounting overlay.'
umount $BASEDIR/merged
echo 'Removing filesystem.'
rm -rf $BASEDIR
echo 'Remount filesystem for further tests.'
mkdir $BASEDIR
