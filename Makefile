.PHONY: build clean

PROJECT=../Groupo.xcodeproj
SCHEME=Groupo
DESTINATION='generic/platform=iOS Simulator'

build:
	xcodebuild -scheme $(SCHEME) -project $(PROJECT) -destination $(DESTINATION) -quiet

clean:
	xcodebuild -scheme $(SCHEME) -project $(PROJECT) clean -quiet
