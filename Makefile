build:
	docker build . -t nvim-test
run:build
	docker run -it --rm nvim-test
