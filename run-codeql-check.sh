#!/bin/bash

# File: run-codeql-check.sh
# Local CodeQL analysis script for AEM Guides WKND project

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting CodeQL security analysis...${NC}"

# Create output directories
mkdir -p codeql-local/results

# Step 1: Create a CodeQL database for JavaScript
echo -e "${YELLOW}Creating CodeQL database...${NC}"
codeql database create codeql-local/db --language=javascript --source-root . --overwrite

# Check if database creation was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Error creating CodeQL database${NC}"
    exit 1
fi

# Step 2: Find built-in JavaScript queries
echo -e "${YELLOW}Looking for built-in CodeQL security queries...${NC}"

# Find DOM-based XSS query (this is a very basic common query that should be available)
XSS_QUERY=$(find /opt/codeql -name "DomBasedXss.ql" 2>/dev/null | head -1)

if [ -z "$XSS_QUERY" ]; then
    echo -e "${RED}Could not find built-in CodeQL XSS query.${NC}"
    echo -e "${YELLOW}Running simplified analysis instead.${NC}"
    
    # Create a file listing files with potential XSS-related issues
    grep -r "innerHTML" --include="*.js" --include="*.jsx" --include="*.ts" --include="*.tsx" . > codeql-local/results/potential-xss.txt
    
    # Get a count of potential issues
    COUNT=$(cat codeql-local/results/potential-xss.txt | wc -l)
    
    # Generate a simple report
    echo "## Manual Security Analysis Results" > codeql-local/security-report.md
    echo "Analysis completed on $(date)" >> codeql-local/security-report.md
    echo "" >> codeql-local/security-report.md
    echo "* **Total Potential Issues:** $COUNT" >> codeql-local/security-report.md
    
    if [ "$COUNT" -gt 0 ]; then
        echo -e "${YELLOW}Found $COUNT potential security issues.${NC}"
        echo "### Potential Security Issues Found:" >> codeql-local/security-report.md
        echo "Files that use innerHTML or similar potentially unsafe DOM manipulation:" >> codeql-local/security-report.md
        echo '```' >> codeql-local/security-report.md
        cat codeql-local/results/potential-xss.txt | head -10 >> codeql-local/security-report.md
        echo '```' >> codeql-local/security-report.md
    else
        echo -e "${GREEN}✅ No potential security issues found!${NC}"
        echo "✅ No potential security issues found!" >> codeql-local/security-report.md
    fi
    
    # Find VulnerableComponent.jsx
    VULNERABLE_COMPONENT=$(find . -name "VulnerableComponent.jsx" 2>/dev/null)
    if [ ! -z "$VULNERABLE_COMPONENT" ]; then
        echo -e "${YELLOW}Vulnerable component detected: ${VULNERABLE_COMPONENT}${NC}"
        grep -r "innerHTML" "$VULNERABLE_COMPONENT" > codeql-local/results/vulnerable-component-issues.txt
        
        VULN_ISSUES=$(cat codeql-local/results/vulnerable-component-issues.txt | wc -l)
        if [ "$VULN_ISSUES" -gt 0 ]; then
            echo -e "${YELLOW}Issues found in VulnerableComponent.jsx:${NC}"
            cat codeql-local/results/vulnerable-component-issues.txt
            
            echo "" >> codeql-local/security-report.md
            echo "### Issues in VulnerableComponent.jsx:" >> codeql-local/security-report.md
            echo '```' >> codeql-local/security-report.md
            cat codeql-local/results/vulnerable-component-issues.txt >> codeql-local/security-report.md
            echo '```' >> codeql-local/security-report.md
        fi
    fi
else
    # Step 3: Run the analysis with the built-in XSS query
    echo -e "${YELLOW}Running CodeQL analysis with built-in DOM-based XSS query...${NC}"
    codeql database analyze codeql-local/db "$XSS_QUERY" \
      --format=sarif-latest \
      --output=codeql-local/results/codeql-results.sarif
    
    # Check if analysis was successful
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error running CodeQL analysis${NC}"
        exit 1
    fi
    
    # Step 4: Generate a human-readable report
    echo -e "${YELLOW}Generating report...${NC}"
    echo "## CodeQL Security Analysis Results" > codeql-local/security-report.md
    echo "Analysis completed on $(date)" >> codeql-local/security-report.md
    echo "" >> codeql-local/security-report.md
    
    # Count total findings (complex due to SARIF format)
    COUNT=$(jq '.runs[0].results | length // 0' codeql-local/results/codeql-results.sarif 2>/dev/null || echo 0)
    echo "* **Total Findings:** $COUNT" >> codeql-local/security-report.md
    
    # List findings by severity
    if [ "$COUNT" -gt 0 ]; then
        echo -e "${RED}Security issues found!${NC}"
        echo "### Security Issues Found:" >> codeql-local/security-report.md
        echo "" >> codeql-local/security-report.md
        
        # Extract and format issues
        jq -r '.runs[0].results[] | "- **" + (.properties.severity // "warning") + "**: " + .message.text' \
          codeql-local/results/codeql-results.sarif | head -10 >> codeql-local/security-report.md
        
        # Show on console
        jq -r '.runs[0].results[] | "- " + (.properties.severity // "warning") + ": " + .message.text' \
          codeql-local/results/codeql-results.sarif | head -10
        
        if [ "$COUNT" -gt 10 ]; then
            echo -e "${YELLOW}...and $(($COUNT - 10)) more issues.${NC}"
            echo "" >> codeql-local/security-report.md
            echo "...and $(($COUNT - 10)) more issues." >> codeql-local/security-report.md
        fi
    else
        echo -e "${GREEN}✅ No security issues found!${NC}"
        echo "✅ No security issues found!" >> codeql-local/security-report.md
    fi
    
    # Find the vulnerable component 
    VULNERABLE_COMPONENT=$(find . -name "VulnerableComponent.jsx" 2>/dev/null)
    if [ ! -z "$VULNERABLE_COMPONENT" ]; then
        echo -e "${YELLOW}Vulnerable component detected: ${VULNERABLE_COMPONENT}${NC}"
        
        # Extract issues specific to the vulnerable component
        COMPONENT_ISSUES=$(jq -r --arg comp "$VULNERABLE_COMPONENT" \
          '.runs[0].results[] | select(.locations[0].physicalLocation.artifactLocation.uri | contains($comp))' \
          codeql-local/results/codeql-results.sarif 2>/dev/null)
        
        if [ ! -z "$COMPONENT_ISSUES" ]; then
            echo -e "${YELLOW}Issues found in VulnerableComponent.jsx:${NC}"
            jq -r '.message.text' <<< "$COMPONENT_ISSUES"
            
            echo "" >> codeql-local/security-report.md
            echo "### Issues in VulnerableComponent.jsx:" >> codeql-local/security-report.md
            jq -r '.message.text' <<< "$COMPONENT_ISSUES" >> codeql-local/security-report.md
        fi
    fi
fi

echo "" >> codeql-local/security-report.md
echo "Full report available in codeql-local/results/" >> codeql-local/security-report.md

# Display the report path
echo -e "${GREEN}Analysis complete! Report saved to:${NC}"
echo "  - Results: codeql-local/results/"
echo "  - Readable Report: codeql-local/security-report.md"

# Return exit code based on findings (non-zero if issues found)
if [ "$COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi