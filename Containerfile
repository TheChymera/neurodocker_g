FROM docker.io/gentoo/portage:20240324 as portage
FROM docker.io/gentoo/stage3:20240318

# copy the entire portage volume in
COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

RUN emerge -v --noreplace dev-vcs/git
RUN emerge -v --noreplace app-editors/vim
RUN emerge -v1u portage

# Pinned commits for the dependency tree state
ARG gentoo_hash=776fd281e8a158bce2ea3f4845d4cfd848bc2dc5
ARG science_hash=0e024beadac3ccaefb4a3961214eb74ee5853cf2
ARG FEATURES="-ipc-sandbox -network-sandbox -pid-sandbox"

# This will be bound, and contents available outside of container
RUN mkdir /outputs

COPY .gentoo/portage/ /etc/portage/

# Moving gentoo repo from default rsync to git
RUN rm /var/db/repos/gentoo -rf

# Disable auto-sync
#RUN sed -i /etc/portage/repos.conf/{gentoo,science} -e "s/sync-type *= *git/sync-type =/g"

# Cloning manually to prevent vdb update, pinning state via git
### This takes a long time dut to the long history and number of objects particularly in ::gentoo
### No idea if first shallow cloning helps, maybe there are other ways to speed it up 🤔
### The `git stash` step was added because somehow `vierror: Untracked working tree file '.editorconfig' would be overwritten by merge.` kept appearing

#RUN \
#	REPO_URL=$(grep "^#sync-uri" /etc/portage/repos.conf/gentoo | sed -e "s/#sync-uri *= *//g") && \
#	mkdir -p /var/db/repos/gentoo && pushd /var/db/repos/gentoo && \
#		ls -lah && git clone ${REPO_URL} . && git fetch origin $gentoo_hash && pwd && ls -lah . && git checkout $gentoo_hash && rm .git -rf && popd && \
#	REPO_URL=$(grep "^#sync-uri" /etc/portage/repos.conf/science | sed -e "s/#sync-uri *= *//g") && \
#	mkdir -p /var/db/repos/science && pushd /var/db/repos/science && \
#		ls -lah && git clone ${REPO_URL} . && git fetch origin $science_hash && pwd && ls -lah . && git checkout $science_hash && rm .git -rf && popd

RUN \
	REPO_URL=$(grep "^sync-uri" /etc/portage/repos.conf/gentoo | sed -e "s/sync-uri *= *//g") && \
	mkdir -p /var/db/repos/gentoo && pushd /var/db/repos/gentoo && \
		git clone ${REPO_URL} . && git fetch origin $gentoo_hash && git checkout $gentoo_hash && rm .git -rf && popd && \
	REPO_URL=$(grep "^sync-uri" /etc/portage/repos.conf/science | sed -e "s/sync-uri *= *//g") && \
	mkdir -p /var/db/repos/science && pushd /var/db/repos/science && \
		git clone ${REPO_URL} . && git fetch origin $science_hash && git checkout $science_hash && rm .git -rf && popd

#RUN REPO_URL=$(grep "^sync-uri" /etc/portage/repos.conf/gentoo | sed -e "s/sync-uri *= *//g"); mkdir -p /var/db/repos/gentoo; pushd /var/db/repos/gentoo; git clone ${REPO_URL} .; git fetch origin $gentoo_hash; git checkout $gentoo_hash; rm .git -rf; popd
#RUN REPO_URL=$(grep "^sync-uri" /etc/portage/repos.conf/science | sed -e "s/sync-uri *= *//g"); mkdir -p /var/db/repos/science; pushd /var/db/repos/science; git clone ${REPO_URL} .; git fetch origin $science_hash; git checkout $science_hash; rm .git -rf; popd


# Remove sync-uri for consistency
RUN sed -i /etc/portage/repos.conf/{gentoo,science} -e "/sync-uri/d"
RUN sed -i /etc/portage/repos.conf/{gentoo,science} -e "/sync-git-verify-commit-signature/d"

# Make sure all CPU flags supported by the hardware are whitelisted
# This only affects packages with handwritten assembly language optimizations, e.g. ffmpeg.
# Removing it is safe, software will just not take full advantage of processor capabilities.
#RUN emerge cpuid2cpuflags 
#RUN echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

### Emerge cool stuff here
RUN emerge afni fsl
