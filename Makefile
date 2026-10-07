GHC ?= ghc
GHCFLAGS = -Wall -Werror -isrc

.PHONY: build run test clean
build:
	mkdir -p .build/app
	$(GHC) $(GHCFLAGS) -outputdir .build/app app/Main.hs -o .build/examples

run: build
	./.build/examples

test:
	mkdir -p .build/test
	$(GHC) $(GHCFLAGS) -outputdir .build/test test/Main.hs -o .build/tests
	./.build/tests

clean:
	rm -rf .build

.PHONY: submission-test submission-demo
submission-test:
	$(MAKE) -C EG_2021_4385 test

submission-demo:
	$(MAKE) -C EG_2021_4385 demo
