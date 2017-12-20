#!/bin/bash


set -e

SCRIPTDIR=$(
    cd $(dirname "$0")
    pwd
)

if [ ! -f ${SCRIPTDIR}/slurm_health_checker.spec.in ]; then
    echo "No slurm_health_checker.spec.in found"
    exit 1
fi

if  ! git describe --tag 2>/dev/null &>/dev/null
then
    VERSION=9999
    BUILD=$(git log --pretty=format:'' | wc -l)
else
    VERSION=$(git describe --tag  | sed -r 's/^v([\.0-9]*)-(.*)$/\1/')
    BUILD=$(git describe --tag  | sed -r 's/^v([\.0-9]*)-(.*)$/\2/' | tr - .)
fi


CHANGELOG=`git log --format="* %cd %aN%n- (%h) %s%d%n" --date=local | sed -r 's/[0-9]+:[0-9]+:[0-9]+ //'`


mkdir -p ${SCRIPTDIR}/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

sed -e "s/__VERSION__/$VERSION/" ${SCRIPTDIR}/slurm_health_checker.spec.in > ${SCRIPTDIR}/SPECS/slurm_health_checker.spec
sed -i "s/__BUILD__/$BUILD/" ${SCRIPTDIR}/SPECS/slurm_health_checker.spec

# git log to rpm's changelog
git log --format="* %cd %aN%n- (%h) %s%d%n" --date=local | sed -r 's/[0-9]+:[0-9]+:[0-9]+ //' >>  ${SCRIPTDIR}/SPECS/slurm_health_checker.spec

git archive --format=tar.gz --prefix=slurm_health_checker-${VERSION}-${BUILD}/  -o ${SCRIPTDIR}/SOURCES/v${VERSION}-${BUILD}.tar.gz HEAD

rm -rf ${SCRIPTDIR}/SRPMS/*.rpm
rpmbuild -bs --define '_topdir ./' ${SCRIPTDIR}/SPECS/slurm_health_checker.spec
rm -rf ${SCRIPTDIR}/RPMS/*.rpm
rpmbuild --rebuild --define "_topdir ${SCRIPTDIR}" ${SCRIPTDIR}/SRPMS/*.rpm
