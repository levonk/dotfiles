#!/usr/bin/env node
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';
import * as os from 'os';

declare const process: {
  argv: string[];
  exit(code?: number): never;
};

type NodeBuffer = {
  length: number;
  [index: number]: number;
  toString(encoding?: string): string;
};

interface Token {
  raw: string;
  normalized: string;
  line: number;
}

interface TemplateMatch {
  file: string;
  startIndex: number;
  endIndex: number;
  startLine: number;
  endLine: number;
  tokenCount: number;
}

interface IgnoreRule {
  baseDir: string;
  regex: RegExp;
  directoryOnly: boolean;
  negated: boolean;
  anchored: boolean;
}

interface BucketRecord {
  hash: string;
  file: string;
  startIndex: number;
  endIndex: number;
  startLine: number;
  endLine: number;
  tokenCount: number;
}

function stripBlockComments(input: string): string {
  return input.replace(/\/\*[\s\S]*?\*\//g, comment => comment.replace(/[^\n]/g, ' '));
}

function stripSingleLineComments(input: string): string {
  return input.replace(/\/\/.*$/gm, '');
}

function normalizeToken(raw: string): string {
  if (!raw) {
    return raw;
  }

  if (/^[A-Za-z_][A-Za-z0-9_]*$/.test(raw)) {
    return 'VAR';
  }

  if (/^[0-9]+(\.[0-9]+)?$/.test(raw)) {
    return 'VAR';
  }

  if (raw === 'STRING') {
    return 'STRING';
  }

  return raw;
}

function tokenize(code: string): Token[] {
  const withoutComments = stripBlockComments(stripSingleLineComments(code));
  const tokens: Token[] = [];
  let current = '';
  let currentLine = 1;

  const flushCurrent = () => {
    if (current.length === 0) {
      return;
    }
    tokens.push({
      raw: current,
      normalized: normalizeToken(current),
      line: currentLine,
    });
    current = '';
  };

  for (let i = 0; i < withoutComments.length; i++) {
    const char = withoutComments[i];

    if (char === '\n') {
      flushCurrent();
      currentLine += 1;
      continue;
    }

    if (char === '\r') {
      continue;
    }

    if (char === '"' || char === "'") {
      flushCurrent();
      const quote = char;
      let literal = quote;
      let j = i + 1;
      while (j < withoutComments.length) {
        const nextChar = withoutComments[j];
        literal += nextChar;
        if (nextChar === '\n') {
          currentLine += 1;
        }
        if (nextChar === '\\') {
          j += 1;
          if (j < withoutComments.length) {
            literal += withoutComments[j];
          }
        } else if (nextChar === quote) {
          break;
        }
        j += 1;
      }
      tokens.push({ raw: literal, normalized: 'STRING', line: currentLine });
      i = j;
      continue;
    }

    if (/\s/.test(char)) {
      flushCurrent();
      continue;
    }

    if (/[A-Za-z0-9_]/.test(char)) {
      current += char;
      continue;
    }

    flushCurrent();
    tokens.push({ raw: char, normalized: char, line: currentLine });
  }

  flushCurrent();
  return tokens;
}

function hashNormalizedTokens(tokens: Token[], start: number, size: number): string {
  const window = tokens
    .slice(start, start + size)
    .map(token => token.normalized)
    .join(' ');
  return crypto.createHash('sha256').update(window).digest('hex');
}

function isProbablyBinary(buffer: NodeBuffer): boolean {
  const sampleLength = Math.min(buffer.length, 4096);
  if (sampleLength === 0) {
    return false;
  }

  let highByteCount = 0;
  for (let i = 0; i < sampleLength; i += 1) {
    const byte = buffer[i];
    if (byte === 0) {
      return true;
    }
    if (byte < 7 || byte > 127) {
      highByteCount += 1;
    }
  }

  return highByteCount / sampleLength > 0.3;
}

function globToRegExp(pattern: string): RegExp {
  let expression = '^';

  for (let i = 0; i < pattern.length; i += 1) {
    const char = pattern[i];

    if (char === '*') {
      if (pattern[i + 1] === '*') {
        expression += '.*';
        i += 1;
      } else {
        expression += '[^/]*';
      }
      continue;
    }

    if (char === '?') {
      expression += '[^/]';
      continue;
    }

    if ('\\^$.|+()[]{}'.includes(char)) {
      expression += `\\${char}`;
      continue;
    }

    expression += char;
  }

  expression += '$';
  return new RegExp(expression);
}

function parseGitignoreFile(filePath: string): IgnoreRule[] {
  let raw = '';
  try {
    raw = fs.readFileSync(filePath, 'utf-8');
  } catch {
    return [];
  }

  const baseDir = path.dirname(filePath);
  const rules: IgnoreRule[] = [];
  const lines = raw.split(/\r?\n/);

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.length === 0 || trimmed.startsWith('#')) {
      continue;
    }

    let pattern = trimmed;
    let negated = false;
    if (pattern.startsWith('!')) {
      negated = true;
      pattern = pattern.slice(1);
    }

    let directoryOnly = false;
    if (pattern.endsWith('/')) {
      directoryOnly = true;
      pattern = pattern.slice(0, -1);
    }

    let anchored = false;
    if (pattern.startsWith('/')) {
      anchored = true;
      pattern = pattern.slice(1);
    }

    if (pattern.length === 0) {
      continue;
    }

    const regex = globToRegExp(pattern);
    rules.push({
      baseDir,
      regex,
      directoryOnly,
      negated,
      anchored,
    });
  }

  return rules;
}

function matchesRule(rule: IgnoreRule, targetPath: string, isDirectory: boolean): boolean {
  if (rule.directoryOnly && !isDirectory) {
    return false;
  }

  const relative = path.relative(rule.baseDir, targetPath).replace(/\\/g, '/');
  if (relative.length === 0 || relative.startsWith('..')) {
    return false;
  }

  if (rule.anchored) {
    return rule.regex.test(relative);
  }

  if (rule.regex.test(relative)) {
    return true;
  }

  const segments = relative.split('/');
  for (let i = 1; i < segments.length; i += 1) {
    const subset = segments.slice(i).join('/');
    if (rule.regex.test(subset)) {
      return true;
    }
  }

  return false;
}

function isIgnored(targetPath: string, isDirectory: boolean, rules: IgnoreRule[]): boolean {
  let ignored = false;

  for (const rule of rules) {
    if (!matchesRule(rule, targetPath, isDirectory)) {
      continue;
    }
    ignored = !rule.negated;
  }

  return ignored;
}

function collectFilesFromPaths(inputPaths: string[]): string[] {
  const collected: string[] = [];

  const visit = (targetPath: string, inheritedRules: IgnoreRule[]) => {
    let stats: fs.Stats;
    try {
      stats = fs.statSync(targetPath);
    } catch {
      return;
    }

    const isDirectory = stats.isDirectory();
    if (isIgnored(targetPath, isDirectory, inheritedRules)) {
      return;
    }

    if (isDirectory) {
      let effectiveRules = inheritedRules;
      const gitignorePath = path.join(targetPath, '.gitignore');
      let newRules: IgnoreRule[] = [];
      try {
        if (fs.existsSync(gitignorePath) && fs.statSync(gitignorePath).isFile()) {
          newRules = parseGitignoreFile(gitignorePath);
        }
      } catch {
        newRules = [];
      }

      if (newRules.length > 0) {
        effectiveRules = inheritedRules.concat(newRules);
      }

      let entries: fs.Dirent[] = [];
      try {
        entries = fs.readdirSync(targetPath, { withFileTypes: true });
      } catch {
        return;
      }

      for (const entry of entries) {
        if (entry.name === '.' || entry.name === '..') {
          continue;
        }
        visit(path.join(targetPath, entry.name), effectiveRules);
      }
      return;
    }

    if (stats.isFile()) {
      collected.push(targetPath);
    }
  };

  for (const inputPath of inputPaths) {
    visit(path.resolve(inputPath), []);
  }

  return collected;
}

function extractTemplatesToDisk(filePaths: string[], windowSize: number): { tempDir: string; buckets: string[] } {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), 'template-finder-'));
  const bucketPaths = new Set<string>();

  for (const file of filePaths) {
    let rawBuffer: Buffer;
    try {
      rawBuffer = fs.readFileSync(file);
    } catch {
      continue;
    }

    if (isProbablyBinary(rawBuffer)) {
      continue;
    }

    const raw = rawBuffer.toString('utf-8');
    const tokens = tokenize(raw);
    tokenCache.set(file, tokens);
    if (tokens.length < windowSize) {
      continue;
    }

    for (let i = 0; i <= tokens.length - windowSize; i += 1) {
      const hash = hashNormalizedTokens(tokens, i, windowSize);
      const record: BucketRecord = {
        hash,
        file,
        startIndex: i,
        endIndex: i + windowSize,
        startLine: tokens[i].line,
        endLine: tokens[i + windowSize - 1].line,
        tokenCount: windowSize,
      };

      const bucketName = hash.slice(0, 2);
      const bucketPath = path.join(tempDir, `${bucketName}.jsonl`);
      try {
        fs.appendFileSync(bucketPath, `${JSON.stringify(record)}\n`);
      } catch (error) {
        throw new Error(`Failed to append bucket file ${bucketPath}: ${(error as Error).message}`);
      }
      bucketPaths.add(bucketPath);
    }
  }

  return { tempDir, buckets: Array.from(bucketPaths) };
}

function readBucketFile(bucketPath: string): BucketRecord[] {
  let raw = '';
  try {
    raw = fs.readFileSync(bucketPath, 'utf-8');
  } catch {
    return [];
  }

  if (raw.length === 0) {
    return [];
  }

  const records: BucketRecord[] = [];
  const lines = raw.split(/\n/);
  for (const line of lines) {
    if (!line) {
      continue;
    }
    try {
      const parsed = JSON.parse(line) as BucketRecord;
      records.push(parsed);
    } catch {
      continue;
    }
  }

  return records;
}

function cleanupTempDir(tempDir: string): void {
  try {
    fs.rmSync(tempDir, { recursive: true, force: true });
  } catch {
    // ignore cleanup failures
  }
}

const fileLineCache = new Map<string, string[]>();
const tokenCache = new Map<string, Token[]>();

function getFileLines(filePath: string): string[] {
  const cached = fileLineCache.get(filePath);
  if (cached) {
    return cached;
  }

  let raw = '';
  try {
    raw = fs.readFileSync(filePath, 'utf-8');
  } catch {
    fileLineCache.set(filePath, []);
    return [];
  }

  const lines = raw.split(/\r?\n/);
  fileLineCache.set(filePath, lines);

  if (fileLineCache.size > 50) {
    const [firstKey] = fileLineCache.keys();
    if (firstKey) {
      fileLineCache.delete(firstKey);
    }
  }

  return lines;
}

function getSnippet(filePath: string, startLine: number, endLine: number): string {
  const lines = getFileLines(filePath);
  if (lines.length === 0) {
    return '';
  }
  const slice = lines.slice(Math.max(0, startLine - 1), Math.min(lines.length, endLine));
  return slice.join('\n').trim();
}

function expandGreedyMatch(first: TemplateMatch, second: TemplateMatch): { first: TemplateMatch; second: TemplateMatch } {
  const firstTokens = tokenCache.get(first.file);
  const secondTokens = tokenCache.get(second.file);

  if (!firstTokens || !secondTokens) {
    return { first, second };
  }

  let firstStart = first.startIndex;
  let secondStart = second.startIndex;
  let firstEnd = first.endIndex;
  let secondEnd = second.endIndex;

  while (
    firstStart > 0 &&
    secondStart > 0 &&
    firstTokens[firstStart - 1].normalized === secondTokens[secondStart - 1].normalized
  ) {
    firstStart -= 1;
    secondStart -= 1;
  }

  while (
    firstEnd < firstTokens.length &&
    secondEnd < secondTokens.length &&
    firstTokens[firstEnd].normalized === secondTokens[secondEnd].normalized
  ) {
    firstEnd += 1;
    secondEnd += 1;
  }

  const expandedFirst: TemplateMatch = {
    file: first.file,
    startIndex: firstStart,
    endIndex: firstEnd,
    startLine: firstTokens[firstStart].line,
    endLine: firstTokens[firstEnd - 1].line,
    tokenCount: firstEnd - firstStart,
  };

  const expandedSecond: TemplateMatch = {
    file: second.file,
    startIndex: secondStart,
    endIndex: secondEnd,
    startLine: secondTokens[secondStart].line,
    endLine: secondTokens[secondEnd - 1].line,
    tokenCount: secondEnd - secondStart,
  };

  return { first: expandedFirst, second: expandedSecond };
}

function parseOption(args: string[], key: '--window' | '--min', fallback: number): number {
  const rawOption = args.find(arg => arg.startsWith(`${key}`));
  if (!rawOption) {
    return fallback;
  }

  const [, value] = rawOption.split('=');
  const parsed = Number.parseInt(value, 10);
  return Number.isNaN(parsed) ? fallback : parsed;
}

function printUsage(): void {
  const message = `
Usage: template-finder [options] <path...>

Detect duplicated token windows across files, grouping matches into CSV output.

Options:
  --window=NUM       Minimum tokens per match window (default 50)
  --min=NUM          Minimum occurrences before reporting (default 2)
  --include-text     Append the matching text column to the CSV output
  -h, --help         Show this help message and exit

Examples:
  template-finder src/
  template-finder src/ --window=75 --min=3 --include-text
`;
  console.log(message.trimEnd());
}

const args = process.argv.slice(2);

const optionArgs: string[] = [];
const targetArgs: string[] = [];
for (const arg of args) {
  if (arg.startsWith('-')) {
    optionArgs.push(arg);
  } else {
    targetArgs.push(arg);
  }
}

if (optionArgs.includes('--help') || optionArgs.includes('-h')) {
  printUsage();
  process.exit(0);
}

if (args.length === 0) {
  console.error('Error: missing required file or directory path.');
  printUsage();
  process.exit(1);
}

if (targetArgs.length === 0) {
  console.error('Error: at least one file or directory path is required.');
  printUsage();
  process.exit(1);
}

const windowSize = Math.max(50, parseOption(optionArgs, '--window', 50));
const minOccurrences = parseOption(optionArgs, '--min', 2);
const includeText = optionArgs.includes('--include-text');

const filePaths = collectFilesFromPaths(targetArgs);

if (filePaths.length === 0) {
  console.error('No files discovered for analysis.');
  process.exit(1);
}

const { tempDir, buckets } = extractTemplatesToDisk(filePaths, windowSize);

const headerColumns = [
  'path1',
  'path2',
  'line-start-1',
  'line-end-1',
  'token-count-1',
  'line-start-2',
  'line-end-2',
  'token-count-2',
];
if (includeText) {
  headerColumns.push('text');
}
console.log(headerColumns.join(', '));

try {
  for (const bucketPath of buckets) {
    const records = readBucketFile(bucketPath);
    if (records.length === 0) {
      continue;
    }

    const groups = new Map<string, TemplateMatch[]>();
    for (const record of records) {
      const match: TemplateMatch = {
        file: record.file,
        startIndex: record.startIndex,
        endIndex: record.endIndex,
        startLine: record.startLine,
        endLine: record.endLine,
        tokenCount: record.tokenCount,
      };

      const existing = groups.get(record.hash);
      if (existing) {
        existing.push(match);
      } else {
        groups.set(record.hash, [match]);
      }
    }

    for (const matches of groups.values()) {
      if (matches.length < minOccurrences) {
        continue;
      }

      const emittedPairs = new Set<string>();
      for (let i = 0; i < matches.length; i += 1) {
        for (let j = i + 1; j < matches.length; j += 1) {
          const expansion = expandGreedyMatch(matches[i], matches[j]);
          const first = expansion.first;
          const second = expansion.second;
          if (
            first.file === second.file &&
            first.startIndex === second.startIndex &&
            first.endIndex === second.endIndex
          ) {
            continue;
          }
          const pairKey = `${first.file}:${first.startIndex}-${first.endIndex}::${second.file}:${second.startIndex}-${second.endIndex}`;
          if (emittedPairs.has(pairKey)) {
            continue;
          }
          emittedPairs.add(pairKey);
          let snippet = '';
          if (includeText) {
            snippet = getSnippet(first.file, first.startLine, first.endLine);
          }
          const row = [
            first.file,
            second.file,
            String(first.startLine),
            String(first.endLine),
            String(first.tokenCount),
            String(second.startLine),
            String(second.endLine),
            String(second.tokenCount),
          ];
          if (includeText) {
            row.push(JSON.stringify(snippet));
          }
          console.log(row.join(', '));
        }
      }
    }
  }
} finally {
  cleanupTempDir(tempDir);
}
