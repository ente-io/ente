#!/usr/bin/env node

/**
 * Dependency Parser for Mobile Packages
 *
 * Parses pubspec.yaml files to build a dependency graph and determines
 * which packages/apps need to be linted based on what changed.
 *
 * Usage:
 *   node get-affected-packages.js <changed_files...>
 *
 * Output (JSON):
 *   {
 *     "packages": ["pkg1", "pkg2", ...],
 *     "lint_photos": "true/false",
 *     "lint_auth": "true/false",
 *     "lint_locker": "true/false",
 *     "lint_all": "true/false"
 *   }
 */

const fs = require('fs');
const path = require('path');
const yaml = require('yaml');

const PACKAGES_DIR = path.join(__dirname, '../../mobile/packages');
const APPS_DIR = path.join(__dirname, '../../mobile/apps');

/**
 * Parse a pubspec.yaml file and extract local package dependencies
 */
function parsePackageDependencies(pubspecPath) {
  try {
    const content = fs.readFileSync(pubspecPath, 'utf8');
    const parsed = yaml.parse(content);
    const deps = [];

    // Check both dependencies and dev_dependencies
    for (const depSection of ['dependencies', 'dev_dependencies']) {
      if (parsed[depSection]) {
        for (const [depName, depConfig] of Object.entries(parsed[depSection])) {
          // Only include local path dependencies (not SDK or pub.dev packages)
          if (depConfig && typeof depConfig === 'object' && depConfig.path) {
            // Extract package name from path (e.g., "../ente_crypto_api" -> "ente_crypto_api")
            const pkgName = depConfig.path.split('/').pop();
            deps.push(pkgName);
          }
        }
      }
    }

    return deps;
  } catch (error) {
    console.error(`Error parsing ${pubspecPath}:`, error.message);
    return [];
  }
}

/**
 * Build dependency graph for all packages
 * Returns: { packageName: [dependencies] }
 */
function buildDependencyGraph() {
  const graph = {};

  // Get all package directories
  const packages = fs.readdirSync(PACKAGES_DIR, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory() && dirent.name !== 'rust')
    .map(dirent => dirent.name);

  // Parse dependencies for each package
  for (const pkg of packages) {
    const pubspecPath = path.join(PACKAGES_DIR, pkg, 'pubspec.yaml');
    if (fs.existsSync(pubspecPath)) {
      graph[pkg] = parsePackageDependencies(pubspecPath);
    } else {
      graph[pkg] = [];
    }
  }

  return graph;
}

/**
 * Reverse the dependency graph to get dependents
 * Returns: { packageName: [packages that depend on it] }
 */
function buildDependentsGraph(depGraph) {
  const dependents = {};

  // Initialize
  for (const pkg of Object.keys(depGraph)) {
    dependents[pkg] = [];
  }

  // Build reverse mapping
  for (const [pkg, deps] of Object.entries(depGraph)) {
    for (const dep of deps) {
      if (!dependents[dep]) {
        dependents[dep] = [];
      }
      dependents[dep].push(pkg);
    }
  }

  return dependents;
}

/**
 * Get all affected packages (transitive dependents)
 */
function getAffectedPackages(changedPackages, dependentsGraph) {
  const affected = new Set(changedPackages);
  const queue = [...changedPackages];

  while (queue.length > 0) {
    const pkg = queue.shift();
    const deps = dependentsGraph[pkg] || [];

    for (const dep of deps) {
      if (!affected.has(dep)) {
        affected.add(dep);
        queue.push(dep);
      }
    }
  }

  return Array.from(affected).sort();
}

/**
 * Determine which apps need linting based on changed packages
 */
function getAffectedApps(affectedPackages) {
  const apps = {
    photos: false,
    auth: false,
    locker: false
  };

  // Parse each app's dependencies
  for (const [appName, _] of Object.entries(apps)) {
    const appPubspec = path.join(APPS_DIR, appName, 'pubspec.yaml');
    if (fs.existsSync(appPubspec)) {
      const appDeps = parsePackageDependencies(appPubspec);
      // If any affected package is used by this app, lint it
      apps[appName] = appDeps.some(dep => affectedPackages.includes(dep));
    }
  }

  return apps;
}

/**
 * Main function
 */
function main() {
  const changedFiles = process.argv.slice(2);

  // Safety check: if no files or workflow/analysis files changed, lint everything
  const safetyFiles = [
    '.github/workflows/mobile-packages-lint.yml',
    'mobile/analysis_options.yaml'
  ];

  const lintAll = changedFiles.length === 0 ||
                  changedFiles.some(f => safetyFiles.some(sf => f.includes(sf))) ||
                  changedFiles.some(f => f.includes('pubspec.yaml'));

  if (lintAll) {
    // Lint everything
    const allPackages = fs.readdirSync(PACKAGES_DIR, { withFileTypes: true })
      .filter(dirent => dirent.isDirectory() && dirent.name !== 'rust')
      .map(dirent => dirent.name)
      .sort();

    const output = {
      packages: allPackages,
      lint_photos: 'true',
      lint_auth: 'true',
      lint_locker: 'true',
      lint_all: 'true',
      reason: 'Safety: workflow/analysis/pubspec changed or no files specified'
    };

    console.log(JSON.stringify(output, null, 2));
    return;
  }

  // Extract changed package names from file paths
  const changedPackages = new Set();
  for (const file of changedFiles) {
    const match = file.match(/mobile\/packages\/([^\/]+)\//);
    if (match) {
      changedPackages.add(match[1]);
    }
  }

  // If no packages changed, nothing to lint
  if (changedPackages.size === 0) {
    const output = {
      packages: [],
      lint_photos: 'false',
      lint_auth: 'false',
      lint_locker: 'false',
      lint_all: 'false',
      reason: 'No package files changed'
    };

    console.log(JSON.stringify(output, null, 2));
    return;
  }

  // Build dependency graphs
  const depGraph = buildDependencyGraph();
  const dependentsGraph = buildDependentsGraph(depGraph);

  // Get all affected packages (changed + their dependents)
  const affectedPackages = getAffectedPackages(Array.from(changedPackages), dependentsGraph);

  // Determine which apps need linting
  const affectedApps = getAffectedApps(affectedPackages);

  // Output result
  const output = {
    packages: affectedPackages,
    lint_photos: affectedApps.photos.toString(),
    lint_auth: affectedApps.auth.toString(),
    lint_locker: affectedApps.locker.toString(),
    lint_all: 'false',
    changed_packages: Array.from(changedPackages),
    reason: `Selective lint: ${changedPackages.size} package(s) changed`
  };

  console.log(JSON.stringify(output, null, 2));
}

main();
