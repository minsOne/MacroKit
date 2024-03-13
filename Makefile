.PHONY: build clean

build:
	./scripts/swift_syntax_build.sh 510.0.1

clean:
	rm -rf XCFramework
	rm -rf swift-syntax
