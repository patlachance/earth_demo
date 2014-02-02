#!/bin/sh
#
# Description: read tags defined for current instance
#
# Dependencies:
#   - READ access policy to EC2 tags and AWS_*_KEY variables defined
#   - utility ec2-metadata installed
#   - ec2-tools
##############################################################################
INSTANCEID=`ec2-metadata -i | cut -d' ' -f2`
FILTER="instance-id=$INSTANCEID"
TMPFILE=/tmp/`basename $0`.$$
# get tags
#ec2-describe-instances -F $FILTER | while read label line; do
ec2-describe-instances -F $FILTER > $TMPFILE
while read label line; do
  case $label in
    'TAG')
	TAGNAME=`echo $line | cut -d' ' -f 3`
	TAGVALUE=`echo $line | cut -d' ' -f 4`
	export $TAGNAME=$TAGVALUE
	;;
    *)
	;;
  esac
done < $TMPFILE
rm $TMPFILE
