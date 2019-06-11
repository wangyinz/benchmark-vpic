#!/bin/bash

git submodule update --init &&
sed -i 's/MAX_PIPELINE = 16/MAX_PIPELINE = 272/g' vpic/src/util/pipelines/pipelines.h
