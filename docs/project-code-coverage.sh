#!/bin/bash

echo "mode: count" > acc.out
for Dir in . $(find ./* -maxdepth 10 -type d ); 
do
	if ls $Dir/*.go &> /dev/null;
	then
		returnval=`go test -coverprofile=profile.out -covermode=count $Dir`
		echo ${returnval}
		if [[ ${returnval} != *FAIL* ]]
		then
    		if [ -f profile.out ]
    		then
        		cat profile.out | grep -v "mode: count" >> acc.out 
    		fi
    	else
    		exit 1
    	fi	
    fi
done

# collect integration test coverage
echo "mode: count" > integration-acc.out
INTPACKS=`go list ./... | grep -v utils | xargs | sed 's/ /,/g'`
returnval=`go test -coverpkg=$INTPACKS -coverprofile=profile.out -covermode=count ./test`
if [[ ${returnval} != *FAIL* ]]
then
    if [ -f profile.out ]
    then
        cat profile.out | grep -v "mode: count" >> integration-acc.out 
    fi
else
    exit 1
fi

cat acc.out integration-acc.out | go run docs/merge-coverprofile.go > merged.out

if [ -n "$COVERALLS" ]
then
	goveralls -service drone.io -coverprofile=merged.out -repotoken $COVERALLS
fi	

rm -rf ./profile.out
rm -rf ./acc.out
rm -rf ./integration-acc.out
rm -rf ./merged.out