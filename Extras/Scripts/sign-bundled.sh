#!/usr/bin/env bash

## Re-sign every plugin and framework using the bundle id and code signing identity of the target
##
## You can use this script in a Run Script phase to ensure that all plugins and frameworks are signed consistently.
##
## (C) 2013 Sam Deane, Elegant Chaos.
## Feel free to use and abuse this script - I'd love to hear of improvements.


sign()
{
  local BUNDLEID="$1"
  local CODE_SIGN_IDENTITY="$2"
  local FILE="$3"
  local NAME=`basename "$FILE"`

  # get current signing details
  local CURRENT=`codesign --verbose=2 -d "${FILE}" 2>&1`
  if [ $? == 0 ]; then

    #echo "current:$CURRENT"

    # get current id
    local PATTERN="Identifier=([a-zA-Z0-9.]*)"
    [[ "$CURRENT" =~ $PATTERN ]]
    local CURRENT_IDENTIFIER=${BASH_REMATCH[1]}

    # get first authority - should match the code signing identity that we're using
    PATTERN="Authority=([a-zA-Z0-9: ]*)"
    [[ "$CURRENT" =~ $PATTERN ]]
    local CURRENT_AUTHORITY=${BASH_REMATCH[1]}

    # if we got an id and weren't being forced to change it to something else, use that
    if [[ "$BUNDLEID" == "" ]] ; then
      BUNDLEID="$CURRENT_IDENTIFIER"
    fi

    #    echo "current:$CURRENT_IDENTIFIER required:$BUNDLEID"
    #    echo "current:$CURRENT_AUTHORITY required:$CODE_SIGN_IDENTITY"

  else

      echo "$NAME wasn't signed at all"

    # if we weren't signed, and haven't been given an id to use, use the app one
    if [[ "$BUNDLEID" == "" ]] ; then
      BUNDLEID="$APPID"
    fi

  fi

  # check if we need to resign (resigning can be slow, so we check first)
  if [[ ("$CURRENT_IDENTIFIER" != "$BUNDLEID") || ("$CURRENT_AUTHORITY" != "$CODE_SIGN_IDENTITY"*) ]] ; then
    echo "Resigning $NAME with id $BUNDLEID"
    codesign --verbose=2 --deep --force --identifier ${BUNDLEID} $OTHER_CODE_SIGN_FLAGS --sign "${CODE_SIGN_IDENTITY}" "${FILE}"
    #codesign --verbose=2 -d "${FILE}"
  else
    echo "Didn't need to sign $NAME - already signed correctly as $CURRENT_IDENTIFIER $CURRENT_AUTHORITY"
  fi
}

sign_folder()
{
  local FOLDER="$1"
  local NAME=`basename "$FOLDER/"`
  if [ -e "$FOLDER/" ]; then
    #echo "Signing $NAME as: ${CODE_SIGN_IDENTITY}"
    local f
    for f in "$FOLDER"/*
    do
      # sign embedded stuff first
      sign_folder "$f/Frameworks"
      sign_folder "$f/PlugIns"

      # if the bundle has an info plist file in it, extract the bundle id to use from it
      # (if not, we'll use the current one to resign, or we'll use the app id as a last resort)
      local BUNDLEID=""
      if [ -e "$f/Contents/Info.plist" ]; then
        BUNDLEID=`/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$f/Contents/Info.plist"`
      elif [ -e "$f/Resources/Info.plist" ]; then
        BUNDLEID=`/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$f/Resources/Info.plist"`
      elif [ -e "$f/Info.plist" ]; then
        BUNDLEID=`/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$f/Info.plist"`
      fi

      # now sign this bundle
      sign "${BUNDLEID}" "${CODE_SIGN_IDENTITY}" "$f"

    done
  fi

}

# Pull out the application's bundle id
BUILT_INFO_PLIST="${CODESIGNING_FOLDER_PATH}/Contents/Info.plist"
APPID=`/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" ${BUILT_INFO_PLIST}`
echo "Resigning bundles items."
echo "App bundle is $APPID."

if [[ "$CODE_SIGN_IDENTITY" == "" ]] ; then
  echo "App not signed, using default identity."
  CODE_SIGN_IDENTITY="3rd Party Mac Developer Application"
fi

# Bit of a hack: according to the codesign tool, Mac Developer is ambiguous (also matches 3rd Party Mac Developer)
# Mac Developer: shouldn't be, so we change it if necessary.
if [[ "$CODE_SIGN_IDENTITY" == "Mac Developer" ]] ; then
  CODE_SIGN_IDENTITY="Mac Developer:"
fi

echo "Using identity $CODE_SIGN_IDENTITY"

# Sign Plugins
sign_folder "${CODESIGNING_FOLDER_PATH}/Contents/PlugIns"

# Sign Frameworks
sign_folder "${CODESIGNING_FOLDER_PATH}/Contents/Frameworks"

# Sign XPCServices
sign_folder "${CODESIGNING_FOLDER_PATH}/Contents/XPCServices"

# Sign Quicklook
sign_folder "${CODESIGNING_FOLDER_PATH}/Contents/Library/QuickLook"


echo ""
echo "Resigning done."