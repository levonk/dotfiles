# Repository File Lists

watching files diverage that should be identical, I decided to modularize it
and combine it then commit all the files. When I need to make a change,
I just run the script to combine the files again

## VCS Ignore Files
- Example outputs
  - .gitignore
- inputs
  - Included
    - .config/filelists/garbage.ignorefile.md
    - .config/filelists/garbage.ignorefile
    - .config/filelists/security.ignorefile
- Excluded
    - .config/filelists/ai.ignorefile
    - .config/filelists/dev.ignorefile

## Packaging Ignore Files
- Example outputs
  - .npmignore
- inputs
  - Included
    - .config/filelists/dev.ignorefile.md
    - .config/filelists/dev.ignorefile
    - .config/filelists/garbage.ignorefile
    - .config/filelists/security.ignorefile
- Excluded
    - .config/filelists/ai.ignorefile

## AI Ignore Files
- Example outputs
  - .codieumignore
  - .cursorignore
- inputs
  - Included
    - .config/filelists/ai.ignorefile.md
    - .config/filelists/ai.ignorefile
    - .config/filelists/garbage.ignorefile
    - .config/filelists/security.ignorefile
- Excluded
    - .config/filelists/dev.ignorefile


## How to Generate
### From the command line
```bash
  .config/filelists/generate-ignores.js
```
### From npm
```json
  {
    "scripts": {
      "generate-ignore": "node .config/filelists/generate-ignores.js"
    }
  }
```