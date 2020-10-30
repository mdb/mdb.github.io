---
title: Using wget over Ansible's get_url
date: 2015-12-23
tags:
- ansible
- operations
thumbnail: wget_thumb.png
teaser: Authenticated downloads with Ansible
---

Problem: In provisioning a server, your Ansible playbook needs to download files from a URL behinded authentication, such as a private GitHub repository. In Ansible 2.0, Ansible's [get_url]() supports custom headers &mdash; such as `Authorization` &mdash; but pre-2.0 Ansible does not.

Solution: Use `wget`, a `wgetrc`, and `ansible-vault`.

Step 1: Generate a [GitHub access token](https://github.com/settings/tokens)

Step 2: Store the token in an Ansible `group_var` at `your_playbook_dir/group_vars/all`:

```yaml
github_token: "your access token value"
```

Step 3: Use `ansible-vault` to encrypt your `github_token`; enter a password at the prompt:

```bash
$ ansible-vault encrypt your_playbook_dir/group_vars/all
Vault password:
Confirm Vault password:
Encryption successful
```

Step 4: Create a `your_playbook_dir/tempaltes/wgetrc.j2` template to house `wgetrc` configuration. Specify the proper headers to authenticate against GitHub:

```bash
header = Authorization: token {{ github_token }}
header = Accept: application/vnd.github.v3.raw
```

Step 5: Add a task to your playbook to lay down the `wgetrc` file:

```yaml
- name: lay down /etc/wgetrc file
  template:
    src: wgetrc.j2
    dest: /etc/wgetrc
```

Step 6: Add a task to your playbook to download the file from a private GitHub repository:

```yaml
- name: download some_service_def init.d script
  shell: "wget -O /etc/init.d/some_service_def https://github.com/raw/user/repo/master/some_service_def"
```

Note that, in Ansible 2.0, the use of `wget` can be replaced with `get_url`, replacing steps 4, 5, and 6 with the following:

```yaml
- name: download some_service_def init.d script
  get_url:
    url:  https://github.com/raw/user/repo/master/some_service_def
    headers: "Authorization:token {{ github_token }},Accept:application/vnd.github.v3.raw"
    dest: /etc/init.d/some_service_def
```
