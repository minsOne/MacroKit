.PHONY: build clean

build:
	./scripts/swift_syntax_build.sh 509.0.2

clean:
	rm -rf XCFramework
	rm -rf swift-syntax
