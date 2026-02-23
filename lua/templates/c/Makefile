EXE_NAME=%s
BUILD_DIR=build

echo-output-path:
	@echo $(shell pwd)/$(BUILD_DIR)/$(EXE_NAME)

generate:
	@cmake -G Ninja -S . -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
build: generate
	@cmake --build ./$(BUILD_DIR)
run: build
	@./$(BUILD_DIR)/$(EXE_NAME)
regen:
	@echo "Removing Build Files..."
	@rm -rf build
	@echo "Regenerating CMake Build Files..."
	@cmake -G Ninja -S . -B $(BUILD_DIR) -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
