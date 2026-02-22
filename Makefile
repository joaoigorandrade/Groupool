.PHONY: build clean

PROJECT=../Groupo.xcodeproj
SCHEME=Groupo
DESTINATION='platform=iOS Simulator,name=iPhone 17'
SDK=iphonesimulator

build:
	xcodebuild -scheme Groupo -project /Users/joaoigor/Developer/Groupo/Groupo.xcodeproj -destination "generic/platform=iOS" build -quiet

clean:
	xcodebuild -scheme $(SCHEME) -project $(PROJECT) clean -quiet
