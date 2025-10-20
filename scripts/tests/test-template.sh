#!/usr/bin/env bash
set -euo pipefail

# Create a test directory
TEST_DIR="$(mktemp -d)"
echo "Testing in: $TEST_DIR"

# Copy the template to the test directory
cp "home/current/.chezmoitemplates/dot_config/ai/workflows/software-dev/devops/ansible/ansible-document10-role.md.tmpl" "$TEST_DIR/"

# Create a test vars file
cat > "$TEST_DIR/vars.yaml" << 'EOF'
min_ansible_version: "2.10+"
min_python_version: "3.8+"
collection_name: "test-collection"
collection_description: "Test collection for template validation"
EOF

# Try to process the template
/tmp/chezmoi execute-template --init --promptString min_ansible_version=2.10+ --promptString min_python_version=3.8+ --promptString collection_name=test-collection --promptString collection_description="Test collection for template validation" < "$TEST_DIR/ansible-document10-role.md.tmpl" > "$TEST_DIR/output.md" 2>&1 || {
    echo "Error processing template:"
    cat "$TEST_DIR/output.md"
    exit 1
}

echo "Template processed successfully. Output in $TEST_DIR/output.md"
cat "$TEST_DIR/output.md"
