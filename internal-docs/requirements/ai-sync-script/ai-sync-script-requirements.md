# AI Sync Script Requirements

I need a Bash script to synchronize my AI workflows and templates from `home/current/.chezmoitemplates/dot_config/ai` template directory tree to various destination directories.

Source Directory:

    - CHEZMOI_ROOT is `home/current`
    - CHEZMOI_TEMPLATES_ROOT is `$CHEZMOI_ROOT/.chezmoitemplates`

destination Mappings (Configuration):

    The script should define its synchronization targets and rules in an easily configurable section at the top of the script, using an associative array or a similar structure. This will map source paths/patterns to destination paths and specify any required transformations.

    Example Mappings (Windsurf family, for now):

        - source: $CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/ -> destination: $CHEZMOI_ROOT/dot_codeium/windsurf/global_workflows/
      notes:
        - supports only flattened files (no subdirectories) at destination
        - set mapping option: flatten = true
    - source: $CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/ -> destination: $CHEZMOI_ROOT/dot_codeium/windsurf-next/global_workflows/
      notes:
        - set mapping option: flatten = true

    Behavior: For each source Markdown file under `workflows/`, generate a corresponding `.md.tmpl` file under the destination `global_workflows/` that contains a single Go template include line referencing the source. If `flatten = false`, preserve the relative subdirectory structure. If `flatten = true`, write all files at the destination root and encode the relative path in the filename using underscores. For example,

        source file: $CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/software-dev/frontend-dev/frontend-node.md
    generated (preserve dirs):  $CHEZMOI_ROOT/dot_codeium/windsurf/global_workflows/software-dev/frontend-dev/frontend-node.md.tmpl
    generated (flatten=true):   $CHEZMOI_ROOT/dot_codeium/windsurf/global_workflows/software-dev_frontend-dev_frontend-node.md.tmpl
    contents:                   {{ includeTemplate "dot_config/ai/workflows/software-dev/frontend-dev/frontend-node.md" . }}

Synchronization Logic (Reference Mode):

    For each defined mapping, the script should:

        Create the destination directory path if it does not already exist.

        Recursively traverse source files (default include: `**/*.md`). For each source file, create a destination file with extension `.md.tmpl` (always append `.tmpl`). If `flatten = false`, preserve the relative path under the destination root.

        Write a single line to each destination file: `{{ includeTemplate "dot_config/ai/<relative_path_from_src_root>" . }}` so that Chezmoi can resolve the include when rendering.

    If a destination file already exists and is not exclusively a single `includeTemplate` line matching the expected include, emit a warning and skip unless `--force` is provided. If `--quiet` is set, suppress this warning.

    Flattening resolution (when `flatten = true`):

        1) Naming strategy: prefer basename-only. The initial candidate destination is `<dst_root>/<basename>.md.tmpl`.

        2) If the candidate does not exist: generate it with the one-line include and stop.

        3) If the candidate exists: read its contents.
           - If it is strictly a single `includeTemplate` line targeting the SAME source path: skip generation (no-op).
           - If it is strictly a single `includeTemplate` line targeting a DIFFERENT source path: compute a disambiguated name by prefixing the source-relative directory path components joined with underscores before the basename, e.g., `<dst_root>/<dir1_dir2_basename>.md.tmpl`. Then generate the new file at that disambiguated path.
           - In both cases above (different source path), emit a warning unless `--quiet` is set. The warning MUST include:
                - path of the existing file (candidate path),
                - the include target found inside the existing file,
                - the include target you are trying to write,
                - and the final path you will write to (for the disambiguated case).

        4) If the candidate exists but is not a single-line include template: warn and skip unless `--force` is provided. With `--force`, overwrite the candidate with the correct one-line include.

        Important: By default, the script should not delete files from the destination that are no longer in the source. When `--delete-stale` is provided, remove generated `.tmpl` files that do not have a corresponding source file.

    Excludes: Respect `.gitignore` rules for source traversal (including nested `.gitignore` files). Only process files not ignored by `.gitignore`.

Reference Mode Details:

    Output extension: default `.md.tmpl`; always append `.tmpl` so includes resolve at template time. Chezmoi will strip `.tmpl` after processing.

    Include root: construct include paths beginning with `dot_config/ai/` followed by the source-relative path (e.g., `dot_config/ai/workflows/...`). Include path construction is independent of `flatten`.

    No content transformation in this first version; the destination file is a one-line include template only.

Execution Modes:

    Dry-Run Mode (--dry-run): Simulate generation without writing files. Report actions like "Would generate include for X → Y" and "Would delete stale Y".

    Verbose Mode (--verbose or -v): Output detailed information about each file being processed and each reference generated.

    These flags should be combinable (e.g., --dry-run --verbose).

Error Handling:

    Check for the existence of source directories.

    Handle cases where destination directories cannot be created.

    Provide informative error messages.

Dependencies:

    Use standard Unix utilities available in Bash (e.g., cp, mkdir -p, rsync, find, sed, awk, readlink, basename, dirname).

Script Structure:

    Organize the script with clear functions for readability (e.g., process_mapping, write_reference_file, dry_run_report).

    Include a main function or similar entry point.

    Provide clear comments.

CLI Flags:

    --dry-run           Simulate all operations without writing.
    --verbose, -v       Verbose logging.
    --delete-stale      Remove destination .tmpl files with no matching source.
    --force             Overwrite existing destination files and silence non-include-only content checks.
    --quiet             Suppress warnings about existing non-include-only files.

Scope (Current):

    Target Windsurf family for now:
        - src_root: $CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/
          dst_root: $CHEZMOI_ROOT/dot_codeium/windsurf/global_workflows/
          flatten: true
        - src_root: $CHEZMOI_TEMPLATES_ROOT/dot_config/ai/workflows/
          dst_root: $CHEZMOI_ROOT/dot_codeium/windsurf-next/global_workflows/
          flatten: true
    Additional mappings (e.g., agents, rules, other IDEs) can be added later using the same pattern and may set `flatten: false` if the IDE supports subdirectories.
