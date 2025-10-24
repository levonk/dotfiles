#!/usr/bin/env node
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

interface MatchLocation {
  file: string;
  index: number;
}

function normalizeCode(code: string): string {
  // Remove comments and normalize whitespace
  code = code.replace(/\/\/.*|\/\*[\s\S]*?\*\//g, ''); // strip comments
  code = code.replace(/\s+/g, ' '); // collapse whitespace
  code = code.replace(/\b\w+\b/g, 'VAR'); // normalize identifiers
  return code.trim();
}

function hashWindow(tokens: string[], start: number, size: number): string {
  const window = tokens.slice(start, start + size).join(' ');
  return crypto.createHash('md5').update(window).digest('hex');
}

function extractTemplates(filePaths: string[], windowSize: number, minOccurrences: number): Map<string, MatchLocation[]> {
  const hashMap = new Map<string, MatchLocation[]>();

  for (const file of filePaths) {
    const raw = fs.readFileSync(file, 'utf-8');
    const norm = normalizeCode(raw);
    const tokens = norm.split(' ');

    for (let i = 0; i <= tokens.length - windowSize; i++) {
      const hash = hashWindow(tokens, i, windowSize);
      const locations = hashMap.get(hash) || [];
      locations.push({ file, index: i });
      hashMap.set(hash, locations);
    }
  }

  // Filter by occurrence threshold
  const filtered = new Map<string, MatchLocation[]>();
  for (const [hash, locs] of hashMap.entries()) {
    if (locs.length >= minOccurrences) {
      filtered.set(hash, locs);
    }
  }

  return filtered;
}

// CLI entry
const args = process.argv.slice(2);
if (args.length < 1) {
  console.error('Usage: ts-node template-finder.ts <file1> <file2> ... [--window 10] [--min 2]');
  process.exit(1);
}

const windowArg = args.find(arg => arg.startsWith('--window'));
const minArg = args.find(arg => arg.startsWith('--min'));
const windowSize = windowArg ? parseInt(windowArg.split('=')[1]) : 10;
const minOccurrences = minArg ? parseInt(minArg.split('=')[1]) : 2;
const filePaths = args.filter(arg => !arg.startsWith('--'));

const templates = extractTemplates(filePaths, windowSize, minOccurrences);

console.log(`\n🔍 Found ${templates.size} templating opportunities:\n`);
for (const [hash, locs] of templates.entries()) {
  console.log(`Template Hash: ${hash}`);
  for (const loc of locs) {
    console.log(`  - ${loc.file} @ token index ${loc.index}`);
  }
  console.log();
}
