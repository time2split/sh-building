#!/usr/bin/env bash

# Create a release branch and merge it into the main branch
#
# parameters
#	changelog
#	releasebranch
#	releasecommit
#	merge
#	-p, prerelease (value)
#		Pre-release version to add to the semver (semver-#prerelease)
#	-m, main (value)
#		Name of the main branch to merge into
#	-h, head (value)
#		The commit/branch to release
#	-f, force
#		Apply the force argument -f for git commands
#	-d, date (value)
#		Change the date of the commits
#		'@branch': use the current branch author date
#		'string': value accepted by git commit --date (https://git-scm.com/docs/git-commit#_date_formats) 
#	-v, version (value)
#		The version to release;
#		if not set the next version is computed with cliff

shopt -s expand_aliases

DIR="$( dirname -- "${BASH_SOURCE[0]}"; )";

source "$DIR/../functions.sh"

declare -A OPT

while (( 0 < $# )) ; do
  case $1 in
    changelog | releasebranch | releasecommit | merge )
		OPT[$1]=1
	;;
	-f | force ) 
		OPT[force]=1
	;;
	-d | date ) 
		OPT[date]=$2
		shift
	;;
	-p | prerelease ) 
		OPT[prerelease]=$2
		shift
	;;
	-h | head )
		OPT[head]=$2
		shift
	;;
	-m | main )
		OPT[main]=$2
		shift
	;;
	-v | version ) 
		OPT[version]=$2
		shift
	;;
    *)
      echo "Invalid option: $1."
      exit 1
	;;
  esac
  shift
done

# Head when the command was invoked
INVOKE_HEAD="$(git rev-parse --abbrev-ref HEAD)"

function end(){
	git checkout $INVOKE_HEAD
	exit ${1:-0}
}

# Get arguments
PRERELEASE=${OPT[prerelease]}

[[ "" !=  "$PRERELEASE" && ! "$PRERELEASE" =~ ^"-" ]] && \
PRERELEASE="-$PRERELEASE"

alias cliff="git cliff"

if [ -z ${OPT[version]} ]; then
	SEMVER="$(cliff --bumped-version)$PRERELEASE"
else
	SEMVER="${OPT[version]}$PRERELEASE"
fi

if [ -n ${OPT[head]} ];then
	GIT_HEAD="${OPT[head]}"
else
	GIT_HEAD="$INVOKE_HEAD"
fi

# Switch to the branch/commit to release
git checkout "$GIT_HEAD" || end

MAIN_BRANCH=${OPT[main]:-'main'}

(( 1 == ${OPT[force]} )) && \
GIT_FORCE='-f'

optDate="${OPT[date]}"

if [ -n "$optDate" ]; then
	if [[ $optDate == '@branch' ]]; then
		optDate="$(git show -s --format=%aI "$GIT_HEAD")"
	fi
	GIT_DATE="--date $optDate"
fi

export GIT_AUTHOR_DATE="$optDate"

# =============================================================================
echo "== Prepare the release of version $SEMVER from $GIT_HEAD to $MAIN_BRANCH (current: $INVOKE_HEAD) =="

# Checkout to the working branch
if (( 1 == ${OPT[releasebranch]:-0})); then
	RELEASE_BRANCH="release/$SEMVER"
	
	git show-ref "$RELEASE_BRANCH" --quiet
	BRANCH_EXISTS=$?

	# =========================
	# Create the release branch
	# =========================
	if (( 1 == $BRANCH_EXISTS )); then
		git branch $GIT_FORCE "$RELEASE_BRANCH" || end
	fi
	git checkout $RELEASE_BRANCH || end
fi

if (( 1 == ${OPT[releasecommit]:-0})); then
	COMMIT_MSG="chore(release): keep $SEMVER"
	KEEP="v$SEMVER"
	touch "$KEEP"
	git add "$KEEP"
	git commit -m "$COMMIT_MSG"
fi

if (( 1 == ${OPT[changelog]:-0} )); then
	CHANGELOG=CHANGELOG.md
	COMMIT_MSG="chore(release): prepare $CHANGELOG for $SEMVER"

	echo "- Create $CHANGELOG"

	cliff \
		--with-commit "$COMMIT_MSG" \
		--with-tag-message "$TAG_MSG" \
		-o $CHANGELOG

	echo "- Commit $CHANGELOG ($COMMIT_MSG)"

	git add "$CHANGELOG"
	git commit -m "$COMMIT_MSG"
fi

# ========================
# Merge the release branch
# ========================

RELEASE_MSG="chore(release): version $SEMVER"
TAG_MSG="release of $SEMVER"
TAG="v$SEMVER"

if (( 1 == ${OPT[merge]:-0} ));then
	echo "- Merge $GIT_HEAD into $MAIN_BRANCH"
	git checkout $MAIN_BRANCH
	git merge $GIT_HEAD --no-ff  -m "$RELEASE_MSG"
fi
echo "- Add Tag ($TAG)"
git tag $GIT_FORCE $TAG -m "$TAG_MSG"
end
