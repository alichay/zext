#!/bin/sh

../Odin/odin build tests/json_formatter.odin -collection=zext=lib
tests/json_formatter
rm tests/json_formatter