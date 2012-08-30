PATH := ./node_modules/.bin:$(PATH)

test: compile
	NODE_ENV=test mocha --recursive test --compilers coffee:coffee-script

compile:
	coffee --compile --output lib/ src

.PHONY: test
