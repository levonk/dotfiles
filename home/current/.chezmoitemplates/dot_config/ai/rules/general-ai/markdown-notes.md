---
description: Markdown Notes guidelines
---
# Markdown Notes

## II. Linking Strategy

### General

- Standard date format is {YYYY-MM-DD} (prefered) or {YYYYMMDD} (really long file names)
- Add alt text for images
- try to have tags, MOCs, folders, links be related to each other
- Every page should have a level 1 heading `# {header}` if one doesn't exist. If it doesn't exist, set it to the file title.

### Frontmatter

- Always add front-matter to a page (title, tags, aliases, contextual tags)
- Use YAML arrays instead of comma separated

### Maps of Content (MOC)

- Create new MOCs if necessary in `{vault}/Meta/MOC - Map Of Content` path
- Always link back to the appropriate MOC
- There is a template for new MOCs in `{vault}/Meta/Templates/99 MOC Template.md`
- MOC filename should start with `MOC - *.md`

## Templates

- Don't put page specific content on any pages in the subtree `{vault}/Meta/Templates` as those pages are meant to be materialized for new pages.
- Templates belong in `{vault}/Meta/Templates`
- Template filenames that you create should begin with `99 *.md`

## File Organization

- Lets put attachments (non- *.md files) in `{vault}/Meta/Attachments` with a tree that mirrors the path to the note that includes it. So `{vault}/Default/CRM.md` would have the attachments in `{vault}/Meta/Attachments/Default`
- if you encounter duplicate notes, let me know.

### A. Link Types

- **1. Direct Links:**  Link to specific pages when discussing a related concept.
  - Example: "The [[Waterstart]] is an essential skill for windsurfers."
- **2. Implied Links:**  Use tags to create implied links.  For example, if a page is tagged with `#gybing`, it will be implicitly linked to any other page that also has the `#gybing` tag. This works well with Dataview queries in Obsidian.
- **3. Contextual Links:** Link to pages that provide additional context or background information.
  - Example: "For more information about [[Sail Trim]], see this page."

- If page content is referring to an external company, or linkable item, make it a link to the external site.

### B. Linking Considerations

- **1. Avoid Over-Linking:** Don't link every word on a page.  Only link to pages that are *directly relevant* to the current topic.
- **2. Link in Both Directions:**  If you link from page A to page B, **consider** adding a link back from page B to page A (where appropriate).  This creates a bidirectional link, making it easier to navigate the knowledge base. Backlinks are automatic in Obsidian.
- **3. Use Aliases:** Use aliases to create more natural-sounding links.
  - Example: `[[Duck Gybe Technique|Duck Gybe]]`  (The link will display as "Duck Gybe" but will link to the "Duck Gybe Technique" page).
- **4. Visualize the Graph:** Regularly use the graph view (if your system has one) to visualize the connections between your notes and identify any gaps in your linking strategy.

### C. Linking Examples

- **Technique Pages:** Link to prerequisite skills, related techniques, gear recommendations, and locations where the technique is commonly practiced.
- **Gear Pages:** Link to the types of windsurfing the gear is best suited for, techniques that require that gear, and locations where the gear is popular.
- **Location Pages:** Link to common windsurfing conditions, the types of gear recommended, and techniques practiced in that location.
- **People Pages:** Link to their accomplishments, signature gear, favourite spots, relevant techniques.

## III. Tagging Strategy

### A. Standardized Tags

The directory path typically carries useful information for tagging purposes.

Use a standardized set of tags to categorize notes.  Examples:

- `#windsurf` (General Windsurfing)
- `#technique`
- `#gear`
- `#location`
- `#people`
- `#trick`
- `#beginner`
- `#intermediate`
- `#advanced`
- `#wavesailing`
- `#freestyle`
- `#slalom`

### B. Hierarchical Tags

Use hierarchical tags to create a more granular categorization system.

- Example:
  - `#technique/gybing`
  - `#gear/sail`
  - `#location/wavespot`

### C. Tag Considerations

- **1. Don't Over-Tag:** Don't add superficial tags that are unlikely to be used, or overwhelming if used, to a page.  Only use tags that are truly relevant.
- **2. Consistency:**  Use the same tags consistently throughout the knowledge base.
- **3. Review and Refine:** Regularly review your tags and remove any that are no longer needed.

## IV. Naming Conventions

### A. Page Titles

- **1. Descriptive Titles:** Use clear, descriptive titles for your pages.
- **2. Specificity:** Be as specific as possible in your titles.
- **3. Consistency:** Use a consistent naming convention for similar types of pages.
- **4. Examples:**
  - "Duck Gybe Technique" (not just "Duck Gybe")
  - "Starboard Tacks" (not just "Sailing")
  - "Hookipa Beach Park, Maui" (not just "Hookipa")

### B. File Names (If applicable - important for Obsidian or systems that use file names)

- **1. Match Page Title:** Generally, the file name should match the page title (with spaces replaced by hyphens or underscores).
- **2. Lowercase:** Use lowercase letters for file names.
- **3. Avoid Special Characters:** Avoid using special characters in file names (except for hyphens or underscores).

## V. Maintenance & Evolution

- **A. Regular Review:** Regularly review your notes and links to ensure they are accurate and up-to-date.
- **B. Refactor as Needed:** Don't be afraid to refactor your notes and links as your understanding evolves.
