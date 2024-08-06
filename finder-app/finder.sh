#!/bin/sh

###################################################################### 
# VARIABLES
FILESDIR=$1
SEARCHSTR=$2

# Find all the files required and redirect errors away from ui
FILES=$(find "$FILESDIR" -type f 2> /dev/null)
TOTAL_FILES=$(find "${FILESDIR}" -type f | wc -l)

DIRECTORY_NAME=$(dirname ${FILESDIR})

if [ $# -ne 2 ]
then
    printf "Usage: %s <directory> <search string>\n" "$FILESDIR"
    exit 1
elif [ -z "$FILESDIR" ] || [ -z "$SEARCHSTR" ]
then
    printf "Usage: %s <directory> <search string>\n" "$FILESDIR"
    exit 1
elif [ ! -d ${DIRECTORY_NAME} ]
then
    printf "%s is not a valid directory\n" ${DIRECTORY_NAME}
fi

#######################################################################
# Loop through files, count total files and grepped files

GREPPED_FILES=$(find ${FILESDIR} -type f -exec grep -r "${SEARCHSTR}" {} \; | wc -l)
printf "The number of files are %d and the number of matching lines are %d\n" ${TOTAL_FILES} ${GREPPED_FILES}
