.PHONY: test
test:
	emacs \
		-batch \
		-l rfcreader.el \
		-l test/rfcreader-test.el \
		-f ert-run-tests-batch-and-exit
