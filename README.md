# Flexion application security design challenge

## Introduction

This is a small working application built using AWS (https://aws.amazon.com/),
Terraform (https://www.terraform.io/), Ansible (https://www.ansible.com/), and
Node.js (https://nodejs.org/en/).

The application itself is merely meant to be a primitive placeholder, and
provides the following functionality:

- The `/` endpoint is the homepage which prints a welcome message and the name
  of the app.
- Setting `/?app_name=new_app_name` will persistently change the name of the
  app.

All of the deployment is orchestrated by Terraform, so the following will deploy
the full application stack:

```
cd terraform
bash deploy.sh
```

To run the application (not required for this challenge) you must have Terraform,
Ansible, and the AWS CLI (https://aws.amazon.com/cli/) installed on your machine.
