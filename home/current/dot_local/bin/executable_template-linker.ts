#!/usr/bin/env node
import * as fs from "fs";
import * as path from "path";
import { spawnSync } from "child_process";

declare const process: {
  argv: string[];
  stdin: {
    setEncoding(enc: string): void;
    on(event: "data", listener: (chunk: string) => void): void;
    on(event: "end", listener: () => void): void;
  };
  exit(code?: number): never;
};

type CsvRow = {
  path1: string;
  path2: string;
  startLine1: number;
  endLine1: number;
  tokenCount1: number;
  startLine2: number;
  endLine2: number;
  tokenCount2: number;
  snippet?: string;
};

type Segment = {
  startLine: number;
  endLine: number;
  templatePath: string;
  fullFile: boolean;
};

type FileConversion = {
  originalPath: string;
  destPath: string;
  newline: string;
  segments: Segment[];
  originalContent: string;
};

type TemplateRecord = {
  content: string;
  isPartial: boolean;
  sourceExample: string;
};

const args = process.argv.slice(2);

function parseArgValue(flag: string): string | undefined {
  const prefix = `${flag}=`;
  for (const arg of args) {
    if (arg.startsWith(prefix)) {
      return arg.slice(prefix.length);
    }
  }
  return undefined;
}

function hasFlag(flag: string): boolean {
  return args.includes(flag);
}

function printUsage(): void {
  const message = `
Usage: executable_template-linker --boilerplates=PATH [--min-length=NUM] [--dry-run]

Reads CSV output from executable_template-finder (with --include-text) on stdin,
creates Jinja2 boilerplate templates, and replaces duplicate content with
template includes in other files.

Required:
  --boilerplates=PATH   Root directory where boilerplate templates should live

Options:
  --min-length=NUM      Minimum character length for a snippet (default 280)
  --dry-run             Only print planned operations without changing files
  -h, --help            Show this message
`;
  console.log(message.trimEnd());
}

if (hasFlag("--help") || hasFlag("-h")) {
  printUsage();
  process.exit(0);
}

const boilerplatesArg = parseArgValue("--boilerplates");

if (!boilerplatesArg) {
  console.error("Error: --boilerplates=PATH is required.");
  printUsage();
  process.exit(1);
}

const boilerplatesRoot = path.resolve(boilerplatesArg);
const minLength = Number.parseInt(parseArgValue("--min-length") ?? "280", 10);
const dryRun = hasFlag("--dry-run");

if (Number.isNaN(minLength) || minLength < 1) {
  console.error("Error: --min-length must be a positive integer.");
  process.exit(1);
}

function ensureDirectory(dirPath: string): void {
  if (dryRun) {
    return;
  }
  fs.mkdirSync(dirPath, { recursive: true });
}

function readAllStdin(): Promise<string> {
  return new Promise(resolve => {
    const chunks: string[] = [];
    process.stdin.setEncoding("utf-8");
    process.stdin.on("data", chunk => {
      chunks.push(chunk);
    });
    process.stdin.on("end", () => {
      resolve(chunks.join(""));
    });
  });
}

function parseCsv(input: string): CsvRow[] {
  const rows: CsvRow[] = [];
  const lines = input.split(/\r?\n/).filter(line => line.trim().length > 0);
  if (lines.length === 0) {
    return rows;
  }

  const header = lines[0];
  const headerColumns = header
    .split(",")
    .map(col => col.trim().toLowerCase());
  const includeText = headerColumns.includes("text");

  for (let i = 1; i < lines.length; i += 1) {
    const line = lines[i];
    const fields = [] as string[];
    let current = "";
    let inQuotes = false;

    for (let j = 0; j < line.length; j += 1) {
      const char = line[j];
      if (char === "\"" && line[j - 1] !== "\\") {
        inQuotes = !inQuotes;
        current += char;
        continue;
      }
      if (char === "," && !inQuotes) {
        fields.push(current.trim());
        current = "";
        continue;
      }
      current += char;
    }
    fields.push(current.trim());

    if (fields.length < 8) {
      continue;
    }

    const row: CsvRow = {
      path1: fields[0],
      path2: fields[1],
      startLine1: Number.parseInt(fields[2], 10),
      endLine1: Number.parseInt(fields[3], 10),
      tokenCount1: Number.parseInt(fields[4], 10),
      startLine2: Number.parseInt(fields[5], 10),
      endLine2: Number.parseInt(fields[6], 10),
      tokenCount2: Number.parseInt(fields[7], 10),
    };

    if (includeText && fields.length >= 9) {
      try {
        row.snippet = JSON.parse(fields[8]);
      } catch {
        row.snippet = undefined;
      }
    }

    rows.push(row);
  }

  return rows;
}

function normalizePath(targetPath: string): string {
  if (!targetPath) {
    return targetPath;
  }
  if (path.isAbsolute(targetPath)) {
    return path.normalize(targetPath);
  }
  return path.resolve(targetPath);
}

function readSegment(filePath: string, startLine: number, endLine: number): { content: string; totalLines: number; newline: string } | null {
  let raw: string;
  try {
    raw = fs.readFileSync(filePath, "utf-8");
  } catch {
    return null;
  }

  const newline = raw.includes("\r\n") ? "\r\n" : "\n";
  const lines = raw.split(/\r?\n/);
  if (startLine < 1 || endLine > lines.length) {
    return null;
  }
  const slice = lines.slice(startLine - 1, endLine);
  return {
    content: slice.join(newline),
    totalLines: lines.length,
    newline,
  };
}

function isSubPath(candidate: string, parent: string): boolean {
  const relative = path.relative(parent, candidate);
  return !relative.startsWith("..") && !path.isAbsolute(relative);
}

function findCommonAncestor(first: string, second: string): string {
  const firstParts = first.split(path.sep).filter(Boolean);
  const secondParts = second.split(path.sep).filter(Boolean);
  const length = Math.min(firstParts.length, secondParts.length);
  const segments: string[] = [];
  for (let i = 0; i < length; i += 1) {
    if (firstParts[i] !== secondParts[i]) {
      break;
    }
    segments.push(firstParts[i]);
  }
  if (segments.length === 0) {
    return path.parse(first).root || "/";
  }
  return `${path.parse(first).root}${segments.join(path.sep)}`;
}

function toPosix(targetPath: string): string {
  return targetPath.split(path.sep).join("/");
}

function appendJinjaSuffix(filePath: string, partialIndex?: number): string {
  const parsed = path.parse(filePath);
  const baseName = partialIndex
    ? `${parsed.name}.${partialIndex}${parsed.ext}`
    : `${parsed.name}${parsed.ext}`;
  const finalName = `${baseName}.jinja2`;
  return path.join(parsed.dir, finalName);
}

function ensureJinjaPath(filePath: string): string {
  if (filePath.endsWith(".jinja2")) {
    return filePath;
  }
  return `${filePath}.jinja2`;
}

function detectGitRoot(startDir: string): string | null {
  let current = startDir;
  while (true) {
    if (fs.existsSync(path.join(current, ".git"))) {
      return current;
    }
    const parent = path.dirname(current);
    if (parent === current) {
      break;
    }
    current = parent;
  }
  return null;
}

function moveFilePreservingGitHistory(from: string, to: string): void {
  if (from === to) {
    return;
  }

  ensureDirectory(path.dirname(to));

  const gitRoot = detectGitRoot(path.dirname(from));
  if (gitRoot) {
    const fromRelative = path.relative(gitRoot, from);
    const toRelative = path.relative(gitRoot, to);
    try {
      const status = spawnSync("git", ["ls-files", "--error-unmatch", fromRelative], {
        cwd: gitRoot,
        stdio: "ignore",
      });
      if (status.status === 0) {
        const mvResult = spawnSync("git", ["mv", fromRelative, toRelative], {
          cwd: gitRoot,
          stdio: "pipe",
        });
        if (mvResult.status === 0) {
          return;
        }
      }
    } catch {
      // fall back to fs rename
+    }
+  }
+
+  if (dryRun) {
+    return;
+  }
+
+  fs.renameSync(from, to);
+}
+
+function writeFile(targetPath: string, content: string): void {
+  ensureDirectory(path.dirname(targetPath));
+  if (dryRun) {
+    return;
+  }
+  fs.writeFileSync(targetPath, content, "utf-8");
+}
+
+function createIncludeLine(templatePath: string, indent: string): string {
+  return `${indent}{% include "${toPosix(templatePath)}" %}`;
+}
+
+function prepareTemplatePath(originalPath: string, partial: boolean, counter: Map<string, number>): string {
+  const canonicalOriginal = normalizePath(originalPath);
+  const commonAncestor = findCommonAncestor(canonicalOriginal, boilerplatesRoot);
+  let relative = path.relative(commonAncestor, canonicalOriginal);
+  if (relative.startsWith("..")) {
+    relative = path.basename(canonicalOriginal);
+  }
+  const parsed = path.parse(relative);
+  const key = path.join(parsed.dir, `${parsed.name}${parsed.ext}`);
+  let targetPath: string;
+  if (partial) {
+    const current = counter.get(key) ?? 1;
+    counter.set(key, current + 1);
+    targetPath = appendJinjaSuffix(path.join(boilerplatesRoot, parsed.dir, `${parsed.name}${parsed.ext}`), current);
+  } else {
+    targetPath = ensureJinjaPath(path.join(boilerplatesRoot, parsed.dir, `${parsed.name}${parsed.ext}`));
+  }
+  return path.normalize(targetPath);
+}
+
+function ensureTemplateRecord(
+  templates: Map<string, TemplateRecord>,
+  templatePath: string,
+  content: string,
+  isPartial: boolean,
+  sourceExample: string,
+): void {
+  const existing = templates.get(templatePath);
+  if (existing) {
+    if (existing.content === content) {
+      return;
+    }
+    throw new Error(
+      `Conflicting template content detected for ${templatePath}. Verify template finder output before rerunning.`,
+    );
+  }
+  templates.set(templatePath, {
+    content,
+    isPartial,
+    sourceExample,
+  });
+}
+
+function registerSegment(
+  conversions: Map<string, FileConversion>,
+  entryPath: string,
+  segment: Segment,
+  newline: string,
+  originalContent: string,
+): void {
+  const existing = conversions.get(entryPath);
+  if (existing) {
+    existing.segments.push(segment);
+    return;
+  }
+  const destPath = ensureJinjaPath(entryPath);
+  conversions.set(entryPath, {
+    originalPath: entryPath,
+    destPath,
+    newline,
+    segments: [segment],
+    originalContent,
+  });
+}
+
+(async () => {
+  const input = await readAllStdin();
+  if (input.trim().length === 0) {
+    console.error("No CSV input detected on stdin. Ensure the template finder output is piped into this tool.");
+    process.exit(1);
+  }
+
+  const rows = parseCsv(input);
+  if (rows.length === 0) {
+    console.error("No data rows parsed from CSV input. Confirm template finder was run with --include-text.");
+    process.exit(1);
+  }
+
+  const templateRecords = new Map<string, TemplateRecord>();
+  const fileConversions = new Map<string, FileConversion>();
+  const partialCounter = new Map<string, number>();
+  const processedSegments = new Set<string>();
+  const processedPairs = new Set<string>();
+
+  const plannedMoves: Array<{ from: string; to: string }> = [];
+
+  for (const row of rows) {
+    const entryPaths = [normalizePath(row.path1), normalizePath(row.path2)];
+    const pairKey = entryPaths
+      .map((entryPath, index) => `${entryPath}:${index === 0 ? row.startLine1 : row.startLine2}-${index === 0 ? row.endLine1 : row.endLine2}`)
+      .sort()
+      .join("::");
+    if (processedPairs.has(pairKey)) {
+      continue;
+    }
+    processedPairs.add(pairKey);
+
+    const entries = [
+      {
+        path: entryPaths[0],
+        startLine: row.startLine1,
+        endLine: row.endLine1,
+        tokenCount: row.tokenCount1,
+      },
+      {
+        path: entryPaths[1],
+        startLine: row.startLine2,
+        endLine: row.endLine2,
+        tokenCount: row.tokenCount2,
+      },
+    ];
+
+    const entrySegments = entries.map(entry => {
+      const segmentKey = `${entry.path}:${entry.startLine}-${entry.endLine}`;
+      return { entry, segmentKey };
+    });
+
+    if (entrySegments.every(segment => processedSegments.has(segment.segmentKey))) {
+      continue;
+    }
+
+    const enrichedEntries = [] as Array<{
+      path: string;
+      startLine: number;
+      endLine: number;
+      segmentKey: string;
+      snippet: string;
+      totalLines: number;
+      newline: string;
+      inBoilerplates: boolean;
+      fullFile: boolean;
+    }>;
+
+    for (const segment of entrySegments) {
+      const segmentData = readSegment(segment.entry.path, segment.entry.startLine, segment.entry.endLine);
+      if (!segmentData) {
+        continue;
+      }
+      const inBoilerplates = isSubPath(segment.entry.path, boilerplatesRoot);
+      const fullFile = segment.entry.startLine === 1 && segment.entry.endLine === segmentData.totalLines;
+      enrichedEntries.push({
+        path: segment.entry.path,
+        startLine: segment.entry.startLine,
+        endLine: segment.entry.endLine,
+        segmentKey: segment.segmentKey,
+        snippet: segmentData.content,
+        totalLines: segmentData.totalLines,
+        newline: segmentData.newline,
+        inBoilerplates,
+        fullFile,
+      });
+    }
+
+    if (enrichedEntries.length !== 2) {
+      continue;
+    }
+
+    const canonicalSnippet = enrichedEntries[0].snippet.length >= enrichedEntries[1].snippet.length
+      ? enrichedEntries[0].snippet
+      : enrichedEntries[1].snippet;
+
+    if (canonicalSnippet.length < minLength) {
+      continue;
+    }
+
+    const templateSource = enrichedEntries.find(entry => entry.inBoilerplates && entry.fullFile);
+    const templateEntry = templateSource ?? enrichedEntries[0];
+    const snippet = templateEntry.snippet;
+    const isPartial = !(templateEntry.startLine === 1 && templateEntry.endLine === templateEntry.totalLines);
+
+    const templatePath = templateSource
+      ? ensureJinjaPath(templateEntry.path)
+      : prepareTemplatePath(templateEntry.path, isPartial, partialCounter);
+
+    const includePathRelative = toPosix(path.relative(path.dirname(boilerplatesRoot), templatePath));
+
+    try {
+      ensureTemplateRecord(templateRecords, templatePath, snippet, isPartial, templateEntry.path);
+    } catch (error) {
+      console.error((error as Error).message);
+      process.exit(1);
+    }
+
+    if (templateSource && templateEntry.path !== templatePath) {
+      plannedMoves.push({ from: templateEntry.path, to: templatePath });
+    }
+
+    for (const entry of enrichedEntries) {
+      processedSegments.add(entry.segmentKey);
+
+      const fullFile = entry.startLine === 1 && entry.endLine === entry.totalLines;
+      if (isSubPath(entry.path, boilerplatesRoot) && entry.path === templatePath && fullFile) {
+        continue;
+      }
+
+      if (isSubPath(entry.path, boilerplatesRoot) && entry.path !== templatePath) {
+        registerSegment(
+          fileConversions,
+          entry.path,
+          {
+            startLine: entry.startLine,
+            endLine: entry.endLine,
+            templatePath: includePathRelative,
+            fullFile,
+          },
+          entry.newline,
+          entry.snippet,
+        );
+        continue;
+      }
+
+      registerSegment(
+        fileConversions,
+        entry.path,
+        {
+          startLine: entry.startLine,
+          endLine: entry.endLine,
+          templatePath: includePathRelative,
+          fullFile,
+        },
+        entry.newline,
+        entry.snippet,
+      );
+    }
+  }
+
+  const operations: string[] = [];
+
+  if (templateRecords.size === 0 && fileConversions.size === 0 && plannedMoves.length === 0) {
+    console.log("No qualifying snippets detected above the minimum length threshold. No changes required.");
+    process.exit(0);
+  }
+
+  for (const move of plannedMoves) {
+    operations.push(`Move ${move.from} -> ${move.to}`);
+    if (!dryRun) {
+      moveFilePreservingGitHistory(move.from, move.to);
+    }
+  }
+
+  for (const [templatePath, record] of templateRecords.entries()) {
+    operations.push(`Write template ${templatePath}`);
+    if (!dryRun) {
+      writeFile(templatePath, record.content.endsWith("\n") ? record.content : `${record.content}\n`);
+    }
+  }
+
+  for (const [filePath, conversion] of fileConversions.entries()) {
+    const destPath = conversion.destPath;
+    if (filePath !== destPath) {
+      operations.push(`Rename ${filePath} -> ${destPath}`);
+      if (!dryRun) {
+        moveFilePreservingGitHistory(filePath, destPath);
+      }
+    }
+
+    const lines = conversion.originalContent.split(/\r?\n/);
+    const newline = conversion.newline;
+
+    const sortedSegments = conversion.segments.sort((a, b) => b.startLine - a.startLine);
+
+    for (const segment of sortedSegments) {
+      const includeLine = createIncludeLine(segment.templatePath, (() => {
+        const originalLine = lines[segment.startLine - 1] ?? "";
+        const match = originalLine.match(/^\s*/);
+        return match ? match[0] : "";
+      })());
+      if (segment.fullFile) {
+        lines.splice(0, lines.length, includeLine);
+      } else {
+        const deleteCount = segment.endLine - segment.startLine + 1;
+        lines.splice(segment.startLine - 1, deleteCount, includeLine);
+      }
+    }
+
+    let updatedContent = lines.join(newline);
+    if (!updatedContent.endsWith(newline)) {
+      updatedContent += newline;
+    }
+
+    operations.push(`Update includes in ${destPath}`);
+    if (!dryRun) {
+      writeFile(destPath, updatedContent);
+    }
+  }
+
+  if (dryRun) {
+    console.log("Planned operations:");
+    for (const op of operations) {
+      console.log(`  - ${op}`);
+    }
+  }
+})().catch(error => {
+  console.error(`Fatal error: ${(error as Error).message}`);
+  process.exit(1);
+});
