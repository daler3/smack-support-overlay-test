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


#####setting up file system#####
echo "file in upper" > $BASEDIR/upper/upperfile
echo "second file in upper" > $BASEDIR/upper/upperfile2
echo "third file in upper" > $BASEDIR/upper/upperfile3
mkdir $BASEDIR/upper/subupper
mkdir $BASEDIR/upper/subupper4
mkdir $BASEDIR/upper/subupper3 #other subdirectory in the upper
echo "file in subdir of upper" > $BASEDIR/upper/subupper/subupperfile
echo "second file in subdir of upper" > $BASEDIR/upper/subupper/subupperfile2

echo "file in lower" > $BASEDIR/lower/lowerfile
echo "second file in lower" > $BASEDIR/lower/lowerfile2
echo "third file in lower" > $BASEDIR/lower/lowerfile3
mkdir $BASEDIR/lower/sublower
mkdir $BASEDIR/lower/sublower4
mkdir $BASEDIR/lower/sublower3 #other subdirectory in the upper
echo "file in subdir of lower" > $BASEDIR/lower/sublower/sublowerfile
echo "second file in subdir of lower" > $BASEDIR/lower/sublower/sublowerfile2

echo "file in merged" > $BASEDIR/merged/mergedfile
mkdir $BASEDIR/merged/submerged
echo "file in subdir of merged" > $BASEDIR/merged/submerged/submergedfile

#mounting overlay
mount -t overlay -o lowerdir=$BASEDIR/lower,upperdir=$BASEDIR/upper,workdir=$BASEDIR/work overlay $BASEDIR/merged
echo '------------------'
echo '------------------'
echo "Overlay mounted."
echo '------------------'
echo '------------------'

echo '-----------------'
echo '-----------------'
echo '------------------'
echo 'TESTS ON FILES ORIGINALLY IN THE UPPER'
echo '-----------------'
echo '-----------------'
echo '-----------------'


#####file originally in the upper layer scenarios###########
filename="${BASEDIR}/upper/upperfile"
filename2="${BASEDIR}/merged/upperfile"
attr -S -s selinux -V "unconfined_u:object_r:label_changed_upperfile_t:s0" $filename2
labelupupper="$(getfattr -d -n security.selinux $filename --only-values 2> /dev/null)"
labelupmerged="$(getfattr -d -n security.selinux $filename2 --only-values 2> /dev/null)"

echo "- TEST 1: Modifying a label on a file in the upper layer. Label of file in upper layer equal to the one in merged?"
if [ $labelupupper ==  $labelupmerged ];
then
    echo "------ YES"
else
	echo "------ NO"
fi

####I change labels on a directory in the upper, let's see what happens on the file, does it get the label of the dir?
filename="${BASEDIR}/upper/subupper/subupperfile"
filename2="${BASEDIR}/merged/subupper/subupperfile"
dirname1="${BASEDIR}/upper/subupper"
dirname2="${BASEDIR}/merged/subupper"
attr -S -s selinux -V "unconfined_u:object_r:label_changed_subupper_dir_t:s0" $dirname2 #modify label on merged 
labelsubupdirup="$(getfattr -d -n security.selinux $dirname1 --only-values 2> /dev/null)"
labelsubupdirmerg="$(getfattr -d -n security.selinux $dirname2 --only-values 2> /dev/null)"
labelsubupfileup="$(getfattr -d -n security.selinux $filename1 --only-values 2> /dev/null)" #label of file in the subupperdir of upper
labelsubupfilemerg="$(getfattr -d -n security.selinux $filename2 --only-values 2> /dev/null)" #label of file in the subupperdir of merged

echo "- TEST 2: Modifying a label on a directory in the upper."
echo "--- TEST 2.1: Is the label of upper directory modified?"

if [ $labelsubupdirup ==  $labelsubupdirmerg ];
then
    echo "------ YES"
else
	echo "------ NO"
fi

echo "--- TEST 2.2: Is the label of directory inehrited from dir to the file"

if [ $labelsubupdirmerg == $labelsubupfilemerg ];
then
    echo "------ YES"
    echo "--- TEST 2.3: Is the label of the file in directory in the upper modified as well? "

    if [ $labelsubupfileup == $labelsubupfilemerg ];
	then
		echo "------ YES"
	else
		echo "------ NO"
	fi
else
	echo "------ NO"
fi


###MODIFY A FILE IN THE CONTENT AND THEN CHECK IF THE CONTENT OF THE FILE IS EQUAL IN THE UPPER#####
echo "second file in the subupper modified" >> $BASEDIR/merged/subupper/subupperfile2 #append
file1="${BASEDIR}/merged/subupper/subupperfile2"
file2="${BASEDIR}/upper/subupper/subupperfile2"
filename2="${BASEDIR}/merged/upperfile2"

echo "- TEST 3: Modifying a file originally in the upperdir in the content."
echo "--- TEST 3.1: Is the file modified in the upperdir?"

declare -i result
result="$(cmp -l $file1 $file2)"
if [ $result > 0 ];
then
	echo "------ YES"
	attr -S -s selinux -V "unconfined_u:object_r:label_changed_subupperfile2_t:s0" $file1
	echo "--- TEST 3.2: Modifying label on the file just modified in the content. Is the label modified also in the upper?"
	label1="$(getfattr -d -n security.selinux $file1 --only-values 2> /dev/null)"
	label2="$(getfattr -d -n security.selinux $file2 --only-values 2> /dev/null)"

	if [ $label1 == $label2 ];
	then
    	echo "------ YES"
	else
		echo "------ NO"
	fi

else
	echo "------ NO"
fi


###now change label on directory of modified file, check if this file modified has the same label of the dir, and check in the upper as well
filename1="${BASEDIR}/upper/subupper/subupperfile2"
filename2="${BASEDIR}/merged/subupper/subupperfile2"
dir1="${BASEDIR}/upper/subupper"
dir2="${BASEDIR}/merged/subupper"
attr -S -s selinux -V "unconfined_u:object_r:label_changed_subupperfile2_dir:s0" $dir2
labelfile1="$(getfattr -d -n security.selinux $filename1 --only-values 2> /dev/null)"
labelfile2="$(getfattr -d -n security.selinux $filename2 --only-values 2> /dev/null)"
labeldir1="$(getfattr -d -n security.selinux $dir1 --only-values 2> /dev/null)"
labeldir2="$(getfattr -d -n security.selinux $dir2 --only-values 2> /dev/null)"

echo "- TEST 4: Modifying a label of the directory of just modified file."
echo "--- TEST 4.1: Is the label of the file in directory in the merged modified as well?"
#check just in the merged
if [ $labeldir2 == $labelfile2 ];
then
	echo "------ YES"
	echo "--- TEST 4.2: Is the label of the file in the upper directory getting the same label of the file in the merged?"
	#check in the upper if 
	if [ $labelfile2 == $labelfile1 ];
	then
		echo "------ YES"
	else
		echo "------ NO"
	fi
else
	echo "------ NO"
fi


###now rename a file, check file name the upper
mv $BASEDIR/merged/upperfile2 $BASEDIR/merged/upperfile2_name_modified
echo "- TEST 5: Modifying a name of a file originally in the upper directory. Is the file name modified in the upperdir as well?"

if [ -f $BASEDIR/upper/upperfile2_name_modified ]; 
then
	echo "------ YES"
else
	echo "------ NO"
fi


###now rename a directory, check directory name in the upper
mv $BASEDIR/merged/subupper $BASEDIR/merged/subupper_modified_name
echo "- TEST 6: Modifying a name of a directory originally in the upper directory. Is the directory name modified in the upperdir as well?"

if [ -d $BASEDIR/upper/subupper_modified_name ]; #directory name in upper is changed
then
	echo "------ YES"
else
	echo "------ NO"
fi


###now remove a file, check if it is still there in the upper
rm $BASEDIR/merged/upperfile3
echo "- TEST 7: Removing a file originally in the upper directory. Is the file removed in the upper directory as well?"

if [ -f $BASEDIR/upper/upperfile3 ]; #directory name in upper is changed
then
	echo "------ NO"
else
	echo "------ YES"
fi


###now remove a directory, check if it is still there in the upper
rm -rf $BASEDIR/merged/subupper3/
echo "- TEST 8: Removing a directory originally in the upper directory. Is the directory removed in the upper directory as well?"

if [ -d $BASEDIR/upper/subupper3 ]; #directory name in upper is changed
then
	echo "------ NO"
else
	echo "------ YES"
fi


echo "new file in subdir of upper" > $BASEDIR/merged/subupper4/verynewupperfile

echo "- TEST 9: Creating a new file in an original directory of upper dir. Is the file in the upperdir as well?"
if [ -f $BASEDIR/upper/subupper4/verynewupperfile ]; 
then
	echo "------ YES"
else
	echo "------ NO"
fi




#################NOW DO SAME THINGS IN THE LOWER, BUT CHECK THE MERGED AND THE UPPER DIRECTORY AS WELL ###################
echo '------------------'
echo '-----------------'
echo '-----------------'
echo 'TESTS ON FILES ORIGINALLY IN THE LOWER'
echo '-----------------'
echo '-----------------'
echo '-----------------'








#####file originally in the lower layer scenarios###########
filename="${BASEDIR}/lower/lowerfile"
filename2="${BASEDIR}/merged/lowerfile"
filename3="${BASEDIR}/upper/lowerfile"
attr -S -s selinux -V "unconfined_u:object_r:label_changed_lowerfile_t:s0" $filename2
labellowlower="$(getfattr -d -n security.selinux $filename --only-values 2> /dev/null)"
labellowmerged="$(getfattr -d -n security.selinux $filename2 --only-values 2> /dev/null)"
labellowupper="$(getfattr -d -n security.selinux $filename3 --only-values 2> /dev/null)"

echo "- TEST 11: Modifying a label on a file originally in the lower layer. "
echo "--- TEST 11.1: Label of file in lower layer equal to the one in merged?"
if [ $labellowlower ==  $labellowmerged ];
then
    echo "------ YES"
else
	echo "------ NO"
fi
echo "--- TEST 11.2: Label of file in upper layer equal to the one in merged?"
if [ $labellowupper ==  $labellowmerged ];
then
    echo "------ YES"
else
	echo "------ NO"
fi


####I change labels on a directory in the lower, let's see what happens on the file, does it get the label of the dir?
filename="${BASEDIR}/lower/sublower/sublowerfile"
filename2="${BASEDIR}/merged/sublower/sublowerfile"
dirname1="${BASEDIR}/lower/sublower"
dirname2="${BASEDIR}/merged/sublower"
dirname3="${BASEDIR}/upper/sublower"
attr -S -s selinux -V "unconfined_u:object_r:label_changed_sublower_dir_t:s0" $dirname2 #modify label on merged 

labelsublowdirlow="$(getfattr -d -n security.selinux $dirname1 --only-values 2> /dev/null)"
labelsublowdirmerg="$(getfattr -d -n security.selinux $dirname2 --only-values 2> /dev/null)"
labelsublowdirupper="$(getfattr -d -n security.selinux $dirname3 --only-values 2> /dev/null)"

labelsublowfilelow="$(getfattr -d -n security.selinux $filename1 --only-values 2> /dev/null)" #label of file in the sublowerdir of lower
labelsublowfilemerg="$(getfattr -d -n security.selinux $filename2 --only-values 2> /dev/null)" #label of file in the sublowerdir of merged
labelsublowfileupper="$(getfattr -d -n security.selinux $filename3 --only-values 2> /dev/null)" #label of file in the sublowerdir of upper

echo "- TEST 12: Modifying a label on a directory in the lower."
echo "--- TEST 12.1: Is the label of lower directory modified?"

if [ $labelsublowdirlow ==  $labelsublowdirmerg ];
then
    echo "------ YES"
else
	echo "------ NO"
fi

echo "--- TEST 12.2: Is the label of upper directory modified?"
if [ $labelsublowdirupper ==  $labelsublowdirmerg ];
then
    echo "------ YES"
else
	echo "------ NO"
fi

echo "--- TEST 12.3: Is the label of directory inehrited from dir to the file?"
if [ $labelsublowdirmerg == $labelsublowfilemerg ];
then
    echo "------ YES"

    echo "--- TEST 12.4: Is the label of the file in directory in the lower modified as well? "
    if [ $labelsublowfilelow == $labelsublowfilemerg ];
	then
		echo "------ YES"
	else
		echo "------ NO"
	fi

	echo "--- TEST 12.5: Is the label of the file in directory in the upper modified as well? "
    if [ $labelsublowfileupper == $labelsublowfilemerg ];
	then
		echo "------ YES"
	else
		echo "------ NO"
	fi

else
	echo "------ NO"
fi




###MODIFY A FILE IN THE CONTENT AND THEN CHECK IF THE CONTENT OF THE FILE IS EQUAL IN THE lower#####
echo "second file in the sublower modified" >> $BASEDIR/merged/sublower/sublowerfile2 #append
file1="${BASEDIR}/merged/sublower/sublowerfile2"
file2="${BASEDIR}/lower/sublower/sublowerfile2"
file3="${BASEDIR}/upper/sublower/sublowerfile2"
filename2="${BASEDIR}/merged/lowerfile2"

echo "- TEST 13: Modifying a file originally in the lowerdir in the content."
echo "--- TEST 13.1: Is the file modified in the lowerdir?"

declare -i result
result="$(cmp -l $file1 $file2)"
if [ $result > 0 ];
then
	echo "------ YES"
	attr -S -s selinux -V "unconfined_u:object_r:label_changed_sublowerfile2_t:s0" $file1
	echo "--- TEST 13.1.2: Modifying label on the file just modified in the content. Is the label modified also in the lower?"
	label1="$(getfattr -d -n security.selinux $file1 --only-values 2> /dev/null)"
	label2="$(getfattr -d -n security.selinux $file2 --only-values 2> /dev/null)"

	if [ $label1 == $label2 ];
	then
    	echo "------ YES"
	else
		echo "------ NO"
	fi

else
	echo "------ NO"
fi

echo "--- TEST 13.2: Is the file modified in the upperdir?"

result="$(cmp -l $file1 $file3)"
if [ $result > 0 ];
then
	echo "------ YES"
	attr -S -s selinux -V "unconfined_u:object_r:label_changed_sublowerfile2_t:s0" $file1
	echo "--- TEST 13.2.2: Modifying label on the file just modified in the content. Is the label modified also in the upper?"
	label1="$(getfattr -d -n security.selinux $file1 --only-values 2> /dev/null)"
	label3="$(getfattr -d -n security.selinux $file3 --only-values 2> /dev/null)"

	if [ $label1 == $label3 ];
	then
    	echo "------ YES"
	else
		echo "------ NO"
	fi

else
	echo "------ NO"
fi


###now change label on directory of modified file, check if this file modified has the same label of the dir, and check in the lower as well
filename1="${BASEDIR}/lower/sublower/sublowerfile2"
filename2="${BASEDIR}/merged/sublower/sublowerfile2"
filename3="${BASEDIR}/upper/sublower/sublowerfile2"
dir1="${BASEDIR}/lower/sublower"
dir2="${BASEDIR}/merged/sublower"
dir3="${BASEDIR}/upper/sublower"
attr -S -s selinux -V "unconfined_u:object_r:label_changed_sublowerfile2_dir:s0" $dir2
labelfile1="$(getfattr -d -n security.selinux $filename1 --only-values 2> /dev/null)"
labelfile2="$(getfattr -d -n security.selinux $filename2 --only-values 2> /dev/null)"
labelfile3="$(getfattr -d -n security.selinux $filename3 --only-values 2> /dev/null)"
labeldir1="$(getfattr -d -n security.selinux $dir1 --only-values 2> /dev/null)"
labeldir2="$(getfattr -d -n security.selinux $dir2 --only-values 2> /dev/null)"
labeldir3="$(getfattr -d -n security.selinux $dir3 --only-values 2> /dev/null)"

echo "- TEST 14: Modifying a label of the directory of just modified file."
echo "--- TEST 14.1: Is the label of the file in directory in the merged modified as well?"
#check just in the merged
if [ $labeldir2 == $labelfile2 ];
then
	echo "------ YES"
	echo "--- TEST 14.2: Is the label of the file in the lower directory getting the same label of the file in the merged?"
	#check in the lower  
	if [ $labelfile2 == $labelfile1 ];
	then
		echo "------ YES"
	else
		echo "------ NO"
	fi
	echo "--- TEST 14.3: Is the label of the file in the upper directory getting the same label of the file in the merged?"
	#check in the upper  
	if [ $labelfile2 == $labelfile3 ];
	then
		echo "------ YES"
	else
		echo "------ NO"
	fi
else
	echo "------ NO"
fi




###now rename a file, check file name the lower
mv $BASEDIR/merged/lowerfile2 $BASEDIR/merged/lowerfile2_name_modified
echo "- TEST 15: Modifying a name of a file originally in the lower directory. Is the file name modified in the lowerdir as well?"
echo "--- TEST 15.1: Is the file name modified in the lowerdir as well?" 

if [ -f $BASEDIR/lower/lowerfile2_name_modified ]; 
then
	echo "------ YES"
else
	echo "------ NO"
fi

echo "--- TEST 15.2: Is the file name modified in the upperdir as well?" 
if [ -f $BASEDIR/upper/lowerfile2_name_modified ]; 
then
	echo "------ YES"
else
	echo "------ NO"
fi


###now rename a directory, check directory name in the lower
mv $BASEDIR/merged/sublower $BASEDIR/merged/sublower_modified_name
echo "- TEST 16: Modifying a name of a directory originally in the lower directory."
echo "--- TEST 16.1: Is the directory name modified in the lowerdir as well?" 
if [ -d $BASEDIR/lower/sublower_modified_name ]; #directory name in lower is changed
then
	echo "------ YES"
else
	echo "------ NO"
fi

echo "--- TEST 16.2: Is the directory name modified in the upperdir as well?" 
if [ -d $BASEDIR/upper/sublower_modified_name ]; #directory name in upper is changed
then
	echo "------ YES"
else
	echo "------ NO"
fi


###now remove a file, check if it is still there in the lower
rm $BASEDIR/merged/lowerfile3
echo "- TEST 17: Removing a file originally in the lower directory. Is the file removed in the lower directory as well?"
echo "--- TEST 17.1:  Is the file removed in the lower directory as well?" 

if [ -f $BASEDIR/lower/lowerfile3 ]; #directory name in lower is changed
then
	echo "------ NO"
else
	echo "------ YES"
fi
echo "--- TEST 17.2:  Is the file removed in the upper directory as well?" 

if [ -f $BASEDIR/upper/lowerfile3 ]; #directory name in upper is changed
then
	echo "------ NO"
else
	echo "------ YES"
fi


###now remove a directory, check if it is still there in the lower
rm -rf $BASEDIR/merged/sublower3/
echo "- TEST 8: Removing a directory originally in the lower directory."
echo "--- TEST 18.1: Is the directory removed in the lower directory as well?"

if [ -d $BASEDIR/lower/sublower3 ]; #directory name in lower is changed
then
	echo "------ NO"
else
	echo "------ YES"
fi

echo "--- TEST 18.2: Is the directory removed in the upper directory as well?"
if [ -d $BASEDIR/upper/sublower3 ]; #directory name in upper is changed
then
	echo "------ NO"
else
	echo "------ YES"
fi


echo "new file in subdir of lower" > $BASEDIR/merged/sublower4/verynewlowerfile

echo "- TEST 19: Creating a new file in an original directory of lower dir. Is the file in the lowerdir as well?"
echo "--- TEST 19.1: Is the file in the lowerdir as well?"
if [ -f $BASEDIR/lower/sublower4/verynewlowerfile ]; 
then
	echo "------ YES"
else
	echo "------ NO"
fi

echo "--- TEST 19.2: Is the file in the upperdir as well?"
if [ -f $BASEDIR/upper/sublower4/verynewlowerfile ]; 
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
