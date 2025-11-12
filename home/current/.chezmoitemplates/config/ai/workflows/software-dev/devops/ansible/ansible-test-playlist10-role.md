---
description: Update `test-levonk.{collection}.{role}.yml` playlist with all tasks in roles in the collection asked for of `levonk` namespace
---

Scan the `README.md`s of the ansible namespace.collection.role passed in as an argument of the namespace `levonk` located in `/mnt/d/p/gh/lrepo52/mrepo/proj/homenet/deployment-operations/3rdparty/gh/levonk/levonk-ansible-galaxy/ansible-galaxy/collections/ansible_collections/levonk`, then update the test playlist located in `/mnt/d/p/gh/lrepo52/mrepo/proj/homenet/deployment-operations/3rdparty/gh/levonk/levonk-ansible-galaxy/test-{fully qualified role e.g., levonk.sample-collection.sample-role}.yml` making sure every task in every role of the collection in namespace `levonk` located in `/mnt/d/p/gh/lrepo52/mrepo/proj/homenet/deployment-operations/3rdparty/gh/levonk/levonk-ansible-galaxy/ansible-galaxy/collections/ansible_collections/levonk` is enabled. You are expected to do this by investigating the role-level `README.md` file in the specified role that was passed in.

Note: 
- If this was called on anything other than a specific role, please go to the `levonk.{collection.role}` and traverse the tree to the appropriate role (i.e., if the user is in a specific task file, go up the tree until you get to the role that owns that task file.