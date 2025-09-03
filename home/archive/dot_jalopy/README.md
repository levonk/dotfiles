# Jalopy configuration

This directory contains configuration for the legacy Jalopy Java source code formatter.

- File: `jalopy.xml` — baseline, conservative settings.
- Scope: 4-space indentation, 120-character column width, end-of-line braces, sorted imports with groups, basic Javadoc formatting.

## Usage

- Console:
  ```bash
  jalopy -c /path/to/jalopy.xml -r -d <outputDir> <inputDirOrFiles>
  ```
- Maven Plugin (Jalopy 2):
  ```xml
  <plugin>
    <groupId>jalopy</groupId>
    <artifactId>jalopy-maven-plugin</artifactId>
    <version>2.0</version>
    <configuration>
      <conventionFile>${project.basedir}/.jalopy/jalopy.xml</conventionFile>
    </configuration>
    <executions>
      <execution>
        <goals>
          <goal>format</goal>
        </goals>
      </execution>
    </executions>
  </plugin>
  ```

## DOCTYPE note
Some Jalopy distributions expect a DOCTYPE reference for validation. If your formatter errors on load, uncomment and adjust the DOCTYPE in `jalopy.xml` header to match your installation (example shown in the file comments).

## Customization
Adjust groups, max line length, wrapping, and Javadoc limits to match project standards. Exporting from a Jalopy GUI and diffing against this file can help align settings precisely.
