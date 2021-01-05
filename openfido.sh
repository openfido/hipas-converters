#!/bin/sh
#
# GridLAB-D converter shell script
#
# Environment:
#
#   OPENFIDO_INPUT --> input folder when MDB files are placed
#   OPENFIDO_OUTPUT --> output folder when CSV files are placed
#
# Special files:
#
#   config.csv -> run configuration
#
#     INTPUTFILE,<inputfile> --> (required) input file name (must be located in OPENFIDO_INPUT folder)
#     OUTPUTFILE,<outputfile> --> (required) output file name (will be place in OPENFIDO_OUTPUT folder)
#     FROMTYPE,<inputtype> --> (require) input file type (must be a valid converter input type)
#     TOTYPE,<outputtype> --> (required) output file type (must be a valid converter output type)
#     SOURCE,<repourl> --> (optional) repo to use for converter source (default "https://github.com/slacgismo/gridlabd-converters")
#     BRANCH,<branchname> --> (optional> repo branch to use for converter source (default "master")
#     OPTION,<name1>=<value1> --> (optional) first option to pass to converter 
#     OPTION,<name2>=<value2> --> (optional) second option to pass to converter
#     ...
#     OPTION,<nameN>=<valueN> --> (optional) last option to pass to converter
#
# Exit codes
#   1 - invalid starting environment

VERSION=0

DEFAULT_SOURCE="https://raw.githubusercontent.com/slacgismo/gridlabd"
DEFAULT_BRANCH="master"
DEFAULT_SRCPATH="gldcore/converters"

# error handling
EXECNAME=$0
TMP=/tmp/openfido-$$
OLDWD=${PWD}
LINENO="?"
CONFIG="${OPENFIDO_INPUT}/config.csv"
STDOUT="${OPENFIDO_OUTPUT}/stdout"
STDERR="${OPENFIDO_OUTPUT}/stderr"
trap 'onexit $0 ${LINENO} $?' EXIT
onexit()
{
	cd $OLDWD
	rm -rf $TMP
	if [ $3 -ne 0 -a $# -gt 3 ]; then
		echo "*** ERROR $3 ***"
		grep -v '^+' ${STDERR}
		echo "  $1($2): see ${STDERR} output for details"
	fi
	if [ $3 -eq 0 ]; then
		echo "Completed $1 at $(date)"
	else
		echo "Failed $1 at $(date) (see ${STDERR} for details)"
	fi
	exit $3
}
error()
{
	XC="$1"
	shift 1
	echo "*** ERROR ***" 
	echo "  $*" 
	exit $XC
}
warning()
{
	echo "WARNING [${EXECNAME}:${LINENO}]: $*" 
}
require()
{
	for VAR in $*; do
		test ! -z "$(printenv ${VAR})" || error 3 "Required value for ${VAR} not specified in ${CONFIG}"
	done
}
default()
{
	VAR="$1"
	if [ -z "$(printenv ${VAR})" ]; then
		shift 1
		export ${VAR}="$*"
	fi
}

# nounset: undefined variable outputs error message, and forces an exit
set -u

# errexit: abort script at first error
set -e

# print command to stderr before executing it:
set -x

# path to postproc folder
if [ "$0" = "openfido.sh" ]; then
	SRCDIR=$PWD
else
	SRCDIR=$(cd $(echo "$0" | sed "s/$(basename $0)\$//") ; pwd )
fi

# startup notice
echo "Starting $0 at $(date) in ${SRCDIR}"

# check and load startup environment
if [ ! -f "${CONFIG}" ]; then
	error 1 "Required file '${CONFIG}' not found"
fi
export INPUTFILE=$(grep ^INPUTFILE, "${CONFIG}" | cut -f2 -d,)
export OUTPUTFILE=$(grep ^OUTPUTFILE, "${CONFIG}" | cut -f2 -d,)
export FROMTYPE=$(grep ^FROMTYPE, "${CONFIG}" | cut -f2 -d,)
export TOTYPE=$(grep ^TOTYPE, "${CONFIG}" | cut -f2 -d,)
export SOURCE=$(grep ^SOURCE, "${CONFIG}" | cut -f2 -d, | tr '\n' ' ')
export BRANCH=$(grep ^BRANCH, "${CONFIG}" | cut -f2 -d,)
export SRCPATH=$(grep ^BRANCH, "${CONFIG}" | cut -f2 -d)
export OPTIONS=$(grep ^OPTION, "${CONFIG}" | cut -f2 -d,)

require INPUTFILE OUTPUTFILE FROMTYPE TOTYPE
default SOURCE "${DEFAULT_SOURCE}"
default BRANCH "${DEFAULT_BRANCH}"
default SRCPATH "${DEFAULT_SRCPATH}"
default OPTIONS ""

# install required tools
if [ ! -z "$(which brew)" ]; then
	INSTALL="brew install -q"
	brew update -yq 1>/dev/null 2>/dev/null || error 2 "unable to update brew"
elif [ ! -z "$(which apt)" ]; then
	INSTALL="apt install -yqq"
	apt update -yq 1>/dev/null 2>/dev/null || error 2 "unable to update apt"
elif [ ! -z "(which yum)" ]; then
	INSTALL="yum install -yqq"
	yum update -yq 1>/dev/null 2>/dev/null || error 2 "unable to update yum"
else
	INSTALL="false"
fi
for TOOL in $(cat "install.txt");  do
	if [ -z "$(which ${TOOL})" ]; then
		echo "Installing ${TOOL}"
		${INSTALL} ${TOOL} 1>/dev/null 2>/dev/null || error 2 "unable to install tool '${TOOL}' specified in 'install.txt'"
	fi
done

# work in new temporary directory
rm -rf "$TMP"
mkdir -p "$TMP"
cd "$TMP"
echo "  TMP = ${TMP} (working folder)"

# display environment information
echo "Environment settings:"
echo "  OPENFIDO_INPUT = $OPENFIDO_INPUT"
echo "  OPENFIDO_OUTPUT = $OPENFIDO_OUTPUT"

echo "Config settings:"
echo "  INPUTFILE = ${INPUTFILE}"
echo "  OUTPUTFILE = ${OUTPUTFILE}"
echo "  FROMTYPE = ${FROMTYPE}"
echo "  TOTYPE = ${TOTYPE}"
echo "  SOURCE = ${SOURCE}"
echo "  BRANCH = ${BRANCH}"
echo "  OPTIONS = ${OPTIONS}"

# requirements
if [ -f "${OPENFIDO_INPUT}/requirements.txt" ]; then
	$(which python3) -m pip install -r "${OPENFIDO_INPUT}/requirements.txt" || error 2 "unable to satisfy user 'requirements.txt'"
fi
if [ -f "requirements.txt" ]; then
	$(which python3) -m pip install -r "requirements.txt" || error 2 "unable to satisfy system 'requirements.txt'"
fi
if [ ! -f "${OPENFIDO_INPUT}/${INPUTFILE}" ]; then
	error 4 "file '${INPUTFILE}' is not found"
fi
FROMEXT=${INPUTFILE##*.}
if [ -z "$FROMEXT" ]; then
	error 4 "file '${INPUTFILE}' does not have a recognizable extension"
fi
TOEXT=${OUTPUTFILE##*.}
if [ -z "$TOEXT" ]; then
	error 4 "file '${OUTPUTFILE}' does not have a recognizable extension"
fi

# download type converter
CONVERTER="${FROMEXT}-${FROMTYPE}2${TOEXT}-${TOTYPE}.py"
DOWNLOAD="${SOURCE}/${BRANCH}/${SRCPATH}/${CONVERTER}"
curl -sSL "${DOWNLOAD}" > "${CONVERTER}" || error 5 "converter '${CONVERTER}' not found at '${DOWNLOAD}'"

# download main converter
CONVERTER="${FROMEXT}2${TOEXT}.py"
DOWNLOAD="${SOURCE}/${BRANCH}/${SRCPATH}/${CONVERTER}"
curl -sSL "${DOWNLOAD}" > "${CONVERTER}" || error 5 "converter '${CONVERTER}' not found at '${DOWNLOAD}'"

# run the main converter
COMMAND="$(which python3) $CONVERTER -i ${OPENFIDO_INPUT}/${INPUTFILE} -o ${OPENFIDO_OUTPUT}/${OUTPUTFILE} -f ${FROMTYPE} -t ${TOTYPE} ${OPTIONS}"
${COMMAND} || error 6 "${CONVERTER} failed"
