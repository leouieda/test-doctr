#!/bin/bash
#
# Push HTML pages to the gh-pages branch of the current Github repository.
#
# Keeps pages built from git tags in separate folders (named after the tag).
# Pages for the master branch are in the 'dev' folder. 'latest' is a link to
# the last tag.

# To return a failure if any commands inside fail
set -o xtrace
set -e
set -x

# Place the HTML is different folders for different versions
if [[ "${TRAVIS_TAG}" != "" ]]; then
    VERSION=${TRAVIS_TAG}
else
    VERSION=dev
fi
SOURCE=${HTML_BUILDDIR:-doc/_build/html}
DESTINATION=${VERSION}

echo -e "DEPLOYING HTML TO GITHUB PAGES:"
echo -e "HTML source: ${SOURCE}"
echo -e "HTML destination: ${DESTINATION}"


cat > ${SOURCE}/process.sh << EOF
#!/bin/bash
set -o xtrace
set -e
set -x

# Need to have this file so that Github doesn't try to run Jekyll
touch .nojekyll
touch test-file
git add -A .nojekyll test-file

# If this is a new release, update the link from /latest to the new release
if [[ "${VERSION}" != "dev" ]]; then
    rm -f latest
    ln -sf ${DESTINATION} latest
    git add -A latest
fi

git status

# If this is a dev build and the last commit was from a dev build, reuse the
# same commit
if [[ "${VERSION}" == "dev" ]]; then
    git add -A ${DESTINATION}
    if [[ `git log -1 --format='%s'` == *"dev"* ]]; then
        git commit --amend --reset-author --no-edit
    else
        git commit -m "Deploy $VERSION from TravisCI"
    fi
fi
EOF

chmod +x ${SOURCE}/process.sh

doctr deploy ${DESTINATION} --build-tags --built-docs ${SOURCE} --key-path .github/deploy_key.enc --command "${DESTINATION}/process.sh"

echo -e "Finished uploading generated files."

set +x
set +e
