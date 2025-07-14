# Contributing to LiveCaptionsXR

First off, thank you for considering contributing to LiveCaptionsXR! It's people like you that make the open source community such a great place. We welcome any and all contributions.

## Code of Conduct

This project and everyone participating in it is governed by the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

There are many ways to contribute to LiveCaptionsXR, from writing code and documentation to reporting bugs and suggesting new features.

### Reporting Bugs

If you find a bug, please open an issue on the GitHub repository. Please include as much detail as possible, including:

*   A clear and descriptive title.
*   A detailed description of the bug, including steps to reproduce it.
*   The expected behavior and what actually happened.
*   Your environment details (e.g., device, OS version).

### Suggesting Enhancements

If you have an idea for a new feature or an enhancement to an existing one, please open an issue on the GitHub repository. Please include:

*   A clear and descriptive title.
*   A detailed description of the proposed enhancement.
*   Any mockups or examples that might help illustrate your idea.

### Pull Requests

We welcome pull requests! If you'd like to contribute code, please follow these steps:

1.  Fork the repository and create your branch from `main`.
2.  Set up your development environment (see "Getting Started" below).
3.  Make your changes, and please be sure to follow the project's coding style.
4.  Add or update tests for your changes.
5.  Ensure that all tests pass.
6.  Open a pull request with a clear and descriptive title and a detailed description of your changes.

## Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/craigm26/LiveCaptionsXR.git
    cd LiveCaptionsXR
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the app:**
    ```bash
    flutter run
    ```

## Running Tests

The project uses `flutter_test` for unit and widget tests, and `integration_test` for integration tests. We use `mockito` for mocking dependencies and `build_runner` to generate the necessary mock files.

*   **Run all tests:**
    ```bash
    flutter test
    ```
*   **Run tests in a specific file:**
    ```bash
    flutter test test/path/to/your_test.dart
    ```
*   **Generate mocks:**
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

## Coding Style

This project follows the standard Dart and Flutter style guides. We use the analysis options defined in the `analysis_options.yaml` file to enforce these styles. Please ensure that your code is formatted and analyzed before submitting a pull request.

*   **Format code:**
    ```bash
    dart format .
    ```
*   **Analyze code:**
    ```bash
    flutter analyze
    ```

## Questions?

If you have any questions, please feel free to open an issue on the GitHub repository.
