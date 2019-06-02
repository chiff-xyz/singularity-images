USER?=
APP?=python
VER?=3.7.3-debian

.PHONY: build
build:
	sudo singularity build build/${APP}-${VER}.sif ${APP}/${VER}.def
	singularity sign build/${APP}-${VER}.sif

.PHONY: publish
publish:
	singularity push build/${APP}-${VER}.sif library://${USER}/default/${APP}:${VER}
