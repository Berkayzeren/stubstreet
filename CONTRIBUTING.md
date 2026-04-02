# Contributing to StubStreet

First off, thank you for considering contributing to StubStreet! It's people like you that make StubStreet such a great marketplace. 

By participating in this project, you agree to abide by our code of conduct.

## 1. How Can I Contribute?

### Reporting Bugs
This section guides you through submitting a bug report. Following these guidelines helps maintainers understand your report, reproduce the behavior, and find related issues.
* Check the existing issues to see if the bug has already been reported.
* Use the **Bug Report** template provided in the issues section.
* Include clear steps to reproduce, the expected behavior, and what actually happens.

### Suggesting Enhancements
* Check the existing issues for similar suggestions.
* Use the **Feature Request** template to submit your idea.
* Clearly explain how your enhancement would improve the project or user experience.

### Contributing Code (Pull Requests)
Public contributions are warmly welcomed through Pull Requests (PRs). However, **no code will be merged without the explicit review and approval of the repository owner.**

1. **Fork the Repository:** Create your own fork of the project to your GitHub account.
2. **Clone the Fork:** Clone the repository to your local machine.
3. **Create a Branch:** Create a branch for your feature or bugfix.
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bugfix-name
   ```
4. **Develop Your Changes:** 
   * Ensure your code follows the existing style guidelines.
   * Test your API changes and make sure the existing CI workflow (`flutter test`) passes.
   * Keep commits descriptive and atomic.
5. **Push to Your Fork:** 
   ```bash
   git push origin your-branch-name
   ```
6. **Open a Pull Request:** Go to the original repository and open a Pull Request. Use the provided PR template to summarize your changes.

## 2. Setting Up the Development Environment
Please refer to the `README.md` for detailed instructions on `scripts/dev_setup.sh` and setting up your local Firebase Emulator. Do NOT use production keys for your local test environment! Instead, request a test config if necessary or use the provided mock data examples.

## 3. Pull Request Review Process
* The Project Maintainer(s) will review your PR.
* You may be asked to make changes to your code.
* Once everything looks good, the maintainers will **Approve** and **Merge** the PR into the `main` or develop branch.

Thank you for your time and effort!
