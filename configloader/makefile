all: configloader
	@echo Making configloader done.
	@cp configloader $(GOPATH)/tools

configloader: configloader.go
	@go build -o configloader
clean:
	@go clean -i


