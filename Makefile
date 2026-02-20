.PHONY: build clean

PROJECT=../Groupo.xcodeproj
SCHEME=Groupo
DESTINATION='platform=iOS Simulator,name=iPhone 17'
SDK=iphonesimulator

build:
	xcodebuild -scheme $(SCHEME) -project $(PROJECT) -destination $(DESTINATION) -sdk $(SDK) -quiet

clean:
	xcodebuild -scheme $(SCHEME) -project $(PROJECT) clean -quiet
