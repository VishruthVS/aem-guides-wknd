#!/bin/bash

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running GitHub Actions workflow locally with act...${NC}"

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo -e "${RED}Error: 'act' is not installed. Please install it:${NC}"
    echo "brew install act"
    exit 1
fi

# Make sure we're in the repository root
if [ ! -f ".github/workflows/codeql-analysis.yml" ]; then
    echo -e "${RED}Error: Could not find workflow file.${NC}"
    echo "Please run this script from the repository root."
    exit 1
fi

# Run only the CodeQL analysis workflow
echo -e "${YELLOW}Running CodeQL analysis workflow...${NC}"
echo -e "${YELLOW}(This might take several minutes)${NC}"

# Create a temporary GitHub token file
echo -e "${YELLOW}Creating temporary GitHub token file...${NC}"
echo "GITHUB_TOKEN=github_pat_dummy_token_for_local_testing" > .env

# Run the workflow with the token
act -W .github/workflows/codeql-analysis.yml -j analyze \
  --container-architecture linux/amd64 \
  -s GITHUB_TOKEN=github_pat_dummy_token_for_local_testing \
  --env-file .env

# Capture the exit code
RESULT=$?

# Clean up the token file
rm -f .env

# Check result
if [ $RESULT -ne 0 ]; then
    echo -e "${RED}Workflow failed.${NC}"
    echo -e "${YELLOW}You might need to modify the codeql-analysis.yml file for local execution.${NC}"
    echo -e "${YELLOW}Consider creating a simpler local analysis script instead.${NC}"
    exit 1
else
    echo -e "${GREEN}Workflow completed successfully.${NC}"
fi

echo -e "${YELLOW}Note: Results may differ slightly from GitHub's CodeQL implementation.${NC}"
echo -e "${YELLOW}For production-quality results, consider pushing to a draft PR.${NC}"

exit 0