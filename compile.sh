#!/bin/bash

# compile the duckdb with configurations
CMAKE_BUILD_PARALLEL_LEVEL=$(sysctl -n hw.ncpu)
CMAKE_C_COMPILER_LAUNCHER=ccache
CMAKE_CXX_COMPILER_LAUNCHER=ccache

GEN=ninja make debug