#!/bin/bash
#
# Bash wrapper for cvlc (command line VLC) to record DVB broadcasts
#
# Copyright (c) 2010,2013 Stephan Bourgeois <stephanb2@hotmail.com>
# Distributed under the GNU General Public License (GPL) version 3.
#
# For help type ./dvbrecord.sh (without arguments)
# For configuration, edit the variables at the top of this script.

set -o errexit
set -o nounset

#--------- edit this section for your configuration
VFOLDER="/media/video3/pvr"
ADAPTER="/dev/dvb/adapter0/dvr0"
CHCONF=".tzap/channels.conf"

#--------- global vars
TEST=0
DURATION=0
CHANNEL=""

USAGE="dvbrecord 0.8 is a wrapper for cvlc to record DVB broadcasts.\n\n\
USAGE:\tdvbrecord -c CHANNEL -d DURATION [-t] [-h]\n\
  -c CHANNEL: channel name, most names must be quoted eg. \"BBC ONE\"\n\
\t name must be in ~/.tzap/channels.conf. Use -t to test\n\
  -d DURATION: number of minutes to record\n\
  -t test arguments before use\n\
  -h help, display this message\n"

#--------- if invoked without any arguments
if [ $# -eq 0 ]		
  then echo -e $USAGE; exit 1
fi


#--------- parse command line arguments
while getopts "c:d:th" options; do
  case $options in
    c ) CHANNEL=$OPTARG;;
    d ) DURATION=$OPTARG;;
    t ) TEST=1;;
    h ) echo -e $USAGE; exit 1;;
    \? ) echo -e $USAGE; exit 1;;
    * ) echo -e $USAGE; exit 1;;
  esac
done

#--------- arguments and sanity tests
if [ $DURATION -eq 0 ]
then 
    echo -e "[ERROR] duration not set"
    exit 1
fi

if [ -z "$CHANNEL" ]
then 
    echo -e "[ERROR] channel not set"
    exit 1
fi

type vlc &>/dev/null
if  [ $? -ne 0 ]
then
    echo -e "[ERROR] vlc is not installed"
    exit 1
fi


if [ $TEST -eq 1 ]
then 
  grep "$CHANNEL": $HOME/$CHCONF >/dev/null
  if  [ $? -eq 0 ]
  then
      PLAYLIST="$VFOLDER/$CHANNEL-$(date +%Y%m%d-%H%M).conf"
      FILENAME="$VFOLDER/$CHANNEL-$(date +%Y%m%d-%H%M).mpg"
      echo -e "[OK] will record $CHANNEL for $DURATION minutes with:"
      echo cvlc --run-time $[DURATION*60] --sout "$FILENAME" "$PLAYLIST" vlc://quit
      exit 0
  else 
      echo -e "[ERROR] channel $CHANNEL not listed in $CHCONF"
      exit 1
  fi
fi

#--------- set recording playlist and filename
PLAYLIST="$VFOLDER/$CHANNEL-$(date +%Y%m%d-%H%M).conf"
FILENAME="$VFOLDER/$CHANNEL-$(date +%Y%m%d-%H%M).mpg"

grep "$CHANNEL": "$HOME/$CHCONF" > "$PLAYLIST"
echo [OK] cvlc --run-time $[DURATION*60] --sout "$FILENAME" "$PLAYLIST" vlc://quit

#--------- gracefully handle interrupts and clean temporary playlist
trap 'rm "$PLAYLIST"; kill %1; exit $?' INT TERM

#--------- record dvb channel to file with cvlc
cvlc --run-time $[DURATION*60] --sout "$FILENAME" "$PLAYLIST" vlc://quit

#--------- cleanup. clean temporary playlist
rm "$PLAYLIST"

trap - INT TERM

