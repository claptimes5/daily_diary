# diary_app

Daily Diary App

## Overview

The goal of this app is to be able to record 15 seconds of an audio diary each day and the play them back over the course of the year.
More to come!

bundletool install-apks --apks=daily_diary.apks --adb=/Users/avi/Library/Android/sdk/platform-tools/adb
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=daily_diary.apks --ks-key-alias=key --ks=~/key.jks --ks-pass=pass: --key-pass=pass: