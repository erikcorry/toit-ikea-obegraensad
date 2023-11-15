all:
	jag pkg install
	(cd examples; jag pkg install)
	jag run -d host examples/hello.toit
