format:
	dart format .

analyze:
	dart analyze

test:
	dart test

coverage:
	dart test --coverage

publish-dry-run:
	dart pub publish --dry-run

publish: publish-dry-run
	git push
	dart pub publish
