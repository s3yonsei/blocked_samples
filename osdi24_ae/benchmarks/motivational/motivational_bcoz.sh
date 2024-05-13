#!/bin/bash

cd src

for((i=0;i<5;i++))
do
	echo "${i}th iteration (case 1). Without specifying offcpu subclass"
	sleep 2

	bcoz run --- ./test_motivational_case1_bcoz >> temp.txt
done

for((i=0;i<5;i++))
do
	echo "${i}th iteration (case 1). With specifying offcpu subclass (I/O)"
	sleep 2

	bcoz run --blocked-scope i --- ./test_motivational_case1_bcoz >> temp.txt
done

mv profile.coz ../profile_case1.coz


for((i=0;i<5;i++))
do
	echo "${i}th iteration (case 2). Without specifying offcpu subclass"
	sleep 2

	bcoz run --- ./test_motivational_case2_bcoz >> temp.txt
done

for((i=0;i<5;i++))
do
	echo "${i}th iteration (case 2). With specifying offcpu subclass (I/O)"
	sleep 2

	bcoz run --blocked-scope i --- ./test_motivational_case2_bcoz >> temp.txt
done

mv profile.coz ../profile_case2.coz

rm temp.txt

cd ..
