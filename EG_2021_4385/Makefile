GHC ?= ghc
FLAGS = -Wall -Wincomplete-patterns -Werror
.PHONY: test demo clean

test:
	mkdir -p .build/hof .build/pm .build/project .build/demo .build/parity
	$(GHC) $(FLAGS) -outputdir .build/hof Assignments/HigherOrderFunctions.hs -o .build/hof/run
	./.build/hof/run
	$(GHC) $(FLAGS) -outputdir .build/pm Assignments/PatternMatching.hs -o .build/pm/run
	./.build/pm/run
	$(GHC) $(FLAGS) -iProject -outputdir .build/project Project/Tests.hs -o .build/project/run
	./.build/project/run
	$(GHC) $(FLAGS) -iProject -outputdir .build/demo Project/Main.hs -o .build/demo/run
	./.build/demo/run
	$(GHC) $(FLAGS) -iProject -outputdir .build/parity Project/Parity.hs -o .build/parity/run
	python3 -B Project/comparison.py --parity

demo:
	runghc -iProject Project/Main.hs

clean:
	rm -rf .build
