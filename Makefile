# as this is first rule, it is run atomatically when just 'make' called

list:
	@echo 'Please, use make with some of available targets: compile, watch, run[-dev | -prod], clean, test [-cov | -cov-html], release[-patch | -minor | -major], publish, deploy'
.PHONY: list


# Compile coffee script source and target
BIN = ./node_modules/.bin

SRV_SRC=$(shell find ./src -name "*.coffee")
SRV_LIB = $(patsubst ./src/%.coffee, ./lib/%.js, $(SRV_SRC))

TEST_SRC=$(shell find ./test/src -name "*.coffee")
TEST_LIB = $(patsubst ./test/src/%.coffee, ./test/lib/%.js, $(TEST_SRC))

# Program to be opened when notification icon is clicked for example 'com.sublimetext.3'
NOTIFIER = 'com.googlecode.iterm2'

debug:
	@echo $(SRV_SRC)


lib/%.js: src/%.coffee
	@echo "Coffee $< -- $@"
	@coffee -c -o $(@D) $<

test/lib/%.js: test/src/%.coffee
	@echo "Coffee $< -- $@"
	@coffee -c -o $(@D) $<

compile: $(SRV_LIB) $(TEST_LIB)


#------- Watch file changes -------
 watch:
	#watch -i 500ms $(MAKE) compile
	rm -f ./test/test.log
	watch -q -i 2000ms $(MAKE) test
.PHONY: watch


# Run targets
#------- Run dev -------
run-dev: compile
	nodemon -w ./src ./src/index.coffee
.PHONY: run

#------- Run prod -------
run-prod: compile
	NODE_ENV='production' node index.js
.PHONY: run-prod

#------- Clean -------
clean:
	@rm -f ./lib/*.*
	@rm -f ./test/lib/*.*
	@rm -f ./test/test.log

.PHONY: clean

#------- Test notifications by https://github.com/alloy/terminal-notifier ------
test-notify:
	@if grep 'failed' '$(LOGFILE)'; then tail -50 '$(LOGFILE)' | terminal-notifier -title '$(TITLE)' -group '$(LOGFILE)' -sound Basso  -sender $(NOTIFIER) -image 'test/img/passed.png'; fi
	@if grep 'complete' '$(LOGFILE)'; then grep 'complete' '$(LOGFILE)' | terminal-notifier -title '$(TITLE)' -group '$(LOGFILE)' -sound Pop -sender $(NOTIFIER) --image 'test/img/passed.png'; fi
.PHONY: test-notify

#------- Test  -------
test: test/test.log

test/test.log: $(TEST_SRC) $(SRV_SRC)
	@make compile
	@node_modules/lab/bin/lab -r console 2>&1 | tee ./test/test.log
	@make test-notify  TITLE=test LOGFILE='./test/test.log'

test-cov: $(TEST_LIB) $(SRV_LIB)
	node node_modules/lab/bin/lab -r threshold -t 100

test-cov-html: $(TEST_LIB) $(SRV_LIB)
	node node_modules/lab/bin/lab -r html -o test/coverage.html

.PHONY: test test-cov test-cov-html


#------- Release -------
define release
 	VERSION=`node -pe "require('./package.json').version"` && \
	NEXT_VERSION=`node -pe "require('semver').inc(\"$$VERSION\", '$(1)')"` && \
	node -e "\
	var j = require('./package.json');\
	j.version = \"$$NEXT_VERSION\";\
	var s = JSON.stringify(j, null, 2);\
	require('fs').writeFileSync('./package.json', s);" && \
	@echo "Commit $$NEXT_VERSION"
	#git commit -m "release $$NEXT_VERSION" -- package.json && \
 	#git tag "$$NEXT_VERSION" -m "release $$NEXT_VERSION"
endef

release-patch: compile test
	@$(call release,patch)

release-minor: compile test
	@$(call release,minor)

release-major: compile test
	@$(call release,major)

#------- Publish -------
publish:
	git push --tags origin HEAD:master
	#npm publish

#------- Deploy -------
deploy:
	git push heroku master
.PHONY: deploy

.PHONY: release-patch release-minor release-major publish
