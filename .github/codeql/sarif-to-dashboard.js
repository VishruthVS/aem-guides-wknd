const fs = require('fs');
const path = require('path');

/**
 * Parses SARIF files and converts them to the format needed by our dashboard
 * This script should be run after CodeQL analysis to generate dashboard data
 */
function parseSarifFiles(sarifDir) {
  const dashboardData = {
    severityCounts: {
      critical: 0,
      high: 0,
      medium: 0,
      low: 0
    },
    categories: {},
    topFiles: {},
    trend: {
      labels: [],
      data: []
    },
    issues: []
  };

  // Get all SARIF files in the directory
  const files = fs.readdirSync(sarifDir)
    .filter(file => file.endsWith('.sarif'))
    .map(file => path.join(sarifDir, file));

  if (files.length === 0) {
    console.error(`No SARIF files found in ${sarifDir}`);
    return dashboardData;
  }

  // Process each SARIF file
  files.forEach(file => {
    try {
      const sarifContent = fs.readFileSync(file, 'utf8');
      const sarifData = JSON.parse(sarifContent);

      // Process results from each run
      sarifData.runs.forEach(run => {
        // Extract rules info to get categories
        const ruleMap = {};
        if (run.tool && run.tool.driver && run.tool.driver.rules) {
          run.tool.driver.rules.forEach(rule => {
            ruleMap[rule.id] = {
              name: rule.name || rule.id,
              category: (rule.properties && rule.properties.category) || 'Other',
              severity: mapSeverity(rule.properties && rule.properties.severity)
            };
          });
        }

        // Process each result (issue)
        if (run.results) {
          run.results.forEach(result => {
            const ruleId = result.ruleId;
            const rule = ruleMap[ruleId] || { 
              name: ruleId || 'Unknown', 
              category: 'Other',
              severity: mapSeverity(result.level)
            };
            
            const severity = rule.severity;
            const category = rule.category;
            
            // Increment severity count
            dashboardData.severityCounts[severity]++;
            
            // Increment category count
            dashboardData.categories[category] = (dashboardData.categories[category] || 0) + 1;
            
            // Process locations (files with issues)
            result.locations.forEach(location => {
              if (location.physicalLocation && location.physicalLocation.artifactLocation) {
                const filePath = location.physicalLocation.artifactLocation.uri || 
                                location.physicalLocation.artifactLocation.uriBaseId || 'Unknown file';
                
                // Keep track of files with most issues
                dashboardData.topFiles[filePath] = (dashboardData.topFiles[filePath] || 0) + 1;
                
                // Add detailed issue info
                const lineNum = location.physicalLocation.region ? location.physicalLocation.region.startLine : 0;
                
                dashboardData.issues.push({
                  severity: severity,
                  description: result.message.text || `${rule.name} issue`,
                  file: filePath,
                  line: lineNum,
                  ruleId: ruleId
                });
              }
            });
          });
        }
      });
    } catch (error) {
      console.error(`Error processing SARIF file ${file}:`, error);
    }
  });

  // Sort topFiles by count descending and limit to top 10
  const sortedFiles = Object.entries(dashboardData.topFiles)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10);
  
  dashboardData.topFiles = Object.fromEntries(sortedFiles);

  // Generate fake trend data (real implementation would need to track dates)
  const today = new Date();
  for (let i = 4; i >= 0; i--) {
    const date = new Date(today);
    date.setMonth(today.getMonth() - i);
    dashboardData.trend.labels.push(date.toLocaleString('default', { month: 'short' }));
    
    // Just for demo - would need a real source of historical data
    const fakeValue = Math.floor(Math.random() * 30) + 5;
    dashboardData.trend.data.push(fakeValue);
  }
  
  // Replace last trend data point with current count
  const totalIssues = dashboardData.issues.length;
  dashboardData.trend.data[dashboardData.trend.data.length - 1] = totalIssues;

  return dashboardData;
}

/**
 * Map CodeQL severity levels to our dashboard categories
 */
function mapSeverity(level) {
  if (!level) return 'medium';
  
  level = level.toLowerCase();
  
  if (level === 'error' || level === 'critical') return 'critical';
  if (level === 'warning' || level === 'high') return 'high';
  if (level === 'note' || level === 'medium') return 'medium';
  if (level === 'none' || level === 'low') return 'low';
  
  return 'medium'; // Default
}

/**
 * Main function to execute the script
 */
function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 2) {
    console.error('Usage: node sarif-to-dashboard.js <sarif-dir> <output-file>');
    process.exit(1);
  }
  
  const sarifDir = args[0];
  const outputFile = args[1];
  
  if (!fs.existsSync(sarifDir)) {
    console.error(`SARIF directory does not exist: ${sarifDir}`);
    process.exit(1);
  }
  
  const dashboardData = parseSarifFiles(sarifDir);
  
  // Write dashboard data to output file
  fs.writeFileSync(outputFile, JSON.stringify(dashboardData, null, 2));
  console.log(`Dashboard data written to ${outputFile}`);
}

// Run the script
main();