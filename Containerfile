FROM docker.io/gentoo/portage:20240324 as portage
FROM docker.io/gentoo/stage3:20240318

# copy the entire portage volume in
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

RUN emerge -v --noreplace dev-vcs/git
RUN emerge -v1u portage

# Pinned commits for the dependency tree state
ARG gentoo_hash=2d25617a1d085316761b06c17a93ec972f172fc6
ARG science_hash=73916dd3680ffd92e5bd3d32b262e5d78c86a448
ARG FEATURES="-ipc-sandbox -network-sandbox -pid-sandbox"

# This will be bound, and contents available outside of container
RUN mkdir /outputs

COPY .gentoo/portage/ /etc/portage/

# Moving gentoo repo from default rsync to git
RUN rm /var/db/repos/gentoo -rf

# Cloning manually to prevent vdb update, pinning state via git
# Allegedly it's better to chain everything in one command, something with container layers 🤔
RUN \
	REPO_URL=$(grep "^sync-uri" /etc/portage/repos.conf/gentoo | sed -e "s/sync-uri *= *//g") && \
	mkdir -p /var/db/repos/gentoo && pushd /var/db/repos/gentoo && git init . && \
		git remote add origin ${REPO_URL} && \
		git fetch --filter="blob:none" origin $gentoo_hash && \
		git reset --hard $gentoo_hash && rm .git -rf && popd && \
	REPO_URL=$(grep "^sync-uri" /etc/portage/repos.conf/science | sed -e "s/sync-uri *= *//g") && \
	mkdir -p /var/db/repos/science && pushd /var/db/repos/science && git init . && \
		git remote add origin ${REPO_URL} && \
		git fetch --filter="blob:none" origin $science_hash && \
		git reset --hard $science_hash && rm .git -rf && popd



# Old Christian: Remove sync-uri to not accidentally re-sync if we work with the package management interactively
# Christian from the future: Maybe we want the option to re-sync if we're debugging it interactively...
#RUN sed -i /etc/portage/repos.conf/{gentoo,science} -e "s/sync-type *= *git/sync-type =/g"
#RUN sed -i /etc/portage/repos.conf/{gentoo,science} -e "/sync-uri/d"
#RUN sed -i /etc/portage/repos.conf/{gentoo,science} -e "/sync-git-verify-commit-signature/d"

# Make sure all CPU flags supported by the hardware are whitelisted
# This only affects packages with handwritten assembly language optimizations, e.g. ffmpeg.
# Removing it is safe, software will just not take full advantage of processor capabilities.
#RUN emerge cpuid2cpuflags
#RUN echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

### Emerge cool stuff here
### Autounmask-continue enables all features on dependencies which the top level packages require
### By default this needs user confirmation which would interrupt the build.
RUN emerge --autounmask-continue afni fsl
